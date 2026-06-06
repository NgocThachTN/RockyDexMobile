import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/mangadex_api_client.dart';
import '../domain/chapter_detail_model.dart';

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final mangadexApi = ref.watch(mangadexApiClientProvider);
  return ReaderRepository(dio, mangadexApi);
});

class ReaderRepository {
  final Dio _dio;
  final MangadexApiClient _mangadexApi;

  ReaderRepository(this._dio, this._mangadexApi);

  Future<ChapterDetailInfoModel> getChapterDetail(String apiDataUrl) async {
    try {
      final Response<dynamic> response;
      if (apiDataUrl.contains('api.mangadex.org')) {
        final uri = Uri.parse(apiDataUrl);
        final path = uri.path;
        response = await _mangadexApi.get(path);
      } else {
        response = await _dio.get(apiDataUrl);
      }
      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      if (apiDataUrl.contains('api.mangadex.org')) {
        // Parse MangaDex at-home response
        final baseUrl = responseData['baseUrl'] as String? ?? 'https://uploads.mangadex.org';
        final chapter = responseData['chapter'] as Map<String, dynamic>? ?? {};
        final hash = chapter['hash'] as String? ?? '';
        final dataFiles = chapter['data'] as List? ?? [];
        
        final List<ChapterPageImageModel> images = [];
        for (int i = 0; i < dataFiles.length; i++) {
          images.add(ChapterPageImageModel(
            imagePage: i + 1,
            imageFile: dataFiles[i] as String? ?? '',
          ));
        }

        // Extrapolate chapterId from url: https://api.mangadex.org/at-home/server/{chapterId}
        final uri = Uri.tryParse(apiDataUrl);
        final chapterId = uri != null && uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';

        return ChapterDetailInfoModel(
          domainCdn: baseUrl,
          item: ChapterDetailItemModel(
            id: chapterId,
            comicName: '',
            chapterName: '',
            chapterTitle: '',
            chapterPath: 'data/$hash',
            chapterImage: images,
          ),
        );
      }

      // Default OTruyen processing
      final rawData = responseData['data'];
      return ChapterDetailInfoModel.fromJson(rawData as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Không thể tải trang truyện: $e');
    }
  }
}
