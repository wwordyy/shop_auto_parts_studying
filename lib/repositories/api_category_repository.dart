import 'package:dio/dio.dart';

import '../core/api_support.dart';
import '../models/category.dart';
import '../queries/category_query.dart';
import '../utils/page_result.dart';
import 'category_repository.dart';

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(Dio dio)
      : _api = ApiResource<Category>(
          dio: dio,
          path: '/categories',
          fromJson: Category.fromJson,
        );

  final ApiResource<Category> _api;

  Map<String, dynamic> _query(CategoryQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': true,
      };

  Map<String, dynamic> _body(Category category) => {
        'name': category.name,
        'description': category.description,
      };

  @override
  Future<PageResult<Category>> find(CategoryQuery query) => _api.find(_query(query));

  @override
  Future<List<Category>> getAll({bool includeDeleted = false}) =>
      _api.getAll(includeDeleted: includeDeleted);

  @override
  Future<Category?> findById(int id) => _api.findById(id);

  @override
  Future<Category> create(Category category) => _api.create(_body(category));

  @override
  Future<Category> update(Category category) => _api.update(category.id, _body(category));

  @override
  Future<void> softDelete(int id) => _api.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _api.hardDelete(id);

  @override
  Future<void> restore(int id) => _api.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _api.deleteMany(ids);
}
