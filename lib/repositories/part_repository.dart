import '../models/auto_part.dart';
import '../models/page_result.dart';
import '../models/part_query.dart';

abstract interface class PartRepository {
  Future<PageResult<AutoPart>> find(PartQuery query);
  Future<AutoPart?> findById(int id);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
