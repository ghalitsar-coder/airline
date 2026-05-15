package repository

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"airline/flight-ops-service/internal/model"
)

var ErrNotFound = errors.New("not found")

type FlightRepo struct {
	db *gorm.DB
}

func New(db *gorm.DB) *FlightRepo {
	return &FlightRepo{db: db}
}

type flightRow struct {
	FlightID           uuid.UUID
	FlightNumber       string
	Origin             string
	Destination        string
	ScheduledDeparture time.Time
	ScheduledArrival   time.Time
	Status             string
}

func (r *FlightRepo) ListFlights(origin, destination, date string) ([]model.FlightListItem, error) {
	var rows []flightRow
	q := r.db.Table("flights f").
		Select(`f.flight_id, f.flight_number, oa.iata_code AS origin, da.iata_code AS destination,
			f.scheduled_departure, f.scheduled_arrival, f.status`).
		Joins("JOIN routes rt ON rt.route_id = f.route_id").
		Joins("JOIN airports oa ON oa.airport_id = rt.origin_airport_id").
		Joins("JOIN airports da ON da.airport_id = rt.destination_airport_id").
		Where("oa.iata_code = ? AND da.iata_code = ?", origin, destination).
		Where("DATE(f.scheduled_departure AT TIME ZONE COALESCE(oa.timezone, 'UTC')) = ?::date", date).
		Order("f.scheduled_departure ASC")

	if err := q.Scan(&rows).Error; err != nil {
		return nil, err
	}

	result := make([]model.FlightListItem, len(rows))
	for i, row := range rows {
		result[i] = model.FlightListItem{
			FlightID:           row.FlightID,
			FlightNumber:       row.FlightNumber,
			Origin:             row.Origin,
			Destination:        row.Destination,
			ScheduledDeparture: row.ScheduledDeparture,
			ScheduledArrival:   row.ScheduledArrival,
			Status:             row.Status,
		}
	}
	return result, nil
}

func (r *FlightRepo) GetFlightByID(id uuid.UUID) (*model.FlightDetailResponse, error) {
	var detail model.FlightDetailResponse
	err := r.db.Table("flights f").
		Select(`f.flight_id, f.flight_number, f.route_id, oa.iata_code AS origin, da.iata_code AS destination,
			f.aircraft_id, f.scheduled_departure, f.scheduled_arrival, f.status`).
		Joins("JOIN routes rt ON rt.route_id = f.route_id").
		Joins("JOIN airports oa ON oa.airport_id = rt.origin_airport_id").
		Joins("JOIN airports da ON da.airport_id = rt.destination_airport_id").
		Where("f.flight_id = ?", id).
		Scan(&detail).Error
	if err != nil {
		return nil, err
	}
	if detail.FlightID == uuid.Nil {
		return nil, ErrNotFound
	}
	return &detail, nil
}

func (r *FlightRepo) GetFlightOperational(id uuid.UUID) (*model.FlightOperationalResponse, error) {
	var flight model.Flight
	err := r.db.Select("flight_id", "status", "scheduled_departure", "scheduled_arrival", "aircraft_id").
		Where("flight_id = ?", id).
		First(&flight).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &model.FlightOperationalResponse{
		FlightID:           flight.FlightID,
		Status:             flight.Status,
		ScheduledDeparture: flight.ScheduledDeparture,
		ScheduledArrival:   flight.ScheduledArrival,
		AircraftID:         flight.AircraftID,
	}, nil
}

func (r *FlightRepo) UpdateFlightStatus(id uuid.UUID, status string) (*model.Flight, string, error) {
	var flight model.Flight
	if err := r.db.Where("flight_id = ?", id).First(&flight).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, "", ErrNotFound
		}
		return nil, "", err
	}

	previous := flight.Status
	flight.Status = status
	if err := r.db.Model(&flight).Update("status", status).Error; err != nil {
		return nil, "", err
	}
	return &flight, previous, nil
}

func (r *FlightRepo) ListRoutes() ([]model.RouteResponse, error) {
	var routes []model.RouteResponse
	err := r.db.Table("routes rt").
		Select(`rt.route_id, oa.iata_code AS origin, da.iata_code AS destination,
			rt.distance_km, rt.flight_duration_min`).
		Joins("JOIN airports oa ON oa.airport_id = rt.origin_airport_id").
		Joins("JOIN airports da ON da.airport_id = rt.destination_airport_id").
		Order("oa.iata_code, da.iata_code").
		Scan(&routes).Error
	if err != nil {
		return nil, err
	}
	return routes, nil
}

func (r *FlightRepo) ListGatesByAirportCode(code string) ([]model.GateResponse, error) {
	var gates []model.GateResponse
	err := r.db.Table("gates g").
		Select("g.gate_id, g.gate_code, t.terminal_code").
		Joins("JOIN terminals t ON t.terminal_id = g.terminal_id").
		Joins("JOIN airports a ON a.airport_id = t.airport_id").
		Where("a.iata_code = ?", code).
		Order("t.terminal_code, g.gate_code").
		Scan(&gates).Error
	if err != nil {
		return nil, err
	}
	if gates == nil {
		gates = []model.GateResponse{}
	}
	return gates, nil
}

func (r *FlightRepo) AirportExists(code string) (bool, error) {
	var count int64
	err := r.db.Model(&model.Airport{}).Where("iata_code = ?", code).Count(&count).Error
	return count > 0, err
}
