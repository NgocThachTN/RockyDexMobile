import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/server_source_provider.dart';
import '../../home/domain/comic_model.dart';
import '../data/search_repository.dart';

class SearchState {
  final String query;
  final List<String> history;
  final List<ComicModel> results;
  final bool isLoading;
  final bool isLoadMore;
  final int page;
  final bool hasMore;
  final String? error;
  final int targetFilteredCount;
  final bool isMangaDex;

  // Filters
  final String selectedCountry; // 'all', 'china' (Trung Quốc), 'korea' (Hàn Quốc), 'japan' (Nhật Bản), 'vietnam' (Việt Nam)
  final String selectedStatus;  // 'all', 'ongoing', 'completed'
  final String selectedYear;    // 'all', '2026', '2025', '2024', '2023', '2022', '2021', 'before_2021'
  final String selectedSortBy;  // 'latestUploadedChapter', 'relevance', 'rating', 'followedCount'
  final List<String> selectedGenres; // List of MangaDex Tag/Genre UUIDs

  SearchState({
    this.query = '',
    this.history = const [],
    this.results = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
    this.targetFilteredCount = 20,
    this.isMangaDex = false,
    this.selectedCountry = 'all',
    this.selectedStatus = 'all',
    this.selectedYear = 'all',
    this.selectedSortBy = 'latestUploadedChapter',
    this.selectedGenres = const [],
  });

  bool get hasActiveFilter {
    if (isMangaDex) {
      return selectedStatus != 'all' ||
          selectedYear != 'all' ||
          selectedSortBy != 'latestUploadedChapter' ||
          selectedGenres.isNotEmpty;
    }
    return selectedCountry != 'all' ||
        selectedStatus != 'all' ||
        selectedYear != 'all';
  }

  List<ComicModel> get filteredResults {
    if (isMangaDex) {
      return results;
    }
    return results.where((comic) {
      // 1. Filter by status
      if (selectedStatus != 'all' && comic.status != selectedStatus) {
        return false;
      }

      // 2. Filter by country
      if (selectedCountry != 'all') {
        final hasCountry = comic.category.any((cat) {
          final slug = cat.slug.toLowerCase();
          final name = cat.name.toLowerCase();
          if (selectedCountry == 'china') {
            return slug == 'trung-quoc' || slug == 'manhua' || name.contains('trung quốc');
          } else if (selectedCountry == 'korea') {
            return slug == 'han-quoc' || slug == 'manhwa' || name.contains('hàn quốc');
          } else if (selectedCountry == 'japan') {
            return slug == 'nhat-ban' || slug == 'manga' || name.contains('nhật bản');
          } else if (selectedCountry == 'vietnam') {
            return slug == 'viet-nam' || name.contains('việt nam');
          }
          return false;
        });
        if (!hasCountry) return false;
      }

      // 3. Filter by year (extracted from updatedAt as the API doesn't provide a release year)
      if (selectedYear != 'all') {
        final yearMatch = RegExp(r'^(\d{4})').firstMatch(comic.updatedAt);
        if (yearMatch != null) {
          final yearStr = yearMatch.group(1);
          final year = int.tryParse(yearStr ?? '');
          if (year != null) {
            if (selectedYear == 'before_2021') {
              if (year >= 2021) return false;
            } else {
              if (yearStr != selectedYear) return false;
            }
          } else {
            return false;
          }
        } else {
          return false;
        }
      }

      return true;
    }).toList();
  }

  SearchState copyWith({
    String? query,
    List<String>? history,
    List<ComicModel>? results,
    bool? isLoading,
    bool? isLoadMore,
    int? page,
    bool? hasMore,
    String? error,
    int? targetFilteredCount,
    bool? isMangaDex,
    String? selectedCountry,
    String? selectedStatus,
    String? selectedYear,
    String? selectedSortBy,
    List<String>? selectedGenres,
  }) {
    return SearchState(
      query: query ?? this.query,
      history: history ?? this.history,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      targetFilteredCount: targetFilteredCount ?? this.targetFilteredCount,
      isMangaDex: isMangaDex ?? this.isMangaDex,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedSortBy: selectedSortBy ?? this.selectedSortBy,
      selectedGenres: selectedGenres ?? this.selectedGenres,
    );
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return SearchNotifier(repo);
});

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repository;

  SearchNotifier(this._repository) : super(SearchState()) {
    _loadHistory();
    state = state.copyWith(isMangaDex: _repository.source == ServerSource.mangadex);
  }

  void _loadHistory() {
    state = state.copyWith(history: _repository.getSearchHistory());
  }

  Future<void> search(String query, {bool saveToHistory = false}) async {
    final isMangaDex = _repository.source == ServerSource.mangadex;
    if (query.trim().isEmpty && !isMangaDex) {
      state = state.copyWith(query: '', results: []);
      return;
    }

    state = state.copyWith(
      query: query,
      isLoading: true,
      results: [],
      page: 1,
      hasMore: true,
      error: null,
      targetFilteredCount: 20,
      isMangaDex: isMangaDex,
    );
    if (saveToHistory && query.trim().isNotEmpty) {
      await _repository.addSearchHistory(query);
      _loadHistory();
    }

    try {
      final list = await _repository.searchComics(
        query,
        page: 1,
        year: state.selectedYear,
        status: state.selectedStatus,
        sortBy: state.selectedSortBy,
        genres: state.selectedGenres,
      );
      state = state.copyWith(
        isLoading: false,
        results: list,
        hasMore: list.length >= 20,
      );
      _checkAndLoadMore();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadMore || !state.hasMore) return;
    if (!state.isMangaDex && state.query.isEmpty) return;

    final newTarget = state.filteredResults.length < state.targetFilteredCount ? state.targetFilteredCount : state.targetFilteredCount + 20;
    state = state.copyWith(
      isLoadMore: true,
      targetFilteredCount: newTarget,
    );
    final nextPage = state.page + 1;

    try {
      final list = await _repository.searchComics(
        state.query,
        page: nextPage,
        year: state.selectedYear,
        status: state.selectedStatus,
        sortBy: state.selectedSortBy,
        genres: state.selectedGenres,
      );
      state = state.copyWith(
        isLoadMore: false,
        results: [...state.results, ...list],
        page: nextPage,
        hasMore: list.isNotEmpty,
      );
      _checkAndLoadMore();
    } catch (e) {
      state = state.copyWith(isLoadMore: false);
    }
  }

  void _checkAndLoadMore() {
    if (state.isLoading || state.isLoadMore || !state.hasMore) return;
    if (!state.isMangaDex && state.query.isEmpty) return;
    if (state.filteredResults.length < state.targetFilteredCount) {
      loadMore();
    }
  }

  Future<void> clearHistory() async {
    await _repository.clearSearchHistory();
    state = state.copyWith(history: []);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void updateCountry(String country) {
    state = state.copyWith(selectedCountry: country, targetFilteredCount: 20);
    _checkAndLoadMore();
  }

  void updateStatus(String status) {
    state = state.copyWith(selectedStatus: status, targetFilteredCount: 20);
    if (state.isMangaDex) {
      search(state.query, saveToHistory: false);
    } else {
      _checkAndLoadMore();
    }
  }

  void updateYear(String year) {
    state = state.copyWith(selectedYear: year, targetFilteredCount: 20);
    if (state.isMangaDex) {
      search(state.query, saveToHistory: false);
    } else {
      _checkAndLoadMore();
    }
  }

  void updateSortBy(String sortBy) {
    state = state.copyWith(selectedSortBy: sortBy, targetFilteredCount: 20);
    if (state.isMangaDex) {
      search(state.query, saveToHistory: false);
    } else {
      _checkAndLoadMore();
    }
  }

  void toggleGenre(String genreId) {
    final genres = List<String>.from(state.selectedGenres);
    if (genres.contains(genreId)) {
      genres.remove(genreId);
    } else {
      genres.add(genreId);
    }
    state = state.copyWith(selectedGenres: genres, targetFilteredCount: 20);
    if (state.isMangaDex) {
      search(state.query, saveToHistory: false);
    } else {
      _checkAndLoadMore();
    }
  }

  void resetFilters() {
    state = state.copyWith(
      selectedCountry: 'all',
      selectedStatus: 'all',
      selectedYear: 'all',
      selectedSortBy: 'latestUploadedChapter',
      selectedGenres: const [],
      targetFilteredCount: 20,
    );
    if (state.isMangaDex) {
      search(state.query, saveToHistory: false);
    } else {
      _checkAndLoadMore();
    }
  }
}
