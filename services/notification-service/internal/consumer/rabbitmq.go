package consumer

import (
	"encoding/json"
	"log"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"

	"airline/notification-service/internal/model"
	"airline/notification-service/internal/service"
)

const (
	exchangeName  = "notification.in"
	queueName     = "notif.email.queue"
	routingKey    = "email"
	exchangeType  = "direct"
)

type Consumer struct {
	url string
	svc *service.NotificationService
}

func New(url string, svc *service.NotificationService) *Consumer {
	return &Consumer{url: url, svc: svc}
}

func (c *Consumer) Start() {
	go c.run()
}

func (c *Consumer) run() {
	for {
		if err := c.consume(); err != nil {
			log.Printf("rabbitmq consumer error: %v; reconnecting in 5s", err)
			time.Sleep(5 * time.Second)
		}
	}
}

func (c *Consumer) consume() error {
	conn, err := amqp.Dial(c.url)
	if err != nil {
		return err
	}
	defer conn.Close()

	ch, err := conn.Channel()
	if err != nil {
		return err
	}
	defer ch.Close()

	if err := ch.ExchangeDeclare(exchangeName, exchangeType, true, false, false, false, nil); err != nil {
		return err
	}

	q, err := ch.QueueDeclare(queueName, true, false, false, false, nil)
	if err != nil {
		return err
	}

	if err := ch.QueueBind(q.Name, routingKey, exchangeName, false, nil); err != nil {
		return err
	}

	if err := ch.Qos(1, 0, false); err != nil {
		return err
	}

	deliveries, err := ch.Consume(q.Name, "notification-service", false, false, false, false, nil)
	if err != nil {
		return err
	}

	log.Printf("rabbitmq consumer started: exchange=%s queue=%s routing_key=%s", exchangeName, queueName, routingKey)

	for d := range deliveries {
		c.handleDelivery(d)
	}

	return amqp.ErrClosed
}

func (c *Consumer) handleDelivery(d amqp.Delivery) {
	var envelope model.EventEnvelope
	if err := json.Unmarshal(d.Body, &envelope); err != nil {
		log.Printf("invalid message JSON: %v body=%s", err, string(d.Body))
		_ = d.Nack(false, false)
		return
	}

	if err := c.svc.ProcessEmailEvent(envelope); err != nil {
		log.Printf("process email event %q: %v", envelope.EventType, err)
		_ = d.Nack(false, true)
		return
	}

	if err := d.Ack(false); err != nil {
		log.Printf("ack message: %v", err)
	}
}
