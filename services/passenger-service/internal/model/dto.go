package model

import "time"

type RegisterRequest struct {
	FirstName   string `json:"first_name" binding:"required"`
	LastName    string `json:"last_name" binding:"required"`
	Email       string `json:"email" binding:"required,email"`
	Password    string `json:"password" binding:"required,min=8"`
	DateOfBirth string `json:"date_of_birth" binding:"required"`
	Gender      string `json:"gender" binding:"required,oneof=MALE FEMALE OTHER PREFER_NOT_TO_SAY"`
	Nationality string `json:"nationality" binding:"required,len=2"`
	PhoneNumber string `json:"phone_number"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type UpdatePassengerRequest struct {
	FirstName   string `json:"first_name"`
	MiddleName  string `json:"middle_name"`
	LastName    string `json:"last_name"`
	PhoneNumber string `json:"phone_number"`
	Nationality string `json:"nationality"`
}

type CreateDocumentRequest struct {
	DocumentType   string `json:"document_type" binding:"required,oneof=PASSPORT NATIONAL_ID DRIVING_LICENSE VISA"`
	DocumentNumber string `json:"document_number" binding:"required"`
	IssuingCountry string `json:"issuing_country" binding:"required,len=2"`
	ExpiryDate     string `json:"expiry_date" binding:"required"`
	IsPrimary      bool   `json:"is_primary"`
}

type PassengerResponse struct {
	PassengerID string    `json:"passenger_id"`
	FirstName   string    `json:"first_name"`
	MiddleName  string    `json:"middle_name,omitempty"`
	LastName    string    `json:"last_name"`
	DateOfBirth string    `json:"date_of_birth"`
	Gender      string    `json:"gender"`
	Nationality string    `json:"nationality,omitempty"`
	Email       string    `json:"email,omitempty"`
	PhoneNumber string    `json:"phone_number,omitempty"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
}

type UserResponse struct {
	UserID      string `json:"user_id"`
	PassengerID string `json:"passenger_id,omitempty"`
	Username    string `json:"username"`
	Email       string `json:"email"`
	IsActive    bool   `json:"is_active"`
}

type LoginResponse struct {
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
	ExpiresAt    time.Time    `json:"expires_at"`
	User         UserResponse `json:"user"`
}

type DocumentResponse struct {
	DocumentID     string `json:"document_id"`
	PassengerID    string `json:"passenger_id"`
	DocumentType   string `json:"document_type"`
	DocumentNumber string `json:"document_number"`
	IssuingCountry string `json:"issuing_country,omitempty"`
	ExpiryDate     string `json:"expiry_date"`
	IsPrimary      bool   `json:"is_primary"`
	IsVerified     bool   `json:"is_verified"`
}

type CountryResponse struct {
	CountryID   string `json:"country_id"`
	CountryName string `json:"country_name"`
	Nationality string `json:"nationality,omitempty"`
	Continent   string `json:"continent,omitempty"`
	PhoneCode   string `json:"phone_code,omitempty"`
}

func ToPassengerResponse(p *Passenger) PassengerResponse {
	resp := PassengerResponse{
		PassengerID: p.PassengerID.String(),
		FirstName:   p.FirstName,
		LastName:    p.LastName,
		DateOfBirth: p.DateOfBirth.Format("2006-01-02"),
		Gender:      p.Gender,
		IsActive:    p.IsActive,
		CreatedAt:   p.CreatedAt,
	}
	if p.MiddleName != nil {
		resp.MiddleName = *p.MiddleName
	}
	if p.Nationality != nil {
		resp.Nationality = *p.Nationality
	}
	if p.Email != nil {
		resp.Email = *p.Email
	}
	if p.PhoneNumber != nil {
		resp.PhoneNumber = *p.PhoneNumber
	}
	return resp
}

func ToUserResponse(u *User) UserResponse {
	resp := UserResponse{
		UserID:   u.UserID.String(),
		Username: u.Username,
		Email:    u.Email,
		IsActive: u.IsActive,
	}
	if u.PassengerID != nil {
		resp.PassengerID = u.PassengerID.String()
	}
	return resp
}

func ToDocumentResponse(d *PassengerDocument) DocumentResponse {
	resp := DocumentResponse{
		DocumentID:     d.DocumentID.String(),
		PassengerID:    d.PassengerID.String(),
		DocumentType:   d.DocumentType,
		DocumentNumber: d.DocumentNumber,
		ExpiryDate:     d.ExpiryDate.Format("2006-01-02"),
		IsPrimary:      d.IsPrimary,
		IsVerified:     d.IsVerified,
	}
	if d.IssuingCountry != nil {
		resp.IssuingCountry = *d.IssuingCountry
	}
	return resp
}

func ToCountryResponse(c Country) CountryResponse {
	resp := CountryResponse{
		CountryID:   c.CountryID,
		CountryName: c.CountryName,
	}
	if c.Nationality != nil {
		resp.Nationality = *c.Nationality
	}
	if c.Continent != nil {
		resp.Continent = *c.Continent
	}
	if c.PhoneCode != nil {
		resp.PhoneCode = *c.PhoneCode
	}
	return resp
}
