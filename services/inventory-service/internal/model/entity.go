package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AircraftType struct {
	AircraftTypeID uuid.UUID `gorm:"column:aircraft_type_id;type:uuid;primaryKey"`
	IATATypeCode   string    `gorm:"column:iata_type_code;size:10;not null"`
	Manufacturer   string    `gorm:"column:manufacturer;size:100;not null"`
	Model          string    `gorm:"column:model;size:100;not null"`
	MaxSeats       int       `gorm:"column:max_seats;not null"`
}

func (AircraftType) TableName() string { return "aircraft_types" }

type Aircraft struct {
	AircraftID         uuid.UUID `gorm:"column:aircraft_id;type:uuid;primaryKey"`
	AircraftTypeID     uuid.UUID `gorm:"column:aircraft_type_id;type:uuid;not null"`
	RegistrationNumber string    `gorm:"column:registration_number;size:20;not null"`
	Status             string    `gorm:"column:status;size:20;not null"`
}

func (Aircraft) TableName() string { return "aircrafts" }

type CabinConfiguration struct {
	ConfigID       uuid.UUID `gorm:"column:config_id;type:uuid;primaryKey"`
	AircraftTypeID uuid.UUID `gorm:"column:aircraft_type_id;type:uuid;not null"`
	SeatClass      string    `gorm:"column:seat_class;size:20;not null"`
	TotalSeats     int       `gorm:"column:total_seats;not null"`
	RowsStart      int       `gorm:"column:rows_start;not null"`
	RowsEnd        int       `gorm:"column:rows_end;not null"`
	SeatsPerRow    int       `gorm:"column:seats_per_row;not null"`
}

func (CabinConfiguration) TableName() string { return "cabin_configurations" }

type Seat struct {
	SeatID     uuid.UUID `gorm:"column:seat_id;type:uuid;primaryKey"`
	AircraftID uuid.UUID `gorm:"column:aircraft_id;type:uuid;not null"`
	SeatNumber string    `gorm:"column:seat_number;size:5;not null"`
	SeatRow    int       `gorm:"column:seat_row;not null"`
	SeatLetter string    `gorm:"column:seat_letter;size:1;not null"`
	SeatClass  string    `gorm:"column:seat_class;size:20;not null"`
	IsWindow   bool      `gorm:"column:is_window;not null"`
	IsAisle    bool      `gorm:"column:is_aisle;not null"`
	IsExitRow  bool      `gorm:"column:is_exit_row;not null"`
	IsActive   bool      `gorm:"column:is_active;not null"`
}

func (Seat) TableName() string { return "seats" }

type SeatReservation struct {
	ReservationID uuid.UUID  `gorm:"column:reservation_id;type:uuid;primaryKey"`
	FlightID      uuid.UUID  `gorm:"column:flight_id;type:uuid;not null"`
	SeatID        uuid.UUID  `gorm:"column:seat_id;type:uuid;not null"`
	Status        string     `gorm:"column:status;size:20;not null"`
	ReservedAt    time.Time  `gorm:"column:reserved_at;not null"`
	ExpiresAt     *time.Time `gorm:"column:expires_at"`
}

func (SeatReservation) TableName() string { return "seat_reservations" }

func (r *SeatReservation) BeforeCreate(tx *gorm.DB) error {
	if r.ReservationID == uuid.Nil {
		r.ReservationID = uuid.New()
	}
	return nil
}
