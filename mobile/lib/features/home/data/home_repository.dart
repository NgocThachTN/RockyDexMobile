import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/otruyen_api_client.dart';
import '../domain/comic_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(dioProvider));
});

class HomeRepository {
  final Dio _dio;
  late final OtruyenApiClient _otruyenApi;

  HomeRepository(this._dio) {
    _otruyenApi = OtruyenApiClient(_dio);
  }

  Future<List<ComicModel>> getHomeComics() async {
    try {
      final response = await _otruyenApi.get(ApiConstants.pathHome);
      return _mapComicsResponse(response.data);
    } catch (e) {
      throw Exception('Khong the tai truyen trang chu: $e');
    }
  }

  Future<List<ComicModel>> getComicsList(String type, {int page = 1}) async {
    try {
      final response = await _otruyenApi.get(
        '${ApiConstants.pathList}/$type',
        queryParameters: {'page': page, 'limit': 20},
      );
      return _mapComicsResponse(response.data);
    } catch (e) {
      throw Exception('Khong the tai danh sach truyen: $e');
    }
  }

  Future<List<CategoryModel>> getCategories() async {
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
    try {
      final response = await _otruyenApi.get(
        '${ApiConstants.pathCategories}/$categorySlug',
        queryParameters: {'page': page, 'limit': 20},
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
}
