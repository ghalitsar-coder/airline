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

	RedisURL          string
	DefaultLockTTLSec int
}

func Load() *Config {
	return &Config{
		Port:              getEnv("PORT", "8002"),
		DBHost:            getEnv("DB_HOST", "localhost"),
		DBPort:            getEnv("DB_PORT", "5432"),
		DBName:            getEnv("DB_NAME", "inventory_db"),
		DBUser:            getEnv("DB_USER", "airline"),
		DBPassword:        getEnv("DB_PASSWORD", "postgres"),
		RedisURL:          getEnv("REDIS_URL", "redis://localhost:6379"),
		DefaultLockTTLSec: getEnvInt("DEFAULT_LOCK_TTL_SEC", 600),
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
