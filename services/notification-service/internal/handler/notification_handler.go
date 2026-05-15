package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"airline/notification-service/internal/model"
	"airline/notification-service/internal/service"
	"airline/notification-service/pkg/response"
)

type NotificationHandler struct {
	svc *service.NotificationService
}

func NewNotificationHandler(svc *service.NotificationService) *NotificationHandler {
	return &NotificationHandler{svc: svc}
}

func Health(c *gin.Context) {
	response.Success(c, gin.H{"status": "ok", "service": "notification-service"})
}

func (h *NotificationHandler) List(c *gin.Context) {
	passengerIDStr := c.Query("passenger_id")
	if passengerIDStr == "" {
		response.BadRequest(c, "passenger_id query parameter is required")
		return
	}

	passengerID, err := uuid.Parse(passengerIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid passenger_id")
		return
	}

	items, err := h.svc.ListByPassenger(passengerID)
	if err != nil {
		response.InternalError(c, "Failed to list notifications")
		return
	}

	if items == nil {
		items = []model.NotificationResponse{}
	}
	response.Success(c, items)
}

func (h *NotificationHandler) Create(c *gin.Context) {
	var req model.CreateNotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	result, err := h.svc.Create(req)
	if err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	response.Created(c, result)
}
