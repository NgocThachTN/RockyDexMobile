package application

import (
	"rockydex-api/internal/domain"
)

type LibraryService struct {
	favRepo  domain.FavoriteRepository
	histRepo domain.HistoryRepository
}

func NewLibraryService(favRepo domain.FavoriteRepository, histRepo domain.HistoryRepository) *LibraryService {
	return &LibraryService{favRepo: favRepo, histRepo: histRepo}
}

// Favorites
func (s *LibraryService) AddToFavorites(userID string, comic domain.Favorite) error {
	comic.UserID = userID
	return s.favRepo.Add(&comic)
}

func (s *LibraryService) RemoveFromFavorites(userID string, comicSlug string) error {
	return s.favRepo.Remove(userID, comicSlug)
}

func (s *LibraryService) GetFavorites(userID string) ([]domain.Favorite, error) {
	return s.favRepo.GetList(userID)
}

func (s *LibraryService) CheckFavorite(userID string, comicSlug string) (bool, error) {
	return s.favRepo.IsFavorite(userID, comicSlug)
}

// History
func (s *LibraryService) SaveHistory(userID string, hist domain.History) error {
	hist.UserID = userID
	return s.histRepo.Save(&hist)
}

func (s *LibraryService) GetHistory(userID string) ([]domain.History, error) {
	return s.histRepo.GetList(userID)
}

func (s *LibraryService) GetComicHistory(userID string, comicSlug string) (*domain.History, error) {
	return s.histRepo.GetByComic(userID, comicSlug)
}

func (s *LibraryService) DeleteHistory(userID string, comicSlug string) error {
	return s.histRepo.Delete(userID, comicSlug)
}

func (s *LibraryService) ClearHistory(userID string) error {
	return s.histRepo.Clear(userID)
}
