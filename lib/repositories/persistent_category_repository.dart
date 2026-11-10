import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/category.dart';
import '../queries/category_query.dart';
import '../utils/page_result.dart';
import '../storage/local_collection.dart';
import '../storage/storage_status.dart';
import 'category_repository.dart';

class PersistentCategoryRepository implements CategoryRepository {
  PersistentCategoryRepository(SharedPreferences prefs, [StorageStatus? status])
      : _store = LocalCollection<Category>(
          prefs: prefs,
          key: 'categories_v1',
          seed: seedCategories,
          fromJson: Category.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.id,
          isDeleted: (item) => item.isDeleted,
          copyDeleted: (item, {deletedAt, clearDeletedAt = false}) =>
              item.copyWith(deletedAt: deletedAt, clearDeletedAt: clearDeletedAt),
          status: status,
        );

  final LocalCollection<Category> _store;

  @override
  Future<PageResult<Category>> find(CategoryQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    var rows = _store.visible(includeDeleted: query.includeDeleted);
    if (query.search.trim().isNotEmpty) {
      final needle = query.search.trim().toLowerCase();
      rows = rows
          .where((item) =>
              item.name.toLowerCase().contains(needle) ||
              item.description.toLowerCase().contains(needle))
          .toList();
    }
    rows.sort((a, b) {
      final result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return query.sortAscending ? result : -result;
    });
    return PageResult.fromList(rows, page: query.page, size: query.size);
  }

  @override
  Future<List<Category>> getAll({bool includeDeleted = false}) async =>
      _store.visible(includeDeleted: includeDeleted);

  @override
  Future<Category?> findById(int id) async => _store.byId(id);

  @override
  Future<Category> create(Category category) => _store.add(category.copyWith(id: _store.nextId));

  @override
  Future<Category> update(Category category) =>
      _store.replace(category.id, (current) => category.copyWith(deletedAt: current.deletedAt));

  @override
  Future<void> softDelete(int id) => _store.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _store.removeId(id);

  @override
  Future<void> restore(int id) => _store.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _store.deleteMany(ids);
}
