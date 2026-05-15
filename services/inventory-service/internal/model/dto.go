package model

import (
	"time"

	"github.com/google/uuid"
)

type AircraftTypeResponse struct {
	AircraftTypeID uuid.UUID `json:"aircraft_type_id"`
	IATATypeCode   string    `json:"iata_type_code"`
	Manufacturer   string    `json:"manufacturer"`
	Model          string    `json:"model"`
	MaxSeats       int       `json:"max_seats"`
}

type CabinConfigResponse struct {
	ConfigID    uuid.UUID `json:"config_id"`
	SeatClass   string    `json:"seat_class"`
	TotalSeats  int       `json:"total_seats"`
	RowsStart   int       `json:"rows_start"`
	RowsEnd     int       `json:"rows_end"`
	SeatsPerRow int       `json:"seats_per_row"`
}

type SeatResponse struct {
	SeatID     uuid.UUID `json:"seat_id"`
	SeatNumber string    `json:"seat_number"`
	SeatRow    int       `json:"seat_row"`
	SeatLetter string    `json:"seat_letter"`
	SeatClass  string    `json:"seat_class"`
	IsWindow   bool      `json:"is_window"`
	IsAisle    bool      `json:"is_aisle"`
	IsExitRow  bool      `json:"is_exit_row"`
	IsActive   bool      `json:"is_active"`
}

type SeatMapResponse struct {
	AircraftID         uuid.UUID             `json:"aircraft_id"`
	RegistrationNumber string                `json:"registration_number"`
	AircraftType       AircraftTypeResponse  `json:"aircraft_type"`
	CabinConfigurations []CabinConfigResponse `json:"cabin_configurations"`
	Seats              []SeatResponse        `json:"seats"`
}

type CreateSeatReservationRequest struct {
	FlightID           uuid.UUID `json:"flight_id" binding:"required"`
	SeatID             uuid.UUID `json:"seat_id" binding:"required"`
	BookingSessionID   string    `json:"booking_session_id" binding:"required"`
	TTLSeconds         *int      `json:"ttl_seconds"`
}

type SeatReservationResponse struct {
	LockID             uuid.UUID  `json:"lock_id"`
	FlightID           uuid.UUID  `json:"flight_id"`
	SeatID             uuid.UUID  `json:"seat_id"`
	BookingSessionID   string     `json:"booking_session_id"`
	Status             string     `json:"status"`
	ReservedAt         time.Time  `json:"reserved_at"`
	ExpiresAt          *time.Time `json:"expires_at,omitempty"`
}

type AvailableSeatsResponse struct {
	FlightID       uuid.UUID      `json:"flight_id"`
	AircraftID     uuid.UUID      `json:"aircraft_id"`
	AvailableCount int            `json:"available_count"`
	Seats          []SeatResponse `json:"seats"`
}

func ToAircraftTypeResponse(at AircraftType) AircraftTypeResponse {
	return AircraftTypeResponse{
		AircraftTypeID: at.AircraftTypeID,
		IATATypeCode:   at.IATATypeCode,
		Manufacturer:   at.Manufacturer,
		Model:          at.Model,
		MaxSeats:       at.MaxSeats,
	}
}

func ToSeatResponse(s Seat) SeatResponse {
	return SeatResponse{
		SeatID:     s.SeatID,
		SeatNumber: s.SeatNumber,
		SeatRow:    s.SeatRow,
		SeatLetter: s.SeatLetter,
		SeatClass:  s.SeatClass,
		IsWindow:   s.IsWindow,
		IsAisle:    s.IsAisle,
		IsExitRow:  s.IsExitRow,
		IsActive:   s.IsActive,
	}
}

func ToSeatResponses(seats []Seat) []SeatResponse {
	out := make([]SeatResponse, len(seats))
	for i, s := range seats {
		out[i] = ToSeatResponse(s)
	}
	return out
}
