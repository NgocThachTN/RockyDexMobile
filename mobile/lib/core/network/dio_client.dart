import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final dioProvider = Provider<Dio>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Automatically inject JWT if available
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Setup base url. Default to rockydexBaseUrl but checks local emulator
        if (options.path.startsWith('/')) {
          options.baseUrl = ApiConstants.rockydexBaseUrl;
        }

        return handler.next(options);
      },
      onError: (e, handler) {
        // Handle common errors (401, network, etc.)
        if (e.response?.statusCode == 401) {
          // Auto logout/clear session if token expired
          prefs.remove('auth_token');
          prefs.remove('user_data');
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
