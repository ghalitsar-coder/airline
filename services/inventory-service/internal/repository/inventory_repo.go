package repository

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"airline/inventory-service/internal/model"
)

var ErrNotFound = errors.New("not found")

type InventoryRepo struct {
	db *gorm.DB
}

func New(db *gorm.DB) *InventoryRepo {
	return &InventoryRepo{db: db}
}

func (r *InventoryRepo) ListAircraftTypes() ([]model.AircraftType, error) {
	var types []model.AircraftType
	if err := r.db.Order("manufacturer, model").Find(&types).Error; err != nil {
		return nil, err
	}
	return types, nil
}

func (r *InventoryRepo) GetAircraftWithType(aircraftID uuid.UUID) (*model.Aircraft, *model.AircraftType, error) {
	var aircraft model.Aircraft
	if err := r.db.First(&aircraft, "aircraft_id = ?", aircraftID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil, ErrNotFound
		}
		return nil, nil, err
	}

	var aircraftType model.AircraftType
	if err := r.db.First(&aircraftType, "aircraft_type_id = ?", aircraft.AircraftTypeID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil, ErrNotFound
		}
		return nil, nil, err
	}

	return &aircraft, &aircraftType, nil
}

func (r *InventoryRepo) ListCabinConfigurations(aircraftTypeID uuid.UUID) ([]model.CabinConfiguration, error) {
	var configs []model.CabinConfiguration
	if err := r.db.Where("aircraft_type_id = ?", aircraftTypeID).
		Order("rows_start").
		Find(&configs).Error; err != nil {
		return nil, err
	}
	return configs, nil
}

func (r *InventoryRepo) ListSeatsByAircraft(aircraftID uuid.UUID) ([]model.Seat, error) {
	var seats []model.Seat
	if err := r.db.Where("aircraft_id = ?", aircraftID).
		Order("seat_row, seat_letter").
		Find(&seats).Error; err != nil {
		return nil, err
	}
	return seats, nil
}

func (r *InventoryRepo) GetSeat(seatID uuid.UUID) (*model.Seat, error) {
	var seat model.Seat
	if err := r.db.First(&seat, "seat_id = ?", seatID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &seat, nil
}

func (r *InventoryRepo) HasActiveReservation(flightID, seatID uuid.UUID) (bool, error) {
	var count int64
	now := time.Now().UTC()
	err := r.db.Model(&model.SeatReservation{}).
		Where("flight_id = ? AND seat_id = ? AND status = ? AND (expires_at IS NULL OR expires_at > ?)",
			flightID, seatID, "RESERVED", now).
		Count(&count).Error
	return count > 0, err
}

func (r *InventoryRepo) CreateReservation(res *model.SeatReservation) error {
	return r.db.Create(res).Error
}

func (r *InventoryRepo) GetReservation(reservationID uuid.UUID) (*model.SeatReservation, error) {
	var res model.SeatReservation
	if err := r.db.First(&res, "reservation_id = ?", reservationID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &res, nil
}

func (r *InventoryRepo) DeleteReservation(reservationID uuid.UUID) error {
	result := r.db.Delete(&model.SeatReservation{}, "reservation_id = ?", reservationID)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *InventoryRepo) ListReservedSeatIDs(flightID uuid.UUID) ([]uuid.UUID, error) {
	now := time.Now().UTC()
	var seatIDs []uuid.UUID
	err := r.db.Model(&model.SeatReservation{}).
		Where("flight_id = ? AND status = ? AND (expires_at IS NULL OR expires_at > ?)",
			flightID, "RESERVED", now).
		Pluck("seat_id", &seatIDs).Error
	return seatIDs, err
}

func (r *InventoryRepo) ListAvailableSeats(aircraftID, flightID uuid.UUID) ([]model.Seat, error) {
	reservedIDs, err := r.ListReservedSeatIDs(flightID)
	if err != nil {
		return nil, err
	}

	q := r.db.Where("aircraft_id = ? AND is_active = ?", aircraftID, true)
	if len(reservedIDs) > 0 {
		q = q.Where("seat_id NOT IN ?", reservedIDs)
	}

	var seats []model.Seat
	if err := q.Order("seat_row, seat_letter").Find(&seats).Error; err != nil {
		return nil, err
	}
	return seats, nil
}
