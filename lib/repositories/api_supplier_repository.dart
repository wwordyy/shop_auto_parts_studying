import 'package:dio/dio.dart';

import '../core/api_support.dart';
import '../models/supplier.dart';
import '../queries/supplier_query.dart';
import '../utils/page_result.dart';
import 'supplier_repository.dart';

class ApiSupplierRepository implements SupplierRepository {
  ApiSupplierRepository(Dio dio)
      : _api = ApiResource<Supplier>(
          dio: dio,
          path: '/suppliers',
          fromJson: Supplier.fromJson,
        );

  final ApiResource<Supplier> _api;

  Map<String, dynamic> _query(SupplierQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.country != null && query.country!.isNotEmpty)
          'country': query.country,
        if (query.minRating != null) 'minRating': query.minRating,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': true,
      };

  Map<String, dynamic> _body(Supplier supplier) => {
        'name': supplier.name,
        'country': supplier.country,
        'phone': supplier.phone,
        'email': supplier.email,
        'rating': supplier.rating,
      };

  @override
  Future<PageResult<Supplier>> find(SupplierQuery query) =>
      _api.find(_query(query));

  @override
  Future<List<Supplier>> getAll({bool includeDeleted = false}) =>
      _api.getAll(includeDeleted: includeDeleted);

  @override
  Future<Supplier?> findById(int id) => _api.findById(id);

  @override
  Future<Supplier> create(Supplier supplier) => _api.create(_body(supplier));

  @override
  Future<Supplier> update(Supplier supplier) =>
      _api.update(supplier.id, _body(supplier));

  @override
  Future<void> softDelete(int id) => _api.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _api.hardDelete(id);

  @override
  Future<void> restore(int id) => _api.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _api.deleteMany(ids);
}
