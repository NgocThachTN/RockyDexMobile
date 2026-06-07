package http

import (
	"net/http"

	"rockydex-api/internal/application"
	"rockydex-api/internal/application/dto"

	"github.com/gin-gonic/gin"
)

type UserHandler struct {
	userService *application.UserService
}

func NewUserHandler(userService *application.UserService) *UserHandler {
	return &UserHandler{userService: userService}
}

// GetProfile godoc
// @Summary Get user profile
// @Description Returns the user's profile information including preferences.
// @Tags user
// @Produce json
// @Security BearerAuth
// @Success 200 {object} domain.User
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /user/profile [get]
func (h *UserHandler) GetProfile(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	user, err := h.userService.GetProfile(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, user)
}

// UpdateProfile godoc
// @Summary Update user profile preferences
// @Description Updates user profile avatar, theme, layout, or brightness settings.
// @Tags user
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param input body dto.UpdateProfileInput true "Profile details to update"
// @Success 200 {object} domain.Profile
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /user/profile [put]
func (h *UserHandler) UpdateProfile(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	var input dto.UpdateProfileInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	profile, err := h.userService.UpdateProfile(userID, input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, profile)
}

// GetStats godoc
// @Summary Get user reading statistics
// @Description Returns counts of read comics, favorites, and chapters read.
// @Tags user
// @Produce json
// @Security BearerAuth
// @Success 200 {object} dto.ReadingStats
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /user/stats [get]
func (h *UserHandler) GetStats(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	stats, err := h.userService.GetReadingStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}
