package domain

import (
	"time"
)

type History struct {
	ID              uint      `json:"id" gorm:"primaryKey"`
	UserID          string    `json:"user_id" gorm:"type:uuid;index;not null"`
	ComicSlug       string    `json:"comic_slug" gorm:"not null"`
	ComicName       string    `json:"comic_name" gorm:"not null"`
	ComicThumb      string    `json:"comic_thumb"`
	ChapterSlug     string    `json:"chapter_slug" gorm:"not null"`
	ChapterName     string    `json:"chapter_name" gorm:"not null"`
	ProgressPercent int       `json:"progress_percent" gorm:"default:0"` // 0 to 100
	LastReadAt      time.Time `json:"last_read_at"`
}

type HistoryRepository interface {
	Save(hist *History) error
	GetList(userID string) ([]History, error)
	GetByComic(userID string, comicSlug string) (*History, error)
	Delete(userID string, comicSlug string) error
	Clear(userID string) error
}
