package service

import (
	"context"
	"time"

	"github.com/google/uuid"

	"airline/flight-ops-service/internal/messaging"
	"airline/flight-ops-service/internal/model"
	"airline/flight-ops-service/internal/repository"
)

type FlightService struct {
	repo      *repository.FlightRepo
	publisher *messaging.Publisher
}

func New(repo *repository.FlightRepo, publisher *messaging.Publisher) *FlightService {
	return &FlightService{repo: repo, publisher: publisher}
}

func (s *FlightService) ListFlights(origin, destination, date string) ([]model.FlightListItem, error) {
	flights, err := s.repo.ListFlights(origin, destination, date)
	if err != nil {
		return nil, err
	}
	if flights == nil {
		flights = []model.FlightListItem{}
	}
	return flights, nil
}

func (s *FlightService) GetFlight(id uuid.UUID) (*model.FlightDetailResponse, error) {
	return s.repo.GetFlightByID(id)
}

func (s *FlightService) GetOperational(id uuid.UUID) (*model.FlightOperationalResponse, error) {
	return s.repo.GetFlightOperational(id)
}

func (s *FlightService) UpdateStatus(id uuid.UUID, status string) (*model.FlightDetailResponse, error) {
	flight, previous, err := s.repo.UpdateFlightStatus(id, status)
	if err != nil {
		return nil, err
	}

	if s.publisher != nil {
		_ = s.publisher.PublishFlightStatusChanged(context.Background(), model.FlightStatusChangedEvent{
			EventType:      "FlightStatusChanged",
			FlightID:       flight.FlightID.String(),
			FlightNumber:   flight.FlightNumber,
			PreviousStatus: previous,
			Status:         status,
			Timestamp:      time.Now().UTC(),
		})
	}

	return s.repo.GetFlightByID(id)
}

func (s *FlightService) ListRoutes() ([]model.RouteResponse, error) {
	routes, err := s.repo.ListRoutes()
	if err != nil {
		return nil, err
	}
	if routes == nil {
		routes = []model.RouteResponse{}
	}
	return routes, nil
}

func (s *FlightService) ListGates(airportCode string) ([]model.GateResponse, error) {
	exists, err := s.repo.AirportExists(airportCode)
	if err != nil {
		return nil, err
	}
	if !exists {
		return nil, repository.ErrNotFound
	}
	return s.repo.ListGatesByAirportCode(airportCode)
}

func (s *FlightService) CreateAirportSlot(_ model.AirportSlotRequest) model.AirportSlotResponse {
	return model.AirportSlotResponse{SlotID: uuid.New().String()}
}
