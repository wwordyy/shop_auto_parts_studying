import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/api_support.dart';
import '../models/auto_part.dart';
import '../queries/part_query.dart';
import '../utils/page_result.dart';
import 'part_repository.dart';

class ApiPartRepository implements PartRepository {
  ApiPartRepository(Dio dio)
      : _dio = dio,
        _api = ApiResource<AutoPart>(
          dio: dio,
          path: '/parts',
          fromJson: AutoPart.fromJson,
        );

  final Dio _dio;
  final ApiResource<AutoPart> _api;

  Map<String, dynamic> _query(PartQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.categoryId != null) 'categoryId': query.categoryId,
        if (query.brandId != null) 'brandId': query.brandId,
        if (query.carModelId != null) 'carModelId': query.carModelId,
        if (query.yearFrom != null) 'yearFrom': query.yearFrom,
        if (query.yearTo != null) 'yearTo': query.yearTo,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': true,
      };

  Map<String, dynamic> _body(AutoPart part) => {
        'name': part.name,
        'sku': part.sku,
        'year': part.year,
        'price': part.price,
        'brandId': part.brandId,
        'categoryIds': part.categoryIds,
        'carModelIds': part.carModelIds,
        'stockTotal': part.stockTotal,
        'stockAvailable': part.stockAvailable,
      };

  @override
  Future<PageResult<AutoPart>> find(PartQuery query) => _api.find(_query(query));

  @override
  Future<List<AutoPart>> getAll({bool includeDeleted = false}) =>
      _api.getAll(includeDeleted: includeDeleted);

  @override
  Future<AutoPart?> findById(int id) => _api.findById(id);

  @override
  Future<AutoPart> create(AutoPart part) => _api.create(_body(part));

  @override
  Future<AutoPart> update(AutoPart part) => _api.update(part.id, _body(part));

  @override
  Future<void> softDelete(int id) => _api.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _api.hardDelete(id);

  @override
  Future<void> restore(int id) => _api.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _api.deleteMany(ids);

  @override
  Future<bool> skuExists(String sku, {int? exceptId}) async {
    final page = await _api.find({
      'search': sku.trim(),
      'size': 100,
      'page': 1,
    });
    final needle = sku.trim().toLowerCase();
    return page.items.any((item) => item.sku.toLowerCase() == needle && item.id != exceptId);
  }

  @override
  Future<int> countByBrand(int brandId) async {
    final page = await _api.find({
      'brandId': brandId,
      'size': 1,
      'page': 1,
      'includeDeleted': true,
    });
    return page.total;
  }

  @override
  Future<AutoPart> sell(int id, {int quantity = 1}) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/parts/$id/sell',
        data: {'quantity': quantity},
      );
      return AutoPart.fromJson(asJsonMap(response.data));
    });
  }
}
