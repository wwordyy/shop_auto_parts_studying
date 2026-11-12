import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/auth_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final auth = AuthSession();
  final dio = buildDio(tokenProvider: () => auth.accessToken);
  try {
    await auth.tryLogin(dio);
  } catch (_) {
    // Список каталога доступен и без токена; CUD потребует повторного входа.
  }
  runApp(ShopApp(dio: dio, auth: auth));
}
