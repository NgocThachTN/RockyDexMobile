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

// Favorites
func (h *LibraryHandler) GetFavorites(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	list, err := h.libService.GetFavorites(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, list)
}

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

// History
func (h *LibraryHandler) GetHistory(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	list, err := h.libService.GetHistory(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, list)
}

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

func (h *LibraryHandler) ClearHistory(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	err := h.libService.ClearHistory(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "history cleared"})
}
