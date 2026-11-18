import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/auth_api.dart';
import 'core/connectivity_monitor.dart';
import 'state/auth_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  final auth = AuthNotifier(prefs);
  final connectivity = ConnectivityMonitor()..attach();
  final dio = buildDio(auth: auth, connectivity: connectivity);
  auth.attachApi(AuthApi(dio));
  await auth.restore();
  runApp(ShopApp(dio: dio, auth: auth, connectivity: connectivity));
}
