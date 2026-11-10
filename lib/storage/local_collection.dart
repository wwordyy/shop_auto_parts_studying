import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'storage_status.dart';

class LocalCollection<T> {
  LocalCollection({
    required SharedPreferences prefs,
    required String key,
    required List<T> seed,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required int Function(T) idOf,
    required bool Function(T) isDeleted,
    required T Function(T item, {DateTime? deletedAt, bool clearDeletedAt}) copyDeleted,
    StorageStatus? status,
  })  : _prefs = prefs,
        _key = key,
        _seed = seed,
        _fromJson = fromJson,
        _toJson = toJson,
        _idOf = idOf,
        _isDeleted = isDeleted,
        _copyDeleted = copyDeleted,
        _status = status {
    loadFromPrefs();
  }

  final SharedPreferences _prefs;
  final String _key;
  final List<T> _seed;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;
  final int Function(T) _idOf;
  final bool Function(T) _isDeleted;
  final T Function(T item, {DateTime? deletedAt, bool clearDeletedAt}) _copyDeleted;
  final StorageStatus? _status;

  List<T> items = [];

  void loadFromPrefs() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      items = [..._seed];
      persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      items = list.map((item) => _fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      items = [..._seed];
      _status?.markReset(_key);
      persist();
    }
  }

  Future<void> persist() async {
    await _prefs.setString(_key, jsonEncode(items.map(_toJson).toList()));
  }

  T? byId(int id) {
    for (final item in items) {
      if (_idOf(item) == id) return item;
    }
    return null;
  }

  int get nextId {
    var maxId = 0;
    for (final item in items) {
      final id = _idOf(item);
      if (id > maxId) maxId = id;
    }
    return maxId + 1;
  }

  int indexOfId(int id) => items.indexWhere((item) => _idOf(item) == id);

  List<T> visible({required bool includeDeleted}) {
    return items.where((item) => includeDeleted || !_isDeleted(item)).toList();
  }

  Future<T> add(T item) async {
    items.add(item);
    await persist();
    return item;
  }

  Future<T> replace(int id, T Function(T current) build) async {
    final index = indexOfId(id);
    if (index == -1) throw StateError('Запись $id не найдена');
    items[index] = build(items[index]);
    await persist();
    return items[index];
  }

  Future<void> softDelete(int id) async {
    await replace(id, (item) => _copyDeleted(item, deletedAt: DateTime.now(), clearDeletedAt: false));
  }

  Future<void> restore(int id) async {
    await replace(id, (item) => _copyDeleted(item, clearDeletedAt: true));
  }

  Future<void> removeId(int id) async {
    items.removeWhere((item) => _idOf(item) == id);
    await persist();
  }

  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final index = items.indexWhere((item) => _idOf(item) == id && !_isDeleted(item));
      if (index != -1) {
        items[index] = _copyDeleted(items[index], deletedAt: DateTime.now(), clearDeletedAt: false);
        count++;
      }
    }
    await persist();
    return count;
  }
}
