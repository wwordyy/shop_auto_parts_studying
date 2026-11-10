import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/car_model.dart';
import '../queries/car_model_query.dart';
import '../utils/page_result.dart';
import '../storage/local_collection.dart';
import '../storage/storage_status.dart';
import 'car_model_repository.dart';

class PersistentCarModelRepository implements CarModelRepository {
  PersistentCarModelRepository(SharedPreferences prefs, [StorageStatus? status])
      : _store = LocalCollection<CarModel>(
          prefs: prefs,
          key: 'car_models_v1',
          seed: seedCarModels,
          fromJson: CarModel.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.id,
          isDeleted: (item) => item.isDeleted,
          copyDeleted: (item, {deletedAt, clearDeletedAt = false}) =>
              item.copyWith(deletedAt: deletedAt, clearDeletedAt: clearDeletedAt),
          status: status,
        );

  final LocalCollection<CarModel> _store;

  @override
  Future<PageResult<CarModel>> find(CarModelQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    var rows = _store.visible(includeDeleted: query.includeDeleted);
    if (query.search.trim().isNotEmpty) {
      final needle = query.search.trim().toLowerCase();
      rows = rows
          .where((item) =>
              item.name.toLowerCase().contains(needle) || item.maker.toLowerCase().contains(needle))
          .toList();
    }
    if (query.maker != null && query.maker!.isNotEmpty) {
      rows = rows.where((item) => item.maker == query.maker).toList();
    }
    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'maker' => a.maker.toLowerCase().compareTo(b.maker.toLowerCase()),
        'yearFrom' => a.yearFrom.compareTo(b.yearFrom),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return query.sortAscending ? result : -result;
    });
    return PageResult.fromList(rows, page: query.page, size: query.size);
  }

  @override
  Future<List<CarModel>> getAll({bool includeDeleted = false}) async =>
      _store.visible(includeDeleted: includeDeleted);

  @override
  Future<CarModel?> findById(int id) async => _store.byId(id);

  @override
  Future<CarModel> create(CarModel model) => _store.add(model.copyWith(id: _store.nextId));

  @override
  Future<CarModel> update(CarModel model) =>
      _store.replace(model.id, (current) => model.copyWith(deletedAt: current.deletedAt));

  @override
  Future<void> softDelete(int id) => _store.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _store.removeId(id);

  @override
  Future<void> restore(int id) => _store.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _store.deleteMany(ids);
}
