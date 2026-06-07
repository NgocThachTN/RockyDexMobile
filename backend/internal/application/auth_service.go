package application

import (
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"time"

	"rockydex-api/internal/domain"
	"rockydex-api/internal/shared/config"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	userRepo domain.UserRepository
	cfg      *config.Config
}

type RegisterInput struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Name     string `json:"name" binding:"required"`
}

type LoginInput struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type GoogleLoginInput struct {
	IDToken string `json:"id_token" binding:"required"`
}

type ForgotPasswordInput struct {
	Email string `json:"email" binding:"required,email"`
}

type ResetPasswordInput struct {
	Email       string `json:"email" binding:"required,email"`
	Token       string `json:"token" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=6"`
}

type AuthResponse struct {
	Token string       `json:"token"`
	User  *domain.User `json:"user"`
}

type JWTRefreshClaims struct {
	UserID string `json:"user_id"`
	jwt.RegisteredClaims
}

func NewAuthService(userRepo domain.UserRepository, cfg *config.Config) *AuthService {
	return &AuthService{userRepo: userRepo, cfg: cfg}
}

func (s *AuthService) Register(input RegisterInput) (*AuthResponse, error) {
	existing, err := s.userRepo.GetByEmail(input.Email)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return nil, errors.New("email already registered")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &domain.User{
		Email:        input.Email,
		PasswordHash: string(hashedPassword),
		Name:         input.Name,
	}

	if err := s.userRepo.Create(user); err != nil {
		return nil, err
	}

	token, err := s.generateToken(user.ID)
	if err != nil {
		return nil, err
	}

	// Fetch full details (profile loaded)
	fullUser, _ := s.userRepo.GetByID(user.ID)

	return &AuthResponse{
		Token: token,
		User:  fullUser,
	}, nil
}

func (s *AuthService) Login(input LoginInput) (*AuthResponse, error) {
	user, err := s.userRepo.GetByEmail(input.Email)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("invalid email or password")
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(input.Password))
	if err != nil {
		return nil, errors.New("invalid email or password")
	}

	token, err := s.generateToken(user.ID)
	if err != nil {
		return nil, err
	}

	return &AuthResponse{
		Token: token,
		User:  user,
	}, nil
}

func (s *AuthService) LoginGoogle(idToken string) (*AuthResponse, error) {
	// 1. Call Google TokenInfo endpoint to verify the ID Token
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Get("https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken)
	if err != nil {
		return nil, fmt.Errorf("google auth network error: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, errors.New("invalid google token")
	}

	var info struct {
		Email         string `json:"email"`
		Name          string `json:"name"`
		Picture       string `json:"picture"`
		EmailVerified string `json:"email_verified"`
		Error         string `json:"error"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return nil, fmt.Errorf("failed to parse google response: %w", err)
	}

	if info.Error != "" {
		return nil, errors.New(info.Error)
	}

	if info.Email == "" {
		return nil, errors.New("google token did not contain email")
	}

	// 2. Check if user already exists
	user, err := s.userRepo.GetByEmail(info.Email)
	if err != nil {
		return nil, err
	}

	if user == nil {
		// Register a new user with Google details
		// Generate a secure random password since Google login is passwordless
		randomPassword := generateRandomString(32)
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(randomPassword), bcrypt.DefaultCost)
		if err != nil {
			return nil, err
		}

		user = &domain.User{
			Email:        info.Email,
			PasswordHash: string(hashedPassword),
			Name:         info.Name,
			Profile: domain.Profile{
				AvatarURL: info.Picture,
			},
		}

		if err := s.userRepo.Create(user); err != nil {
			return nil, err
		}

		// Retrieve full details
		user, _ = s.userRepo.GetByID(user.ID)
	} else {
		// Update user name/avatar if they were empty
		updated := false
		if user.Name == "" && info.Name != "" {
			user.Name = info.Name
			updated = true
		}
		if user.Profile.AvatarURL == "" && info.Picture != "" {
			user.Profile.AvatarURL = info.Picture
			_ = s.userRepo.UpdateProfile(&user.Profile)
		}
		if updated {
			_ = s.userRepo.Update(user)
		}
	}

	// 3. Generate JWT Token
	token, err := s.generateToken(user.ID)
	if err != nil {
		return nil, err
	}

	return &AuthResponse{
		Token: token,
		User:  user,
	}, nil
}

func (s *AuthService) ForgotPassword(email string) (string, error) {
	user, err := s.userRepo.GetByEmail(email)
	if err != nil {
		return "", err
	}
	if user == nil {
		return "", errors.New("user not found with this email")
	}

	// Generate 6-digit random token
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	token := fmt.Sprintf("%06d", n.Int64())

	user.PasswordResetToken = token
	user.PasswordResetExpires = time.Now().Add(15 * time.Minute)

	if err := s.userRepo.Update(user); err != nil {
		return "", err
	}

	return token, nil
}

func (s *AuthService) ResetPassword(email string, token string, newPassword string) error {
	user, err := s.userRepo.GetByEmail(email)
	if err != nil {
		return err
	}
	if user == nil {
		return errors.New("user not found")
	}

	if user.PasswordResetToken == "" || user.PasswordResetToken != token {
		return errors.New("invalid reset token")
	}

	if time.Now().After(user.PasswordResetExpires) {
		return errors.New("reset token has expired")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	user.PasswordHash = string(hashedPassword)
	user.PasswordResetToken = ""
	user.PasswordResetExpires = time.Time{}

	return s.userRepo.Update(user)
}

func (s *AuthService) generateToken(userID string) (string, error) {
	claims := JWTRefreshClaims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(s.cfg.JWTExpiryHours) * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.cfg.JWTSecret))
}

func (s *AuthService) ValidateToken(tokenString string) (string, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTRefreshClaims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(s.cfg.JWTSecret), nil
	})
	if err != nil {
		return "", err
	}

	if claims, ok := token.Claims.(*JWTRefreshClaims); ok && token.Valid {
		return claims.UserID, nil
	}

	return "", errors.New("invalid token")
}

func generateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+"
	result := make([]byte, length)
	for i := range result {
		num, _ := rand.Int(rand.Reader, big.NewInt(int64(len(charset))))
		result[i] = charset[num.Int64()]
	}
	return string(result)
}
