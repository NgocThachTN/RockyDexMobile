import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/comic_model.dart';
import '../data/home_repository.dart';
import '../../../core/constants/api_constants.dart';

class HomeState {
  final String selectedListType; // 'truyen-noi-bat', 'truyen-moi', 'dang-phat-hanh', 'hoan-thanh'
  final String selectedCategorySlug; // '' if none, or specific category slug
  final List<ComicModel> comics;
  final List<CategoryModel> categories;
  final bool isLoading;
  final bool isLoadMore;
  final int page;
  final bool hasMore;
  final String? error;

  HomeState({
    this.selectedListType = ApiConstants.listFeatured,
    this.selectedCategorySlug = '',
    this.comics = const [],
    this.categories = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  bool get isCategoryFilterActive => selectedCategorySlug.isNotEmpty;

  HomeState copyWith({
    String? selectedListType,
    String? selectedCategorySlug,
    List<ComicModel>? comics,
    List<CategoryModel>? categories,
    bool? isLoading,
    bool? isLoadMore,
    int? page,
    bool? hasMore,
    String? error,
  }) {
    return HomeState(
      selectedListType: selectedListType ?? this.selectedListType,
      selectedCategorySlug: selectedCategorySlug ?? this.selectedCategorySlug,
      comics: comics ?? this.comics,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repo);
});

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;

  HomeNotifier(this._repository) : super(HomeState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cats = await _repository.getCategories();
      state = state.copyWith(categories: cats);
      await loadComics(reset: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
    if (state.isLoadMore || (state.isLoading && !reset)) return;

    final targetPage = reset ? 1 : state.page + 1;
    if (reset) {
      state = state.copyWith(isLoading: true, error: null, page: 1, hasMore: true);
    } else {
      state = state.copyWith(isLoadMore: true);
    }

    try {
      List<ComicModel> list;
      if (state.isCategoryFilterActive) {
        list = await _repository.getComicsByCategory(state.selectedCategorySlug, page: targetPage);
      } else {
        list = await _repository.getComicsList(state.selectedListType, page: targetPage);
      }

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

  Future<void> refresh() async {
    await loadComics(reset: true);
  }
}
