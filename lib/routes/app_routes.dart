import 'package:flutter/material.dart';
import '../models/store_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/store_detail/store_detail_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const storeDetail = '/store-detail';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    home: (_) => const HomeScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case storeDetail:
        final store = settings.arguments as Store;
        return MaterialPageRoute(
          builder: (_) => StoreDetailScreen(store: store),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('Route ${settings.name} tidak ditemukan'),
            ),
          ),
        );
    }
  }

  static void toStoreDetail(BuildContext context, Store store) {
    Navigator.pushNamed(context, storeDetail, arguments: store);
  }

  static void toHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, home, (_) => false);
  }

  static void toLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, login, (_) => false);
  }
}
