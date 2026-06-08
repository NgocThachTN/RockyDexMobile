import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/presentation/auth_notifier.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final authState = ref.watch(authProvider);
  return LibraryRepository(dio, authState);
});

class LibraryRepository {
  final Dio _dio;
  final AuthState _authState;

  LibraryRepository(this._dio, this._authState);

  bool get _isLoggedIn => _authState.user != null;

  // Favorites Sync
  Future<void> syncFavorites() async {
    if (!_isLoggedIn) return;

    try {
      // 1. Fetch remote favorites
      final response = await _dio.get('/favorites');
      final remoteList = response.data as List;

      // 2. Fetch local favorites
      final localList = await LocalStorage.getFavorites();

      final Map<String, dynamic> remoteSlugs = {};
      for (final item in remoteList) {
        final slug = item['slug'] as String;
        remoteSlugs[slug] = item;
      }

      // Upsert remote ones into local DB
      for (final item in remoteList) {
        await LocalStorage.insertFavorite({
          'slug': item['slug'],
          'name': item['name'],
          'thumb_url': item['thumb_url'],
          'created_at': item['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      // Upload local ones that are missing on remote
      for (final localItem in localList) {
        final localSlug = localItem['slug'] as String;
        if (!remoteSlugs.containsKey(localSlug)) {
          final name = localItem['name'] ?? localItem['comic_name'] ?? '';
          final thumb = localItem['thumb_url'] ?? localItem['comic_thumb'] ?? '';
          await addFavoriteRemote(localSlug, name, thumb);
        }
      }
    } catch (e) {
      // Silently log or handle sync failure
      print('Sync favorites error: $e');
    }
  }

  Future<void> addFavoriteRemote(String slug, String name, String thumbUrl) async {
    if (!_isLoggedIn) return;
    try {
      await _dio.post('/favorites', data: {
        'slug': slug,
        'name': name,
        'thumb_url': thumbUrl,
      });
    } catch (_) {}
  }

  Future<void> removeFavoriteRemote(String slug) async {
    if (!_isLoggedIn) return;
    try {
      await _dio.delete('/favorites/$slug');
    } catch (_) {}
  }

  // History Sync
  Future<void> syncHistory() async {
    if (!_isLoggedIn) return;

    try {
      // Fetch remote history
      final response = await _dio.get('/history');
      final remoteList = response.data as List;

      final localList = await LocalStorage.getHistoryList();

      final Map<String, dynamic> remoteSlugs = {};
      for (final item in remoteList) {
        final slug = item['comic_slug'] as String;
        remoteSlugs[slug] = item;
      }

      // Upsert remote ones into local DB
      for (final item in remoteList) {
        await LocalStorage.saveHistory({
          'comic_slug': item['comic_slug'],
          'comic_name': item['comic_name'],
          'comic_thumb': item['comic_thumb'],
          'chapter_slug': item['chapter_slug'],
          'chapter_name': item['chapter_name'],
          'progress_percent': item['progress_percent'],
          'last_read_at': item['last_read_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      // Upload local ones that are missing on remote
      for (final localItem in localList) {
        final slug = localItem['comic_slug'] as String;
        final remoteItem = remoteSlugs[slug];
        if (remoteItem == null) {
          await saveHistoryRemote(
            comicSlug: slug,
            comicName: localItem['comic_name'] ?? '',
            comicThumb: localItem['comic_thumb'] ?? '',
            chapterSlug: localItem['chapter_slug'] ?? '',
            chapterName: localItem['chapter_name'] ?? '',
            progressPercent: localItem['progress_percent'] ?? 0,
          );
        }
      }
    } catch (e) {
      print('Sync history error: $e');
    }
  }

  Future<void> saveHistoryRemote({
    required String comicSlug,
    required String comicName,
    required String comicThumb,
    required String chapterSlug,
    required String chapterName,
    required int progressPercent,
  }) async {
    if (!_isLoggedIn) return;
    try {
      await _dio.post('/history', data: {
        'comic_slug': comicSlug,
        'comic_name': comicName,
        'comic_thumb': comicThumb,
        'chapter_slug': chapterSlug,
        'chapter_name': chapterName,
        'progress_percent': progressPercent,
      });
    } catch (_) {}
  }

  Future<void> deleteHistoryRemote(String slug) async {
    if (!_isLoggedIn) return;
    try {
      await _dio.delete('/history/$slug');
    } catch (_) {}
  }

  Future<void> clearHistoryRemote() async {
    if (!_isLoggedIn) return;
    try {
      await _dio.delete('/history');
    } catch (_) {}
  }
}
