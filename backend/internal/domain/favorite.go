package domain

import (
	"time"
)

type Favorite struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	UserID    string    `json:"user_id" gorm:"type:uuid;index;not null"`
	ComicSlug string    `json:"comic_slug" gorm:"not null"`
	ComicName string    `json:"comic_name" gorm:"not null"`
	ComicThumb string    `json:"comic_thumb"`
	CreatedAt time.Time `json:"created_at"`
}

type FavoriteRepository interface {
	Add(fav *Favorite) error
	Remove(userID string, comicSlug string) error
	GetList(userID string) ([]Favorite, error)
	IsFavorite(userID string, comicSlug string) (bool, error)
}
