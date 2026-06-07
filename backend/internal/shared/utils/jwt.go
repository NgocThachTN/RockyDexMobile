package utils

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type JWTRefreshClaims struct {
	UserID string `json:"user_id"`
	jwt.RegisteredClaims
}

// GenerateToken generates a signed JWT token for a given user ID
func GenerateToken(userID string, expiryHours int, secret string) (string, error) {
	claims := JWTRefreshClaims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(expiryHours) * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ValidateToken parses and validates a JWT token, returning the user ID
func ValidateToken(tokenString string, secret string) (string, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTRefreshClaims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})
	if err != nil {
		return "", err
	}

	if claims, ok := token.Claims.(*JWTRefreshClaims); ok && token.Valid {
		return claims.UserID, nil
	}

	return "", errors.New("invalid token")
}
