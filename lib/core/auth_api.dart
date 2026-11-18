import 'package:dio/dio.dart';

import '../models/app_user.dart';
import '../utils/page_result.dart';
import 'api_exceptions.dart';
import 'api_support.dart';
import 'config.dart';

class AuthApi {
  AuthApi(this._dio, {Dio? refreshClient})
      : _refreshClient = refreshClient ?? _plainClient();

  final Dio _dio;
  final Dio _refreshClient;

  static Dio _plainClient() {
    return Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  Future<AuthTokens> login(String username, String password) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return AuthTokens.fromJson(asJsonMap(response.data));
    });
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String fullName,
    String email = '',
  }) {
    return guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'fullName': fullName,
          if (email.trim().isNotEmpty) 'email': email.trim(),
        },
      );
      return AppUser.fromJson(asJsonMap(response.data));
    });
  }

  Future<AuthTokens> refresh(String refreshToken) {
    return guard(() async {
      final response = await _refreshClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return AuthTokens.fromJson(asJsonMap(response.data));
    });
  }

  Future<AppUser> me() {
    return guard(() async {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AppUser.fromJson(asJsonMap(response.data));
    });
  }

  Future<void> logout(String? refreshToken) {
    return guard(() async {
      await _dio.post<void>(
        '/auth/logout',
        data: {if (refreshToken != null) 'refreshToken': refreshToken},
      );
    });
  }

  Future<PageResult<AppUser>> users({int page = 1, int size = 20}) {
    return retryRead(
      () => guard(() async {
        final response = await _dio.get<dynamic>(
          '/users',
          queryParameters: {'page': page, 'size': size, 'sort': 'username,asc'},
        );
        return parsePage(response.data, AppUser.fromJson, fallbackSize: size);
      }),
    );
  }
}
