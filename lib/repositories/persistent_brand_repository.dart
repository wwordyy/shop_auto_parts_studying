import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/brand.dart';
import '../queries/brand_query.dart';
import '../utils/page_result.dart';
import '../storage/local_collection.dart';
import '../storage/storage_status.dart';
import 'brand_repository.dart';

class PersistentBrandRepository implements BrandRepository {
  PersistentBrandRepository(SharedPreferences prefs, [StorageStatus? status])
      : _store = LocalCollection<Brand>(
          prefs: prefs,
          key: 'brands_v1',
          seed: seedBrands,
          fromJson: Brand.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.id,
          isDeleted: (item) => item.isDeleted,
          copyDeleted: (item, {deletedAt, clearDeletedAt = false}) =>
              item.copyWith(deletedAt: deletedAt, clearDeletedAt: clearDeletedAt),
          status: status,
        );

  final LocalCollection<Brand> _store;

  @override
  Future<PageResult<Brand>> find(BrandQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    var rows = _store.visible(includeDeleted: query.includeDeleted);
    if (query.search.trim().isNotEmpty) {
      final needle = query.search.trim().toLowerCase();
      rows = rows
          .where((brand) =>
              brand.name.toLowerCase().contains(needle) ||
              brand.country.toLowerCase().contains(needle))
          .toList();
    }
    if (query.country != null && query.country!.isNotEmpty) {
      rows = rows.where((brand) => brand.country == query.country).toList();
    }
    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'foundedYear' => a.foundedYear.compareTo(b.foundedYear),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return query.sortAscending ? result : -result;
    });
    return PageResult.fromList(rows, page: query.page, size: query.size);
  }

  @override
  Future<List<Brand>> getAll({bool includeDeleted = false}) async =>
      _store.visible(includeDeleted: includeDeleted);

  @override
  Future<Brand?> findById(int id) async => _store.byId(id);

  @override
  Future<Brand> create(Brand brand) => _store.add(brand.copyWith(id: _store.nextId));

  @override
  Future<Brand> update(Brand brand) =>
      _store.replace(brand.id, (current) => brand.copyWith(deletedAt: current.deletedAt));

  @override
  Future<void> softDelete(int id) => _store.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _store.removeId(id);

  @override
  Future<void> restore(int id) => _store.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _store.deleteMany(ids);
}
