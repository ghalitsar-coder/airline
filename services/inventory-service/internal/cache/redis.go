package cache

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

type Redis struct {
	client *redis.Client
}

func New(redisURL string) (*Redis, error) {
	opts, err := redis.ParseURL(redisURL)
	if err != nil {
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

func seatLockKey(flightID, seatID uuid.UUID) string {
	return fmt.Sprintf("seat:lock:%s:%s", flightID, seatID)
}

func (r *Redis) TryLockSeat(ctx context.Context, flightID, seatID uuid.UUID, bookingSessionID string, ttl time.Duration) (bool, error) {
	key := seatLockKey(flightID, seatID)
	ok, err := r.client.SetNX(ctx, key, bookingSessionID, ttl).Result()
	if err != nil {
		return false, err
	}
	return ok, nil
}

func (r *Redis) ReleaseSeatLock(ctx context.Context, flightID, seatID uuid.UUID) error {
	return r.client.Del(ctx, seatLockKey(flightID, seatID)).Err()
}

func (r *Redis) GetSeatLockSession(ctx context.Context, flightID, seatID uuid.UUID) (string, error) {
	return r.client.Get(ctx, seatLockKey(flightID, seatID)).Result()
}

func (r *Redis) Close() error {
	return r.client.Close()
}
