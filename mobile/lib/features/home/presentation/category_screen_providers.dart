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

  CategoryComicsState({
    this.comics = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  CategoryComicsState copyWith({
    List<ComicModel>? comics,
    bool? isLoading,
    bool? isLoadMore,
    int? page,
    bool? hasMore,
    String? error,
  }) {
    return CategoryComicsState(
      comics: comics ?? this.comics,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
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
}

final categoryComicsProvider = StateNotifierProvider.family<CategoryComicsNotifier, CategoryComicsState, String>((ref, categorySlug) {
  final repo = ref.watch(homeRepositoryProvider);
  return CategoryComicsNotifier(repo, categorySlug);
});
