package model

import (
	"time"

	"github.com/google/uuid"
)

type Airport struct {
	AirportID uuid.UUID `gorm:"column:airport_id;type:uuid;primaryKey"`
	IATACode  string    `gorm:"column:iata_code;type:char(3);uniqueIndex;not null"`
	AirportName string  `gorm:"column:airport_name;size:200;not null"`
	City      *string   `gorm:"column:city;size:100"`
	CountryID *string   `gorm:"column:country_id;type:char(2)"`
}

func (Airport) TableName() string { return "airports" }

type Terminal struct {
	TerminalID   uuid.UUID `gorm:"column:terminal_id;type:uuid;primaryKey"`
	AirportID    uuid.UUID `gorm:"column:airport_id;type:uuid;not null"`
	TerminalCode string    `gorm:"column:terminal_code;size:10;not null"`
}

func (Terminal) TableName() string { return "terminals" }

type Gate struct {
	GateID     uuid.UUID `gorm:"column:gate_id;type:uuid;primaryKey"`
	TerminalID uuid.UUID `gorm:"column:terminal_id;type:uuid;not null"`
	GateCode   string    `gorm:"column:gate_code;size:10;not null"`
}

func (Gate) TableName() string { return "gates" }

type Route struct {
	RouteID              uuid.UUID `gorm:"column:route_id;type:uuid;primaryKey"`
	OriginAirportID      uuid.UUID `gorm:"column:origin_airport_id;type:uuid;not null"`
	DestinationAirportID uuid.UUID `gorm:"column:destination_airport_id;type:uuid;not null"`
	DistanceKm           *float64  `gorm:"column:distance_km;type:decimal(8,2)"`
	FlightDurationMin    *int      `gorm:"column:flight_duration_min"`
}

func (Route) TableName() string { return "routes" }

type Flight struct {
	FlightID           uuid.UUID  `gorm:"column:flight_id;type:uuid;primaryKey"`
	FlightNumber       string     `gorm:"column:flight_number;size:10;not null"`
	RouteID            uuid.UUID  `gorm:"column:route_id;type:uuid;not null"`
	AircraftID         *uuid.UUID `gorm:"column:aircraft_id;type:uuid"`
	ScheduledDeparture time.Time  `gorm:"column:scheduled_departure;not null"`
	ScheduledArrival   time.Time  `gorm:"column:scheduled_arrival;not null"`
	Status             string     `gorm:"column:status;size:20;not null;default:SCHEDULED"`
}

func (Flight) TableName() string { return "flights" }
