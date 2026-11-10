import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/auto_part.dart';
import '../models/brand.dart';
import '../models/car_model.dart';
import '../models/category.dart';
import '../repositories/brand_repository.dart';
import '../repositories/car_model_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/part_repository.dart';
import '../state/list_notifier.dart';
import '../validation/validators.dart';
import '../utils/load_status.dart';
import '../widgets/entity_form.dart';
import '../widgets/load_state_view.dart';

class PartFormScreen extends StatefulWidget {
  final int? id;

  const PartFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<PartFormScreen> createState() => _PartFormScreenState();
}

class _PartFormScreenState extends State<PartFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _year = TextEditingController();
  final _price = TextEditingController();
  final _stockTotal = TextEditingController();
  final _stockAvailable = TextEditingController();

  LoadStatus _status = LoadStatus.loading;
  String? _error;
  bool _dirty = false;
  bool _saving = false;
  String? _skuError;
  int? _brandId;
  List<int> _categoryIds = [];
  List<int> _carModelIds = [];
  List<Brand> _brands = [];
  List<Category> _categories = [];
  List<CarModel> _cars = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _year.dispose();
    _price.dispose();
    _stockTotal.dispose();
    _stockAvailable.dispose();
    super.dispose();
  }

  void _markDirty([String? _]) => setState(() => _dirty = true);

  Future<void> _load() async {
    try {
      final brandRepo = context.read<BrandRepository>();
      final categoryRepo = context.read<CategoryRepository>();
      final carRepo = context.read<CarModelRepository>();
      final partRepo = context.read<PartRepository>();
      final brands = await brandRepo.getAll();
      final categories = await categoryRepo.getAll();
      final cars = await carRepo.getAll();
      AutoPart? part;
      if (widget.isEditing) {
        part = await partRepo.findById(widget.id!);
      }
      if (!mounted) return;
      if (widget.isEditing && part == null) {
        setState(() {
          _status = LoadStatus.error;
          _error = 'Запчасть не найдена';
        });
        return;
      }
      if (part != null) {
        _name.text = part.name;
        _sku.text = part.sku;
        _year.text = '${part.year}';
        _price.text = '${part.price}';
        _stockTotal.text = '${part.stockTotal}';
        _stockAvailable.text = '${part.stockAvailable}';
        _brandId = part.brandId;
        _categoryIds = [...part.categoryIds];
        _carModelIds = [...part.carModelIds];
      }
      setState(() {
        _brands = brands;
        _categories = categories;
        _cars = cars;
        _status = LoadStatus.success;
      });
    } catch (e) {
      setState(() {
        _status = LoadStatus.error;
        _error = '$e';
      });
    }
  }

  List<Category> get _visibleCategories {
    if (_brandId == null) return _categories;
    final allowed = brandProducedCategories[_brandId] ?? const <int>[];
    if (allowed.isEmpty) return _categories;
    return _categories.where((item) => allowed.contains(item.id)).toList();
  }

  void _onBrandChanged(int? value) {
    final allowed = brandProducedCategories[value] ?? const <int>[];
    setState(() {
      _brandId = value;
      _dirty = true;
      if (allowed.isNotEmpty) {
        _categoryIds = _categoryIds.where(allowed.contains).toList();
      }
    });
  }

  Future<void> _save() async {
    setState(() => _skuError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sku = _sku.text.trim();
    final repo = context.read<PartRepository>();
    final notifier = context.read<PartListNotifier>();
    final exists = await repo.skuExists(sku, exceptId: widget.id);
    if (exists) {
      setState(() => _skuError = 'Артикул уже используется');
      _formKey.currentState?.validate();
      return;
    }
    final year = int.parse(_year.text.trim());
    final price = int.parse(_price.text.trim());
    final stockTotal = int.parse(_stockTotal.text.trim());
    final stockAvailable = int.parse(_stockAvailable.text.trim());
    final part = AutoPart(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      sku: sku,
      year: year,
      price: price,
      brandId: _brandId!,
      categoryIds: _categoryIds,
      carModelIds: _carModelIds,
      stockTotal: stockTotal,
      stockAvailable: stockAvailable,
    );
    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await repo.update(part);
      } else {
        await repo.create(part);
      }
      if (!mounted) return;
      await notifier.load();
      if (!mounted) return;
      context.go('/parts');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    return LoadStateView(
      status: _status,
      error: _error,
      onRetry: _load,
      child: EntityFormScaffold(
        title: widget.isEditing ? 'Изменить запчасть' : 'Новая запчасть',
        fallbackPath: '/parts',
        formKey: _formKey,
        isDirty: _dirty,
        saving: _saving,
        onSave: _save,
        fields: [
          FieldSpec.text(
            label: 'Название',
            controller: _name,
            validator: (value) => Validators.name(value),
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Артикул',
            controller: _sku,
            validator: (value) => Validators.sku(value) ?? _skuError,
            onChanged: (value) {
              _skuError = null;
              _markDirty();
            },
          ),
          FieldSpec.text(
            label: 'Год',
            controller: _year,
            keyboardType: TextInputType.number,
            validator: (value) => Validators.range(value, min: 1980, max: currentYear + 1, label: 'Год'),
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Цена',
            controller: _price,
            keyboardType: TextInputType.number,
            validator: (value) => Validators.positive(value, label: 'Цена'),
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Всего на складе',
            controller: _stockTotal,
            keyboardType: TextInputType.number,
            validator: (value) => Validators.positive(value, label: 'Всего на складе'),
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Доступно',
            controller: _stockAvailable,
            keyboardType: TextInputType.number,
            validator: (value) {
              final base = Validators.nonNegative(value, label: 'Доступно');
              if (base != null) return base;
              final available = int.parse(value!.trim());
              final total = int.tryParse(_stockTotal.text.trim()) ?? 0;
              if (available > total) return 'Доступно не может быть больше общего количества';
              return null;
            },
            onChanged: _markDirty,
          ),
          FieldSpec.dropdown(
            label: 'Бренд',
            value: _brandId,
            items: [
              for (final brand in _brands) DropdownMenuItem(value: brand.id, child: Text(brand.name)),
            ],
            onChanged: _onBrandChanged,
            validator: (value) => value == null ? 'Выберите бренд' : null,
          ),
          FieldSpec.chips(
            label: 'Категории',
            value: _categoryIds,
            options: [for (final item in _visibleCategories) ChipOption(item.id, item.name)],
            onChanged: (value) => setState(() {
              _categoryIds = value;
              _dirty = true;
            }),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Выберите хотя бы одну категорию' : null,
          ),
          FieldSpec.chips(
            label: 'Совместимые автомобили',
            value: _carModelIds,
            options: [for (final item in _cars) ChipOption(item.id, item.title)],
            onChanged: (value) => setState(() {
              _carModelIds = value;
              _dirty = true;
            }),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Выберите хотя бы один автомобиль' : null,
          ),
        ],
      ),
    );
  }
}
