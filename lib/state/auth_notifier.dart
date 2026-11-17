import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_api.dart';
import '../core/api_exceptions.dart';
import '../core/config.dart';
import '../core/permissions.dart';
import '../models/app_user.dart';

enum LogoutReason { manual, inactivity, sessionExpired, refreshFailed }

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user';
  static const _kLastActivity = 'auth_last_activity';
  static const _kSessionStarted = 'auth_session_started';

  AuthNotifier(this._prefs);

  final SharedPreferences _prefs;
  AuthApi? _api;
  String? _accessToken;
  String? _refreshToken;
  AppUser? _user;
  Future<bool>? _refreshing;
  Timer? _sessionTimer;
  String? logoutMessage;

  void attachApi(AuthApi api) => _api = api;

  String? get accessToken => _accessToken;

  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  AppUser? get user => _readStoredUser() ?? _user;

  Permissions get permissions => Permissions(user?.role);

  bool has(Role role) => permissions.hasAtLeast(role);

  Future<void> restore() async {
    _accessToken = _prefs.getString(_kAccess);
    _refreshToken = _prefs.getString(_kRefresh);
    _user = _readStoredUser();
    if (_accessToken == null || _accessToken!.isEmpty) {
      await _clear(notify: false);
      return;
    }
    if (_sessionExpiredByWallClock || _sessionExpiredByInactivity) {
      await logout(reason: _sessionExpiredByWallClock ? LogoutReason.sessionExpired : LogoutReason.inactivity);
      return;
    }
    _scheduleSessionEnd();
    try {
      await _api?.me();
    } on UnauthorizedException {
      final refreshed = await refreshTokens();
      if (!refreshed) return;
    } catch (_) {
      // Сервер недоступен: сессию не сбрасываем, покажем ошибку позже.
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final api = _api;
    if (api == null) {
      throw const ServerException('Клиент авторизации не инициализирован.');
    }
    final result = await api.login(username, password);
    await _applyTokens(result);
    logoutMessage = null;
    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String password,
    required String fullName,
    String email = '',
  }) async {
    final api = _api;
    if (api == null) {
      throw const ServerException('Клиент авторизации не инициализирован.');
    }
    await api.register(
      username: username,
      password: password,
      fullName: fullName,
      email: email,
    );
    await login(username, password);
  }

  Future<bool> refreshTokens() {
    final pending = _refreshing;
    if (pending != null) return pending;
    final future = _refreshTokens();
    _refreshing = future;
    return future.whenComplete(() => _refreshing = null);
  }

  Future<bool> _refreshTokens() async {
    final api = _api;
    final token = _refreshToken;
    if (api == null || token == null || token.isEmpty) {
      await logout(reason: LogoutReason.refreshFailed);
      return false;
    }
    try {
      final result = await api.refresh(token);
      await _applyTokens(result, keepSessionStart: true);
      notifyListeners();
      return true;
    } catch (_) {
      await logout(reason: LogoutReason.refreshFailed);
      return false;
    }
  }

  Future<void> logout({LogoutReason reason = LogoutReason.manual}) async {
    final api = _api;
    final refresh = _refreshToken;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    if (api != null && refresh != null) {
      try {
        await api.logout(refresh);
      } catch (_) {}
    }
    logoutMessage = switch (reason) {
      LogoutReason.inactivity => 'Сессия завершена из-за бездействия.',
      LogoutReason.sessionExpired => 'Истекло максимальное время сессии.',
      LogoutReason.refreshFailed => 'Сессия истекла. Войдите снова.',
      LogoutReason.manual => null,
    };
    await _clear(notify: true);
  }

  void touch() {
    if (!isAuthenticated) return;
    unawaited(_prefs.setString(_kLastActivity, DateTime.now().toIso8601String()));
    if (_sessionExpiredByWallClock) {
      unawaited(logout(reason: LogoutReason.sessionExpired));
    }
  }

  Future<void> _applyTokens(AuthTokens result, {bool keepSessionStart = false}) async {
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    await _prefs.setString(_kUser, jsonEncode(result.user.toJson()));
    await _prefs.setString(_kLastActivity, DateTime.now().toIso8601String());
    if (!keepSessionStart || _prefs.getString(_kSessionStarted) == null) {
      await _prefs.setString(_kSessionStarted, DateTime.now().toIso8601String());
    }
    _scheduleSessionEnd();
  }

  Future<void> _clear({required bool notify}) async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kLastActivity);
    await _prefs.remove(_kSessionStarted);
    if (notify) notifyListeners();
  }

  AppUser? _readStoredUser() {
    final raw = _prefs.getString(_kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return AppUser.fromJson(decoded);
      if (decoded is Map) return AppUser.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {}
    return null;
  }

  DateTime? _readTime(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  bool get _sessionExpiredByWallClock {
    final started = _readTime(_kSessionStarted);
    if (started == null) return false;
    return DateTime.now().difference(started) >= Duration(minutes: sessionMaxMinutes);
  }

  bool get _sessionExpiredByInactivity {
    final last = _readTime(_kLastActivity);
    if (last == null) return false;
    return DateTime.now().difference(last) >= Duration(seconds: inactivityTimeoutSeconds);
  }

  void _scheduleSessionEnd() {
    _sessionTimer?.cancel();
    final started = _readTime(_kSessionStarted);
    if (started == null) return;
    final remaining = started.add(Duration(minutes: sessionMaxMinutes)).difference(DateTime.now());
    if (remaining.isNegative) {
      unawaited(logout(reason: LogoutReason.sessionExpired));
      return;
    }
    _sessionTimer = Timer(remaining, () => logout(reason: LogoutReason.sessionExpired));
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
