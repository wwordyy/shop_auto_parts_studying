import 'package:dio/dio.dart';

import '../utils/page_result.dart';
import 'api_exceptions.dart';

Map<String, dynamic> asJsonMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}

PageResult<T> parsePage<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson, {
  int fallbackSize = 10,
}) {
  final json = asJsonMap(data);
  final rawItems = json['items'];
  final items = <T>[];
  if (rawItems is List) {
    for (final item in rawItems) {
      if (item is Map) {
        items.add(fromJson(Map<String, dynamic>.from(item)));
      }
    }
  }
  return PageResult(
    items: items,
    page: (json['page'] as num?)?.toInt() ?? 1,
    size: (json['size'] as num?)?.toInt() ?? fallbackSize,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );
}

class ApiResource<T> {
  ApiResource({
    required Dio dio,
    required this.path,
    required this.fromJson,
  }) : _dio = dio;

  final Dio _dio;
  final String path;
  final T Function(Map<String, dynamic> json) fromJson;
  CancelToken? _listToken;
  List<T>? _cache;

  void invalidateCache() => _cache = null;

  Future<PageResult<T>> find(Map<String, dynamic> query) {
    _listToken?.cancel('stale');
    final token = CancelToken();
    _listToken = token;
    return retryRead(
      () => guard(() async {
        final response = await _dio.get<dynamic>(
          path,
          queryParameters: query,
          cancelToken: token,
        );
        return parsePage(response.data, fromJson);
      }),
    );
  }

  Future<T?> findById(int id) async {
    try {
      return await retryRead(
        () => guard(() async {
          final response = await _dio.get<dynamic>('$path/$id');
          return fromJson(asJsonMap(response.data));
        }),
      );
    } on NotFoundException {
      return null;
    }
  }

  Future<List<T>> getAll({bool includeDeleted = false}) {
    if (!includeDeleted && _cache != null) {
      return Future.value(_cache);
    }
    return retryRead(
      () => guard(() async {
        final response = await _dio.get<dynamic>(
          path,
          queryParameters: {
            'size': 100,
            'page': 1,
            if (includeDeleted) 'includeDeleted': true,
          },
        );
        final page = parsePage(response.data, fromJson, fallbackSize: 100);
        if (!includeDeleted) _cache = page.items;
        return page.items;
      }),
    );
  }

  Future<T> create(Map<String, dynamic> body) {
    return guard(() async {
      final response = await _dio.post<dynamic>(path, data: body);
      invalidateCache();
      return fromJson(asJsonMap(response.data));
    });
  }

  Future<T> update(int id, Map<String, dynamic> body) {
    return guard(() async {
      final response = await _dio.put<dynamic>('$path/$id', data: body);
      invalidateCache();
      return fromJson(asJsonMap(response.data));
    });
  }

  Future<void> softDelete(int id) {
    return guard(() async {
      await _dio.delete<dynamic>('$path/$id');
      invalidateCache();
    });
  }

  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete<dynamic>('$path/$id', queryParameters: {'hard': true});
      invalidateCache();
    });
  }

  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post<dynamic>('$path/$id/restore');
      invalidateCache();
    });
  }

  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post<dynamic>('$path/bulk-delete', data: {'ids': ids});
      invalidateCache();
      return (asJsonMap(response.data)['deleted'] as num?)?.toInt() ?? 0;
    });
  }
}
