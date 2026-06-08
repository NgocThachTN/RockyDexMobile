import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại.';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? 'Đăng ký thất bại. Email có thể đã tồn tại.';
      throw Exception(message);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/user/profile');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Không thể tải thông tin cá nhân.');
    }
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/user/profile', data: data);
      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Cập nhật thất bại.');
    }
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {
          'id_token': idToken,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Đăng nhập bằng Google thất bại.');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {
          'email': email,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Yêu cầu mã đặt lại mật khẩu thất bại.');
    }
  }

  Future<void> resetPassword(String email, String token, String newPassword) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Đặt lại mật khẩu thất bại.');
    }
  }
}
