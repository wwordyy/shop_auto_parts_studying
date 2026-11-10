import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../utils/load_status.dart';
import '../repositories/category_repository.dart';
import '../state/list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import '../widgets/load_state_view.dart';

class CategoryFormScreen extends StatefulWidget {
  final int? id;

  const CategoryFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
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
    _description.dispose();
    super.dispose();
  }

  void _markDirty([String? _]) => setState(() => _dirty = true);

  Future<void> _load() async {
    if (!widget.isEditing) {
      setState(() => _status = LoadStatus.success);
      return;
    }
    try {
      final item = await context.read<CategoryRepository>().findById(widget.id!);
      if (!mounted) return;
      if (item == null) {
        setState(() {
          _status = LoadStatus.error;
          _error = 'Категория не найдена';
        });
        return;
      }
      _name.text = item.name;
      _description.text = item.description;
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
    final item = Category(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      description: _description.text.trim(),
    );
    final repo = context.read<CategoryRepository>();
    final notifier = context.read<CategoryListNotifier>();
    setState(() => _saving = true);
    try {
      widget.isEditing ? await repo.update(item) : await repo.create(item);
      if (!mounted) return;
      await notifier.load();
      if (!mounted) return;
      context.go('/categories');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadStateView(
      status: _status,
      error: _error,
      onRetry: _load,
      child: EntityFormScaffold(
        title: widget.isEditing ? 'Изменить категорию' : 'Новая категория',
        fallbackPath: '/categories',
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
            label: 'Описание',
            controller: _description,
            maxLines: 3,
            validator: (value) => Validators.maxLength(value, 200, label: 'Описание'),
            onChanged: _markDirty,
          ),
        ],
      ),
    );
  }
}
