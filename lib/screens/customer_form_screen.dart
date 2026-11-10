import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../utils/load_status.dart';
import '../repositories/customer_repository.dart';
import '../state/list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import '../widgets/load_state_view.dart';

class CustomerFormScreen extends StatefulWidget {
  final int? id;

  const CustomerFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _cardNumber = TextEditingController();
  final _discount = TextEditingController(text: '5');
  DateTime _issuedAt = DateTime.now();
  bool _cardActive = true;
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  bool _dirty = false;
  bool _saving = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _cardNumber.dispose();
    _discount.dispose();
    super.dispose();
  }

  void _markDirty([String? _]) => setState(() => _dirty = true);

  Future<void> _load() async {
    if (!widget.isEditing) {
      setState(() => _status = LoadStatus.success);
      return;
    }
    try {
      final item = await context.read<CustomerRepository>().findById(widget.id!);
      if (!mounted) return;
      if (item == null) {
        setState(() {
          _status = LoadStatus.error;
          _error = 'Клиент не найден';
        });
        return;
      }
      _fullName.text = item.fullName;
      _email.text = item.email;
      _phone.text = item.phone;
      _cardNumber.text = item.card.number;
      _discount.text = '${item.card.discountPercent}';
      _issuedAt = item.card.issuedAt;
      _cardActive = item.card.active;
      setState(() => _status = LoadStatus.success);
    } catch (e) {
      setState(() {
        _status = LoadStatus.error;
        _error = '$e';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _emailError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final repo = context.read<CustomerRepository>();
    final notifier = context.read<CustomerListNotifier>();
    final exists = await repo.emailExists(email, exceptId: widget.id);
    if (exists) {
      setState(() => _emailError = 'Такой email уже зарегистрирован');
      _formKey.currentState?.validate();
      return;
    }
    final customer = Customer(
      id: widget.id ?? 0,
      fullName: _fullName.text.trim(),
      email: email,
      phone: _phone.text.trim(),
      card: LoyaltyCard(
        number: _cardNumber.text.trim(),
        issuedAt: _issuedAt,
        discountPercent: int.parse(_discount.text.trim()),
        active: _cardActive,
      ),
    );
    setState(() => _saving = true);
    try {
      widget.isEditing ? await repo.update(customer) : await repo.create(customer);
      if (!mounted) return;
      await notifier.load();
      if (!mounted) return;
      context.go('/customers');
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
        title: widget.isEditing ? 'Изменить клиента' : 'Новый клиент',
        fallbackPath: '/customers',
        formKey: _formKey,
        isDirty: _dirty,
        saving: _saving,
        onSave: _save,
        fields: [
          FieldSpec.text(
            label: 'ФИО',
            controller: _fullName,
            validator: (value) => Validators.name(value, label: 'ФИО', max: 80),
            onChanged: _markDirty,
          ),
          FieldSpec.text(
            label: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => Validators.email(value) ?? _emailError,
            onChanged: (_) {
              _emailError = null;
              _markDirty();
            },
          ),
          FieldSpec.text(
            label: 'Телефон',
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
            onChanged: _markDirty,
          ),
          FieldSpec.header('Дисконтная карта'),
          FieldSpec.text(
            label: 'Номер карты',
            controller: _cardNumber,
            validator: (value) =>
                Validators.required(value, label: 'Номер карты') ??
                Validators.maxLength(value, 20, label: 'Номер карты'),
            onChanged: _markDirty,
          ),
          FieldSpec.date(
            label: 'Дата выдачи',
            value: _issuedAt,
            onChanged: (value) => setState(() {
              _issuedAt = value;
              _dirty = true;
            }),
          ),
          FieldSpec.text(
            label: 'Скидка, %',
            controller: _discount,
            keyboardType: TextInputType.number,
            validator: (value) => Validators.range(value, min: 0, max: 50, label: 'Скидка'),
            onChanged: _markDirty,
          ),
          FieldSpec.toggle(
            label: 'Карта активна',
            value: _cardActive,
            onChanged: (value) => setState(() {
              _cardActive = value;
              _dirty = true;
            }),
          ),
        ],
      ),
    );
  }
}
