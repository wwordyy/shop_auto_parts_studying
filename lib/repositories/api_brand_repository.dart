import 'package:dio/dio.dart';

import '../core/api_support.dart';
import '../models/brand.dart';
import '../queries/brand_query.dart';
import '../utils/page_result.dart';
import 'brand_repository.dart';

class ApiBrandRepository implements BrandRepository {
  ApiBrandRepository(Dio dio)
      : _api = ApiResource<Brand>(
          dio: dio,
          path: '/brands',
          fromJson: Brand.fromJson,
        );

  final ApiResource<Brand> _api;

  Map<String, dynamic> _query(BrandQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.country != null && query.country!.isNotEmpty) 'country': query.country,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': true,
      };

  Map<String, dynamic> _body(Brand brand) => {
        'name': brand.name,
        'country': brand.country,
        'foundedYear': brand.foundedYear,
      };

  @override
  Future<PageResult<Brand>> find(BrandQuery query) => _api.find(_query(query));

  @override
  Future<List<Brand>> getAll({bool includeDeleted = false}) =>
      _api.getAll(includeDeleted: includeDeleted);

  @override
  Future<Brand?> findById(int id) => _api.findById(id);

  @override
  Future<Brand> create(Brand brand) => _api.create(_body(brand));

  @override
  Future<Brand> update(Brand brand) => _api.update(brand.id, _body(brand));

  @override
  Future<void> softDelete(int id) => _api.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _api.hardDelete(id);

  @override
  Future<void> restore(int id) => _api.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _api.deleteMany(ids);
}
