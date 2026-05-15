package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"airline/notification-service/internal/config"
	"airline/notification-service/internal/consumer"
	"airline/notification-service/internal/db"
	"airline/notification-service/internal/handler"
	"airline/notification-service/internal/middleware"
	"airline/notification-service/internal/repository"
	"airline/notification-service/internal/service"
)

func main() {
	cfg := config.Load()

	gdb, err := db.Connect(cfg.DBHost, cfg.DBPort, cfg.DBName, cfg.DBUser, cfg.DBPassword)
	if err != nil {
		log.Fatalf("database: %v", err)
	}

	repo := repository.New(gdb)
	svc := service.New(repo, cfg)
	notifHandler := handler.NewNotificationHandler(svc)

	if cfg.RabbitMQURL != "" {
		consumer.New(cfg.RabbitMQURL, svc).Start()
	}

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery(), gin.Logger(), middleware.RequestID())

	r.GET("/health", handler.Health)

	v1 := r.Group("/v1")
	{
		v1.GET("/notifications", notifHandler.List)
		v1.POST("/notifications", notifHandler.Create)
	}

	log.Printf("notification-service listening on :%s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
