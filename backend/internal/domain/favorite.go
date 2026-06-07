package domain

import (
	"encoding/json"
	"time"
)

type Favorite struct {
	ID         uint      `json:"id" gorm:"primaryKey"`
	UserID     string    `json:"user_id" gorm:"type:uuid;index;not null"`
	ComicSlug  string    `json:"comic_slug" gorm:"not null"`
	ComicName  string    `json:"comic_name" gorm:"not null"`
	ComicThumb string    `json:"comic_thumb"`
	CreatedAt  time.Time `json:"created_at"`
}

// UnmarshalJSON customizes unmarshaling to accept both local DB keys (slug, name, thumb_url)
// and standard backend keys (comic_slug, comic_name, comic_thumb).
func (f *Favorite) UnmarshalJSON(data []byte) error {
	type Alias Favorite
	aux := &struct {
		Slug     string `json:"slug"`
		Name     string `json:"name"`
		ThumbURL string `json:"thumb_url"`
		*Alias
	}{
		Alias: (*Alias)(f),
	}

	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}

	if f.ComicSlug == "" && aux.Slug != "" {
		f.ComicSlug = aux.Slug
	}
	if f.ComicName == "" && aux.Name != "" {
		f.ComicName = aux.Name
	}
	if f.ComicThumb == "" && aux.ThumbURL != "" {
		f.ComicThumb = aux.ThumbURL
	}

	return nil
}

type FavoriteRepository interface {
	Add(fav *Favorite) error
	Remove(userID string, comicSlug string) error
	GetList(userID string) ([]Favorite, error)
	IsFavorite(userID string, comicSlug string) (bool, error)
}
