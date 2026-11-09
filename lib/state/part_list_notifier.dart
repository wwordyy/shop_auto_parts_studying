import 'package:flutter/foundation.dart';

import '../models/auto_part.dart';
import '../models/load_status.dart';
import '../models/page_result.dart';
import '../models/part_query.dart';
import '../repositories/part_repository.dart';

class PartListNotifier extends ChangeNotifier {
  PartListNotifier(this._repository);

  final PartRepository _repository;
  PartQuery _query = const PartQuery();
  PageResult<AutoPart> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  PartQuery get query => _query;
  PageResult<AutoPart> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(PartQuery next) async {
    if (next == _query && _status == LoadStatus.success) return;
    _query = next;
    _selected.clear();
    await load();
  }

  Future<AutoPart?> findById(int id) => _repository.findById(id);

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void selectAllOnPage(bool select) {
    if (select) {
      _selected.addAll(_result.items.map((p) => p.id));
    } else {
      for (final part in _result.items) {
        _selected.remove(part.id);
      }
    }
    notifyListeners();
  }

  Future<void> deleteSelected({required bool hard}) async {
    final ids = _selected.toList();
    if (hard) {
      for (final id in ids) {
        await _repository.hardDelete(id);
      }
    } else {
      await _repository.deleteMany(ids);
    }
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }
}
