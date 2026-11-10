import '../models/customer.dart';
import '../queries/customer_query.dart';
import 'crud.dart';

abstract interface class CustomerRepository implements CrudRepository<Customer, CustomerQuery> {
  Future<List<Customer>> getAll({bool includeDeleted = false});
  Future<Customer> create(Customer customer);
  Future<Customer> update(Customer customer);
  Future<bool> emailExists(String email, {int? exceptId});
}
