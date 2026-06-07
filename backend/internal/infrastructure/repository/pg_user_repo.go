package repository

import (
	"errors"

	"rockydex-api/internal/domain"

	"gorm.io/gorm"
)

type PgUserRepository struct {
	db *gorm.DB
}

func NewPgUserRepository(db *gorm.DB) domain.UserRepository {
	return &PgUserRepository{db: db}
}

func (r *PgUserRepository) Create(user *domain.User) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(user).Error; err != nil {
			return err
		}
		profile := domain.Profile{
			UserID:    user.ID,
			AvatarURL: user.Profile.AvatarURL,
		}
		return tx.Create(&profile).Error
	})
}

func (r *PgUserRepository) GetByID(id string) (*domain.User, error) {
	var user domain.User
	err := r.db.Preload("Profile").First(&user, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

func (r *PgUserRepository) GetByEmail(email string) (*domain.User, error) {
	var user domain.User
	err := r.db.Preload("Profile").First(&user, "email = ?", email).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

func (r *PgUserRepository) Update(user *domain.User) error {
	return r.db.Save(user).Error
}

func (r *PgUserRepository) UpdateProfile(profile *domain.Profile) error {
	return r.db.Save(profile).Error
}
