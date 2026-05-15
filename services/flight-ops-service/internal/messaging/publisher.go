package messaging

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"

	"airline/flight-ops-service/internal/model"
)

const (
	exchangeName = "flight.events"
)

type Publisher struct {
	conn    *amqp.Connection
	channel *amqp.Channel
}

func NewPublisher(url string) (*Publisher, error) {
	conn, err := amqp.Dial(url)
	if err != nil {
		return nil, fmt.Errorf("rabbitmq dial: %w", err)
	}

	ch, err := conn.Channel()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("rabbitmq channel: %w", err)
	}

	if err := ch.ExchangeDeclare(
		exchangeName,
		"topic",
		true,
		false,
		false,
		false,
		nil,
	); err != nil {
		ch.Close()
		conn.Close()
		return nil, fmt.Errorf("declare exchange: %w", err)
	}

	log.Println("connected to RabbitMQ")
	return &Publisher{conn: conn, channel: ch}, nil
}

func (p *Publisher) Close() {
	if p.channel != nil {
		p.channel.Close()
	}
	if p.conn != nil {
		p.conn.Close()
	}
}

func (p *Publisher) PublishFlightStatusChanged(ctx context.Context, event model.FlightStatusChangedEvent) error {
	if p == nil || p.channel == nil {
		return nil
	}

	body, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("marshal event: %w", err)
	}

	routingKey := fmt.Sprintf("flight.status.%s", event.Status)
	return p.channel.PublishWithContext(ctx, exchangeName, routingKey, false, false, amqp.Publishing{
		ContentType:  "application/json",
		DeliveryMode: amqp.Persistent,
		Timestamp:    time.Now().UTC(),
		Body:         body,
	})
}
