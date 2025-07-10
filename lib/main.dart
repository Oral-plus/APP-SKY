import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

void main() {
  // Inicializar WebView
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const SkyPagosApp());
}

class SkyPagosApp extends StatelessWidget {
  const SkyPagosApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'SkyPagos',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
