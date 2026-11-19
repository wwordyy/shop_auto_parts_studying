import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/sales_report.dart';
import '../layout/app_layout.dart';
import '../repositories/brand_repository.dart';
import '../repositories/card_repository.dart';
import '../repositories/car_model_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/part_repository.dart';
import '../repositories/supplier_repository.dart';
import '../utils/load_status.dart';
import '../widgets/load_state_view.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  int _parts = 0;
  int _deletedParts = 0;
  int _brands = 0;
  int _categories = 0;
  int _cars = 0;
  int _customers = 0;
  int _cards = 0;
  int _suppliers = 0;
  SalesReport _sales = const SalesReport(
    orderCount: 0,
    paidCount: 0,
    newCount: 0,
    cancelledCount: 0,
    paidSubtotal: 0,
    paidTotal: 0,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final partRepo = context.read<PartRepository>();
      final brandRepo = context.read<BrandRepository>();
      final categoryRepo = context.read<CategoryRepository>();
      final carRepo = context.read<CarModelRepository>();
      final customerRepo = context.read<CustomerRepository>();
      final cardRepo = context.read<CardRepository>();
      final supplierRepo = context.read<SupplierRepository>();
      final orderRepo = context.read<OrderRepository>();
      final parts = await partRepo.getAll();
      final allParts = await partRepo.getAll(includeDeleted: true);
      final brands = await brandRepo.getAll();
      final categories = await categoryRepo.getAll();
      final cars = await carRepo.getAll();
      final customers = await customerRepo.getAll();
      final cards = await cardRepo.getAll();
      final suppliers = await supplierRepo.getAll();
      final orders = await orderRepo.getAll();
      if (!mounted) return;
      setState(() {
        _parts = parts.length;
        _deletedParts = allParts.where((item) => item.isDeleted).length;
        _brands = brands.length;
        _categories = categories.length;
        _cars = cars.length;
        _customers = customers.length;
        _cards = cards.length;
        _suppliers = suppliers.length;
        _sales = SalesReport.fromOrders(orders);
        _status = LoadStatus.success;
      });
    } catch (error) {
      setState(() {
        _status = LoadStatus.error;
        _error = '$error';
      });
    }
  }

  Widget _bar(String label, int value, int max, Color color) {
    final fraction = max <= 0 ? 0.0 : value / max;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label — $value'),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = AppLayout.of(context).statsColumns;
    final cards = [
      _card('Запчасти в каталоге', '$_parts', Icons.build),
      _card('Логически удалённые запчасти', '$_deletedParts',
          Icons.delete_outline),
      _card('Бренды', '$_brands', Icons.factory),
      _card('Категории', '$_categories', Icons.category),
      _card('Автомобили', '$_cars', Icons.directions_car),
      _card('Клиенты', '$_customers', Icons.people),
      _card('Карты лояльности', '$_cards', Icons.loyalty),
      _card('Поставщики', '$_suppliers', Icons.local_shipping),
      _card('Заказы', '${_sales.orderCount}', Icons.receipt_long),
    ];
    final salesCards = [
      _card('Выручка (оплачено)', '${_sales.paidTotal} ₽', Icons.payments),
      _card('Скидки по картам', '${_sales.discountAmount} ₽', Icons.loyalty),
      _card('Средний чек', '${_sales.averagePaidCheck} ₽', Icons.receipt),
    ];
    final maxStatus = [
      _sales.newCount,
      _sales.paidCount,
      _sales.cancelledCount,
    ].fold(0, (a, b) => a > b ? a : b);
    return LoadStateView(
      status: _status,
      error: _error,
      onRetry: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Отчёт по продажам',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
              'Только администратор. Выручка считается по оплаченным заказам: сумма позиций минус скидка активной карты лояльности (не больше 50%). Отменённые заказы в выручку не входят, остаток на складе по ним возвращён.'),
          const SizedBox(height: 16),
          for (var row = 0; row < (salesCards.length / columns).ceil(); row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) const SizedBox(width: 12),
                    Expanded(
                      child: row * columns + col < salesCards.length
                          ? salesCards[row * columns + col]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Заказы по статусам',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _bar('Новые', _sales.newCount, maxStatus,
                      Theme.of(context).colorScheme.primary),
                  _bar('Оплачены', _sales.paidCount, maxStatus,
                      Theme.of(context).colorScheme.tertiary),
                  _bar('Отменены', _sales.cancelledCount, maxStatus,
                      Theme.of(context).colorScheme.error),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Каталог', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (var row = 0; row < (cards.length / columns).ceil(); row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) const SizedBox(width: 12),
                    Expanded(
                      child: row * columns + col < cards.length
                          ? cards[row * columns + col]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
