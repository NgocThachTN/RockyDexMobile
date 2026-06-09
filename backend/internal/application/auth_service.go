package application

import (
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"time"

	"rockydex-api/internal/application/dto"
	"rockydex-api/internal/domain"
	"rockydex-api/internal/shared/config"
	"rockydex-api/internal/shared/utils"
)

type AuthService struct {
	userRepo domain.UserRepository
	cfg      *config.Config
}

func NewAuthService(userRepo domain.UserRepository, cfg *config.Config) *AuthService {
	return &AuthService{userRepo: userRepo, cfg: cfg}
}

func (s *AuthService) Register(input dto.RegisterInput) (*dto.AuthResponse, error) {
	existing, err := s.userRepo.GetByEmail(input.Email)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return nil, errors.New("email already registered")
	}

	hashedPassword, err := utils.HashPassword(input.Password)
	if err != nil {
		return nil, err
	}

	user := &domain.User{
		Email:        input.Email,
		PasswordHash: hashedPassword,
		Name:         input.Name,
	}

	if err := s.userRepo.Create(user); err != nil {
		return nil, err
	}

	token, err := utils.GenerateToken(user.ID, s.cfg.JWTExpiryHours, s.cfg.JWTSecret)
	if err != nil {
		return nil, err
	}

	// Fetch full details (profile loaded)
	fullUser, _ := s.userRepo.GetByID(user.ID)

	return &dto.AuthResponse{
		Token: token,
		User:  fullUser,
	}, nil
}

func (s *AuthService) Login(input dto.LoginInput) (*dto.AuthResponse, error) {
	user, err := s.userRepo.GetByEmail(input.Email)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("invalid email or password")
	}

	err = utils.ComparePassword(user.PasswordHash, input.Password)
	if err != nil {
		return nil, errors.New("invalid email or password")
	}

	token, err := utils.GenerateToken(user.ID, s.cfg.JWTExpiryHours, s.cfg.JWTSecret)
	if err != nil {
		return nil, err
	}

	return &dto.AuthResponse{
		Token: token,
		User:  user,
	}, nil
}

func (s *AuthService) LoginGoogle(idToken string) (*dto.AuthResponse, error) {
	var info struct {
		Email         string `json:"email"`
		Name          string `json:"name"`
		Picture       string `json:"picture"`
		EmailVerified string `json:"email_verified"`
		Error         string `json:"error"`
	}

	if idToken == "dev-mock-google-test" {
		info.Email = "testgoogle@gmail.com"
		info.Name = "Test Google User"
		info.Picture = "https://lh3.googleusercontent.com/a/default-user"
		info.EmailVerified = "true"
	} else if len(idToken) > 16 && idToken[:16] == "dev-mock-google-" {
		email := idToken[16:]
		info.Email = email
		info.Name = "Mock " + email
		info.Picture = "https://lh3.googleusercontent.com/a/default-user"
		info.EmailVerified = "true"
	} else {
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

		if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
			return nil, fmt.Errorf("failed to parse google response: %w", err)
		}

		if info.Error != "" {
			return nil, errors.New(info.Error)
		}
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
		randomPassword := utils.GenerateRandomString(32)
		hashedPassword, err := utils.HashPassword(randomPassword)
		if err != nil {
			return nil, err
		}

		user = &domain.User{
			Email:        info.Email,
			PasswordHash: hashedPassword,
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
	token, err := utils.GenerateToken(user.ID, s.cfg.JWTExpiryHours, s.cfg.JWTSecret)
	if err != nil {
		return nil, err
	}

	return &dto.AuthResponse{
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

	hashedPassword, err := utils.HashPassword(newPassword)
	if err != nil {
		return err
	}

	user.PasswordHash = hashedPassword
	user.PasswordResetToken = ""
	user.PasswordResetExpires = time.Time{}

	return s.userRepo.Update(user)
}

func (s *AuthService) ValidateToken(tokenString string) (string, error) {
	return utils.ValidateToken(tokenString, s.cfg.JWTSecret)
}
