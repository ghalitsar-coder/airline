package repository

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"airline/passenger-service/internal/model"
)

var (
	ErrNotFound             = errors.New("not found")
	ErrInvalidCredentials   = errors.New("invalid credentials")
	ErrDuplicateEmail       = errors.New("duplicate email")
	ErrDocumentLimitReached = errors.New("document limit reached")
)

type PassengerRepo struct {
	db *gorm.DB
}

func New(db *gorm.DB) *PassengerRepo {
	return &PassengerRepo{db: db}
}

func (r *PassengerRepo) CreateUser(req model.RegisterRequest) (*model.User, *model.Passenger, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, nil, err
	}

	dob, err := time.Parse("2006-01-02", req.DateOfBirth)
	if err != nil {
		return nil, nil, err
	}

	var user *model.User
	var passenger *model.Passenger

	err = r.db.Transaction(func(tx *gorm.DB) error {
		email := req.Email
		passenger = &model.Passenger{
			FirstName:   req.FirstName,
			LastName:    req.LastName,
			DateOfBirth: dob,
			Gender:      req.Gender,
			Email:       &email,
			IsActive:    true,
		}
		if req.Nationality != "" {
			passenger.Nationality = &req.Nationality
		}
		if req.PhoneNumber != "" {
			passenger.PhoneNumber = &req.PhoneNumber
		}
		if err := tx.Create(passenger).Error; err != nil {
			return err
		}

		pid := passenger.PassengerID
		user = &model.User{
			PassengerID:  &pid,
			Username:     req.Email,
			Email:        req.Email,
			PasswordHash: string(hash),
			IsActive:     true,
		}
		return tx.Create(user).Error
	})
	if err != nil {
		if isUniqueViolation(err) {
			return nil, nil, ErrDuplicateEmail
		}
		return nil, nil, err
	}
	return user, passenger, nil
}

func (r *PassengerRepo) AuthenticateUser(email, password string) (*model.User, error) {
	var user model.User
	err := r.db.Where("email = ? AND is_active = ?", email, true).First(&user).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrInvalidCredentials
		}
		return nil, err
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return nil, ErrInvalidCredentials
	}
	return &user, nil
}

func (r *PassengerRepo) GetUserByID(userID uuid.UUID) (*model.User, error) {
	var user model.User
	err := r.db.Where("user_id = ?", userID).First(&user).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrNotFound
	}
	return &user, err
}

func (r *PassengerRepo) GetPassengerByID(passengerID uuid.UUID) (*model.Passenger, error) {
	var p model.Passenger
	err := r.db.Where("passenger_id = ?", passengerID).First(&p).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrNotFound
	}
	return &p, err
}

func (r *PassengerRepo) UpdatePassenger(passengerID uuid.UUID, req model.UpdatePassengerRequest) (*model.Passenger, error) {
	updates := map[string]interface{}{}
	if req.FirstName != "" {
		updates["first_name"] = req.FirstName
	}
	if req.MiddleName != "" {
		updates["middle_name"] = req.MiddleName
	}
	if req.LastName != "" {
		updates["last_name"] = req.LastName
	}
	if req.PhoneNumber != "" {
		updates["phone_number"] = req.PhoneNumber
	}
	if req.Nationality != "" {
		updates["nationality"] = req.Nationality
	}
	if len(updates) == 0 {
		return r.GetPassengerByID(passengerID)
	}

	result := r.db.Model(&model.Passenger{}).Where("passenger_id = ?", passengerID).Updates(updates)
	if result.Error != nil {
		return nil, result.Error
	}
	if result.RowsAffected == 0 {
		return nil, ErrNotFound
	}
	return r.GetPassengerByID(passengerID)
}

func (r *PassengerRepo) CountDocumentsByType(passengerID uuid.UUID, docType string) (int64, error) {
	var count int64
	err := r.db.Model(&model.PassengerDocument{}).
		Where("passenger_id = ? AND document_type = ?", passengerID, docType).
		Count(&count).Error
	return count, err
}

func (r *PassengerRepo) CreateDocument(passengerID uuid.UUID, req model.CreateDocumentRequest) (*model.PassengerDocument, error) {
	count, err := r.CountDocumentsByType(passengerID, req.DocumentType)
	if err != nil {
		return nil, err
	}
	if count >= 5 {
		return nil, ErrDocumentLimitReached
	}

	expiry, err := time.Parse("2006-01-02", req.ExpiryDate)
	if err != nil {
		return nil, err
	}

	doc := &model.PassengerDocument{
		PassengerID:    passengerID,
		DocumentType:   req.DocumentType,
		DocumentNumber: req.DocumentNumber,
		ExpiryDate:     expiry,
		IsPrimary:      req.IsPrimary,
	}
	if req.IssuingCountry != "" {
		doc.IssuingCountry = &req.IssuingCountry
	}
	if err := r.db.Create(doc).Error; err != nil {
		return nil, err
	}
	return doc, nil
}

func (r *PassengerRepo) GetDocuments(passengerID uuid.UUID) ([]model.PassengerDocument, error) {
	var docs []model.PassengerDocument
	err := r.db.Where("passenger_id = ?", passengerID).
		Order("is_primary DESC, document_type ASC").
		Find(&docs).Error
	return docs, err
}

func (r *PassengerRepo) GetDocument(passengerID, documentID uuid.UUID) (*model.PassengerDocument, error) {
	var doc model.PassengerDocument
	err := r.db.Where("document_id = ? AND passenger_id = ?", documentID, passengerID).First(&doc).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrNotFound
	}
	return &doc, err
}

func (r *PassengerRepo) DeleteDocument(passengerID, documentID uuid.UUID) error {
	result := r.db.Where("document_id = ? AND passenger_id = ?", documentID, passengerID).
		Delete(&model.PassengerDocument{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PassengerRepo) GetCountries() ([]model.Country, error) {
	var countries []model.Country
	err := r.db.Order("country_name ASC").Find(&countries).Error
	return countries, err
}

func isUniqueViolation(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return errors.Is(err, gorm.ErrDuplicatedKey) ||
		strings.Contains(msg, "duplicate key") ||
		strings.Contains(msg, "unique constraint")
}
