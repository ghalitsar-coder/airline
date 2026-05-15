package handler

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"airline/inventory-service/internal/model"
	"airline/inventory-service/internal/service"
	"airline/inventory-service/pkg/response"
)

type InventoryHandler struct {
	svc *service.InventoryService
}

func NewInventoryHandler(svc *service.InventoryService) *InventoryHandler {
	return &InventoryHandler{svc: svc}
}

func Health(c *gin.Context) {
	response.Success(c, gin.H{"status": "ok", "service": "inventory-service"})
}

func (h *InventoryHandler) ListAircraftTypes(c *gin.Context) {
	types, err := h.svc.ListAircraftTypes()
	if err != nil {
		response.InternalError(c, "Failed to list aircraft types")
		return
	}
	if types == nil {
		types = []model.AircraftTypeResponse{}
	}
	response.Success(c, types)
}

func (h *InventoryHandler) GetSeatMap(c *gin.Context) {
	aircraftID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid aircraft id")
		return
	}

	result, err := h.svc.GetSeatMap(aircraftID)
	if err != nil {
		if errors.Is(err, service.ErrNotFound) {
			response.NotFound(c, "Aircraft not found")
			return
		}
		response.InternalError(c, "Failed to get seat map")
		return
	}
	response.Success(c, result)
}

func (h *InventoryHandler) CreateSeatReservation(c *gin.Context) {
	var req model.CreateSeatReservationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	if req.BookingSessionID == "" {
		response.BadRequest(c, "booking_session_id is required")
		return
	}

	result, err := h.svc.CreateSeatReservation(req)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrSeatConflict):
			response.Conflict(c, "Seat is already locked")
		case errors.Is(err, service.ErrSeatBlocked):
			response.Unprocessable(c, "Seat is not available for reservation")
		case errors.Is(err, service.ErrNotFound):
			response.NotFound(c, "Seat not found")
		case errors.Is(err, service.ErrRedisRequired):
			response.InternalError(c, "Seat locking unavailable")
		default:
			response.InternalError(c, "Failed to create seat reservation")
		}
		return
	}
	response.Created(c, result)
}

func (h *InventoryHandler) GetSeatReservation(c *gin.Context) {
	lockID, err := uuid.Parse(c.Param("lockId"))
	if err != nil {
		response.BadRequest(c, "Invalid lock id")
		return
	}

	result, err := h.svc.GetSeatReservation(lockID)
	if err != nil {
		if errors.Is(err, service.ErrNotFound) {
			response.NotFound(c, "Seat reservation not found")
			return
		}
		response.InternalError(c, "Failed to get seat reservation")
		return
	}
	response.Success(c, result)
}

func (h *InventoryHandler) ReleaseSeatReservation(c *gin.Context) {
	lockID, err := uuid.Parse(c.Param("lockId"))
	if err != nil {
		response.BadRequest(c, "Invalid lock id")
		return
	}

	if err := h.svc.ReleaseSeatReservation(lockID); err != nil {
		if errors.Is(err, service.ErrNotFound) {
			response.NotFound(c, "Seat reservation not found")
			return
		}
		response.InternalError(c, "Failed to release seat reservation")
		return
	}
	response.Success(c, gin.H{"released": true, "lock_id": lockID})
}

func (h *InventoryHandler) GetAvailableSeats(c *gin.Context) {
	flightID, err := uuid.Parse(c.Param("flightId"))
	if err != nil {
		response.BadRequest(c, "Invalid flight id")
		return
	}

	aircraftIDStr := c.Query("aircraft_id")
	if aircraftIDStr == "" {
		response.BadRequest(c, "aircraft_id query parameter is required")
		return
	}
	aircraftID, err := uuid.Parse(aircraftIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid aircraft_id")
		return
	}

	result, err := h.svc.GetAvailableSeats(flightID, aircraftID)
	if err != nil {
		if errors.Is(err, service.ErrNotFound) {
			response.NotFound(c, "Aircraft not found")
			return
		}
		response.InternalError(c, "Failed to get available seats")
		return
	}
	response.Success(c, result)
}
