import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/comic_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(dioProvider));
});

class HomeRepository {
  final Dio _dio;

  HomeRepository(this._dio);

  // Fetch standard home lists
  Future<List<ComicModel>> getComicsList(String type, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.otruyenBaseUrl}${ApiConstants.pathList}/$type',
        queryParameters: {'page': page},
      );

      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }
      final data = responseData['data'];
      final items = data['items'] as List;

      // Extract CDN Domain if present
      final cdnImage = data['APP_DOMAIN_CDN_IMAGE'] as String? ?? ApiConstants.otruyenImageBaseCdn;

      return items.map((item) {
        // Map DTO to domain model. Thumb URL should be absolute
        final rawThumb = item['thumb_url'] as String;
        final absoluteThumb = rawThumb.startsWith('http')
            ? rawThumb
            : '$cdnImage/uploads/comics/$rawThumb';

        final mappedItem = Map<String, dynamic>.from(item);
        mappedItem['thumb_url'] = absoluteThumb;

        return ComicModel.fromJson(mappedItem);
      }).toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách truyện: $e');
    }
  }

  // Fetch all genres
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('${ApiConstants.otruyenBaseUrl}${ApiConstants.pathCategories}');
      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }
      final items = responseData['data']['items'] as List;
      return items.map((item) => CategoryModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Không thể tải thể loại: $e');
    }
  }

  // Fetch comics by category slug
  Future<List<ComicModel>> getComicsByCategory(String categorySlug, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.otruyenBaseUrl}${ApiConstants.pathCategories}/$categorySlug',
        queryParameters: {'page': page},
      );

      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }
      final data = responseData['data'];
      final items = data['items'] as List;

      // Extract CDN Domain if present
      final cdnImage = data['APP_DOMAIN_CDN_IMAGE'] as String? ?? ApiConstants.otruyenImageBaseCdn;

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
      throw Exception('Không thể tải danh sách truyện theo thể loại: $e');
    }
  }
}
