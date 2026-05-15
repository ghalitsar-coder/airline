package handler

import (
	"errors"

	"github.com/gin-gonic/gin"

	"airline/passenger-service/internal/model"
	"airline/passenger-service/internal/repository"
	"airline/passenger-service/internal/service"
	"airline/passenger-service/internal/validation"
	"airline/passenger-service/pkg/response"
)

type AuthHandler struct {
	svc *service.PassengerService
}

func NewAuthHandler(svc *service.PassengerService) *AuthHandler {
	return &AuthHandler{svc: svc}
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req model.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	result, err := h.svc.Register(req)
	if err != nil {
		if errors.Is(err, validation.ErrWeakPassword) {
			response.Unprocessable(c, err.Error())
			return
		}
		if errors.Is(err, repository.ErrDuplicateEmail) {
			response.Conflict(c, "Email already registered")
			return
		}
		response.InternalError(c, "Failed to register user")
		return
	}
	response.Created(c, result)
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req model.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	result, err := h.svc.Login(req)
	if err != nil {
		if errors.Is(err, repository.ErrInvalidCredentials) {
			response.Unauthorized(c, "Invalid email or password")
			return
		}
		response.InternalError(c, "Failed to login")
		return
	}
	response.Success(c, result)
}

func (h *AuthHandler) Refresh(c *gin.Context) {
	var req model.RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	result, err := h.svc.Refresh(req.RefreshToken)
	if err != nil {
		if errors.Is(err, repository.ErrInvalidCredentials) {
			response.Unauthorized(c, "Invalid refresh token")
			return
		}
		response.InternalError(c, "Failed to refresh token")
		return
	}
	response.Success(c, result)
}
