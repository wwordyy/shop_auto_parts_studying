import '../utils/page_result.dart';

abstract interface class CrudRepository<T, Q> {
  Future<PageResult<T>> find(Q query);
  Future<T?> findById(int id);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
