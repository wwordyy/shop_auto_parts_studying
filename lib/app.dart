import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'core/auth_api.dart';
import 'core/config.dart';
import 'core/connectivity_monitor.dart';
import 'repositories/api_brand_repository.dart';
import 'repositories/api_car_model_repository.dart';
import 'repositories/api_category_repository.dart';
import 'repositories/api_customer_repository.dart';
import 'repositories/api_part_repository.dart';
import 'repositories/brand_repository.dart';
import 'repositories/car_model_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/part_repository.dart';
import 'state/auth_notifier.dart';
import 'state/list_notifier.dart';
import 'widgets/connectivity_host.dart';
import 'widgets/inactivity_watcher.dart';

class ShopApp extends StatefulWidget {
  final Dio dio;
  final AuthNotifier auth;
  final ConnectivityMonitor connectivity;

  const ShopApp({
    super.key,
    required this.dio,
    required this.auth,
    required this.connectivity,
  });

  @override
  State<ShopApp> createState() => _ShopAppState();
}

class _ShopAppState extends State<ShopApp> {
  late final _router = buildRouter(widget.auth);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Dio>.value(value: widget.dio),
        ChangeNotifierProvider<AuthNotifier>.value(value: widget.auth),
        ChangeNotifierProvider<ConnectivityMonitor>.value(
            value: widget.connectivity),
        Provider<AuthApi>(create: (_) => AuthApi(widget.dio)),
        Provider<PartRepository>(create: (_) => ApiPartRepository(widget.dio)),
        Provider<BrandRepository>(
            create: (_) => ApiBrandRepository(widget.dio)),
        Provider<CategoryRepository>(
            create: (_) => ApiCategoryRepository(widget.dio)),
        Provider<CarModelRepository>(
            create: (_) => ApiCarModelRepository(widget.dio)),
        Provider<CustomerRepository>(
            create: (_) => ApiCustomerRepository(widget.dio)),
        ChangeNotifierProvider(
          create: (context) => PartListNotifier(context.read<PartRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              BrandListNotifier(context.read<BrandRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CategoryListNotifier(context.read<CategoryRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CarModelListNotifier(context.read<CarModelRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CustomerListNotifier(context.read<CustomerRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Магазин автозапчастей',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100)),
          useMaterial3: true,
          visualDensity: VisualDensity.standard,
        ),
        routerConfig: _router,
        builder: (context, child) {
          final auth = context.watch<AuthNotifier>();
          return ConnectivityHost(
            child: InactivityWatcher(
              enabled: auth.isAuthenticated,
              timeout: const Duration(seconds: inactivityTimeoutSeconds),
              warningBefore: const Duration(seconds: inactivityWarningSeconds),
              onActivity: auth.touch,
              onTimeout: () => auth.logout(reason: LogoutReason.inactivity),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
