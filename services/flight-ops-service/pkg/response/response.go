package response

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type Body struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   *ErrorBody  `json:"error,omitempty"`
	Meta    Meta        `json:"meta"`
}

type ErrorBody struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

type Meta struct {
	RequestID string `json:"request_id,omitempty"`
	Timestamp string `json:"timestamp"`
}

func meta(c *gin.Context) Meta {
	return Meta{
		RequestID: c.GetString("request_id"),
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}
}

func JSON(c *gin.Context, status int, data interface{}) {
	c.JSON(status, Body{
		Success: status < 400,
		Data:    data,
		Meta:    meta(c),
	})
}

func Success(c *gin.Context, data interface{}) {
	JSON(c, http.StatusOK, data)
}

func Created(c *gin.Context, data interface{}) {
	JSON(c, http.StatusCreated, data)
}

func Error(c *gin.Context, status int, code, message string, details interface{}) {
	c.JSON(status, Body{
		Success: false,
		Error: &ErrorBody{
			Code:    code,
			Message: message,
			Details: details,
		},
		Meta: meta(c),
	})
}

func BadRequest(c *gin.Context, message string) {
	Error(c, http.StatusBadRequest, "BAD_REQUEST", message, nil)
}

func NotFound(c *gin.Context, message string) {
	Error(c, http.StatusNotFound, "NOT_FOUND", message, nil)
}

func InternalError(c *gin.Context, message string) {
	Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", message, nil)
}
