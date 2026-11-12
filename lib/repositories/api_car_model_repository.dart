import 'package:dio/dio.dart';

import '../core/api_support.dart';
import '../models/car_model.dart';
import '../queries/car_model_query.dart';
import '../utils/page_result.dart';
import 'car_model_repository.dart';

class ApiCarModelRepository implements CarModelRepository {
  ApiCarModelRepository(Dio dio)
      : _api = ApiResource<CarModel>(
          dio: dio,
          path: '/cars',
          fromJson: CarModel.fromJson,
        );

  final ApiResource<CarModel> _api;

  Map<String, dynamic> _query(CarModelQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.maker != null && query.maker!.isNotEmpty) 'maker': query.maker,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': true,
      };

  Map<String, dynamic> _body(CarModel model) => {
        'name': model.name,
        'maker': model.maker,
        'yearFrom': model.yearFrom,
        'yearTo': model.yearTo,
      };

  @override
  Future<PageResult<CarModel>> find(CarModelQuery query) => _api.find(_query(query));

  @override
  Future<List<CarModel>> getAll({bool includeDeleted = false}) =>
      _api.getAll(includeDeleted: includeDeleted);

  @override
  Future<CarModel?> findById(int id) => _api.findById(id);

  @override
  Future<CarModel> create(CarModel model) => _api.create(_body(model));

  @override
  Future<CarModel> update(CarModel model) => _api.update(model.id, _body(model));

  @override
  Future<void> softDelete(int id) => _api.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _api.hardDelete(id);

  @override
  Future<void> restore(int id) => _api.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _api.deleteMany(ids);
}
