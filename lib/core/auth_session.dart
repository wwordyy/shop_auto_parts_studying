import 'package:dio/dio.dart';

import 'api_exceptions.dart';
import 'config.dart';

class AuthSession {
  String? accessToken;
  String? refreshToken;
  Map<String, dynamic>? user;

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  Future<void> tryLogin(Dio dio, {String? username, String? password}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': username ?? apiLogin,
          'password': password ?? apiPassword,
        },
      );
      final data = response.data ?? const <String, dynamic>{};
      accessToken = data['accessToken'] as String?;
      refreshToken = data['refreshToken'] as String?;
      final rawUser = data['user'];
      user = rawUser is Map<String, dynamic> ? rawUser : null;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
