package database

import (
	"fmt"
	"log"

	"rockydex-api/internal/domain"
	"rockydex-api/internal/shared/config"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func InitPostgres(cfg *config.Config) (*gorm.DB, error) {
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
		cfg.DBHost, cfg.DBUser, cfg.DBPassword, cfg.DBName, cfg.DBPort, cfg.DBSSLMode)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to connect database: %w", err)
	}

	log.Println("Migrating database schemas...")
	err = db.AutoMigrate(
		&domain.User{},
		&domain.Profile{},
		&domain.Favorite{},
		&domain.History{},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to migrate schemas: %w", err)
	}

	log.Println("PostgreSQL connection established and migrated successfully.")
	return db, nil
}
