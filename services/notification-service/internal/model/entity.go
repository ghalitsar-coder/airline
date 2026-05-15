package model

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Notification struct {
	NotificationID uuid.UUID  `gorm:"column:notification_id;type:uuid;primaryKey"`
	PassengerID    *uuid.UUID `gorm:"column:passenger_id;type:uuid"`
	Channel        string     `gorm:"column:channel;size:20"`
	TemplateCode   string     `gorm:"column:template_code;size:50"`
	Body           string     `gorm:"column:body;type:text"`
	Status         string     `gorm:"column:status;size:20"`
}

func (Notification) TableName() string { return "notifications" }

func (n *Notification) BeforeCreate(tx *gorm.DB) error {
	if n.NotificationID == uuid.Nil {
		n.NotificationID = uuid.New()
	}
	return nil
}
