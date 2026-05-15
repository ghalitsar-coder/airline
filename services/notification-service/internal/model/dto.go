package model

type CreateNotificationRequest struct {
	PassengerID  *string `json:"passenger_id"`
	Channel      string  `json:"channel" binding:"required"`
	TemplateCode string  `json:"template_code" binding:"required"`
	Body         string  `json:"body" binding:"required"`
	Status       string  `json:"status"`
}

type NotificationResponse struct {
	NotificationID string  `json:"notification_id"`
	PassengerID    *string `json:"passenger_id,omitempty"`
	Channel        string  `json:"channel"`
	TemplateCode   string  `json:"template_code"`
	Body           string  `json:"body"`
	Status         string  `json:"status"`
}

type EventEnvelope struct {
	EventType string                 `json:"event_type"`
	Payload   map[string]interface{} `json:"payload"`
}
