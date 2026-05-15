package validation

import (
	"errors"
	"unicode"
)

var ErrWeakPassword = errors.New("password must be at least 8 characters with uppercase, lowercase, number, and symbol")

func ValidatePassword(password string) error {
	if len(password) < 8 {
		return ErrWeakPassword
	}
	var upper, lower, digit, symbol bool
	for _, r := range password {
		switch {
		case unicode.IsUpper(r):
			upper = true
		case unicode.IsLower(r):
			lower = true
		case unicode.IsDigit(r):
			digit = true
		case unicode.IsPunct(r) || unicode.IsSymbol(r):
			symbol = true
		}
	}
	if !upper || !lower || !digit || !symbol {
		return ErrWeakPassword
	}
	return nil
}
