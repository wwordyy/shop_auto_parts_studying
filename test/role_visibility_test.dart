import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_auto_parts/screens/app_shell.dart';
import 'package:shop_auto_parts/state/auth_notifier.dart';
import 'package:shop_auto_parts/widgets/list_toolbar.dart';

Future<AuthNotifier> _authWithRole(String role) async {
  SharedPreferences.setMockInitialValues({
    'auth_access_token': 'token',
    'auth_refresh_token': 'refresh',
    'auth_user': jsonEncode({
      'id': 1,
      'username': 'user',
      'fullName': 'Тестовый пользователь',
      'email': 'user@test.ru',
      'role': role,
    }),
    'auth_last_activity': DateTime.now().toIso8601String(),
    'auth_session_started': DateTime.now().toIso8601String(),
  });
  final prefs = await SharedPreferences.getInstance();
  final auth = AuthNotifier(prefs);
  await auth.restore();
  return auth;
}

Widget _shell(AuthNotifier auth) {
  return ChangeNotifierProvider.value(
    value: auth,
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/parts',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                  path: '/parts', builder: (_, __) => const Text('Каталог')),
              GoRoute(
                  path: '/brands', builder: (_, __) => const SizedBox.shrink()),
              GoRoute(
                  path: '/categories',
                  builder: (_, __) => const SizedBox.shrink()),
              GoRoute(
                  path: '/cars', builder: (_, __) => const SizedBox.shrink()),
              GoRoute(
                  path: '/customers',
                  builder: (_, __) => const SizedBox.shrink()),
              GoRoute(
                  path: '/cabinet',
                  builder: (_, __) => const SizedBox.shrink()),
              GoRoute(
                  path: '/admin/users',
                  builder: (_, __) => const SizedBox.shrink()),
              GoRoute(
                  path: '/admin/stats',
                  builder: (_, __) => const SizedBox.shrink()),
            ],
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('скрывает недоступные разделы при роли покупателя',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = await _authWithRole('buyer');
    await tester.pumpWidget(_shell(auth));
    await tester.pumpAndSettle();

    expect(find.text('Кабинет'), findsWidgets);
    expect(find.text('Запчасти'), findsWidgets);
    expect(find.text('Клиенты'), findsNothing);
    expect(find.text('Пользователи'), findsNothing);
    expect(find.text('Статистика'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    auth.dispose();
  });

  testWidgets('скрывает кнопку Добавить при роли покупателя', (tester) async {
    final auth = await _authWithRole('buyer');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final perms = context.watch<AuthNotifier>().permissions;
                return ListToolbar(
                  search: const SizedBox.shrink(),
                  onAdd: perms.canMutate ? () {} : null,
                  filters: const [],
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('Добавить'), findsNothing);
    auth.dispose();
  });
}
