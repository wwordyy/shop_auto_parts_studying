import 'package:dio/dio.dart';

import '../core/api_support.dart';
import '../models/customer.dart';
import '../queries/customer_query.dart';
import '../utils/page_result.dart';
import 'customer_repository.dart';

class ApiCustomerRepository implements CustomerRepository {
  ApiCustomerRepository(Dio dio)
      : _api = ApiResource<Customer>(
          dio: dio,
          path: '/customers',
          fromJson: Customer.fromJson,
        );

  final ApiResource<Customer> _api;

  Map<String, dynamic> _query(CustomerQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': true,
      };

  Map<String, dynamic> _body(Customer customer) => {
        'fullName': customer.fullName,
        'email': customer.email,
        'phone': customer.phone,
        'card': customer.card.toJson(),
      };

  @override
  Future<PageResult<Customer>> find(CustomerQuery query) => _api.find(_query(query));

  @override
  Future<List<Customer>> getAll({bool includeDeleted = false}) =>
      _api.getAll(includeDeleted: includeDeleted);

  @override
  Future<Customer?> findById(int id) => _api.findById(id);

  @override
  Future<Customer> create(Customer customer) => _api.create(_body(customer));

  @override
  Future<Customer> update(Customer customer) => _api.update(customer.id, _body(customer));

  @override
  Future<void> softDelete(int id) => _api.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _api.hardDelete(id);

  @override
  Future<void> restore(int id) => _api.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _api.deleteMany(ids);

  @override
  Future<bool> emailExists(String email, {int? exceptId}) async {
    final page = await _api.find({
      'search': email.trim(),
      'size': 100,
      'page': 1,
    });
    final needle = email.trim().toLowerCase();
    return page.items.any((item) => item.email.toLowerCase() == needle && item.id != exceptId);
  }
}
