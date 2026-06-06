import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'dio_client.dart';

final mangadexApiClientProvider = Provider<MangadexApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return MangadexApiClient(dio);
});

class MangadexApiClient {
  final Dio _dio;

  MangadexApiClient(this._dio);

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.mangadexBaseUrl}$path',
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw Exception('Lỗi kết nối MangaDex API: ${e.message}');
    }
  }
}
