import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/supplier.dart';
import '../repositories/supplier_repository.dart';
import '../state/list_notifier.dart';
import '../utils/load_status.dart';
import '../validation/validators.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_form.dart';
import '../widgets/load_state_view.dart';

class SupplierFormScreen extends StatefulWidget {
  final int? id;

  const SupplierFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _rating = TextEditingController(text: '3');
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
    _country.dispose();
    _phone.dispose();
    _email.dispose();
    _rating.dispose();
    super.dispose();
  }

  void _markDirty([String? _]) => setState(() => _dirty = true);

  Future<void> _load() async {
    if (!widget.isEditing) {
      setState(() => _status = LoadStatus.success);
      return;
    }
    try {
      final supplier =
          await context.read<SupplierRepository>().findById(widget.id!);
      if (!mounted) return;
      if (supplier == null) {
        setState(() {
          _status = LoadStatus.error;
          _error = 'Поставщик не найден';
        });
        return;
      }
      _name.text = supplier.name;
      _country.text = supplier.country;
      _phone.text = supplier.phone;
      _email.text = supplier.email;
      _rating.text = '${supplier.rating}';
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
    final supplier = Supplier(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      country: _country.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      rating: int.parse(_rating.text.trim()),
    );
    final repo = context.read<SupplierRepository>();
    final notifier = context.read<SupplierListNotifier>();
    setState(() => _saving = true);
    try {
      widget.isEditing
          ? await repo.update(supplier)
          : await repo.create(supplier);
      if (!mounted) return;
      await notifier.load();
      if (!mounted) return;
      context.go('/suppliers');
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
    return LoadStateView(
      status: _status,
      error: _error,
      onRetry: _load,
      child: EntityFormScaffold(
        title: widget.isEditing ? 'Изменить поставщика' : 'Новый поставщик',
        fallbackPath: '/suppliers',
        formKey: _formKey,
        isDirty: _dirty,
        saving: _saving,
        onSave: _save,
        fields: [
          FieldSpec.text(
            label: 'Название',
            controller: _name,
            validator: (value) =>
                Validators.name(value, label: 'Название') ??
                _serverErrors['name'],
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Страна',
            controller: _country,
            validator: (value) =>
                Validators.name(value, label: 'Страна', max: 40) ??
                _serverErrors['country'],
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Телефон',
            controller: _phone,
            validator: (value) =>
                Validators.phone(value) ?? _serverErrors['phone'],
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Email',
            controller: _email,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              return Validators.email(value) ?? _serverErrors['email'];
            },
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Рейтинг',
            controller: _rating,
            keyboardType: TextInputType.number,
            validator: (value) =>
                Validators.range(value, min: 1, max: 5, label: 'Рейтинг') ??
                _serverErrors['rating'],
            onChanged: _markDirty,
          ),
        ],
      ),
    );
  }
}
