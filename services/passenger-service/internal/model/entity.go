package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Passenger struct {
	PassengerID uuid.UUID `gorm:"column:passenger_id;type:uuid;primaryKey"`
	FirstName   string    `gorm:"column:first_name;size:100;not null"`
	MiddleName  *string   `gorm:"column:middle_name;size:100"`
	LastName    string    `gorm:"column:last_name;size:100;not null"`
	DateOfBirth time.Time `gorm:"column:date_of_birth;type:date;not null"`
	Gender      string    `gorm:"column:gender;type:gender_type;not null"`
	Nationality *string   `gorm:"column:nationality;type:char(2)"`
	Email       *string   `gorm:"column:email;size:255"`
	PhoneNumber *string   `gorm:"column:phone_number;size:30"`
	IsActive    bool      `gorm:"column:is_active;not null;default:true"`
	CreatedAt   time.Time `gorm:"column:created_at;not null"`
}

func (Passenger) TableName() string { return "passengers" }

type User struct {
	UserID       uuid.UUID  `gorm:"column:user_id;type:uuid;primaryKey"`
	PassengerID  *uuid.UUID `gorm:"column:passenger_id;type:uuid"`
	Username     string     `gorm:"column:username;size:100;uniqueIndex;not null"`
	Email        string     `gorm:"column:email;size:255;uniqueIndex;not null"`
	PasswordHash string     `gorm:"column:password_hash;size:255;not null"`
	IsActive     bool       `gorm:"column:is_active;not null;default:true"`
}

func (User) TableName() string { return "users" }

type PassengerDocument struct {
	DocumentID     uuid.UUID `gorm:"column:document_id;type:uuid;primaryKey"`
	PassengerID    uuid.UUID `gorm:"column:passenger_id;type:uuid;not null"`
	DocumentType   string    `gorm:"column:document_type;type:document_type;not null"`
	DocumentNumber string    `gorm:"column:document_number;size:50;not null"`
	IssuingCountry *string   `gorm:"column:issuing_country;type:char(2)"`
	ExpiryDate     time.Time `gorm:"column:expiry_date;type:date;not null"`
	IsPrimary      bool      `gorm:"column:is_primary;not null;default:false"`
	IsVerified     bool      `gorm:"column:is_verified;not null;default:false"`
}

func (PassengerDocument) TableName() string { return "passenger_documents" }

type Country struct {
	CountryID   string  `gorm:"column:country_id;type:char(2);primaryKey"`
	CountryName string  `gorm:"column:country_name;size:100;not null"`
	Nationality *string `gorm:"column:nationality;size:100"`
	Continent   *string `gorm:"column:continent;size:50"`
	PhoneCode   *string `gorm:"column:phone_code;size:10"`
}

func (Country) TableName() string { return "countries" }

func (p *Passenger) BeforeCreate(tx *gorm.DB) error {
	if p.PassengerID == uuid.Nil {
		p.PassengerID = uuid.New()
	}
	return nil
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.UserID == uuid.Nil {
		u.UserID = uuid.New()
	}
	return nil
}

func (d *PassengerDocument) BeforeCreate(tx *gorm.DB) error {
	if d.DocumentID == uuid.Nil {
		d.DocumentID = uuid.New()
	}
	return nil
}
