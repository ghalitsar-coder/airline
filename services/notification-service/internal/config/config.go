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

	RabbitMQURL string

	SMTPHost     string
	SMTPPort     int
	SMTPUser     string
	SMTPPassword string
	SMTPFrom     string
}

func Load() *Config {
	return &Config{
		Port:         getEnv("PORT", "8004"),
		DBHost:       getEnv("DB_HOST", "localhost"),
		DBPort:       getEnv("DB_PORT", "5432"),
		DBName:       getEnv("DB_NAME", "notif_db"),
		DBUser:       getEnv("DB_USER", "airline"),
		DBPassword:   getEnv("DB_PASSWORD", "postgres"),
		RabbitMQURL:  getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672"),
		SMTPHost:     getEnv("SMTP_HOST", ""),
		SMTPPort:     getEnvInt("SMTP_PORT", 587),
		SMTPUser:     getEnv("SMTP_USER", ""),
		SMTPPassword: getEnv("SMTP_PASSWORD", ""),
		SMTPFrom:     getEnv("SMTP_FROM", "noreply@skylink.airline"),
	}
}

func (c *Config) SMTPEnabled() bool {
	return c.SMTPHost != ""
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
