package http

import (
	"net/http"

	"rockydex-api/internal/application"
	"rockydex-api/internal/application/dto"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService *application.AuthService
}

func NewAuthHandler(authService *application.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// Register godoc
// @Summary Register a new user
// @Description Creates a new user account with email, name, and password.
// @Tags auth
// @Accept json
// @Produce json
// @Param input body dto.RegisterInput true "Registration details"
// @Success 201 {object} dto.AuthResponse
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 409 {object} map[string]string "Conflict - Email already registered"
// @Router /auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var input dto.RegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.authService.Register(input)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, response)
}

// Login godoc
// @Summary User Login
// @Description Authenticates a user with email and password, returning a JWT token.
// @Tags auth
// @Accept json
// @Produce json
// @Param input body dto.LoginInput true "Login Credentials"
// @Success 200 {object} dto.AuthResponse
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Router /auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var input dto.LoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.authService.Login(input)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GoogleLogin godoc
// @Summary Google Authentication Login
// @Description Authenticates a user using a Google Identity Token. Registers them if not already registered.
// @Tags auth
// @Accept json
// @Produce json
// @Param input body dto.GoogleLoginInput true "Google ID Token"
// @Success 200 {object} dto.AuthResponse
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Router /auth/google [post]
func (h *AuthHandler) GoogleLogin(c *gin.Context) {
	var input dto.GoogleLoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.authService.LoginGoogle(input.IDToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// ForgotPassword godoc
// @Summary Request Password Reset Code
// @Description Generates a 6-digit password reset PIN for the given email. Logs and returns the code (dev-only fallback).
// @Tags auth
// @Accept json
// @Produce json
// @Param input body dto.ForgotPasswordInput true "User Email"
// @Success 200 {object} map[string]string "Reset PIN requested"
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /auth/forgot-password [post]
func (h *AuthHandler) ForgotPassword(c *gin.Context) {
	var input dto.ForgotPasswordInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	token, err := h.authService.ForgotPassword(input.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":             "Password reset code sent. Please check your email.",
		"reset_code_dev_only": token,
	})
}

// ResetPassword godoc
// @Summary Reset User Password
// @Description Resets the user's password using the 6-digit token code received.
// @Tags auth
// @Accept json
// @Produce json
// @Param input body dto.ResetPasswordInput true "Reset details (Email, Token, and New Password)"
// @Success 200 {object} map[string]string "Password reset successfully"
// @Failure 400 {object} map[string]string "Bad Request / Invalid token / Expired"
// @Router /auth/reset-password [post]
func (h *AuthHandler) ResetPassword(c *gin.Context) {
	var input dto.ResetPasswordInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.authService.ResetPassword(input.Email, input.Token, input.NewPassword)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password reset successfully."})
}
