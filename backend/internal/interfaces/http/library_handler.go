package http

import (
	"net/http"

	"rockydex-api/internal/application"
	"rockydex-api/internal/domain"

	"github.com/gin-gonic/gin"
)

type LibraryHandler struct {
	libService *application.LibraryService
}

func NewLibraryHandler(libService *application.LibraryService) *LibraryHandler {
	return &LibraryHandler{libService: libService}
}

// GetFavorites godoc
// @Summary Get user's favorite comics list
// @Description Returns a list of all comics marked as favorite by the logged-in user.
// @Tags library
// @Produce json
// @Security BearerAuth
// @Success 200 {array} domain.Favorite
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /favorites [get]
func (h *LibraryHandler) GetFavorites(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	list, err := h.libService.GetFavorites(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, list)
}

// AddFavorite godoc
// @Summary Add a comic to user's favorites
// @Description Marks a comic as favorite.
// @Tags library
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param input body domain.Favorite true "Favorite comic details"
// @Success 200 {object} map[string]string "Added to favorites"
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /favorites [post]
func (h *LibraryHandler) AddFavorite(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	var input domain.Favorite
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.libService.AddToFavorites(userID, input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "added to favorites"})
}

// RemoveFavorite godoc
// @Summary Remove a comic from user's favorites
// @Description Unmarks a comic as favorite by its slug.
// @Tags library
// @Produce json
// @Security BearerAuth
// @Param slug path string true "Comic Slug"
// @Success 200 {object} map[string]string "Removed from favorites"
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /favorites/{slug} [delete]
func (h *LibraryHandler) RemoveFavorite(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	comicSlug := c.Param("slug")
	if comicSlug == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "slug is required"})
		return
	}

	err := h.libService.RemoveFromFavorites(userID, comicSlug)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "removed from favorites"})
}

// CheckFavorite godoc
// @Summary Check if a comic is in user's favorites
// @Description Checks if the user has favorited a comic.
// @Tags library
// @Produce json
// @Security BearerAuth
// @Param slug path string true "Comic Slug"
// @Success 200 {object} map[string]bool "is_favorite status"
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /favorites/check/{slug} [get]
func (h *LibraryHandler) CheckFavorite(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	comicSlug := c.Param("slug")
	if comicSlug == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "slug is required"})
		return
	}

	isFav, err := h.libService.CheckFavorite(userID, comicSlug)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"is_favorite": isFav})
}

// GetHistory godoc
// @Summary Get user's reading history
// @Description Returns the chronological list of comics and chapters the user has read.
// @Tags library
// @Produce json
// @Security BearerAuth
// @Success 200 {array} domain.History
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /history [get]
func (h *LibraryHandler) GetHistory(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	list, err := h.libService.GetHistory(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, list)
}

// SaveHistory godoc
// @Summary Save reading history progress
// @Description Saves or updates reading history and chapter progress for a comic.
// @Tags library
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param input body domain.History true "History details"
// @Success 200 {object} map[string]string "History saved"
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /history [post]
func (h *LibraryHandler) SaveHistory(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	var input domain.History
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.libService.SaveHistory(userID, input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "history saved"})
}

// GetComicHistory godoc
// @Summary Get reading history for a specific comic
// @Description Returns the reading history for a specific comic if it exists.
// @Tags library
// @Produce json
// @Security BearerAuth
// @Param slug path string true "Comic Slug"
// @Success 200 {object} domain.History
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 404 {object} map[string]string "Not Found"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /history/comic/{slug} [get]
func (h *LibraryHandler) GetComicHistory(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	comicSlug := c.Param("slug")
	if comicSlug == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "slug is required"})
		return
	}

	hist, err := h.libService.GetComicHistory(userID, comicSlug)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if hist == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "no history for this comic"})
		return
	}
	c.JSON(http.StatusOK, hist)
}

// DeleteHistory godoc
// @Summary Delete reading history for a specific comic
// @Description Deletes the user's reading history for a single comic.
// @Tags library
// @Produce json
// @Security BearerAuth
// @Param slug path string true "Comic Slug"
// @Success 200 {object} map[string]string "History deleted"
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /history/{slug} [delete]
func (h *LibraryHandler) DeleteHistory(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	comicSlug := c.Param("slug")
	if comicSlug == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "slug is required"})
		return
	}

	err := h.libService.DeleteHistory(userID, comicSlug)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "history deleted"})
}

// ClearHistory godoc
// @Summary Clear all reading history
// @Description Deletes all reading history records for the user.
// @Tags library
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]string "History cleared"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /history [delete]
func (h *LibraryHandler) ClearHistory(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	err := h.libService.ClearHistory(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "history cleared"})
}
