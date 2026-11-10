import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'repositories/brand_repository.dart';
import 'repositories/car_model_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/part_repository.dart';
import 'repositories/persistent_brand_repository.dart';
import 'repositories/persistent_car_model_repository.dart';
import 'repositories/persistent_category_repository.dart';
import 'repositories/persistent_customer_repository.dart';
import 'repositories/persistent_part_repository.dart';
import 'state/list_notifier.dart';
import 'storage/storage_status.dart';
import 'widgets/app_dialogs.dart';

class ShopApp extends StatefulWidget {
  final SharedPreferences prefs;

  const ShopApp({super.key, required this.prefs});

  @override
  State<ShopApp> createState() => _ShopAppState();
}

class _ShopAppState extends State<ShopApp> {
  late final StorageStatus _storageStatus;
  bool _noticeShown = false;

  @override
  void initState() {
    super.initState();
    _storageStatus = StorageStatus(widget.prefs);
  }

  void _showNoticeIfNeeded(BuildContext context) {
    if (_noticeShown) return;
    _noticeShown = true;
    final notice = _storageStatus.takeNotice();
    if (notice == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showInfo(
        context,
        'Хранилище обновлено',
        'Формат данных изменился, поэтому старые записи были сброшены к начальному набору.\n\n$notice',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PartRepository>(
          create: (_) => PersistentPartRepository(widget.prefs, _storageStatus),
        ),
        Provider<BrandRepository>(
          create: (_) => PersistentBrandRepository(widget.prefs, _storageStatus),
        ),
        Provider<CategoryRepository>(
          create: (_) => PersistentCategoryRepository(widget.prefs, _storageStatus),
        ),
        Provider<CarModelRepository>(
          create: (_) => PersistentCarModelRepository(widget.prefs, _storageStatus),
        ),
        Provider<CustomerRepository>(
          create: (_) => PersistentCustomerRepository(widget.prefs, _storageStatus),
        ),
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
        builder: (context, child) {
          _showNoticeIfNeeded(context);
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
