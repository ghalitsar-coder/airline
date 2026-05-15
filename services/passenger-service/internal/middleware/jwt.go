package middleware

import (
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"airline/passenger-service/pkg/response"
)

const (
	ContextUserID    = "userID"
	ContextUserEmail = "userEmail"
	ContextUserRole  = "userRole"
)

func JWT(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			response.Unauthorized(c, "Authorization header required")
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
			response.Unauthorized(c, "Invalid authorization header format")
			c.Abort()
			return
		}

		token, err := jwt.Parse(parts[1], func(t *jwt.Token) (interface{}, error) {
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(secret), nil
		})
		if err != nil || !token.Valid {
			response.Unauthorized(c, "Invalid or expired token")
			c.Abort()
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			response.Unauthorized(c, "Invalid token claims")
			c.Abort()
			return
		}

		if exp, ok := claims["exp"].(float64); ok && time.Now().Unix() > int64(exp) {
			response.Unauthorized(c, "Token expired")
			c.Abort()
			return
		}

		if typ, _ := claims["type"].(string); typ == "refresh" {
			response.Unauthorized(c, "Refresh token cannot be used as access token")
			c.Abort()
			return
		}

		c.Set(ContextUserID, claims["sub"])
		c.Set(ContextUserEmail, claims["email"])
		c.Set(ContextUserRole, claims["role"])
		c.Next()
	}
}

func GetUserID(c *gin.Context) (uuid.UUID, bool) {
	v, ok := c.Get(ContextUserID)
	if !ok {
		return uuid.Nil, false
	}
	switch id := v.(type) {
	case string:
		parsed, err := uuid.Parse(id)
		return parsed, err == nil
	default:
		return uuid.Nil, false
	}
}

func GenerateTokens(userID, email, role, secret string, accessExpMin, refreshExpHour int) (accessToken, refreshToken string, expiresAt time.Time, err error) {
	now := time.Now()
	expiresAt = now.Add(time.Duration(accessExpMin) * time.Minute)

	accessClaims := jwt.MapClaims{
		"sub":   userID,
		"email": email,
		"role":  role,
		"iat":   now.Unix(),
		"exp":   expiresAt.Unix(),
		"jti":   uuid.New().String(),
	}
	at := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessToken, err = at.SignedString([]byte(secret))
	if err != nil {
		return
	}

	refreshExp := now.Add(time.Duration(refreshExpHour) * time.Hour)
	refreshClaims := jwt.MapClaims{
		"sub":  userID,
		"type": "refresh",
		"iat":  now.Unix(),
		"exp":  refreshExp.Unix(),
		"jti":  uuid.New().String(),
	}
	rt := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshToken, err = rt.SignedString([]byte(secret))
	return
}

func ParseRefreshToken(tokenStr, secret string) (userID string, err error) {
	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return "", jwt.ErrTokenInvalidClaims
	}
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", jwt.ErrTokenInvalidClaims
	}
	if typ, _ := claims["type"].(string); typ != "refresh" {
		return "", jwt.ErrTokenInvalidClaims
	}
	sub, _ := claims["sub"].(string)
	if sub == "" {
		return "", jwt.ErrTokenInvalidClaims
	}
	return sub, nil
}
