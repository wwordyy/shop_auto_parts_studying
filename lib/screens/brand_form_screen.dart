import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../utils/load_status.dart';
import '../repositories/brand_repository.dart';
import '../state/list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import '../widgets/load_state_view.dart';

class BrandFormScreen extends StatefulWidget {
  final int? id;

  const BrandFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends State<BrandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _foundedYear = TextEditingController();
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _country.dispose();
    _foundedYear.dispose();
    super.dispose();
  }

  void _markDirty([String? _]) => setState(() => _dirty = true);

  Future<void> _load() async {
    if (!widget.isEditing) {
      setState(() => _status = LoadStatus.success);
      return;
    }
    try {
      final brand = await context.read<BrandRepository>().findById(widget.id!);
      if (!mounted) return;
      if (brand == null) {
        setState(() {
          _status = LoadStatus.error;
          _error = 'Бренд не найден';
        });
        return;
      }
      _name.text = brand.name;
      _country.text = brand.country;
      _foundedYear.text = '${brand.foundedYear}';
      setState(() => _status = LoadStatus.success);
    } catch (e) {
      setState(() {
        _status = LoadStatus.error;
        _error = '$e';
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final brand = Brand(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      country: _country.text.trim(),
      foundedYear: int.parse(_foundedYear.text.trim()),
    );
    final repo = context.read<BrandRepository>();
    final notifier = context.read<BrandListNotifier>();
    setState(() => _saving = true);
    try {
      widget.isEditing ? await repo.update(brand) : await repo.create(brand);
      if (!mounted) return;
      await notifier.load();
      if (!mounted) return;
      context.go('/brands');
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
        title: widget.isEditing ? 'Изменить бренд' : 'Новый бренд',
        fallbackPath: '/brands',
        formKey: _formKey,
        isDirty: _dirty,
        saving: _saving,
        onSave: _save,
        fields: [
          FieldSpec.text(
            label: 'Название',
            controller: _name,
            validator: (value) => Validators.name(value, label: 'Название'),
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Страна',
            controller: _country,
            validator: (value) => Validators.name(value, label: 'Страна', max: 40),
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Год основания',
            controller: _foundedYear,
            keyboardType: TextInputType.number,
            validator: (value) =>
                Validators.range(value, min: 1800, max: currentYear, label: 'Год основания'),
            onChanged: _markDirty,
          ),
        ],
      ),
    );
  }
}
