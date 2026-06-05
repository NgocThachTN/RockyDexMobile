import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/chapter_detail_model.dart';

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  return ReaderRepository(ref.watch(dioProvider));
});

class ReaderRepository {
  final Dio _dio;

  ReaderRepository(this._dio);

  Future<ChapterDetailInfoModel> getChapterDetail(String apiDataUrl) async {
    try {
      // Fetch directly from the absolute URL
      final response = await _dio.get(apiDataUrl);
      final rawData = response.data['data'];
      return ChapterDetailInfoModel.fromJson(rawData as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Không thể tải trang truyện: $e');
    }
  }
}
