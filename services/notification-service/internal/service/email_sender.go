package service

import (
	"fmt"
	"log"
	"net/smtp"
	"strconv"

	"airline/notification-service/internal/config"
)

type EmailSender struct {
	cfg *config.Config
}

func NewEmailSender(cfg *config.Config) *EmailSender {
	return &EmailSender{cfg: cfg}
}

func (s *EmailSender) Send(to, subject, body string) error {
	if !s.cfg.SMTPEnabled() {
		log.Printf("[email] to=%s subject=%q body=%s", to, subject, body)
		return nil
	}

	addr := s.cfg.SMTPHost + ":" + strconv.Itoa(s.cfg.SMTPPort)
	from := s.cfg.SMTPFrom
	if to == "" {
		to = s.cfg.SMTPFrom
	}

	msg := []byte(fmt.Sprintf(
		"From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s",
		from, to, subject, body,
	))

	var auth smtp.Auth
	if s.cfg.SMTPUser != "" {
		auth = smtp.PlainAuth("", s.cfg.SMTPUser, s.cfg.SMTPPassword, s.cfg.SMTPHost)
	}

	if err := smtp.SendMail(addr, auth, from, []string{to}, msg); err != nil {
		return fmt.Errorf("smtp send: %w", err)
	}

	log.Printf("[email] sent via SMTP to=%s subject=%q", to, subject)
	return nil
}
