import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'core/auth_session.dart';
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
import 'state/list_notifier.dart';

class ShopApp extends StatelessWidget {
  final Dio dio;
  final AuthSession auth;

  const ShopApp({super.key, required this.dio, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        Provider<AuthSession>.value(value: auth),
        Provider<PartRepository>(create: (_) => ApiPartRepository(dio)),
        Provider<BrandRepository>(create: (_) => ApiBrandRepository(dio)),
        Provider<CategoryRepository>(create: (_) => ApiCategoryRepository(dio)),
        Provider<CarModelRepository>(create: (_) => ApiCarModelRepository(dio)),
        Provider<CustomerRepository>(create: (_) => ApiCustomerRepository(dio)),
        ChangeNotifierProvider(
          create: (context) => PartListNotifier(context.read<PartRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => BrandListNotifier(context.read<BrandRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CategoryListNotifier(context.read<CategoryRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CarModelListNotifier(context.read<CarModelRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CustomerListNotifier(context.read<CustomerRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Магазин автозапчастей',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100)),
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
