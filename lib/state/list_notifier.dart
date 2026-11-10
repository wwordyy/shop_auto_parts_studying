import 'package:flutter/foundation.dart' hide Category;

import '../models/auto_part.dart';
import '../models/brand.dart';
import '../models/car_model.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../queries/brand_query.dart';
import '../queries/car_model_query.dart';
import '../queries/category_query.dart';
import '../queries/customer_query.dart';
import '../queries/part_query.dart';
import '../repositories/crud.dart';
import '../utils/load_status.dart';
import '../utils/page_result.dart';

class ListNotifier<T, Q> extends ChangeNotifier {
  ListNotifier(this._repository, {required int Function(T) idOf, required Q initialQuery})
      : _idOf = idOf,
        _query = initialQuery;

  final CrudRepository<T, Q> _repository;
  final int Function(T) _idOf;
  Q _query;
  PageResult<T> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  Q get query => _query;
  PageResult<T> get result => _result;
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

  Future<void> applyQuery(Q next) async {
    if (next == _query && _status == LoadStatus.success) return;
    _query = next;
    _selected.clear();
    await load();
  }

  Future<T?> findById(int id) => _repository.findById(id);

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void selectAllOnPage(bool select) {
    if (select) {
      _selected.addAll(_result.items.map(_idOf));
    } else {
      for (final item in _result.items) {
        _selected.remove(_idOf(item));
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

class PartListNotifier extends ListNotifier<AutoPart, PartQuery> {
  PartListNotifier(super.repository)
      : super(idOf: (item) => item.id, initialQuery: const PartQuery());
}

class BrandListNotifier extends ListNotifier<Brand, BrandQuery> {
  BrandListNotifier(super.repository)
      : super(idOf: (item) => item.id, initialQuery: const BrandQuery());
}

class CategoryListNotifier extends ListNotifier<Category, CategoryQuery> {
  CategoryListNotifier(super.repository)
      : super(idOf: (item) => item.id, initialQuery: const CategoryQuery());
}

class CarModelListNotifier extends ListNotifier<CarModel, CarModelQuery> {
  CarModelListNotifier(super.repository)
      : super(idOf: (item) => item.id, initialQuery: const CarModelQuery());
}

class CustomerListNotifier extends ListNotifier<Customer, CustomerQuery> {
  CustomerListNotifier(super.repository)
      : super(idOf: (item) => item.id, initialQuery: const CustomerQuery());
}
