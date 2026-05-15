package handler

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"airline/passenger-service/internal/middleware"
	"airline/passenger-service/internal/model"
	"airline/passenger-service/internal/repository"
	"airline/passenger-service/internal/service"
	"airline/passenger-service/pkg/response"
)

type PassengerHandler struct {
	svc *service.PassengerService
}

func NewPassengerHandler(svc *service.PassengerService) *PassengerHandler {
	return &PassengerHandler{svc: svc}
}

func (h *PassengerHandler) GetPassenger(c *gin.Context) {
	passengerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid passenger id")
		return
	}

	userID, ok := middleware.GetUserID(c)
	if !ok {
		response.Unauthorized(c, "Unauthorized")
		return
	}
	if err := h.svc.EnsurePassengerAccess(userID, passengerID); err != nil {
		response.NotFound(c, "Passenger not found")
		return
	}

	result, err := h.svc.GetPassenger(passengerID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			response.NotFound(c, "Passenger not found")
			return
		}
		response.InternalError(c, "Failed to get passenger")
		return
	}
	response.Success(c, result)
}

func (h *PassengerHandler) UpdatePassenger(c *gin.Context) {
	passengerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid passenger id")
		return
	}

	userID, ok := middleware.GetUserID(c)
	if !ok {
		response.Unauthorized(c, "Unauthorized")
		return
	}
	if err := h.svc.EnsurePassengerAccess(userID, passengerID); err != nil {
		response.NotFound(c, "Passenger not found")
		return
	}

	var req model.UpdatePassengerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	result, err := h.svc.UpdatePassenger(passengerID, req)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			response.NotFound(c, "Passenger not found")
			return
		}
		response.InternalError(c, "Failed to update passenger")
		return
	}
	response.Success(c, result)
}

func (h *PassengerHandler) CreateDocument(c *gin.Context) {
	passengerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid passenger id")
		return
	}

	userID, ok := middleware.GetUserID(c)
	if !ok {
		response.Unauthorized(c, "Unauthorized")
		return
	}
	if err := h.svc.EnsurePassengerAccess(userID, passengerID); err != nil {
		response.NotFound(c, "Passenger not found")
		return
	}

	req := model.CreateDocumentRequest{
		DocumentType:   c.PostForm("document_type"),
		DocumentNumber: c.PostForm("document_number"),
		IssuingCountry: c.PostForm("issuing_country"),
		ExpiryDate:     c.PostForm("expiry_date"),
		IsPrimary:      c.PostForm("is_primary") == "true",
	}
	if req.DocumentType == "" || req.DocumentNumber == "" || req.IssuingCountry == "" || req.ExpiryDate == "" {
		response.BadRequest(c, "document_type, document_number, issuing_country, and expiry_date are required")
		return
	}

	file, _ := c.FormFile("file")
	result, err := h.svc.CreateDocument(passengerID, req, file)
	if err != nil {
		if errors.Is(err, repository.ErrDocumentLimitReached) {
			response.Conflict(c, "Maximum 5 documents per type allowed")
			return
		}
		if err.Error() == "passport must be valid for at least 6 months" {
			response.Unprocessable(c, err.Error())
			return
		}
		response.InternalError(c, "Failed to create document")
		return
	}
	response.Created(c, result)
}

func (h *PassengerHandler) CreateDocumentJSON(c *gin.Context) {
	passengerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid passenger id")
		return
	}

	userID, ok := middleware.GetUserID(c)
	if !ok {
		response.Unauthorized(c, "Unauthorized")
		return
	}
	if err := h.svc.EnsurePassengerAccess(userID, passengerID); err != nil {
		response.NotFound(c, "Passenger not found")
		return
	}

	var req model.CreateDocumentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	result, err := h.svc.CreateDocument(passengerID, req, nil)
	if err != nil {
		if errors.Is(err, repository.ErrDocumentLimitReached) {
			response.Conflict(c, "Maximum 5 documents per type allowed")
			return
		}
		if err.Error() == "passport must be valid for at least 6 months" {
			response.Unprocessable(c, err.Error())
			return
		}
		response.InternalError(c, "Failed to create document")
		return
	}
	response.Created(c, result)
}

func (h *PassengerHandler) GetDocuments(c *gin.Context) {
	passengerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid passenger id")
		return
	}

	userID, ok := middleware.GetUserID(c)
	if !ok {
		response.Unauthorized(c, "Unauthorized")
		return
	}
	if err := h.svc.EnsurePassengerAccess(userID, passengerID); err != nil {
		response.NotFound(c, "Passenger not found")
		return
	}

	docs, err := h.svc.GetDocuments(passengerID)
	if err != nil {
		response.InternalError(c, "Failed to list documents")
		return
	}
	if docs == nil {
		docs = []model.DocumentResponse{}
	}
	response.Success(c, docs)
}

func (h *PassengerHandler) DeleteDocument(c *gin.Context) {
	passengerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid passenger id")
		return
	}
	docID, err := uuid.Parse(c.Param("docId"))
	if err != nil {
		response.BadRequest(c, "Invalid document id")
		return
	}

	userID, ok := middleware.GetUserID(c)
	if !ok {
		response.Unauthorized(c, "Unauthorized")
		return
	}
	if err := h.svc.EnsurePassengerAccess(userID, passengerID); err != nil {
		response.NotFound(c, "Passenger not found")
		return
	}

	if err := h.svc.DeleteDocument(passengerID, docID); err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			response.NotFound(c, "Document not found")
			return
		}
		response.InternalError(c, "Failed to delete document")
		return
	}
	response.Success(c, gin.H{"deleted": true})
}

func (h *PassengerHandler) GetCountries(c *gin.Context) {
	countries, err := h.svc.GetCountries()
	if err != nil {
		response.InternalError(c, "Failed to list countries")
		return
	}
	if countries == nil {
		countries = []model.CountryResponse{}
	}
	response.Success(c, countries)
}

func Health(c *gin.Context) {
	response.Success(c, gin.H{"status": "ok", "service": "passenger-service"})
}
