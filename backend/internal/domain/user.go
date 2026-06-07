package domain

import (
	"time"
)

type User struct {
	ID                   string    `json:"id" gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	Email                string    `json:"email" gorm:"uniqueIndex;not null"`
	PasswordHash         string    `json:"-" gorm:"not null"`
	Name                 string    `json:"name"`
	CreatedAt            time.Time `json:"created_at"`
	UpdatedAt            time.Time `json:"updated_at"`
	Profile              Profile   `json:"profile" gorm:"foreignKey:UserID"`
	PasswordResetToken   string    `json:"-"`
	PasswordResetExpires time.Time `json:"-"`
}

type Profile struct {
	UserID            string    `json:"user_id" gorm:"type:uuid;primaryKey"`
	AvatarURL         string    `json:"avatar_url"`
	ThemePreference   string    `json:"theme_preference" gorm:"default:'system'"` // light, dark, system
	ReadingLayout     string    `json:"reading_layout" gorm:"default:'vertical'"` // vertical, horizontal, continuous
	ReadingBrightness float64   `json:"reading_brightness" gorm:"default:1.0"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

type UserRepository interface {
	Create(user *User) error
	GetByID(id string) (*User, error)
	GetByEmail(email string) (*User, error)
	Update(user *User) error
	UpdateProfile(profile *Profile) error
}
