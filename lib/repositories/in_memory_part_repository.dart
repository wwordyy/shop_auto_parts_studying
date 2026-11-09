import '../data/seed_data.dart';
import '../models/auto_part.dart';
import '../models/page_result.dart';
import '../models/part_query.dart';
import 'part_repository.dart';

class InMemoryPartRepository implements PartRepository {
  final List<AutoPart> _parts = [...seedParts];

  @override
  Future<PageResult<AutoPart>> find(PartQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows = _parts.where((p) => q.includeDeleted || !p.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((p) =>
              p.name.toLowerCase().contains(needle) ||
              p.sku.toLowerCase().contains(needle))
          .toList();
    }
    if (q.categoryId != null) {
      rows = rows.where((p) => p.categoryId == q.categoryId).toList();
    }
    if (q.brandId != null) {
      rows = rows.where((p) => p.brandId == q.brandId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((p) => p.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((p) => p.year <= q.yearTo!).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'price' => a.price.compareTo(b.price),
        'sku' => a.sku.toLowerCase().compareTo(b.sku.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : from + q.size;
    final items = from >= total ? <AutoPart>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<AutoPart?> findById(int id) async {
    for (final part in _parts) {
      if (part.id == id) return part;
    }
    return null;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _parts.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Запчасть $id не найдена');
    _parts[i] = _parts[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _parts.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _parts.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Запчасть $id не найдена');
    _parts[i] = _parts[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _parts.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _parts[i] = _parts[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
