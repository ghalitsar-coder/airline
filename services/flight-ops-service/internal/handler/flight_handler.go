package handler

import (
	"errors"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"airline/flight-ops-service/internal/model"
	"airline/flight-ops-service/internal/repository"
	"airline/flight-ops-service/internal/service"
	"airline/flight-ops-service/pkg/response"
)

type FlightHandler struct {
	svc *service.FlightService
}

func NewFlightHandler(svc *service.FlightService) *FlightHandler {
	return &FlightHandler{svc: svc}
}

func (h *FlightHandler) ListFlights(c *gin.Context) {
	origin := c.Query("origin")
	destination := c.Query("destination")
	date := c.Query("date")

	if origin == "" || destination == "" || date == "" {
		response.BadRequest(c, "origin, destination, and date query parameters are required")
		return
	}
	if _, err := time.Parse("2006-01-02", date); err != nil {
		response.BadRequest(c, "date must be in YYYY-MM-DD format")
		return
	}

	flights, err := h.svc.ListFlights(origin, destination, date)
	if err != nil {
		response.InternalError(c, "Failed to list flights")
		return
	}
	response.Success(c, flights)
}

func (h *FlightHandler) GetFlight(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid flight id")
		return
	}

	flight, err := h.svc.GetFlight(id)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			response.NotFound(c, "Flight not found")
			return
		}
		response.InternalError(c, "Failed to get flight")
		return
	}
	response.Success(c, flight)
}

func (h *FlightHandler) UpdateFlightStatus(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid flight id")
		return
	}

	var req model.UpdateFlightStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	flight, err := h.svc.UpdateStatus(id, req.Status)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			response.NotFound(c, "Flight not found")
			return
		}
		response.InternalError(c, "Failed to update flight status")
		return
	}
	response.Success(c, flight)
}

func (h *FlightHandler) GetOperational(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid flight id")
		return
	}

	op, err := h.svc.GetOperational(id)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			response.NotFound(c, "Flight not found")
			return
		}
		response.InternalError(c, "Failed to get operational data")
		return
	}
	response.Success(c, op)
}

func (h *FlightHandler) ListRoutes(c *gin.Context) {
	routes, err := h.svc.ListRoutes()
	if err != nil {
		response.InternalError(c, "Failed to list routes")
		return
	}
	response.Success(c, routes)
}

func (h *FlightHandler) ListGates(c *gin.Context) {
	code := c.Param("code")
	if len(code) != 3 {
		response.BadRequest(c, "Invalid airport code")
		return
	}

	gates, err := h.svc.ListGates(code)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			response.NotFound(c, "Airport not found")
			return
		}
		response.InternalError(c, "Failed to list gates")
		return
	}
	response.Success(c, gates)
}

func (h *FlightHandler) CreateAirportSlot(c *gin.Context) {
	var req model.AirportSlotRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	result := h.svc.CreateAirportSlot(req)
	response.Created(c, result)
}

func Health(c *gin.Context) {
	response.Success(c, gin.H{"status": "ok", "service": "flight-ops-service"})
}
