package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"airline/inventory-service/internal/cache"
	"airline/inventory-service/internal/config"
	"airline/inventory-service/internal/db"
	"airline/inventory-service/internal/handler"
	"airline/inventory-service/internal/middleware"
	"airline/inventory-service/internal/repository"
	"airline/inventory-service/internal/service"
)

func main() {
	cfg := config.Load()

	gdb, err := db.Connect(cfg.DBHost, cfg.DBPort, cfg.DBName, cfg.DBUser, cfg.DBPassword)
	if err != nil {
		log.Fatalf("database: %v", err)
	}

	var redisClient *cache.Redis
	if cfg.RedisURL != "" {
		redisClient, err = cache.New(cfg.RedisURL)
		if err != nil {
			log.Fatalf("redis: %v", err)
		}
	}

	repo := repository.New(gdb)
	svc := service.New(repo, redisClient, cfg)
	inventoryHandler := handler.NewInventoryHandler(svc)

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery(), gin.Logger(), middleware.RequestID())

	r.GET("/health", handler.Health)

	v1 := r.Group("/v1")
	{
		v1.GET("/aircraft-types", inventoryHandler.ListAircraftTypes)
		v1.GET("/aircrafts/:id/seat-map", inventoryHandler.GetSeatMap)
		v1.POST("/seat-reservations", inventoryHandler.CreateSeatReservation)
		v1.GET("/seat-reservations/:lockId", inventoryHandler.GetSeatReservation)
		v1.DELETE("/seat-reservations/:lockId", inventoryHandler.ReleaseSeatReservation)
		v1.GET("/flights/:flightId/available-seats", inventoryHandler.GetAvailableSeats)
	}

	log.Printf("inventory-service listening on :%s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
