import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../domain/comic_detail_model.dart';

final comicRepositoryProvider = Provider<ComicRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final authState = ref.watch(authProvider);
  return ComicRepository(dio, authState);
});

class ComicRepository {
  final Dio _dio;
  final AuthState _authState;

  ComicRepository(this._dio, this._authState);

  bool get _isLoggedIn => _authState.user != null;

  Dio get dio => _dio;
  AuthState get authState => _authState;

  Future<ComicDetailInfoModel> getComicDetail(String slug) async {
    try {
      final response = await _dio.get('${ApiConstants.otruyenBaseUrl}${ApiConstants.pathComicDetail}/$slug');
      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }
      final rawData = responseData['data'];
      final rawItem = rawData['item'];
      final cdnImage = rawData['APP_DOMAIN_CDN_IMAGE'] as String? ?? ApiConstants.otruyenImageBaseCdn;

      // Make cover URL absolute
      final rawThumb = rawItem['thumb_url'] as String;
      final absoluteThumb = rawThumb.startsWith('http')
          ? rawThumb
          : '$cdnImage/uploads/comics/$rawThumb';

      final mappedItem = Map<String, dynamic>.from(rawItem);
      mappedItem['thumb_url'] = absoluteThumb;

      // Handle server chapters mapping
      final rawChapters = rawItem['chapters'] as List;
      final mappedChapters = rawChapters.map((srv) {
        final srvMap = Map<String, dynamic>.from(srv);
        final listData = srv['server_data'] as List;
        srvMap['server_data'] = listData.map((chap) {
          final chapMap = Map<String, dynamic>.from(chap);
          // Standardize chapter API link
          return chapMap;
        }).toList();
        return srvMap;
      }).toList();
      mappedItem['chapters'] = mappedChapters;

      return ComicDetailInfoModel.fromJson(mappedItem);
    } catch (e) {
      throw Exception('Không thể tải chi tiết truyện: $e');
    }
  }

  // Favorite / Bookmark Sync Operations
  Future<bool> isFavorite(String slug) async {
    if (_isLoggedIn) {
      try {
        final response = await _dio.get('/favorites/check/$slug');
        return response.data['is_favorite'] as bool;
      } catch (_) {
        // Fallback to local
        return LocalStorage.isFavorite(slug);
      }
    } else {
      return LocalStorage.isFavorite(slug);
    }
  }

  Future<void> toggleFavorite(ComicDetailInfoModel comic, bool isFav) async {
    final favData = {
      'comic_slug': comic.slug,
      'comic_name': comic.name,
      'comic_thumb': comic.thumbUrl,
    };

    if (isFav) {
      // Add
      if (_isLoggedIn) {
        try {
          await _dio.post('/favorites', data: favData);
        } catch (_) {}
      }
      await LocalStorage.insertFavorite({
        'slug': comic.slug,
        'name': comic.name,
        'thumb_url': comic.thumbUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Remove
      if (_isLoggedIn) {
        try {
          await _dio.delete('/favorites/${comic.slug}');
        } catch (_) {}
      }
      await LocalStorage.deleteFavorite(comic.slug);
    }
  }

  // Reading History Sync Operations
  Future<void> saveHistory({
    required String comicSlug,
    required String comicName,
    required String comicThumb,
    required String chapterSlug,
    required String chapterName,
    required int progressPercent,
  }) async {
    final histData = {
      'comic_slug': comicSlug,
      'comic_name': comicName,
      'comic_thumb': comicThumb,
      'chapter_slug': chapterSlug,
      'chapter_name': chapterName,
      'progress_percent': progressPercent,
    };

    if (_isLoggedIn) {
      try {
        await _dio.post('/history', data: histData);
      } catch (_) {}
    }

    await LocalStorage.saveHistory({
      'comic_slug': comicSlug,
      'comic_name': comicName,
      'comic_thumb': comicThumb,
      'chapter_slug': chapterSlug,
      'chapter_name': chapterName,
      'progress_percent': progressPercent,
      'last_read_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getReadingHistory(String comicSlug) async {
    if (_isLoggedIn) {
      try {
        final response = await _dio.get('/history/comic/$comicSlug');
        return response.data as Map<String, dynamic>;
      } catch (_) {
        return LocalStorage.getComicHistory(comicSlug);
      }
    } else {
      return LocalStorage.getComicHistory(comicSlug);
    }
  }
}
