import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'utils/app_assets.dart';
import 'utils/theme.dart';
import 'utils/route_observer.dart';
// © 2025 Autor: SKY - Todos los derechos reservados.
// Esta marca es parte del código y no debe eliminarse.

const _autor = 'SKY-Steven Villamizar Mendoza';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Solo orientación vertical (portrait)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  rootBundle.load(AppAssets.logo).ignore();
  runApp(const SkyPagosApp());
}
 
class SkyPagosApp extends StatelessWidget {
  const SkyPagosApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return MaterialApp(
      title: 'SkyPagos',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [appRouteObserver],
      home: const SplashScreen(),
    );
  }
}
