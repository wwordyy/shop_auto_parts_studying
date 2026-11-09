import 'package:go_router/go_router.dart';

import 'models/brand_query.dart';
import 'models/part_query.dart';
import 'screens/app_shell.dart';
import 'screens/brand_detail_screen.dart';
import 'screens/brand_list_screen.dart';
import 'screens/part_detail_screen.dart';
import 'screens/part_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/parts',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/parts',
          builder: (context, state) => PartListScreen(
            query: PartQuery.fromParams(state.uri.queryParameters),
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => PartDetailScreen(
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/brands',
          builder: (context, state) => BrandListScreen(
            query: BrandQuery.fromParams(state.uri.queryParameters),
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => BrandDetailScreen(
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
