package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port string

	DBHost     string
	DBPort     string
	DBName     string
	DBUser     string
	DBPassword string

	RedisURL    string
	RabbitMQURL string

	MinIOEndpoint  string
	MinIOAccessKey string
	MinIOSecretKey string
	MinIOUseSSL    bool

	JWTSecret          string
	JWTAccessExpMinute int
	JWTRefreshExpHour  int

	ServiceAPIKey string
}

func Load() *Config {
	return &Config{
		Port:               getEnv("PORT", "8001"),
		DBHost:             getEnv("DB_HOST", "localhost"),
		DBPort:             getEnv("DB_PORT", "5432"),
		DBName:             getEnv("DB_NAME", "passenger_db"),
		DBUser:             getEnv("DB_USER", "airline"),
		DBPassword:         getEnv("DB_PASSWORD", "postgres"),
		RedisURL:           getEnv("REDIS_URL", "redis://localhost:6379"),
		RabbitMQURL:        getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672"),
		MinIOEndpoint:      getEnv("MINIO_ENDPOINT", "localhost:9000"),
		MinIOAccessKey:     getEnv("MINIO_ACCESS_KEY", "minioadmin"),
		MinIOSecretKey:     getEnv("MINIO_SECRET_KEY", "minioadmin"),
		MinIOUseSSL:        getEnvBool("MINIO_USE_SSL", false),
		JWTSecret:          getEnv("JWT_SECRET", "airline-jwt-secret-key-change-in-production"),
		JWTAccessExpMinute: getEnvInt("JWT_ACCESS_EXP_MIN", 15),
		JWTRefreshExpHour:  getEnvInt("JWT_REFRESH_EXP_HOUR", 168),
		ServiceAPIKey:      getEnv("SERVICE_API_KEY", "airline-internal-dev-key"),
	}
}

func getEnv(key, defaultVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultVal
}

func getEnvInt(key string, defaultVal int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return defaultVal
}

func getEnvBool(key string, defaultVal bool) bool {
	if v := os.Getenv(key); v != "" {
		b, err := strconv.ParseBool(v)
		if err == nil {
			return b
		}
	}
	return defaultVal
}
