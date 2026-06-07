package http

import (
	"time"

	"rockydex-api/internal/application"
	"rockydex-api/internal/interfaces/http/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRouter(
	authService *application.AuthService,
	userService *application.UserService,
	libService *application.LibraryService,
) *gin.Engine {
	r := gin.Default()

	// CORS Middleware
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	authHandler := NewAuthHandler(authService)
	userHandler := NewUserHandler(userService)
	libHandler := NewLibraryHandler(libService)

	api := r.Group("/api")
	{
		// Health check
		api.GET("/health", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"status": "ok",
				"time":   time.Now().Format(time.RFC3339),
			})
		})

		// Public Auth routes
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/google", authHandler.GoogleLogin)
			auth.POST("/forgot-password", authHandler.ForgotPassword)
			auth.POST("/reset-password", authHandler.ResetPassword)
		}

		// Protected routes (requires JWT)
		protected := api.Group("")
		protected.Use(middleware.AuthMiddleware(authService))
		{
			// User Profile & Preferences
			user := protected.Group("/user")
			{
				user.GET("/profile", userHandler.GetProfile)
				user.PUT("/profile", userHandler.UpdateProfile)
				user.GET("/stats", userHandler.GetStats)
			}

			// Favorites
			favs := protected.Group("/favorites")
			{
				favs.GET("", libHandler.GetFavorites)
				favs.POST("", libHandler.AddFavorite)
				favs.DELETE("/:slug", libHandler.RemoveFavorite)
				favs.GET("/check/:slug", libHandler.CheckFavorite)
			}

			// Reading History
			hist := protected.Group("/history")
			{
				hist.GET("", libHandler.GetHistory)
				hist.POST("", libHandler.SaveHistory)
				hist.GET("/comic/:slug", libHandler.GetComicHistory)
				hist.DELETE("/:slug", libHandler.DeleteHistory)
				hist.DELETE("", libHandler.ClearHistory)
			}
		}
	}

	return r
}
