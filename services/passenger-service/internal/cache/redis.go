package cache

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

type Redis struct {
	client *redis.Client
}

func New(redisURL string) (*Redis, error) {
	opts, err := redis.ParseURL(redisURL)
	if err != nil {
		// fallback host:port without scheme
		opts = &redis.Options{Addr: strings.TrimPrefix(redisURL, "redis://")}
	}
	client := redis.NewClient(opts)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("redis ping: %w", err)
	}
	return &Redis{client: client}, nil
}

func (r *Redis) SetRefreshToken(ctx context.Context, userID, token string, ttl time.Duration) error {
	key := fmt.Sprintf("refresh:%s", userID)
	return r.client.Set(ctx, key, token, ttl).Err()
}

func (r *Redis) GetRefreshToken(ctx context.Context, userID string) (string, error) {
	key := fmt.Sprintf("refresh:%s", userID)
	return r.client.Get(ctx, key).Result()
}

func (r *Redis) DeleteRefreshToken(ctx context.Context, userID string) error {
	key := fmt.Sprintf("refresh:%s", userID)
	return r.client.Del(ctx, key).Err()
}

func (r *Redis) Close() error {
	return r.client.Close()
}
