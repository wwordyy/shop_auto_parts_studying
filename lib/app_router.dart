import 'package:go_router/go_router.dart';

import 'queries/brand_query.dart';
import 'queries/car_model_query.dart';
import 'queries/category_query.dart';
import 'queries/customer_query.dart';
import 'queries/part_query.dart';
import 'screens/app_shell.dart';
import 'screens/brand_detail_screen.dart';
import 'screens/brand_form_screen.dart';
import 'screens/brand_list_screen.dart';
import 'screens/car_model_detail_screen.dart';
import 'screens/car_model_form_screen.dart';
import 'screens/car_model_list_screen.dart';
import 'screens/category_detail_screen.dart';
import 'screens/category_form_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/customer_detail_screen.dart';
import 'screens/customer_form_screen.dart';
import 'screens/customer_list_screen.dart';
import 'screens/part_detail_screen.dart';
import 'screens/part_form_screen.dart';
import 'screens/part_list_screen.dart';

int _idOf(GoRouterState state) => int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

int? _editIdOf(GoRouterState state) => int.tryParse(state.pathParameters['id'] ?? '');

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
            GoRoute(path: 'new', builder: (context, state) => const PartFormScreen()),
            GoRoute(
              path: ':id',
              builder: (context, state) => PartDetailScreen(id: _idOf(state)),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => PartFormScreen(id: _editIdOf(state)),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/brands',
          builder: (context, state) => BrandListScreen(
            query: BrandQuery.fromParams(state.uri.queryParameters),
          ),
          routes: [
            GoRoute(path: 'new', builder: (context, state) => const BrandFormScreen()),
            GoRoute(
              path: ':id',
              builder: (context, state) => BrandDetailScreen(id: _idOf(state)),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => BrandFormScreen(id: _editIdOf(state)),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => CategoryListScreen(
            query: CategoryQuery.fromParams(state.uri.queryParameters),
          ),
          routes: [
            GoRoute(path: 'new', builder: (context, state) => const CategoryFormScreen()),
            GoRoute(
              path: ':id',
              builder: (context, state) => CategoryDetailScreen(id: _idOf(state)),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => CategoryFormScreen(id: _editIdOf(state)),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/cars',
          builder: (context, state) => CarModelListScreen(
            query: CarModelQuery.fromParams(state.uri.queryParameters),
          ),
          routes: [
            GoRoute(path: 'new', builder: (context, state) => const CarModelFormScreen()),
            GoRoute(
              path: ':id',
              builder: (context, state) => CarModelDetailScreen(id: _idOf(state)),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => CarModelFormScreen(id: _editIdOf(state)),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => CustomerListScreen(
            query: CustomerQuery.fromParams(state.uri.queryParameters),
          ),
          routes: [
            GoRoute(path: 'new', builder: (context, state) => const CustomerFormScreen()),
            GoRoute(
              path: ':id',
              builder: (context, state) => CustomerDetailScreen(id: _idOf(state)),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => CustomerFormScreen(id: _editIdOf(state)),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
