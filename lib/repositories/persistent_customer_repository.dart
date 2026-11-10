import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/customer.dart';
import '../queries/customer_query.dart';
import '../utils/page_result.dart';
import '../storage/local_collection.dart';
import '../storage/storage_status.dart';
import 'customer_repository.dart';

class PersistentCustomerRepository implements CustomerRepository {
  PersistentCustomerRepository(SharedPreferences prefs, [StorageStatus? status])
      : _store = LocalCollection<Customer>(
          prefs: prefs,
          key: 'customers_v1',
          seed: seedCustomers,
          fromJson: Customer.fromJson,
          toJson: (item) => item.toJson(),
          idOf: (item) => item.id,
          isDeleted: (item) => item.isDeleted,
          copyDeleted: (item, {deletedAt, clearDeletedAt = false}) =>
              item.copyWith(deletedAt: deletedAt, clearDeletedAt: clearDeletedAt),
          status: status,
        );

  final LocalCollection<Customer> _store;

  @override
  Future<PageResult<Customer>> find(CustomerQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    var rows = _store.visible(includeDeleted: query.includeDeleted);
    if (query.search.trim().isNotEmpty) {
      final needle = query.search.trim().toLowerCase();
      rows = rows
          .where((item) =>
              item.fullName.toLowerCase().contains(needle) ||
              item.email.toLowerCase().contains(needle) ||
              item.phone.contains(needle))
          .toList();
    }
    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        'phone' => a.phone.compareTo(b.phone),
        _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
      return query.sortAscending ? result : -result;
    });
    return PageResult.fromList(rows, page: query.page, size: query.size);
  }

  @override
  Future<List<Customer>> getAll({bool includeDeleted = false}) async =>
      _store.visible(includeDeleted: includeDeleted);

  @override
  Future<Customer?> findById(int id) async => _store.byId(id);

  @override
  Future<Customer> create(Customer customer) => _store.add(customer.copyWith(id: _store.nextId));

  @override
  Future<Customer> update(Customer customer) =>
      _store.replace(customer.id, (current) => customer.copyWith(deletedAt: current.deletedAt));

  @override
  Future<void> softDelete(int id) => _store.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _store.removeId(id);

  @override
  Future<void> restore(int id) => _store.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _store.deleteMany(ids);

  @override
  Future<bool> emailExists(String email, {int? exceptId}) async {
    final needle = email.trim().toLowerCase();
    return _store.items.any((item) => item.email.toLowerCase() == needle && item.id != exceptId);
  }
}
