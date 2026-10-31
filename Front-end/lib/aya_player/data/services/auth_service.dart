import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.1.4:8000/api/v1';
  static const _storage = FlutterSecureStorage();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['token'] ?? response.data['access_token'];
        if (token != null) {
          await _storage.write(key: 'auth_token', value: token.toString());
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? e.message;
      throw Exception(errorMsg ?? 'فشل إنشاء الحساب');
    }
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'] ?? response.data['access_token'];
        if (token != null) {
          await _storage.write(key: 'auth_token', value: token.toString());
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? e.message;
      throw Exception(errorMsg ?? 'فشل تسجيل الدخول');
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await _dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {}
    }
    await _storage.delete(key: 'auth_token');
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
