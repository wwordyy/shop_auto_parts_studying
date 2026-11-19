import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/customer.dart';
import '../repositories/card_repository.dart';
import '../repositories/customer_repository.dart';
import '../state/list_notifier.dart';
import '../utils/load_status.dart';
import '../validation/validators.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_form.dart';
import '../widgets/load_state_view.dart';

class CardFormScreen extends StatefulWidget {
  final int? id;

  const CardFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _discount = TextEditingController(text: '5');
  int? _customerId;
  DateTime _issuedAt = DateTime.now();
  bool _active = true;
  List<Customer> _customers = [];
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
    _number.dispose();
    _discount.dispose();
    super.dispose();
  }

  void _markDirty([Object? _]) => setState(() => _dirty = true);

  Future<void> _load() async {
    try {
      final customerRepo = context.read<CustomerRepository>();
      final cardRepo = context.read<CardRepository>();
      _customers = await customerRepo.getAll();
      if (widget.isEditing) {
        final card = await cardRepo.findById(widget.id!);
        if (!mounted) return;
        if (card == null) {
          setState(() {
            _status = LoadStatus.error;
            _error = 'Карта не найдена';
          });
          return;
        }
        _customerId = card.customerId;
        _number.text = card.number;
        _discount.text = '${card.discountPercent}';
        _issuedAt = card.issuedAt;
        _active = card.active;
      }
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
    final card = LoyaltyCard(
      id: widget.id ?? 0,
      customerId: _customerId ?? 0,
      number: _number.text.trim(),
      issuedAt: _issuedAt,
      discountPercent: int.parse(_discount.text.trim()),
      active: _active,
    );
    final repo = context.read<CardRepository>();
    final notifier = context.read<CardListNotifier>();
    setState(() => _saving = true);
    try {
      widget.isEditing ? await repo.update(card) : await repo.create(card);
      if (!mounted) return;
      await notifier.load();
      if (!mounted) return;
      context.go('/cards');
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
        title: widget.isEditing ? 'Изменить карту' : 'Новая карта лояльности',
        fallbackPath: '/cards',
        formKey: _formKey,
        isDirty: _dirty,
        saving: _saving,
        onSave: _save,
        fields: [
          FieldSpec.dropdown(
            label: 'Клиент',
            value: _customerId,
            items: [
              for (final customer in _customers)
                DropdownMenuItem(
                    value: customer.id, child: Text(customer.fullName)),
            ],
            onChanged: (value) {
              setState(() => _customerId = value);
              _markDirty();
            },
            validator: (value) => value == null
                ? 'Выберите клиента'
                : _serverErrors['customerId'],
          ),
          FieldSpec.text(
            label: 'Номер карты',
            controller: _number,
            validator: (value) =>
                Validators.name(value, label: 'Номер', max: 20) ??
                _serverErrors['number'],
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Скидка, %',
            controller: _discount,
            keyboardType: TextInputType.number,
            validator: (value) =>
                Validators.range(value, min: 0, max: 50, label: 'Скидка') ??
                _serverErrors['discountPercent'],
            onChanged: _markDirty,
          ),
          FieldSpec.date(
            label: 'Дата выдачи',
            value: _issuedAt,
            onChanged: (value) {
              setState(() => _issuedAt = value);
              _markDirty();
            },
          ),
          FieldSpec.toggle(
            label: 'Карта активна',
            value: _active,
            onChanged: (value) {
              setState(() => _active = value);
              _markDirty();
            },
          ),
        ],
      ),
    );
  }
}
