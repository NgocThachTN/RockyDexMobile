package repository

import (
	"errors"
	"time"

	"rockydex-api/internal/domain"

	"gorm.io/gorm"
)

type PgHistoryRepository struct {
	db *gorm.DB
}

func NewPgHistoryRepository(db *gorm.DB) domain.HistoryRepository {
	return &PgHistoryRepository{db: db}
}

func (r *PgHistoryRepository) Save(hist *domain.History) error {
	now := time.Now()
	result := r.db.Model(&domain.History{}).
		Where("user_id = ? AND comic_slug = ?", hist.UserID, hist.ComicSlug).
		Updates(map[string]interface{}{
			"comic_name":       hist.ComicName,
			"comic_thumb":      hist.ComicThumb,
			"chapter_slug":     hist.ChapterSlug,
			"chapter_name":     hist.ChapterName,
			"progress_percent": hist.ProgressPercent,
			"page_number":      hist.PageNumber,
			"last_read_at":     now,
		})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected > 0 {
		return nil
	}

	hist.LastReadAt = now
	return r.db.Create(hist).Error
}

func (r *PgHistoryRepository) GetList(userID string) ([]domain.History, error) {
	var histories []domain.History
	err := r.db.
		Where("user_id = ?", userID).
		Order("last_read_at desc").
		Find(&histories).Error
	return histories, err
}

func (r *PgHistoryRepository) GetByComic(userID string, comicSlug string) (*domain.History, error) {
	var hist domain.History
	err := r.db.First(&hist, "user_id = ? AND comic_slug = ?", userID, comicSlug).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &hist, nil
}

func (r *PgHistoryRepository) Delete(userID string, comicSlug string) error {
	return r.db.Delete(&domain.History{}, "user_id = ? AND comic_slug = ?", userID, comicSlug).Error
}

func (r *PgHistoryRepository) Clear(userID string) error {
	return r.db.Delete(&domain.History{}, "user_id = ?", userID).Error
}
