package application

import (
	"errors"

	"rockydex-api/internal/application/dto"
	"rockydex-api/internal/domain"
)

type UserService struct {
	userRepo domain.UserRepository
	histRepo domain.HistoryRepository
	favRepo  domain.FavoriteRepository
}

func NewUserService(userRepo domain.UserRepository, histRepo domain.HistoryRepository, favRepo domain.FavoriteRepository) *UserService {
	return &UserService{userRepo: userRepo, histRepo: histRepo, favRepo: favRepo}
}

func (s *UserService) GetProfile(userID string) (*domain.User, error) {
	user, err := s.userRepo.GetByID(userID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("user not found")
	}
	return user, nil
}

func (s *UserService) UpdateProfile(userID string, input dto.UpdateProfileInput) (*domain.Profile, error) {
	user, err := s.userRepo.GetByID(userID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("user not found")
	}

	profile := &user.Profile
	if input.AvatarURL != nil {
		profile.AvatarURL = *input.AvatarURL
	}
	if input.ThemePreference != nil {
		profile.ThemePreference = *input.ThemePreference
	}
	if input.ReadingLayout != nil {
		profile.ReadingLayout = *input.ReadingLayout
	}
	if input.ReadingBrightness != nil {
		profile.ReadingBrightness = *input.ReadingBrightness
	}

	if err := s.userRepo.UpdateProfile(profile); err != nil {
		return nil, err
	}

	return profile, nil
}

func (s *UserService) GetReadingStats(userID string) (*dto.ReadingStats, error) {
	history, err := s.histRepo.GetList(userID)
	if err != nil {
		return nil, err
	}

	favorites, err := s.favRepo.GetList(userID)
	if err != nil {
		return nil, err
	}

	// For stats estimation, total chapters read is calculated. Since our history keeps only the last chapter per comic,
	// we can aggregate stats or sum up based on some logic, or keep a count.
	// For simplicity, we calculate total comics read as len(history), total favorites as len(favorites).
	// We can mock chapters read to be estimated or calculated. Let's make an estimate based on history.
	totalChapters := 0
	for _, h := range history {
		// Mock estimation: assume average of 10 chapters read per history item, or simply use 1 for each
		totalChapters += h.ProgressPercent/10 + 1 // estimation helper
	}

	return &dto.ReadingStats{
		TotalComicsRead: len(history),
		TotalFavorites:  len(favorites),
		ChaptersRead:    totalChapters,
	}, nil
}
