import '../models/auto_part.dart';
import '../queries/part_query.dart';
import 'crud.dart';

abstract interface class PartRepository implements CrudRepository<AutoPart, PartQuery> {
  Future<List<AutoPart>> getAll({bool includeDeleted = false});
  Future<AutoPart> create(AutoPart part);
  Future<AutoPart> update(AutoPart part);
  Future<bool> skuExists(String sku, {int? exceptId});
  Future<int> countByBrand(int brandId);
  Future<AutoPart> sell(int id, {int quantity = 1});
}
