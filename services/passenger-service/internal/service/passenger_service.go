package service

import (
	"context"
	"errors"
	"fmt"
	"mime/multipart"
	"time"

	"github.com/google/uuid"

	"airline/passenger-service/internal/cache"
	"airline/passenger-service/internal/config"
	"airline/passenger-service/internal/middleware"
	"airline/passenger-service/internal/model"
	"airline/passenger-service/internal/repository"
	"airline/passenger-service/internal/storage"
	"airline/passenger-service/internal/validation"
)

type PassengerService struct {
	repo   *repository.PassengerRepo
	redis  *cache.Redis
	minio  *storage.MinIO
	config *config.Config
}

func New(repo *repository.PassengerRepo, redis *cache.Redis, minio *storage.MinIO, cfg *config.Config) *PassengerService {
	return &PassengerService{repo: repo, redis: redis, minio: minio, config: cfg}
}

func (s *PassengerService) Register(req model.RegisterRequest) (*model.LoginResponse, error) {
	if err := validation.ValidatePassword(req.Password); err != nil {
		return nil, err
	}

	user, passenger, err := s.repo.CreateUser(req)
	if err != nil {
		return nil, err
	}

	return s.issueTokens(user, passenger)
}

func (s *PassengerService) Login(req model.LoginRequest) (*model.LoginResponse, error) {
	user, err := s.repo.AuthenticateUser(req.Email, req.Password)
	if err != nil {
		return nil, err
	}
	var passenger *model.Passenger
	if user.PassengerID != nil {
		passenger, _ = s.repo.GetPassengerByID(*user.PassengerID)
	}
	return s.issueTokens(user, passenger)
}

func (s *PassengerService) Refresh(refreshToken string) (*model.LoginResponse, error) {
	userIDStr, err := middleware.ParseRefreshToken(refreshToken, s.config.JWTSecret)
	if err != nil {
		return nil, repository.ErrInvalidCredentials
	}

	if s.redis != nil {
		stored, err := s.redis.GetRefreshToken(context.Background(), userIDStr)
		if err != nil || stored != refreshToken {
			return nil, repository.ErrInvalidCredentials
		}
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return nil, repository.ErrInvalidCredentials
	}

	user, err := s.repo.GetUserByID(userID)
	if err != nil {
		return nil, err
	}

	var passenger *model.Passenger
	if user.PassengerID != nil {
		passenger, _ = s.repo.GetPassengerByID(*user.PassengerID)
	}
	return s.issueTokens(user, passenger)
}

func (s *PassengerService) issueTokens(user *model.User, passenger *model.Passenger) (*model.LoginResponse, error) {
	access, refresh, expiresAt, err := middleware.GenerateTokens(
		user.UserID.String(),
		user.Email,
		"passenger",
		s.config.JWTSecret,
		s.config.JWTAccessExpMinute,
		s.config.JWTRefreshExpHour,
	)
	if err != nil {
		return nil, err
	}

	if s.redis != nil {
		ttl := time.Duration(s.config.JWTRefreshExpHour) * time.Hour
		_ = s.redis.SetRefreshToken(context.Background(), user.UserID.String(), refresh, ttl)
	}

	resp := &model.LoginResponse{
		AccessToken:  access,
		RefreshToken: refresh,
		ExpiresAt:    expiresAt,
		User:         model.ToUserResponse(user),
	}
	_ = passenger
	return resp, nil
}

func (s *PassengerService) GetPassenger(passengerID uuid.UUID) (*model.PassengerResponse, error) {
	p, err := s.repo.GetPassengerByID(passengerID)
	if err != nil {
		return nil, err
	}
	resp := model.ToPassengerResponse(p)
	return &resp, nil
}

func (s *PassengerService) UpdatePassenger(passengerID uuid.UUID, req model.UpdatePassengerRequest) (*model.PassengerResponse, error) {
	p, err := s.repo.UpdatePassenger(passengerID, req)
	if err != nil {
		return nil, err
	}
	resp := model.ToPassengerResponse(p)
	return &resp, nil
}

func (s *PassengerService) CreateDocument(
	passengerID uuid.UUID,
	req model.CreateDocumentRequest,
	file *multipart.FileHeader,
) (*model.DocumentResponse, error) {
	expiry, err := time.Parse("2006-01-02", req.ExpiryDate)
	if err != nil {
		return nil, fmt.Errorf("invalid expiry_date format, use YYYY-MM-DD")
	}
	if req.DocumentType == "PASSPORT" && expiry.Before(time.Now().AddDate(0, 6, 0)) {
		return nil, errors.New("passport must be valid for at least 6 months")
	}

	doc, err := s.repo.CreateDocument(passengerID, req)
	if err != nil {
		return nil, err
	}

	if file != nil && s.minio != nil {
		f, err := file.Open()
		if err != nil {
			return nil, err
		}
		defer f.Close()

		contentType := file.Header.Get("Content-Type")
		if contentType == "" {
			contentType = "application/octet-stream"
		}
		_, err = s.minio.UploadDocument(
			context.Background(),
			passengerID.String(),
			req.DocumentType,
			file.Filename,
			f,
			file.Size,
			contentType,
		)
		if err != nil {
			_ = s.repo.DeleteDocument(passengerID, doc.DocumentID)
			return nil, fmt.Errorf("upload document: %w", err)
		}
	}

	resp := model.ToDocumentResponse(doc)
	return &resp, nil
}

func (s *PassengerService) GetDocuments(passengerID uuid.UUID) ([]model.DocumentResponse, error) {
	docs, err := s.repo.GetDocuments(passengerID)
	if err != nil {
		return nil, err
	}
	out := make([]model.DocumentResponse, 0, len(docs))
	for i := range docs {
		out = append(out, model.ToDocumentResponse(&docs[i]))
	}
	return out, nil
}

func (s *PassengerService) DeleteDocument(passengerID, documentID uuid.UUID) error {
	return s.repo.DeleteDocument(passengerID, documentID)
}

func (s *PassengerService) GetCountries() ([]model.CountryResponse, error) {
	countries, err := s.repo.GetCountries()
	if err != nil {
		return nil, err
	}
	out := make([]model.CountryResponse, 0, len(countries))
	for _, c := range countries {
		out = append(out, model.ToCountryResponse(c))
	}
	return out, nil
}

func (s *PassengerService) EnsurePassengerAccess(userID, passengerID uuid.UUID) error {
	user, err := s.repo.GetUserByID(userID)
	if err != nil {
		return err
	}
	if user.PassengerID == nil || user.PassengerID.String() != passengerID.String() {
		return repository.ErrNotFound
	}
	return nil
}
