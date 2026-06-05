package repository

import (
	"errors"

	"rockydex-api/internal/domain"

	"gorm.io/gorm"
)

type PgFavoriteRepository struct {
	db *gorm.DB
}

func NewPgFavoriteRepository(db *gorm.DB) domain.FavoriteRepository {
	return &PgFavoriteRepository{db: db}
}

func (r *PgFavoriteRepository) Add(fav *domain.Favorite) error {
	var existing domain.Favorite
	err := r.db.First(&existing, "user_id = ? AND comic_slug = ?", fav.UserID, fav.ComicSlug).Error
	if err == nil {
		return nil // already favorited
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}
	return r.db.Create(fav).Error
}

func (r *PgFavoriteRepository) Remove(userID string, comicSlug string) error {
	return r.db.Delete(&domain.Favorite{}, "user_id = ? AND comic_slug = ?", userID, comicSlug).Error
}

func (r *PgFavoriteRepository) GetList(userID string) ([]domain.Favorite, error) {
	var favorites []domain.Favorite
	err := r.db.Find(&favorites, "user_id = ?", userID).Order("created_at desc").Error
	return favorites, err
}

func (r *PgFavoriteRepository) IsFavorite(userID string, comicSlug string) (bool, error) {
	var count int64
	err := r.db.Model(&domain.Favorite{}).Where("user_id = ? AND comic_slug = ?", userID, comicSlug).Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}
