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
  ServerSource get source => _source;
  late final OtruyenApiClient _otruyenApi;
  static const String _historyKey = 'search_history_list';

  SearchRepository(this._dio, this._mangadexApi, this._prefs, this._source) {
    _otruyenApi = OtruyenApiClient(_dio);
  }

  Future<List<ComicModel>> searchComics(
    String keyword, {
    int page = 1,
    String? year,
    String? status,
    String? sortBy,
    List<String>? genres,
  }) async {
    if (_source == ServerSource.mangadex) {
      try {
        final offset = (page - 1) * 20;
        final queryParams = <String, dynamic>{
          'limit': 20,
          'offset': offset,
          'includes[]': ['cover_art', 'author'],
        };

        if (keyword.trim().isNotEmpty) {
          queryParams['title'] = keyword.trim();
        }

        // Apply Year Filter (if not 'all')
        if (year != null && year != 'all') {
          final yearInt = int.tryParse(year);
          if (yearInt != null) {
            queryParams['year'] = yearInt;
          }
        }

        // Apply Status Filter (if not 'all')
        if (status != null && status != 'all') {
          if (status == 'ongoing' || status == 'completed' || status == 'hiatus' || status == 'cancelled') {
            queryParams['status[]'] = [status];
          }
        }

        // Apply Genres Filter (includedTags)
        if (genres != null && genres.isNotEmpty) {
          queryParams['includedTags[]'] = genres;
        }

        // Apply Sort Order (if not null)
        final orderParam = sortBy ?? 'latestUploadedChapter';
        queryParams['order[$orderParam]'] = 'desc';

        final response = await _mangadexApi.get(
          '/manga',
          queryParameters: queryParams,
        );

        final comics = await _mapMangaDexComicsResponse(response.data);

        // Fetch statistics for these comics and merge them
        if (comics.isNotEmpty) {
          try {
            final ids = comics.map((c) => c.id).toList();
            final statsResponse = await _mangadexApi.get(
              '/statistics/manga',
              queryParameters: {
                'manga[]': ids,
              },
            );

            var statsData = statsResponse.data;
            if (statsData is String) {
              statsData = jsonDecode(statsData);
            }
            final statsMap = statsData['statistics'] as Map<String, dynamic>? ?? {};

            return comics.map((c) {
              final comicStats = statsMap[c.id];
              if (comicStats != null) {
                final ratingData = comicStats['rating'];
                final averageRating = (ratingData?['average'] as num?)?.toDouble() ??
                                      (ratingData?['bayesian'] as num?)?.toDouble();
                final followsCount = comicStats['follows'] as int?;
                return c.copyWith(
                  rating: averageRating,
                  followsCount: followsCount,
                );
              }
              return c;
            }).toList();
          } catch (statsError) {
            print('Lỗi khi tải thống kê MangaDex: $statsError');
          }
        }

        return comics;
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

  Future<List<ComicModel>> _mapMangaDexComicsResponse(dynamic rawResponseData) async {
    var responseData = rawResponseData;
    if (responseData is String) {
      responseData = jsonDecode(responseData);
    }

    final items = responseData['data'] as List? ?? [];
    if (items.isEmpty) return [];

    // Collect latest uploaded chapter IDs
    final List<String> latestChapterIds = [];
    final Map<String, String> mangaToChapterId = {};

    for (final item in items) {
      final id = item['id'] as String? ?? '';
      final attributes = item['attributes'] as Map<String, dynamic>? ?? {};
      final latestChapterId = attributes['latestUploadedChapter'] as String? ?? '';
      if (latestChapterId.isNotEmpty) {
        latestChapterIds.add(latestChapterId);
        mangaToChapterId[id] = latestChapterId;
      }
    }

    // Fetch chapter details for these IDs in one request
    final Map<String, String> chapterIdToName = {};
    if (latestChapterIds.isNotEmpty) {
      try {
        final response = await _mangadexApi.get(
          '/chapter',
          queryParameters: {
            'ids[]': latestChapterIds,
            'limit': 100,
          },
        );
        final chapsData = response.data;
        final chapsList = chapsData['data'] as List? ?? [];
        for (final chap in chapsList) {
          final chapId = chap['id'] as String? ?? '';
          final chapAttrs = chap['attributes'] as Map<String, dynamic>? ?? {};
          final chapNum = chapAttrs['chapter'] as String? ?? '';
          if (chapId.isNotEmpty && chapNum.isNotEmpty) {
            chapterIdToName[chapId] = chapNum;
          }
        }
      } catch (e) {
        // Silently catch errors so the main request doesn't fail
        print('Error fetching MangaDex chapter details: $e');
      }
    }

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

      // Get chapter summary if available
      List<ChapterSummaryModel>? chaptersLatest;
      final targetChapterId = mangaToChapterId[id];
      if (targetChapterId != null) {
        final chapNum = chapterIdToName[targetChapterId];
        if (chapNum != null && chapNum.isNotEmpty) {
          chaptersLatest = [
            ChapterSummaryModel(
              filename: '',
              chapterName: chapNum,
              chapterTitle: '',
              chapterApiData: '',
            ),
          ];
        }
      }

      return ComicModel(
        id: id,
        name: name,
        slug: id,
        originName: altNames,
        status: status,
        thumbUrl: thumbUrl,
        category: cats,
        updatedAt: updatedAt,
        chaptersLatest: chaptersLatest,
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
