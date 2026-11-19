import '../models/supplier.dart';
import '../queries/supplier_query.dart';
import 'crud.dart';

abstract interface class SupplierRepository
    implements CrudRepository<Supplier, SupplierQuery> {
  Future<List<Supplier>> getAll({bool includeDeleted = false});
  Future<Supplier> create(Supplier supplier);
  Future<Supplier> update(Supplier supplier);
}
