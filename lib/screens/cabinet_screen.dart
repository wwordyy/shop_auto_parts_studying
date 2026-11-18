import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layout/app_layout.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import '../state/auth_notifier.dart';
import '../utils/load_status.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/load_state_view.dart';

class CabinetScreen extends StatefulWidget {
  const CabinetScreen({super.key});

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  Customer? _customer;

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
      final auth = context.read<AuthNotifier>();
      final customerId = auth.user?.customerId;
      Customer? customer;
      if (customerId != null) {
        customer =
            await context.read<CustomerRepository>().findById(customerId);
      }
      if (!mounted) return;
      setState(() {
        _customer = customer;
        _status = LoadStatus.success;
      });
    } catch (error) {
      setState(() {
        _status = LoadStatus.error;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    final customer = _customer;
    return LoadStateView(
      status: _status,
      error: _error,
      onRetry: _load,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Личный кабинет',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                  'Раздел только для покупателя: свои данные и карта лояльности.'),
              const SizedBox(height: 16),
              ListTile(
                  title: const Text('Логин'),
                  subtitle: Text(user?.username ?? '—')),
              ListTile(
                  title: const Text('Имя'),
                  subtitle: Text(user?.displayName ?? '—')),
              ListTile(
                  title: const Text('Email'),
                  subtitle:
                      Text(user?.email.isEmpty ?? true ? '—' : user!.email)),
              const Divider(),
              if (customer == null)
                const ListTile(
                  title: Text('Карта лояльности'),
                  subtitle: Text('К аккаунту пока не привязана карта клиента.'),
                )
              else ...[
                ListTile(
                    title: const Text('Клиент'),
                    subtitle: Text(customer.fullName)),
                ListTile(
                    title: const Text('Телефон'),
                    subtitle: Text(customer.phone)),
                ListTile(
                    title: const Text('Номер карты'),
                    subtitle: Text(customer.card.number)),
                ListTile(
                    title: const Text('Скидка'),
                    subtitle: Text('${customer.card.discountPercent}%')),
                ListTile(
                  title: const Text('Дата выдачи'),
                  subtitle: Text(formatDate(customer.card.issuedAt)),
                ),
                ListTile(
                  title: const Text('Статус карты'),
                  subtitle:
                      Text(customer.card.active ? 'активна' : 'неактивна'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
