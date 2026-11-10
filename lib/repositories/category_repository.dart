import '../models/category.dart';
import '../queries/category_query.dart';
import 'crud.dart';

abstract interface class CategoryRepository implements CrudRepository<Category, CategoryQuery> {
  Future<List<Category>> getAll({bool includeDeleted = false});
  Future<Category> create(Category category);
  Future<Category> update(Category category);
}
