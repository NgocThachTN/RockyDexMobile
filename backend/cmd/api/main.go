package main

import (
	"log"

	"rockydex-api/internal/application"
	"rockydex-api/internal/infrastructure/database"
	"rockydex-api/internal/infrastructure/repository"
	"rockydex-api/internal/interfaces/http"
	"rockydex-api/internal/shared/config"
)

// @title RockyDex API
// @version 1.1.2
// @description Backend API for RockyDex Mobile App, supporting user authentication, favorites, and reading history synchronization.
// @host localhost:8080
// @BasePath /api
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization

func main() {
	log.Println("Starting RockyDex API Server...")

	// 1. Load Configurations
	cfg := config.LoadConfig()

	// 2. Initialize Database Connection
	db, err := database.InitPostgres(cfg)
	if err != nil {
		log.Fatalf("Database initialization failed: %v", err)
	}

	// 3. Initialize Repositories
	userRepo := repository.NewPgUserRepository(db)
	favRepo := repository.NewPgFavoriteRepository(db)
	histRepo := repository.NewPgHistoryRepository(db)

	// Note: Redis client can be optionally initialized here if needed for session caching
	// rdbClient, err := cache.InitRedis(cfg)
	// if err != nil {
	// 	log.Printf("Warning: Redis failed to connect (caching disabled): %v", err)
	// }

	// 4. Initialize Services (Business Logic)
	authService := application.NewAuthService(userRepo, cfg)
	userService := application.NewUserService(userRepo, histRepo, favRepo)
	libService := application.NewLibraryService(favRepo, histRepo)

	// 5. Setup Router and Start Server
	router := http.SetupRouter(authService, userService, libService)

	log.Printf("Server running on port %s", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}
