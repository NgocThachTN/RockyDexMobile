import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/comic_repository.dart';
import '../domain/comic_detail_model.dart';

final comicDetailProvider = FutureProvider.family<ComicDetailInfoModel, String>((ref, slug) async {
  final repo = ref.watch(comicRepositoryProvider);
  return repo.getComicDetail(slug);
});

// History details for a specific comic
final comicHistoryProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, slug) async {
  final repo = ref.watch(comicRepositoryProvider);
  return repo.getReadingHistory(slug);
});

// Favorite notifier state management
class FavoriteState {
  final bool isFav;
  final bool isLoading;

  FavoriteState({required this.isFav, this.isLoading = false});

  FavoriteState copyWith({bool? isFav, bool? isLoading}) {
    return FavoriteState(
      isFav: isFav ?? this.isFav,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final favoriteNotifierProvider = StateNotifierProvider.family<FavoriteNotifier, FavoriteState, String>((ref, slug) {
  final repo = ref.watch(comicRepositoryProvider);
  return FavoriteNotifier(repo, slug);
});

class FavoriteNotifier extends StateNotifier<FavoriteState> {
  final ComicRepository _repository;
  final String _slug;

  FavoriteNotifier(this._repository, this._slug) : super(FavoriteState(isFav: false)) {
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    state = state.copyWith(isLoading: true);
    final status = await _repository.isFavorite(_slug);
    state = FavoriteState(isFav: status, isLoading: false);
  }

  Future<void> toggleFavorite(ComicDetailInfoModel comic) async {
    final nextStatus = !state.isFav;
    state = state.copyWith(isLoading: true);
    await _repository.toggleFavorite(comic, nextStatus);
    state = FavoriteState(isFav: nextStatus, isLoading: false);
  }
}
