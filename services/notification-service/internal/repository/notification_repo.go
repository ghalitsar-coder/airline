package repository

import (
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"airline/notification-service/internal/model"
)

var ErrNotFound = errors.New("not found")

type NotificationRepo struct {
	db *gorm.DB
}

func New(db *gorm.DB) *NotificationRepo {
	return &NotificationRepo{db: db}
}

func (r *NotificationRepo) Create(n *model.Notification) error {
	return r.db.Create(n).Error
}

func (r *NotificationRepo) ListByPassenger(passengerID uuid.UUID) ([]model.Notification, error) {
	var items []model.Notification
	err := r.db.Where("passenger_id = ?", passengerID).
		Order("notification_id DESC").
		Find(&items).Error
	if items == nil {
		items = []model.Notification{}
	}
	return items, err
}
