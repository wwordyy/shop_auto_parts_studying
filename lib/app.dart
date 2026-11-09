import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'repositories/brand_repository.dart';
import 'repositories/in_memory_brand_repository.dart';
import 'repositories/in_memory_part_repository.dart';
import 'repositories/part_repository.dart';
import 'state/brand_list_notifier.dart';
import 'state/part_list_notifier.dart';

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PartRepository>(create: (_) => InMemoryPartRepository()),
        Provider<BrandRepository>(create: (_) => InMemoryBrandRepository()),
        ChangeNotifierProvider(
          create: (context) => PartListNotifier(context.read<PartRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => BrandListNotifier(context.read<BrandRepository>()),
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
