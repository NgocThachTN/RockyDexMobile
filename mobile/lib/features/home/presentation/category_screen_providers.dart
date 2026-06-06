import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';
import '../domain/comic_model.dart';

class CategoryComicsState {
  final List<ComicModel> comics;
  final bool isLoading;
  final bool isLoadMore;
  final int page;
  final bool hasMore;
  final String? error;

  // Filters
  final String selectedStatus;  // 'all', 'ongoing', 'completed'
  final String selectedYear;    // 'all', '2026', '2025', '2024', '2023', '2022', '2021', 'before_2021'

  CategoryComicsState({
    this.comics = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
    this.selectedStatus = 'all',
    this.selectedYear = 'all',
  });

  List<ComicModel> get filteredComics {
    return comics.where((comic) {
      // 1. Filter by status
      if (selectedStatus != 'all' && comic.status != selectedStatus) {
        return false;
      }

      // 2. Filter by year (extracted from updatedAt as the API doesn't provide a release year)
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

  CategoryComicsState copyWith({
    List<ComicModel>? comics,
    bool? isLoading,
    bool? isLoadMore,
    int? page,
    bool? hasMore,
    String? error,
    String? selectedStatus,
    String? selectedYear,
  }) {
    return CategoryComicsState(
      comics: comics ?? this.comics,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }
}

class CategoryComicsNotifier extends StateNotifier<CategoryComicsState> {
  final HomeRepository _repository;
  final String _categorySlug;

  CategoryComicsNotifier(this._repository, this._categorySlug) : super(CategoryComicsState()) {
    loadComics();
  }

  Future<void> loadComics({bool reset = false}) async {
    if (state.isLoadMore || state.isLoading) return;
    if (!reset && !state.hasMore) return;

    final targetPage = reset ? 1 : state.page + 1;
    if (reset) {
      state = state.copyWith(isLoading: true, error: null, page: 1, hasMore: true);
    } else {
      state = state.copyWith(isLoadMore: true);
    }

    try {
      final list = await _repository.getComicsByCategory(_categorySlug, page: targetPage);
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        comics: reset ? list : [...state.comics, ...list],
        page: targetPage,
        hasMore: list.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        error: e.toString(),
      );
    }
  }

  void updateStatus(String status) {
    state = state.copyWith(selectedStatus: status);
  }

  void updateYear(String year) {
    state = state.copyWith(selectedYear: year);
  }

  void resetFilters() {
    state = state.copyWith(
      selectedStatus: 'all',
      selectedYear: 'all',
    );
  }
}

final categoryComicsProvider = StateNotifierProvider.family<CategoryComicsNotifier, CategoryComicsState, String>((ref, categorySlug) {
  final repo = ref.watch(homeRepositoryProvider);
  return CategoryComicsNotifier(repo, categorySlug);
});
