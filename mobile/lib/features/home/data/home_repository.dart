import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/otruyen_api_client.dart';
import '../../../core/network/mangadex_api_client.dart';
import '../../../core/providers/server_source_provider.dart';
import '../domain/comic_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final mangadexApi = ref.watch(mangadexApiClientProvider);
  final source = ref.watch(serverSourceProvider);
  return HomeRepository(dio, mangadexApi, source);
});

class HomeRepository {
  final Dio _dio;
  final MangadexApiClient _mangadexApi;
  final ServerSource _source;
  late final OtruyenApiClient _otruyenApi;

  HomeRepository(this._dio, this._mangadexApi, this._source) {
    _otruyenApi = OtruyenApiClient(_dio);
  }

  Future<List<ComicModel>> getHomeComics() async {
    if (_source == ServerSource.mangadex) {
      try {
        final response = await _mangadexApi.get(
          '/manga',
          queryParameters: {
            'limit': 20,
            'order[latestUploadedChapter]': 'desc',
            'includes[]': ['cover_art', 'author'],
          },
        );
        return _mapMangaDexComicsResponse(response.data);
      } catch (e) {
        throw Exception('Không thể tải truyện trang chủ MangaDex: $e');
      }
    }

    try {
      final response = await _otruyenApi.get(ApiConstants.pathHome);
      return _mapComicsResponse(response.data);
    } catch (e) {
      throw Exception('Khong the tai truyen trang chu: $e');
    }
  }

  Future<List<ComicModel>> getComicsList(String type, {int page = 1}) async {
    if (_source == ServerSource.mangadex) {
      try {
        final offset = (page - 1) * 20;
        final queryParams = <String, dynamic>{
          'limit': 20,
          'offset': offset,
          'includes[]': ['cover_art', 'author'],
        };
        
        if (type == ApiConstants.listFeatured) {
          queryParams['order[followedCount]'] = 'desc';
        } else if (type == ApiConstants.listOngoing) {
          queryParams['status[]'] = 'ongoing';
          queryParams['order[latestUploadedChapter]'] = 'desc';
        } else if (type == ApiConstants.listCompleted) {
          queryParams['status[]'] = 'completed';
          queryParams['order[latestUploadedChapter]'] = 'desc';
        } else if (type == ApiConstants.listComingSoon) {
          queryParams['status[]'] = 'hiatus';
          queryParams['order[latestUploadedChapter]'] = 'desc';
        } else {
          queryParams['order[latestUploadedChapter]'] = 'desc';
        }

        final response = await _mangadexApi.get(
          '/manga',
          queryParameters: queryParams,
        );
        return _mapMangaDexComicsResponse(response.data);
      } catch (e) {
        throw Exception('Không thể tải danh sách truyện MangaDex: $e');
      }
    }

    try {
      final response = await _otruyenApi.get(
        '${ApiConstants.pathList}/$type',
        queryParameters: {'page': page},
      );
      return _mapComicsResponse(response.data);
    } catch (e) {
      throw Exception('Khong the tai danh sach truyen: $e');
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    if (_source == ServerSource.mangadex) {
      try {
        final response = await _mangadexApi.get('/manga/tag');
        var responseData = response.data;
        if (responseData is String) {
          responseData = jsonDecode(responseData);
        }
        final items = responseData['data'] as List;
        return items.map((item) {
          final id = item['id'] as String? ?? '';
          final nameMap = item['attributes']['name'] as Map? ?? {};
          final name = nameMap['en'] as String? ?? nameMap.values.firstOrNull as String? ?? '';
          return CategoryModel(id: id, name: name, slug: id);
        }).toList();
      } catch (e) {
        throw Exception('Không thể tải thể loại MangaDex: $e');
      }
    }

    try {
      final response = await _otruyenApi.get(ApiConstants.pathCategories);
      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }
      final items = responseData['data']['items'] as List;
      return items
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Khong the tai the loai: $e');
    }
  }

  Future<List<ComicModel>> getComicsByCategory(
    String categorySlug, {
    int page = 1,
  }) async {
    if (_source == ServerSource.mangadex) {
      try {
        final offset = (page - 1) * 20;
        final response = await _mangadexApi.get(
          '/manga',
          queryParameters: {
            'limit': 20,
            'offset': offset,
            'includedTags[]': [categorySlug],
            'includes[]': ['cover_art', 'author'],
            'order[latestUploadedChapter]': 'desc',
          },
        );
        return _mapMangaDexComicsResponse(response.data);
      } catch (e) {
        throw Exception('Không thể tải danh sách truyện theo thể loại MangaDex: $e');
      }
    }

    try {
      final response = await _otruyenApi.get(
        '${ApiConstants.pathCategories}/$categorySlug',
        queryParameters: {'page': page},
      );
      return _mapComicsResponse(response.data);
    } catch (e) {
      throw Exception('Khong the tai danh sach truyen theo the loai: $e');
    }
  }

  List<ComicModel> _mapComicsResponse(dynamic rawResponseData) {
    var responseData = rawResponseData;
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
      final status = rawStatus == 'completed' ? 'completed' : 'ongoing';

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
}
