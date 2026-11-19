import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../domain/order_pricing.dart';
import '../models/auto_part.dart';
import '../models/customer.dart';
import '../models/shop_order.dart';
import '../repositories/customer_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/part_repository.dart';
import '../state/auth_notifier.dart';
import '../state/list_notifier.dart';
import '../utils/load_status.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_form.dart';
import '../widgets/load_state_view.dart';

class OrderFormScreen extends StatefulWidget {
  final int? id;

  const OrderFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _customerId;
  String _status = 'new';
  final List<OrderItem> _items = [];
  List<Customer> _customers = [];
  List<AutoPart> _parts = [];
  LoadStatus _statusLoad = LoadStatus.loading;
  String? _error;
  bool _dirty = false;
  bool _saving = false;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthNotifier>();
      final partRepo = context.read<PartRepository>();
      final customerRepo = context.read<CustomerRepository>();
      final orderRepo = context.read<OrderRepository>();
      _parts = await partRepo.getAll();
      if (auth.permissions.canMutate) {
        _customers = await customerRepo.getAll();
      } else {
        _customerId = auth.user?.customerId;
        if (_customerId != null) {
          final mine = await customerRepo.findById(_customerId!);
          if (mine != null) _customers = [mine];
        }
      }
      if (widget.isEditing) {
        final order = await orderRepo.findById(widget.id!);
        if (!mounted) return;
        if (order == null) {
          setState(() {
            _statusLoad = LoadStatus.error;
            _error = 'Заказ не найден';
          });
          return;
        }
        _customerId = order.customerId;
        _status = order.status;
        _items
          ..clear()
          ..addAll(order.items);
      }
      setState(() => _statusLoad = LoadStatus.success);
    } catch (e) {
      setState(() {
        _statusLoad = LoadStatus.error;
        _error = '$e';
      });
    }
  }

  int get _discount {
    for (final customer in _customers) {
      if (customer.id == _customerId) {
        return customer.card.active ? customer.card.discountPercent : 0;
      }
    }
    return 0;
  }

  int get _subtotal => OrderPricing.subtotal(_items.map((item) => item.asLine));

  int get _total =>
      OrderPricing.total(subtotal: _subtotal, discountPercent: _discount);

  void _addLine() {
    final part = _parts.isEmpty ? null : _parts.first;
    if (part == null) return;
    setState(() {
      _dirty = true;
      _items.add(OrderItem(
        partId: part.id,
        name: part.name,
        sku: part.sku,
        quantity: 1,
        unitPrice: part.price,
      ));
    });
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_items.isEmpty) {
      setState(
          () => _serverErrors = {'items': 'Добавьте хотя бы одну позицию'});
      return;
    }
    final order = ShopOrder(
      id: widget.id ?? 0,
      customerId: _customerId ?? 0,
      status: _status,
      items: List.of(_items),
    );
    final repo = context.read<OrderRepository>();
    final notifier = context.read<OrderListNotifier>();
    setState(() => _saving = true);
    try {
      widget.isEditing ? await repo.update(order) : await repo.create(order);
      if (!mounted) return;
      await notifier.load();
      if (!mounted) return;
      context.go('/orders');
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
    final canPickCustomer = context.watch<AuthNotifier>().permissions.canMutate;
    return LoadStateView(
      status: _statusLoad,
      error: _error,
      onRetry: _load,
      child: EntityFormScaffold(
        title: widget.isEditing ? 'Изменить заказ' : 'Новый заказ',
        fallbackPath: '/orders',
        formKey: _formKey,
        isDirty: _dirty,
        saving: _saving,
        onSave: _save,
        fields: [
          if (canPickCustomer)
            FieldSpec.dropdown(
              label: 'Клиент',
              value: _customerId,
              items: [
                for (final customer in _customers)
                  DropdownMenuItem(
                      value: customer.id, child: Text(customer.fullName)),
              ],
              onChanged: (value) => setState(() {
                _customerId = value;
                _dirty = true;
              }),
              validator: (value) => value == null
                  ? 'Выберите клиента'
                  : _serverErrors['customerId'],
            ),
          if (canPickCustomer)
            FieldSpec.dropdown(
              label: 'Статус',
              value: ['new', 'paid', 'cancelled'].indexOf(_status),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Новый')),
                DropdownMenuItem(value: 1, child: Text('Оплачен')),
                DropdownMenuItem(value: 2, child: Text('Отменён')),
              ],
              onChanged: (value) {
                const statuses = ['new', 'paid', 'cancelled'];
                if (value == null) return;
                setState(() {
                  _status = statuses[value];
                  _dirty = true;
                });
              },
            ),
        ],
        extra: [
          const SizedBox(height: 8),
          Text('Позиции', style: Theme.of(context).textTheme.titleMedium),
          if (_serverErrors['items'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _serverErrors['items']!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          for (var i = 0; i < _items.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _parts.any((p) => p.id == _items[i].partId)
                          ? _items[i].partId
                          : null,
                      items: [
                        for (final part in _parts)
                          DropdownMenuItem(
                            value: part.id,
                            child: Text('${part.name} · ${part.price} ₽'),
                          ),
                      ],
                      onChanged: (value) {
                        final matched = [
                          for (final item in _parts)
                            if (item.id == value) item
                        ];
                        if (matched.isEmpty) return;
                        final part = matched.first;
                        setState(() {
                          _items[i] = OrderItem(
                            partId: part.id,
                            name: part.name,
                            sku: part.sku,
                            quantity: _items[i].quantity,
                            unitPrice: part.price,
                          );
                          _dirty = true;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Запчасть',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: '${_items[i].quantity}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Кол-во',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final qty = int.tryParse(value) ?? 1;
                              setState(() {
                                _items[i] = OrderItem(
                                  partId: _items[i].partId,
                                  name: _items[i].name,
                                  sku: _items[i].sku,
                                  quantity: qty < 1 ? 1 : qty,
                                  unitPrice: _items[i].unitPrice,
                                );
                                _dirty = true;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Удалить позицию',
                          onPressed: () => setState(() {
                            _items.removeAt(i);
                            _dirty = true;
                          }),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addLine,
            icon: const Icon(Icons.add),
            label: const Text('Добавить позицию'),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Расчёт с картой лояльности',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'Сумма позиций умножается на (100 − скидка активной карты) / 100. Скидка не больше 50%. Если на складе меньше выбранного количества, сервер вернёт 409 и заказ не сохранится.'),
                  const SizedBox(height: 12),
                  Text('Сумма позиций: $_subtotal ₽'),
                  Text('Скидка карты: $_discount%'),
                  Text('К оплате: $_total ₽',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
