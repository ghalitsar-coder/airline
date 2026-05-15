package service

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"

	"airline/notification-service/internal/config"
	"airline/notification-service/internal/model"
	"airline/notification-service/internal/repository"
)

const (
	ChannelEmail = "EMAIL"
	StatusSent   = "SENT"
	StatusPending = "PENDING"
)

type NotificationService struct {
	repo   *repository.NotificationRepo
	email  *EmailSender
}

func New(repo *repository.NotificationRepo, cfg *config.Config) *NotificationService {
	return &NotificationService{
		repo:  repo,
		email: NewEmailSender(cfg),
	}
}

func (s *NotificationService) Create(req model.CreateNotificationRequest) (*model.NotificationResponse, error) {
	status := req.Status
	if status == "" {
		status = StatusPending
	}

	n := &model.Notification{
		Channel:      req.Channel,
		TemplateCode: req.TemplateCode,
		Body:         req.Body,
		Status:       status,
	}

	if req.PassengerID != nil && *req.PassengerID != "" {
		pid, err := uuid.Parse(*req.PassengerID)
		if err != nil {
			return nil, fmt.Errorf("invalid passenger_id: %w", err)
		}
		n.PassengerID = &pid
	}

	if err := s.repo.Create(n); err != nil {
		return nil, err
	}

	resp := toResponse(n)
	return &resp, nil
}

func (s *NotificationService) ListByPassenger(passengerID uuid.UUID) ([]model.NotificationResponse, error) {
	items, err := s.repo.ListByPassenger(passengerID)
	if err != nil {
		return nil, err
	}

	out := make([]model.NotificationResponse, 0, len(items))
	for i := range items {
		out = append(out, toResponse(&items[i]))
	}
	return out, nil
}

func (s *NotificationService) ProcessEmailEvent(envelope model.EventEnvelope) error {
	passengerID := extractPassengerID(envelope.Payload)
	templateCode := extractString(envelope.Payload, "template_code")
	if templateCode == "" {
		templateCode = eventTypeToTemplate(envelope.EventType)
	}

	body := extractString(envelope.Payload, "body")
	if body == "" {
		raw, _ := json.Marshal(envelope.Payload)
		body = string(raw)
	}

	to := extractString(envelope.Payload, "to", "email")
	subject := extractString(envelope.Payload, "subject")
	if subject == "" {
		subject = envelope.EventType
	}

	if err := s.email.Send(to, subject, body); err != nil {
		return err
	}

	n := &model.Notification{
		Channel:      ChannelEmail,
		TemplateCode: templateCode,
		Body:         body,
		Status:       StatusSent,
	}
	if passengerID != nil {
		n.PassengerID = passengerID
	}

	return s.repo.Create(n)
}

func toResponse(n *model.Notification) model.NotificationResponse {
	resp := model.NotificationResponse{
		NotificationID: n.NotificationID.String(),
		Channel:        n.Channel,
		TemplateCode:   n.TemplateCode,
		Body:           n.Body,
		Status:         n.Status,
	}
	if n.PassengerID != nil {
		s := n.PassengerID.String()
		resp.PassengerID = &s
	}
	return resp
}

func extractPassengerID(payload map[string]interface{}) *uuid.UUID {
	if payload == nil {
		return nil
	}
	for _, key := range []string{"passenger_id", "passengerId"} {
		if v, ok := payload[key]; ok {
			if id := parseUUID(v); id != nil {
				return id
			}
		}
	}
	if ids, ok := payload["passenger_ids"].([]interface{}); ok && len(ids) > 0 {
		if id := parseUUID(ids[0]); id != nil {
			return id
		}
	}
	return nil
}

func extractString(payload map[string]interface{}, keys ...string) string {
	if payload == nil {
		return ""
	}
	for _, key := range keys {
		if v, ok := payload[key]; ok {
			if s, ok := v.(string); ok && s != "" {
				return s
			}
		}
	}
	return ""
}

func parseUUID(v interface{}) *uuid.UUID {
	switch x := v.(type) {
	case string:
		id, err := uuid.Parse(x)
		if err != nil {
			return nil
		}
		return &id
	default:
		return nil
	}
}

func eventTypeToTemplate(eventType string) string {
	if eventType == "" {
		return "unknown"
	}
	return strings.ToLower(strings.ReplaceAll(eventType, " ", "-"))
}
