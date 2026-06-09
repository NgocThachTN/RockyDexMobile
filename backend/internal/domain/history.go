package domain

import (
	"encoding/json"
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
	PageNumber      int       `json:"page_number" gorm:"default:1"`      // 1-based index of the page
	LastReadAt      time.Time `json:"last_read_at"`
}

// UnmarshalJSON customizes unmarshaling to accept both local DB keys (slug, name, thumb_url)
// and standard backend keys (comic_slug, comic_name, comic_thumb).
func (h *History) UnmarshalJSON(data []byte) error {
	type Alias History
	aux := &struct {
		Slug     string `json:"slug"`
		Name     string `json:"name"`
		ThumbURL string `json:"thumb_url"`
		*Alias
	}{
		Alias: (*Alias)(h),
	}

	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}

	if h.ComicSlug == "" && aux.Slug != "" {
		h.ComicSlug = aux.Slug
	}
	if h.ComicName == "" && aux.Name != "" {
		h.ComicName = aux.Name
	}
	if h.ComicThumb == "" && aux.ThumbURL != "" {
		h.ComicThumb = aux.ThumbURL
	}

	return nil
}

type HistoryRepository interface {
	Save(hist *History) error
	GetList(userID string) ([]History, error)
	GetByComic(userID string, comicSlug string) (*History, error)
	Delete(userID string, comicSlug string) error
	Clear(userID string) error
}
