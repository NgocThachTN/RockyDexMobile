import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

class OtruyenApiClient {
  OtruyenApiClient(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    DioException? lastConnectionError;

    for (final baseUrl in ApiConstants.otruyenBaseUrls) {
      try {
        return await _dio.get(
          '$baseUrl$path',
          queryParameters: queryParameters,
        );
      } on DioException catch (error) {
        if (!_canRetryWithNextHost(error)) {
          rethrow;
        }
        lastConnectionError = error;
      }
    }

    throw lastConnectionError ??
        DioException(
          requestOptions: RequestOptions(path: path),
          message: 'Unable to connect to OTruyen API',
        );
  }

  bool _canRetryWithNextHost(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.unknown;
  }
}
