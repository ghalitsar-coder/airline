package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"airline/flight-ops-service/internal/config"
	"airline/flight-ops-service/internal/db"
	"airline/flight-ops-service/internal/handler"
	"airline/flight-ops-service/internal/messaging"
	"airline/flight-ops-service/internal/middleware"
	"airline/flight-ops-service/internal/repository"
	"airline/flight-ops-service/internal/service"
)

func main() {
	cfg := config.Load()

	gdb, err := db.Connect(cfg.DBHost, cfg.DBPort, cfg.DBName, cfg.DBUser, cfg.DBPassword)
	if err != nil {
		log.Fatalf("database: %v", err)
	}

	var publisher *messaging.Publisher
	if cfg.RabbitMQURL != "" {
		publisher, err = messaging.NewPublisher(cfg.RabbitMQURL)
		if err != nil {
			log.Printf("warning: rabbitmq unavailable: %v", err)
		} else {
			defer publisher.Close()
		}
	}

	repo := repository.New(gdb)
	svc := service.New(repo, publisher)
	flightHandler := handler.NewFlightHandler(svc)

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery(), gin.Logger(), middleware.RequestID())

	r.GET("/health", handler.Health)

	v1 := r.Group("/v1")
	{
		v1.GET("/flights", flightHandler.ListFlights)
		v1.GET("/flights/:id", flightHandler.GetFlight)
		v1.PUT("/flights/:id/status", flightHandler.UpdateFlightStatus)
		v1.GET("/flights/:id/operational", flightHandler.GetOperational)
		v1.GET("/routes", flightHandler.ListRoutes)
		v1.GET("/airports/:code/gates", flightHandler.ListGates)
		v1.POST("/airport-slots", flightHandler.CreateAirportSlot)
	}

	log.Printf("flight-ops-service listening on :%s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
