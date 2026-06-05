import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../comic/data/comic_repository.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/presentation/auth_notifier.dart';

// Sync provider to retrieve favorites list
final libraryFavoritesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(comicRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (authState.user != null) {
    try {
      // Sync from Go backend
      final response = await repo.getFavoritesListRemote();
      return response;
    } catch (_) {
      // Fallback
      return LocalStorage.getFavorites();
    }
  } else {
    return LocalStorage.getFavorites();
  }
});

// Sync provider to retrieve history list
final libraryHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(comicRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (authState.user != null) {
    try {
      // Sync from Go backend
      final response = await repo.getHistoryListRemote();
      return response;
    } catch (_) {
      // Fallback
      return LocalStorage.getHistoryList();
    }
  } else {
    return LocalStorage.getHistoryList();
  }
});

// Extension methods on ComicRepository to fetch remote collections
extension ComicRepositoryRemote on ComicRepository {
  Future<List<Map<String, dynamic>>> getFavoritesListRemote() async {
    final response = await dio.get('/favorites');
    final data = response.data as List;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getHistoryListRemote() async {
    final response = await dio.get('/history');
    final data = response.data as List;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> clearHistoryRemote() async {
    if (authState.user != null) {
      await dio.delete('/history');
    }
    await LocalStorage.clearHistory();
  }
}
