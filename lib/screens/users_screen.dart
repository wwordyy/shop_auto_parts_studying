import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth_api.dart';
import '../models/app_user.dart';
import '../utils/load_status.dart';
import '../utils/page_result.dart';
import '../widgets/entity_table.dart';
import '../widgets/load_state_view.dart';
import '../widgets/pagination_bar.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  int _page = 1;
  PageResult<AppUser> _result = PageResult.empty();

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
      final result = await context.read<AuthApi>().users(page: _page);
      if (!mounted) return;
      setState(() {
        _result = result;
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Пользователи', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Раздел только для администратора: учётные записи и роли.'),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LoadStateView(
              status: _status,
              error: _error,
              isEmpty: _result.items.isEmpty,
              onRetry: _load,
              child: EntityTable<AppUser>(
                items: _result.items,
                idOf: (item) => item.id,
                columns: [
                  TableColumnSpec(label: 'Логин', build: (item) => Text(item.username)),
                  TableColumnSpec(label: 'Имя', build: (item) => Text(item.displayName)),
                  TableColumnSpec(label: 'Email', build: (item) => Text(item.email.isEmpty ? '—' : item.email)),
                  TableColumnSpec(label: 'Роль', build: (item) => Text(item.role.label)),
                ],
              ),
            ),
          ),
        ),
        PaginationBar(
          result: _result,
          onPageChanged: (page) {
            setState(() => _page = page);
            _load();
          },
          onSizeChanged: (_) {},
        ),
      ],
    );
  }
}
