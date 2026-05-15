package config

import "os"

type Config struct {
	Port string

	DBHost     string
	DBPort     string
	DBName     string
	DBUser     string
	DBPassword string

	RabbitMQURL string
}

func Load() *Config {
	return &Config{
		Port:        getEnv("PORT", "8003"),
		DBHost:      getEnv("DB_HOST", "localhost"),
		DBPort:      getEnv("DB_PORT", "5432"),
		DBName:      getEnv("DB_NAME", "flight_db"),
		DBUser:      getEnv("DB_USER", "airline"),
		DBPassword:  getEnv("DB_PASSWORD", "postgres"),
		RabbitMQURL: getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672"),
	}
}

func getEnv(key, defaultVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultVal
}
