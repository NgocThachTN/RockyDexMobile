import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/otruyen_api_client.dart';
import '../../../core/network/mangadex_api_client.dart';
import '../../../core/providers/server_source_provider.dart';
import '../../home/domain/comic_model.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final mangadexApi = ref.watch(mangadexApiClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final source = ref.watch(serverSourceProvider);
  return SearchRepository(dio, mangadexApi, prefs, source);
});

class SearchRepository {
  final Dio _dio;
  final MangadexApiClient _mangadexApi;
  final SharedPreferences _prefs;
  final ServerSource _source;
  late final OtruyenApiClient _otruyenApi;
  static const String _historyKey = 'search_history_list';

  SearchRepository(this._dio, this._mangadexApi, this._prefs, this._source) {
    _otruyenApi = OtruyenApiClient(_dio);
  }

  Future<List<ComicModel>> searchComics(String keyword, {int page = 1}) async {
    if (_source == ServerSource.mangadex) {
      try {
        final offset = (page - 1) * 20;
        final response = await _mangadexApi.get(
          '/manga',
          queryParameters: {
            'title': keyword,
            'limit': 20,
            'offset': offset,
            'includes[]': ['cover_art', 'author'],
            'order[latestUploadedChapter]': 'desc',
          },
        );
        return _mapMangaDexComicsResponse(response.data);
      } catch (e) {
        throw Exception('Tìm kiếm trên MangaDex thất bại: $e');
      }
    }

    try {
      final response = await _otruyenApi.get(
        ApiConstants.pathSearch,
        queryParameters: {
          'keyword': keyword,
          'page': page,
        },
      );

      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }
      final data = responseData['data'];
      final items = data['items'] as List;
      final cdnImage = data['APP_DOMAIN_CDN_IMAGE'] as String? ??
          ApiConstants.otruyenImageBaseCdn;

      return items.map((item) {
        final rawThumb = item['thumb_url'] as String;
        final absoluteThumb = rawThumb.startsWith('http')
            ? rawThumb
            : '$cdnImage/uploads/comics/$rawThumb';

        final mappedItem = Map<String, dynamic>.from(item);
        mappedItem['thumb_url'] = absoluteThumb;

        return ComicModel.fromJson(mappedItem);
      }).toList();
    } catch (e) {
      throw Exception('Tìm kiếm thất bại: $e');
    }
  }

  List<ComicModel> _mapMangaDexComicsResponse(dynamic rawResponseData) {
    var responseData = rawResponseData;
    if (responseData is String) {
      responseData = jsonDecode(responseData);
    }

    final items = responseData['data'] as List? ?? [];
    return items.map((item) {
      final id = item['id'] as String? ?? '';
      final attributes = item['attributes'] as Map<String, dynamic>? ?? {};
      
      final titleMap = attributes['title'] as Map? ?? {};
      String name = 'Chưa có tiêu đề';
      if (titleMap.containsKey('vi')) {
        name = titleMap['vi'] as String;
      } else if (titleMap.containsKey('en')) {
        name = titleMap['en'] as String;
      } else if (titleMap.isNotEmpty) {
        name = titleMap.values.first as String;
      }

      final altTitlesList = attributes['altTitles'] as List? ?? [];
      final List<String> altNames = [];
      for (final alt in altTitlesList) {
        if (alt is Map) {
          final val = alt.values.firstOrNull as String?;
          if (val != null && val.isNotEmpty) altNames.add(val);
        }
      }

      final rawStatus = attributes['status'] as String? ?? 'ongoing';
      final status = rawStatus == 'completed'
          ? 'completed'
          : (rawStatus == 'hiatus' ? 'coming_soon' : 'ongoing');

      final tagsList = attributes['tags'] as List? ?? [];
      final List<CategoryModel> cats = [];
      for (final tag in tagsList) {
        final tagId = tag['id'] as String? ?? '';
        final tagNameMap = tag['attributes']?['name'] as Map? ?? {};
        final tagName = tagNameMap['en'] as String? ?? tagNameMap.values.firstOrNull as String? ?? '';
        cats.add(CategoryModel(id: tagId, name: tagName, slug: tagId));
      }

      final rels = item['relationships'] as List? ?? [];
      String coverFilename = '';
      for (final rel in rels) {
        if (rel['type'] == 'cover_art') {
          final relAttrs = rel['attributes'];
          if (relAttrs != null && relAttrs['fileName'] != null) {
            coverFilename = relAttrs['fileName'] as String;
          }
        }
      }
      final thumbUrl = coverFilename.isNotEmpty
          ? '${ApiConstants.mangadexImageBaseCdn}/$id/$coverFilename.512.jpg'
          : 'https://mangadex.org/avatar.png';

      final updatedAt = attributes['updatedAt'] as String? ?? '';

      return ComicModel(
        id: id,
        name: name,
        slug: id,
        originName: altNames,
        status: status,
        thumbUrl: thumbUrl,
        category: cats,
        updatedAt: updatedAt,
      );
    }).toList();
  }

  // Local Search History Helpers
  List<String> getSearchHistory() {
    return _prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> addSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    final list = getSearchHistory();
    list.remove(keyword); // remove duplicates
    list.insert(0, keyword); // insert at top

    // limit history size to 10 items
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }
    await _prefs.setStringList(_historyKey, list);
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(_historyKey);
  }
}
