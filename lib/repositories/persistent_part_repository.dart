import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/auto_part.dart';
import '../utils/page_result.dart';
import '../queries/part_query.dart';
import '../storage/local_collection.dart';
import '../storage/storage_status.dart';
import 'part_repository.dart';

class PersistentPartRepository implements PartRepository {
  PersistentPartRepository(SharedPreferences prefs, [StorageStatus? status])
      : _store = LocalCollection<AutoPart>(
          prefs: prefs,
          key: 'parts_v1',
          seed: seedParts,
          fromJson: AutoPart.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.id,
          isDeleted: (item) => item.isDeleted,
          copyDeleted: (item, {deletedAt, clearDeletedAt = false}) =>
              item.copyWith(deletedAt: deletedAt, clearDeletedAt: clearDeletedAt),
          status: status,
        );

  final LocalCollection<AutoPart> _store;

  @override
  Future<PageResult<AutoPart>> find(PartQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    var rows = _store.visible(includeDeleted: query.includeDeleted);
    if (query.search.trim().isNotEmpty) {
      final needle = query.search.trim().toLowerCase();
      rows = rows
          .where((part) =>
              part.name.toLowerCase().contains(needle) || part.sku.toLowerCase().contains(needle))
          .toList();
    }
    if (query.categoryId != null) {
      rows = rows.where((part) => part.categoryIds.contains(query.categoryId)).toList();
    }
    if (query.brandId != null) {
      rows = rows.where((part) => part.brandId == query.brandId).toList();
    }
    if (query.carModelId != null) {
      rows = rows.where((part) => part.carModelIds.contains(query.carModelId)).toList();
    }
    if (query.yearFrom != null) {
      rows = rows.where((part) => part.year >= query.yearFrom!).toList();
    }
    if (query.yearTo != null) {
      rows = rows.where((part) => part.year <= query.yearTo!).toList();
    }
    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'year' => a.year.compareTo(b.year),
        'price' => a.price.compareTo(b.price),
        'sku' => a.sku.toLowerCase().compareTo(b.sku.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return query.sortAscending ? result : -result;
    });
    return PageResult.fromList(rows, page: query.page, size: query.size);
  }

  @override
  Future<List<AutoPart>> getAll({bool includeDeleted = false}) async =>
      _store.visible(includeDeleted: includeDeleted);

  @override
  Future<AutoPart?> findById(int id) async => _store.byId(id);

  @override
  Future<AutoPart> create(AutoPart part) => _store.add(part.copyWith(id: _store.nextId));

  @override
  Future<AutoPart> update(AutoPart part) =>
      _store.replace(part.id, (current) => part.copyWith(deletedAt: current.deletedAt));

  @override
  Future<void> softDelete(int id) => _store.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _store.removeId(id);

  @override
  Future<void> restore(int id) => _store.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _store.deleteMany(ids);

  @override
  Future<bool> skuExists(String sku, {int? exceptId}) async {
    final needle = sku.trim().toLowerCase();
    return _store.items.any((part) => part.sku.toLowerCase() == needle && part.id != exceptId);
  }

  @override
  Future<int> countByBrand(int brandId) async {
    return _store.items.where((part) => part.brandId == brandId).length;
  }

  @override
  Future<AutoPart> sell(int id, {int quantity = 1}) {
    return _store.replace(id, (current) {
      if (current.stockAvailable < quantity) {
        throw StateError('Нет доступного остатка для продажи');
      }
      return current.copyWith(stockAvailable: current.stockAvailable - quantity);
    });
  }
}
