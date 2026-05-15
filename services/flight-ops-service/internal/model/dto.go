package model

import (
	"time"

	"github.com/google/uuid"
)

type UpdateFlightStatusRequest struct {
	Status string `json:"status" binding:"required"`
}

type AirportSlotRequest struct {
	AirportCode string `json:"airport_code"`
	FlightID    string `json:"flight_id"`
	SlotTime    string `json:"slot_time"`
}

type FlightListItem struct {
	FlightID           uuid.UUID `json:"flight_id"`
	FlightNumber       string    `json:"flight_number"`
	Origin             string    `json:"origin"`
	Destination        string    `json:"destination"`
	ScheduledDeparture time.Time `json:"scheduled_departure"`
	ScheduledArrival   time.Time `json:"scheduled_arrival"`
	Status             string    `json:"status"`
}

type FlightDetailResponse struct {
	FlightID           uuid.UUID  `json:"flight_id"`
	FlightNumber       string     `json:"flight_number"`
	RouteID            uuid.UUID  `json:"route_id"`
	Origin             string     `json:"origin"`
	Destination        string     `json:"destination"`
	AircraftID         *uuid.UUID `json:"aircraft_id,omitempty"`
	ScheduledDeparture time.Time  `json:"scheduled_departure"`
	ScheduledArrival   time.Time  `json:"scheduled_arrival"`
	Status             string     `json:"status"`
}

type FlightOperationalResponse struct {
	FlightID           uuid.UUID  `json:"flight_id"`
	Status             string     `json:"status"`
	ScheduledDeparture time.Time  `json:"scheduled_departure"`
	ScheduledArrival   time.Time  `json:"scheduled_arrival"`
	AircraftID         *uuid.UUID `json:"aircraft_id,omitempty"`
}

type RouteResponse struct {
	RouteID           uuid.UUID `json:"route_id"`
	Origin            string    `json:"origin"`
	Destination       string    `json:"destination"`
	DistanceKm        *float64  `json:"distance_km,omitempty"`
	FlightDurationMin *int      `json:"flight_duration_min,omitempty"`
}

type GateResponse struct {
	GateID       uuid.UUID `json:"gate_id"`
	GateCode     string    `json:"gate_code"`
	TerminalCode string    `json:"terminal_code"`
}

type AirportSlotResponse struct {
	SlotID string `json:"slot_id"`
}

type FlightStatusChangedEvent struct {
	EventType      string    `json:"event_type"`
	FlightID       string    `json:"flight_id"`
	FlightNumber   string    `json:"flight_number"`
	PreviousStatus string    `json:"previous_status"`
	Status         string    `json:"status"`
	Timestamp      time.Time `json:"timestamp"`
}
