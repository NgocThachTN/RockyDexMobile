package dto

type UpdateProfileInput struct {
	AvatarURL         *string  `json:"avatar_url"`
	ThemePreference   *string  `json:"theme_preference"`
	ReadingLayout     *string  `json:"reading_layout"`
	ReadingBrightness *float64 `json:"reading_brightness"`
}

type ReadingStats struct {
	TotalComicsRead int `json:"total_comics_read"`
	TotalFavorites  int `json:"total_favorites"`
	ChaptersRead    int `json:"chapters_read"`
}
