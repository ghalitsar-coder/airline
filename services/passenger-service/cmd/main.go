package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"airline/passenger-service/internal/cache"
	"airline/passenger-service/internal/config"
	"airline/passenger-service/internal/db"
	"airline/passenger-service/internal/handler"
	"airline/passenger-service/internal/middleware"
	"airline/passenger-service/internal/repository"
	"airline/passenger-service/internal/service"
	"airline/passenger-service/internal/storage"
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
			log.Printf("warning: redis unavailable: %v", err)
		}
	}

	var minioClient *storage.MinIO
	if cfg.MinIOEndpoint != "" {
		minioClient, err = storage.New(cfg.MinIOEndpoint, cfg.MinIOAccessKey, cfg.MinIOSecretKey, cfg.MinIOUseSSL)
		if err != nil {
			log.Printf("warning: minio unavailable: %v", err)
		}
	}

	repo := repository.New(gdb)
	svc := service.New(repo, redisClient, minioClient, cfg)
	authHandler := handler.NewAuthHandler(svc)
	passengerHandler := handler.NewPassengerHandler(svc)
	internalHandler := handler.NewInternalHandler(svc, cfg.ServiceAPIKey)

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery(), gin.Logger(), middleware.RequestID())

	r.GET("/health", handler.Health)

	v1 := r.Group("/v1")
	{
		auth := v1.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.Refresh)
		}

		v1.GET("/countries", passengerHandler.GetCountries)

		internal := v1.Group("/internal")
		internal.Use(internalHandler.ServiceAuth())
		{
			internal.GET("/passengers/:id/validate", internalHandler.ValidatePassenger)
		}

		protected := v1.Group("")
		protected.Use(middleware.JWT(cfg.JWTSecret))
		{
			passengers := protected.Group("/passengers")
			{
				passengers.GET("/:id", passengerHandler.GetPassenger)
				passengers.PUT("/:id", passengerHandler.UpdatePassenger)
				passengers.POST("/:id/documents", passengerHandler.CreateDocumentJSON)
				passengers.POST("/:id/documents/upload", passengerHandler.CreateDocument)
				passengers.GET("/:id/documents", passengerHandler.GetDocuments)
				passengers.DELETE("/:id/documents/:docId", passengerHandler.DeleteDocument)
			}
		}
	}

	log.Printf("passenger-service listening on :%s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
