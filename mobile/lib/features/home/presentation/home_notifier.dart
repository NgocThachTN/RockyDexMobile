import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../data/home_repository.dart';
import '../domain/comic_model.dart';

class HomeState {
  final String selectedListType;
  final String selectedCategorySlug;
  final List<ComicModel> comics;
  final List<CategoryModel> categories;
  final bool isLoading;
  final bool isLoadMore;
  final bool isCategoriesLoading;
  final int page;
  final bool hasMore;
  final String? error;
  final String? categoriesError;

  HomeState({
    this.selectedListType = ApiConstants.listFeatured,
    this.selectedCategorySlug = '',
    this.comics = const [],
    this.categories = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.isCategoriesLoading = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
    this.categoriesError,
  });

  bool get isCategoryFilterActive => selectedCategorySlug.isNotEmpty;
  bool get isFeaturedList => selectedListType == ApiConstants.listFeatured;

  HomeState copyWith({
    String? selectedListType,
    String? selectedCategorySlug,
    List<ComicModel>? comics,
    List<CategoryModel>? categories,
    bool? isLoading,
    bool? isLoadMore,
    bool? isCategoriesLoading,
    int? page,
    bool? hasMore,
    String? error,
    String? categoriesError,
  }) {
    return HomeState(
      selectedListType: selectedListType ?? this.selectedListType,
      selectedCategorySlug: selectedCategorySlug ?? this.selectedCategorySlug,
      comics: comics ?? this.comics,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      categoriesError: categoriesError,
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repo);
});

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;
  bool _didInit = false;
  bool _didLoadCategories = false;

  HomeNotifier(this._repository) : super(HomeState()) {
    init();
  }

  Future<void> init({bool force = false}) async {
    if (_didInit && !force) return;
    _didInit = true;

    state = state.copyWith(
      isCategoriesLoading: !_didLoadCategories,
      categoriesError: null,
    );

    if (!_didLoadCategories || force) {
      final result = await _guard<List<CategoryModel>>(_repository.getCategories());
      final categories = result.data;
      if (categories != null) {
        _didLoadCategories = true;
      }
      state = state.copyWith(
        categories: categories ?? state.categories,
        isCategoriesLoading: false,
        categoriesError: result.error?.toString(),
      );
    }
  }

  Future<void> reloadCategories() async {
    await init(force: true);
  }

  Future<_LoadResult<T>> _guard<T>(Future<T> future) async {
    try {
      return _LoadResult(data: await future);
    } catch (e) {
      return _LoadResult(error: e);
    }
  }
}

class _LoadResult<T> {
  final T? data;
  final Object? error;

  const _LoadResult({this.data, this.error});
}

// ==========================================
// New family providers for separate home tabs
// ==========================================

class HomeListState {
  final List<ComicModel> comics;
  final bool isLoading;
  final bool isLoadMore;
  final int page;
  final bool hasMore;
  final String? error;

  HomeListState({
    this.comics = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  HomeListState copyWith({
    List<ComicModel>? comics,
    bool? isLoading,
    bool? isLoadMore,
    int? page,
    bool? hasMore,
    String? error,
  }) {
    return HomeListState(
      comics: comics ?? this.comics,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class HomeListNotifier extends StateNotifier<HomeListState> {
  final HomeRepository _repository;
  final String _listType;

  HomeListNotifier(this._repository, this._listType) : super(HomeListState()) {
    loadComics(reset: true);
  }

  Future<void> loadComics({bool reset = false}) async {
    if (state.isLoadMore || state.isLoading) return;
    final isFeatured = _listType == ApiConstants.listFeatured;
    if (!reset && (!state.hasMore || isFeatured)) return;

    final targetPage = reset ? 1 : state.page + 1;
    if (reset) {
      state = state.copyWith(isLoading: true, error: null, page: 1, hasMore: true);
    } else {
      state = state.copyWith(isLoadMore: true);
    }

    try {
      final List<ComicModel> list;
      if (isFeatured) {
        list = await _repository.getHomeComics();
      } else {
        list = await _repository.getComicsList(_listType, page: targetPage);
      }
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        comics: reset ? list : [...state.comics, ...list],
        page: targetPage,
        hasMore: isFeatured ? false : list.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadComics(reset: true);
  }
}

final homeListProvider = StateNotifierProvider.family<HomeListNotifier, HomeListState, String>((ref, listType) {
  final repo = ref.watch(homeRepositoryProvider);
  return HomeListNotifier(repo, listType);
});


