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
      isLoading: true,
      isCategoriesLoading: !_didLoadCategories,
      error: null,
      categoriesError: null,
      page: 1,
      hasMore: true,
    );

    final results = await Future.wait([
      if (!_didLoadCategories)
        _guard<List<CategoryModel>>(_repository.getCategories()),
      _guard<List<ComicModel>>(_loadComicsPage(1)),
    ]);

    final categoriesResult =
        !_didLoadCategories ? results.first as _LoadResult<List<CategoryModel>> : null;
    final comicsResult =
        results.last as _LoadResult<List<ComicModel>>;

    final categories = categoriesResult?.data;
    if (categories != null) {
      _didLoadCategories = true;
    }

    final comics = comicsResult.data;
    state = state.copyWith(
      categories: categories ?? state.categories,
      comics: comics ?? state.comics,
      isLoading: false,
      isCategoriesLoading: false,
      error: comics == null ? comicsResult.error.toString() : null,
      categoriesError: categoriesResult?.error?.toString(),
      page: 1,
      hasMore: state.isFeaturedList ? false : (comics?.isNotEmpty ?? false),
    );
  }

  Future<void> selectListType(String listType) async {
    if (state.selectedListType == listType && !state.isCategoryFilterActive) return;
    state = state.copyWith(
      selectedListType: listType,
      selectedCategorySlug: '',
    );
    await loadComics(reset: true);
  }

  Future<void> selectCategory(String categorySlug) async {
    if (state.selectedCategorySlug == categorySlug) return;
    state = state.copyWith(
      selectedCategorySlug: categorySlug,
    );
    await loadComics(reset: true);
  }

  Future<void> clearCategory() async {
    if (state.selectedCategorySlug.isEmpty) return;
    state = state.copyWith(selectedCategorySlug: '');
    await loadComics(reset: true);
  }

  Future<void> loadComics({bool reset = false}) async {
    if (state.isLoadMore || state.isLoading) return;
    if (!reset && (!state.hasMore || state.isFeaturedList)) return;

    final targetPage = reset ? 1 : state.page + 1;
    if (reset) {
      state = state.copyWith(isLoading: true, error: null, page: 1, hasMore: true);
    } else {
      state = state.copyWith(isLoadMore: true);
    }

    try {
      final list = await _loadComicsPage(targetPage);
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        comics: reset ? list : [...state.comics, ...list],
        page: targetPage,
        hasMore: state.isFeaturedList ? false : list.isNotEmpty,
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
    if (!_didLoadCategories && state.comics.isEmpty) {
      await init(force: true);
      return;
    }
    await loadComics(reset: true);
  }

  Future<void> reloadCategories() async {
    if (state.isCategoriesLoading || _didLoadCategories) return;

    state = state.copyWith(isCategoriesLoading: true, categoriesError: null);
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

  Future<List<ComicModel>> _loadComicsPage(int page) {
    if (state.isCategoryFilterActive) {
      return _repository.getComicsByCategory(state.selectedCategorySlug, page: page);
    }
    if (state.isFeaturedList) {
      return _repository.getHomeComics();
    }
    return _repository.getComicsList(state.selectedListType, page: page);
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
