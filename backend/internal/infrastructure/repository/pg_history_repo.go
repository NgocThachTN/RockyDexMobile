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
	var existing domain.History
	err := r.db.First(&existing, "user_id = ? AND comic_slug = ?", hist.UserID, hist.ComicSlug).Error
	if err == nil {
		// Update existing history entry
		existing.ChapterSlug = hist.ChapterSlug
		existing.ChapterName = hist.ChapterName
		existing.ProgressPercent = hist.ProgressPercent
		existing.PageNumber = hist.PageNumber
		existing.LastReadAt = time.Now()
		return r.db.Save(&existing).Error
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}
	// Create new history entry
	hist.LastReadAt = time.Now()
	return r.db.Create(hist).Error
}

func (r *PgHistoryRepository) GetList(userID string) ([]domain.History, error) {
	var histories []domain.History
	err := r.db.Find(&histories, "user_id = ?", userID).Order("last_read_at desc").Error
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
