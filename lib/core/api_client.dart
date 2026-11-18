import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../state/auth_notifier.dart';
import 'api_exceptions.dart';
import 'config.dart';
import 'connectivity_monitor.dart';

bool isAuthPath(String path) {
  return path.contains('/auth/login') ||
      path.contains('/auth/register') ||
      path.contains('/auth/refresh') ||
      path.contains('/auth/logout');
}

Dio buildDio({AuthNotifier? auth, ConnectivityMonitor? connectivity}) {
  late final Dio dio;
  dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        final token = auth?.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (apiDelayMs > 0) {
          options.queryParameters['__delay'] = apiDelayMs;
        }
        if (apiFailCode > 0) {
          options.queryParameters['__fail'] = apiFailCode;
        }
        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        connectivity?.markOnline();
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint(
              '[API] ← $status ${response.requestOptions.method} ${response.requestOptions.uri}');
        }
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (ConnectivityMonitor.isNetworkError(error)) {
          connectivity?.markOffline();
        }
        if (kDebugMode) {
          debugPrint('[API] сбой ${error.requestOptions.uri}: ${error.type}');
        }
        final status = error.response?.statusCode;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;
        if (auth != null &&
            status == 401 &&
            !alreadyRetried &&
            !isAuthPath(error.requestOptions.path)) {
          final refreshed = await auth.refreshTokens();
          if (refreshed) {
            final options = error.requestOptions;
            options.extra['retried'] = true;
            final token = auth.accessToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            try {
              final response = await dio.fetch(options);
              return handler.resolve(response);
            } catch (retryError) {
              if (retryError is DioException) {
                return handler.next(retryError);
              }
            }
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}
