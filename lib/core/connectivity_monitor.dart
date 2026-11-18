import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'config.dart';

class ConnectivityMonitor extends ChangeNotifier {
  ConnectivityMonitor();

  bool _online = true;
  Timer? _probe;
  Dio? _probeClient;

  bool get isOnline => _online;

  void attach() {
    _probeClient ??= Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        validateStatus: (status) => status != null,
      ),
    );
  }

  void markOffline() {
    if (!_online) return;
    _online = false;
    notifyListeners();
    _probe?.cancel();
    _probe = Timer.periodic(const Duration(seconds: 4), (_) => probe());
  }

  void markOnline() {
    if (_online) return;
    _online = true;
    _probe?.cancel();
    _probe = null;
    notifyListeners();
  }

  Future<void> probe() async {
    final client = _probeClient;
    if (client == null) return;
    try {
      await client.get<void>('/auth/me');
      markOnline();
    } on DioException catch (error) {
      if (_isNetwork(error)) return;
      markOnline();
    } catch (_) {
      markOnline();
    }
  }

  static bool isNetworkError(DioException error) => _isNetwork(error);

  static bool _isNetwork(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  @override
  void dispose() {
    _probe?.cancel();
    super.dispose();
  }
}
