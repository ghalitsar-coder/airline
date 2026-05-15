package handler

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"airline/passenger-service/internal/repository"
	"airline/passenger-service/internal/service"
	"airline/passenger-service/pkg/response"
)

// InternalHandler exposes service-to-service endpoints (protected by API key).
type InternalHandler struct {
	svc    *service.PassengerService
	apiKey string
}

func NewInternalHandler(svc *service.PassengerService, apiKey string) *InternalHandler {
	return &InternalHandler{svc: svc, apiKey: apiKey}
}

func (h *InternalHandler) ServiceAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		if h.apiKey == "" {
			c.Next()
			return
		}
		key := c.GetHeader("X-Service-Key")
		if key != h.apiKey {
			response.Forbidden(c, "Invalid service key")
			c.Abort()
			return
		}
		c.Next()
	}
}

func (h *InternalHandler) ValidatePassenger(c *gin.Context) {
	passengerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid passenger id")
		return
	}

	p, err := h.svc.GetPassenger(passengerID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			response.NotFound(c, "Passenger not found")
			return
		}
		response.InternalError(c, "Failed to validate passenger")
		return
	}

	docs, err := h.svc.GetDocuments(passengerID)
	if err != nil {
		response.InternalError(c, "Failed to load documents")
		return
	}

	hasValidPassport := false
	for _, d := range docs {
		if d.DocumentType == "PASSPORT" {
			hasValidPassport = true
			break
		}
	}

	response.Success(c, gin.H{
		"valid":              p.IsActive && hasValidPassport,
		"passenger":          p,
		"has_valid_passport": hasValidPassport,
		"document_count":     len(docs),
	})
}
