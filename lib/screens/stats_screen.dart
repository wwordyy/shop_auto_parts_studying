import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layout/app_layout.dart';
import '../repositories/brand_repository.dart';
import '../repositories/car_model_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/part_repository.dart';
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
      final parts = await partRepo.getAll();
      final allParts = await partRepo.getAll(includeDeleted: true);
      final brands = await brandRepo.getAll();
      final categories = await categoryRepo.getAll();
      final cars = await carRepo.getAll();
      final customers = await customerRepo.getAll();
      if (!mounted) return;
      setState(() {
        _parts = parts.length;
        _deletedParts = allParts.where((item) => item.isDeleted).length;
        _brands = brands.length;
        _categories = categories.length;
        _cars = cars.length;
        _customers = customers.length;
        _status = LoadStatus.success;
      });
    } catch (error) {
      setState(() {
        _status = LoadStatus.error;
        _error = '$error';
      });
    }
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
    ];
    return LoadStateView(
      status: _status,
      error: _error,
      onRetry: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Статистика', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
              'Сводка по каталогу. Экран доступен только администратору.'),
          const SizedBox(height: 16),
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
