import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  SearchState({
    this.query = '',
    this.history = const [],
    this.results = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<String>? history,
    List<ComicModel>? results,
    bool? isLoading,
    bool? isLoadMore,
    int? page,
    bool? hasMore,
    String? error,
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
  }

  void _loadHistory() {
    state = state.copyWith(history: _repository.getSearchHistory());
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: '', results: []);
      return;
    }

    state = state.copyWith(query: query, isLoading: true, results: [], page: 1, hasMore: true, error: null);
    await _repository.addSearchHistory(query);
    _loadHistory();

    try {
      final list = await _repository.searchComics(query, page: 1);
      state = state.copyWith(
        isLoading: false,
        results: list,
        hasMore: list.length >= 20, // OTruyen API standard page size is 24/20
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadMore || !state.hasMore || state.query.isEmpty) return;

    state = state.copyWith(isLoadMore: true);
    final nextPage = state.page + 1;

    try {
      final list = await _repository.searchComics(state.query, page: nextPage);
      state = state.copyWith(
        isLoadMore: false,
        results: [...state.results, ...list],
        page: nextPage,
        hasMore: list.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoadMore: false);
    }
  }

  Future<void> clearHistory() async {
    await _repository.clearSearchHistory();
    state = state.copyWith(history: []);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }
}
