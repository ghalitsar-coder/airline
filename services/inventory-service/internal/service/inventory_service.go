package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"airline/inventory-service/internal/cache"
	"airline/inventory-service/internal/config"
	"airline/inventory-service/internal/model"
	"airline/inventory-service/internal/repository"
)

var (
	ErrNotFound      = errors.New("not found")
	ErrSeatConflict  = errors.New("seat conflict")
	ErrSeatBlocked   = errors.New("seat blocked")
	ErrRedisRequired = errors.New("redis required")
)

type InventoryService struct {
	repo  *repository.InventoryRepo
	redis *cache.Redis
	cfg   *config.Config
}

func New(repo *repository.InventoryRepo, redis *cache.Redis, cfg *config.Config) *InventoryService {
	return &InventoryService{repo: repo, redis: redis, cfg: cfg}
}

func (s *InventoryService) ListAircraftTypes() ([]model.AircraftTypeResponse, error) {
	types, err := s.repo.ListAircraftTypes()
	if err != nil {
		return nil, err
	}
	out := make([]model.AircraftTypeResponse, len(types))
	for i, t := range types {
		out[i] = model.ToAircraftTypeResponse(t)
	}
	return out, nil
}

func (s *InventoryService) GetSeatMap(aircraftID uuid.UUID) (*model.SeatMapResponse, error) {
	aircraft, aircraftType, err := s.repo.GetAircraftWithType(aircraftID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	configs, err := s.repo.ListCabinConfigurations(aircraft.AircraftTypeID)
	if err != nil {
		return nil, err
	}

	seats, err := s.repo.ListSeatsByAircraft(aircraftID)
	if err != nil {
		return nil, err
	}

	cabinOut := make([]model.CabinConfigResponse, len(configs))
	for i, c := range configs {
		cabinOut[i] = model.CabinConfigResponse{
			ConfigID:    c.ConfigID,
			SeatClass:   c.SeatClass,
			TotalSeats:  c.TotalSeats,
			RowsStart:   c.RowsStart,
			RowsEnd:     c.RowsEnd,
			SeatsPerRow: c.SeatsPerRow,
		}
	}

	return &model.SeatMapResponse{
		AircraftID:          aircraft.AircraftID,
		RegistrationNumber:  aircraft.RegistrationNumber,
		AircraftType:        model.ToAircraftTypeResponse(*aircraftType),
		CabinConfigurations: cabinOut,
		Seats:               model.ToSeatResponses(seats),
	}, nil
}

func (s *InventoryService) CreateSeatReservation(req model.CreateSeatReservationRequest) (*model.SeatReservationResponse, error) {
	if s.redis == nil {
		return nil, ErrRedisRequired
	}

	seat, err := s.repo.GetSeat(req.SeatID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	if !seat.IsActive {
		return nil, ErrSeatBlocked
	}

	ttlSec := s.cfg.DefaultLockTTLSec
	if req.TTLSeconds != nil && *req.TTLSeconds > 0 {
		ttlSec = *req.TTLSeconds
	}
	ttl := time.Duration(ttlSec) * time.Second
	expiresAt := time.Now().UTC().Add(ttl)

	ctx := context.Background()
	acquired, err := s.redis.TryLockSeat(ctx, req.FlightID, req.SeatID, req.BookingSessionID, ttl)
	if err != nil {
		return nil, err
	}
	if !acquired {
		return nil, ErrSeatConflict
	}

	taken, err := s.repo.HasActiveReservation(req.FlightID, req.SeatID)
	if err != nil {
		_ = s.redis.ReleaseSeatLock(ctx, req.FlightID, req.SeatID)
		return nil, err
	}
	if taken {
		_ = s.redis.ReleaseSeatLock(ctx, req.FlightID, req.SeatID)
		return nil, ErrSeatConflict
	}

	reservation := &model.SeatReservation{
		FlightID:   req.FlightID,
		SeatID:     req.SeatID,
		Status:     "RESERVED",
		ReservedAt: time.Now().UTC(),
		ExpiresAt:  &expiresAt,
	}
	if err := s.repo.CreateReservation(reservation); err != nil {
		_ = s.redis.ReleaseSeatLock(ctx, req.FlightID, req.SeatID)
		return nil, err
	}

	return s.toReservationResponse(reservation, req.BookingSessionID), nil
}

func (s *InventoryService) GetSeatReservation(lockID uuid.UUID) (*model.SeatReservationResponse, error) {
	reservation, err := s.repo.GetReservation(lockID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	sessionID := ""
	if s.redis != nil {
		sessionID, _ = s.redis.GetSeatLockSession(context.Background(), reservation.FlightID, reservation.SeatID)
	}

	resp := s.toReservationResponse(reservation, sessionID)
	if reservation.ExpiresAt != nil && reservation.ExpiresAt.Before(time.Now().UTC()) && reservation.Status == "RESERVED" {
		resp.Status = "EXPIRED"
	}
	return resp, nil
}

func (s *InventoryService) ReleaseSeatReservation(lockID uuid.UUID) error {
	reservation, err := s.repo.GetReservation(lockID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return ErrNotFound
		}
		return err
	}

	if s.redis != nil {
		_ = s.redis.ReleaseSeatLock(context.Background(), reservation.FlightID, reservation.SeatID)
	}

	return s.repo.DeleteReservation(lockID)
}

func (s *InventoryService) GetAvailableSeats(flightID, aircraftID uuid.UUID) (*model.AvailableSeatsResponse, error) {
	_, _, err := s.repo.GetAircraftWithType(aircraftID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	seats, err := s.repo.ListAvailableSeats(aircraftID, flightID)
	if err != nil {
		return nil, err
	}

	return &model.AvailableSeatsResponse{
		FlightID:       flightID,
		AircraftID:     aircraftID,
		AvailableCount: len(seats),
		Seats:          model.ToSeatResponses(seats),
	}, nil
}

func (s *InventoryService) toReservationResponse(res *model.SeatReservation, bookingSessionID string) *model.SeatReservationResponse {
	return &model.SeatReservationResponse{
		LockID:           res.ReservationID,
		FlightID:         res.FlightID,
		SeatID:           res.SeatID,
		BookingSessionID: bookingSessionID,
		Status:           res.Status,
		ReservedAt:       res.ReservedAt,
		ExpiresAt:        res.ExpiresAt,
	}
}
