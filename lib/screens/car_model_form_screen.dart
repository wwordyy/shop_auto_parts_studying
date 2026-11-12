import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/car_model.dart';
import '../utils/load_status.dart';
import '../repositories/car_model_repository.dart';
import '../state/list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_form.dart';
import '../widgets/load_state_view.dart';

class CarModelFormScreen extends StatefulWidget {
  final int? id;

  const CarModelFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<CarModelFormScreen> createState() => _CarModelFormScreenState();
}

class _CarModelFormScreenState extends State<CarModelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _maker = TextEditingController();
  final _yearFrom = TextEditingController();
  final _yearTo = TextEditingController();
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  bool _dirty = false;
  bool _saving = false;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _maker.dispose();
    _yearFrom.dispose();
    _yearTo.dispose();
    super.dispose();
  }

  void _markDirty([String? _]) => setState(() => _dirty = true);

  Future<void> _load() async {
    if (!widget.isEditing) {
      setState(() => _status = LoadStatus.success);
      return;
    }
    try {
      final item = await context.read<CarModelRepository>().findById(widget.id!);
      if (!mounted) return;
      if (item == null) {
        setState(() {
          _status = LoadStatus.error;
          _error = 'Автомобиль не найден';
        });
        return;
      }
      _name.text = item.name;
      _maker.text = item.maker;
      _yearFrom.text = '${item.yearFrom}';
      _yearTo.text = '${item.yearTo}';
      setState(() => _status = LoadStatus.success);
    } catch (e) {
      setState(() {
        _status = LoadStatus.error;
        _error = '$e';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final item = CarModel(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      maker: _maker.text.trim(),
      yearFrom: int.parse(_yearFrom.text.trim()),
      yearTo: int.parse(_yearTo.text.trim()),
    );
    final repo = context.read<CarModelRepository>();
    final notifier = context.read<CarModelListNotifier>();
    setState(() => _saving = true);
    try {
      widget.isEditing ? await repo.update(item) : await repo.create(item);
      if (!mounted) return;
      await notifier.load();
      if (!mounted) return;
      context.go('/cars');
    } on ValidationException catch (error) {
      setState(() => _serverErrors = error.errors);
      _formKey.currentState?.validate();
    } on ApiException catch (error) {
      if (mounted) showSnack(context, error.message);
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
        title: widget.isEditing ? 'Изменить автомобиль' : 'Новый автомобиль',
        fallbackPath: '/cars',
        formKey: _formKey,
        isDirty: _dirty,
        saving: _saving,
        onSave: _save,
        fields: [
          FieldSpec.text(
            label: 'Марка',
            controller: _maker,
            validator: (value) =>
                Validators.name(value, label: 'Марка', max: 40) ?? _serverErrors['maker'],
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Модель',
            controller: _name,
            validator: (value) => Validators.name(value, label: 'Модель') ?? _serverErrors['name'],
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Год с',
            controller: _yearFrom,
            keyboardType: TextInputType.number,
            validator: (value) => Validators.range(value, min: 1980, max: currentYear + 1, label: 'Год с'),
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Год по',
            controller: _yearTo,
            keyboardType: TextInputType.number,
            validator: (value) {
              final base = Validators.range(value, min: 1980, max: currentYear + 1, label: 'Год по');
              if (base != null) return base;
              final from = int.tryParse(_yearFrom.text.trim()) ?? 0;
              final to = int.parse(value!.trim());
              if (to < from) return 'Год по не может быть меньше года с';
              return null;
            },
            onChanged: _markDirty,
          ),
        ],
      ),
    );
  }
}
