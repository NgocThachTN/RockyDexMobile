import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../home/domain/comic_model.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SearchRepository(dio, prefs);
});

class SearchRepository {
  final Dio _dio;
  final SharedPreferences _prefs;
  static const String _historyKey = 'search_history_list';

  SearchRepository(this._dio, this._prefs);

  Future<List<ComicModel>> searchComics(String keyword, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.otruyenBaseUrl}${ApiConstants.pathSearch}',
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
      throw Exception('Tìm kiếm thất bại: $e');
    }
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
