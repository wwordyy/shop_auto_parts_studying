import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/loyalty_card.dart';
import '../state/auth_notifier.dart';
import '../state/list_notifier.dart';
import '../utils/load_status.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_detail.dart';
import '../widgets/load_state_view.dart';

class CardDetailScreen extends StatefulWidget {
  final int id;

  const CardDetailScreen({super.key, required this.id});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  LoyaltyCard? _card;

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
      final card = await context.read<CardListNotifier>().findById(widget.id);
      setState(() {
        _card = card;
        _status = card == null ? LoadStatus.error : LoadStatus.success;
        _error = card == null ? 'Карта не найдена' : null;
      });
    } catch (e) {
      setState(() {
        _status = LoadStatus.error;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final notifier = context.read<CardListNotifier>();
    final perms = context.watch<AuthNotifier>().permissions;
    return LoadStateView(
      status: _status,
      error: _error,
      isEmpty: card == null,
      emptyTitle: 'Карта не найдена',
      onRetry: _load,
      child: card == null
          ? const SizedBox.shrink()
          : EntityDetail(
              title: card.number,
              fallbackPath: '/cards',
              isDeleted: card.isDeleted,
              showEdit: perms.canMutate,
              showDelete: perms.canSoftDelete,
              showRestore: perms.canRestore,
              allowHardDelete: perms.canHardDelete,
              onEdit: () => context.go('/cards/${card.id}/edit'),
              onRestored: () async {
                await runMutation(context, () async {
                  await notifier.restore(card.id);
                  await _load();
                });
              },
              onDeleted: (hard) async {
                await runMutation(context, () async {
                  if (hard) {
                    await notifier.hardDelete(card.id);
                    if (context.mounted) context.go('/cards');
                  } else {
                    await notifier.softDelete(card.id);
                    await _load();
                  }
                });
              },
              fields: [
                ListTile(
                    title: const Text('Клиент'),
                    subtitle: Text(card.customerName)),
                ListTile(
                    title: const Text('Скидка'),
                    subtitle: Text('${card.discountPercent}%')),
                ListTile(
                    title: const Text('Активна'),
                    subtitle: Text(card.active ? 'да' : 'нет')),
                ListTile(
                    title: const Text('Выдана'),
                    subtitle: Text(
                        card.issuedAt.toLocal().toString().split(' ').first)),
              ],
            ),
    );
  }
}
