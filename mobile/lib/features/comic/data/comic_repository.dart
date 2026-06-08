import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/otruyen_api_client.dart';
import '../../../core/network/mangadex_api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../home/domain/comic_model.dart';
import '../../library/data/library_repository.dart';
import '../domain/comic_detail_model.dart';

final comicRepositoryProvider = Provider<ComicRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final mangadexApi = ref.watch(mangadexApiClientProvider);
  final authState = ref.watch(authProvider);
  return ComicRepository(dio, mangadexApi, authState, ref);
});

class ComicRepository {
  final Dio _dio;
  final MangadexApiClient _mangadexApi;
  final AuthState _authState;
  final Ref _ref;
  late final OtruyenApiClient _otruyenApi;

  ComicRepository(this._dio, this._mangadexApi, this._authState, this._ref) {
    _otruyenApi = OtruyenApiClient(_dio);
  }

  bool _isUuid(String slug) {
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(slug);
  }

  Future<ComicDetailInfoModel> getComicDetail(String slug) async {
    if (_isUuid(slug)) {
      return _getMangaDexComicDetail(slug);
    }

    try {
      final response = await _otruyenApi.get('${ApiConstants.pathComicDetail}/$slug');
      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }
      final rawData = responseData['data'];
      final rawItem = rawData['item'];
      final cdnImage = rawData['APP_DOMAIN_CDN_IMAGE'] as String? ??
          ApiConstants.otruyenImageBaseCdn;

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

  Future<ComicDetailInfoModel> _getMangaDexComicDetail(String id) async {
    try {
      // 1. Fetch Manga Details
      final detailResponse = await _mangadexApi.get(
        '/manga/$id',
        queryParameters: {
          'includes[]': ['cover_art', 'author', 'artist'],
        },
      );
      
      var detailData = detailResponse.data;
      if (detailData is String) {
        detailData = jsonDecode(detailData);
      }
      final itemData = detailData['data'];
      final attributes = itemData['attributes'] as Map<String, dynamic>? ?? {};

      // Title
      final titleMap = attributes['title'] as Map? ?? {};
      String name = 'Chưa có tiêu đề';
      if (titleMap.containsKey('vi')) {
        name = titleMap['vi'] as String;
      } else if (titleMap.containsKey('en')) {
        name = titleMap['en'] as String;
      } else if (titleMap.isNotEmpty) {
        name = titleMap.values.first as String;
      }

      // Alt Titles
      final altTitlesList = attributes['altTitles'] as List? ?? [];
      final List<String> altNames = [];
      for (final alt in altTitlesList) {
        if (alt is Map) {
          final val = alt.values.firstOrNull as String?;
          if (val != null && val.isNotEmpty) altNames.add(val);
        }
      }

      // Description
      final descMap = attributes['description'] as Map? ?? {};
      String content = 'Không có mô tả.';
      if (descMap.containsKey('vi')) {
        content = descMap['vi'] as String;
      } else if (descMap.containsKey('en')) {
        content = descMap['en'] as String;
      } else if (descMap.isNotEmpty) {
        content = descMap.values.first as String;
      }

      // Status
      final rawStatus = attributes['status'] as String? ?? 'ongoing';
      final status = rawStatus == 'completed'
          ? 'completed'
          : (rawStatus == 'hiatus' ? 'coming_soon' : 'ongoing');

      // Authors
      final rels = itemData['relationships'] as List? ?? [];
      final List<String> authors = [];
      String coverFilename = '';
      for (final rel in rels) {
        if (rel['type'] == 'author' || rel['type'] == 'artist') {
          final relAttrs = rel['attributes'];
          if (relAttrs != null && relAttrs['name'] != null) {
            authors.add(relAttrs['name'] as String);
          }
        } else if (rel['type'] == 'cover_art') {
          final relAttrs = rel['attributes'];
          if (relAttrs != null && relAttrs['fileName'] != null) {
            coverFilename = relAttrs['fileName'] as String;
          }
        }
      }
      if (authors.isEmpty) authors.add('Chưa rõ tác giả');

      // Cover Thumbnail
      final thumbUrl = coverFilename.isNotEmpty
          ? '${ApiConstants.mangadexImageBaseCdn}/$id/$coverFilename.512.jpg'
          : 'https://mangadex.org/avatar.png';

      // Tags/Categories
      final tagsList = attributes['tags'] as List? ?? [];
      final List<CategoryModel> categories = [];
      for (final tag in tagsList) {
        final tagId = tag['id'] as String? ?? '';
        final tagNameMap = tag['attributes']?['name'] as Map? ?? {};
        final tagName = tagNameMap['en'] as String? ?? tagNameMap.values.firstOrNull as String? ?? '';
        categories.add(CategoryModel(id: tagId, name: tagName, slug: tagId));
      }

      // 2. Fetch Chapters (VI and EN)
      final feedResponse = await _mangadexApi.get(
        '/manga/$id/feed',
        queryParameters: {
          'limit': 500,
          'translatedLanguage[]': ['vi', 'en', 'ja'],
          'order[chapter]': 'desc',
          'includes[]': ['scanlation_group'],
        },
      );
      
      var feedData = feedResponse.data;
      if (feedData is String) {
        feedData = jsonDecode(feedData);
      }
      final feedItems = feedData['data'] as List? ?? [];

      final List<ChapterModel> viChapters = [];
      final List<ChapterModel> enChapters = [];
      final List<ChapterModel> jaChapters = [];

      for (final ch in feedItems) {
        final chId = ch['id'] as String? ?? '';
        final chAttrs = ch['attributes'] as Map? ?? {};
        final chNum = chAttrs['chapter'] as String? ?? '';
        final chTitle = chAttrs['title'] as String? ?? '';
        final chLang = chAttrs['translatedLanguage'] as String? ?? 'en';
        
        final chapterModel = ChapterModel(
          filename: chId,
          chapterName: chNum.isNotEmpty ? chNum : (chTitle.isNotEmpty ? chTitle : '0'),
          chapterTitle: chTitle,
          chapterApiData: '${ApiConstants.mangadexBaseUrl}/at-home/server/$chId',
        );

        if (chLang == 'vi') {
          viChapters.add(chapterModel);
        } else if (chLang == 'ja') {
          jaChapters.add(chapterModel);
        } else if (chLang == 'en') {
          enChapters.add(chapterModel);
        }
      }

      final List<ServerModel> servers = [];
      if (viChapters.isNotEmpty) {
        servers.add(ServerModel(serverName: 'Tiếng Việt', serverData: viChapters));
      }
      if (enChapters.isNotEmpty) {
        servers.add(ServerModel(serverName: 'Tiếng Anh', serverData: enChapters));
      }
      if (jaChapters.isNotEmpty) {
        servers.add(ServerModel(serverName: 'Tiếng Nhật', serverData: jaChapters));
      }
      if (servers.isEmpty) {
        servers.add(const ServerModel(serverName: 'Tiếng Việt', serverData: []));
      }

      return ComicDetailInfoModel(
        id: id,
        name: name,
        slug: id,
        originName: altNames,
        content: content,
        status: status,
        thumbUrl: thumbUrl,
        author: authors,
        category: categories,
        chapters: servers,
      );
    } catch (e) {
      throw Exception('Không thể tải chi tiết truyện từ MangaDex: $e');
    }
  }

  // Favorite / Bookmark Sync Operations
  Future<bool> isFavorite(String slug) async {
    return LocalStorage.isFavorite(slug);
  }

  Future<void> toggleFavorite(ComicDetailInfoModel comic, bool isFav) async {
    if (isFav) {
      await LocalStorage.insertFavorite({
        'slug': comic.slug,
        'name': comic.name,
        'thumb_url': comic.thumbUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _ref.read(libraryRepositoryProvider).addFavoriteRemote(comic.slug, comic.name, comic.thumbUrl);
    } else {
      await LocalStorage.deleteFavorite(comic.slug);
      await _ref.read(libraryRepositoryProvider).removeFavoriteRemote(comic.slug);
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
    await LocalStorage.saveHistory({
      'comic_slug': comicSlug,
      'comic_name': comicName,
      'comic_thumb': comicThumb,
      'chapter_slug': chapterSlug,
      'chapter_name': chapterName,
      'progress_percent': progressPercent,
      'last_read_at': DateTime.now().toIso8601String(),
    });
    await _ref.read(libraryRepositoryProvider).saveHistoryRemote(
      comicSlug: comicSlug,
      comicName: comicName,
      comicThumb: comicThumb,
      chapterSlug: chapterSlug,
      chapterName: chapterName,
      progressPercent: progressPercent,
    );
  }

  Future<Map<String, dynamic>?> getReadingHistory(String comicSlug) async {
    return LocalStorage.getComicHistory(comicSlug);
  }
}
