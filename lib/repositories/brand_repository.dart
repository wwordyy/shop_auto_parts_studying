import '../models/brand.dart';
import '../queries/brand_query.dart';
import 'crud.dart';

abstract interface class BrandRepository implements CrudRepository<Brand, BrandQuery> {
  Future<List<Brand>> getAll({bool includeDeleted = false});
  Future<Brand> create(Brand brand);
  Future<Brand> update(Brand brand);
}
