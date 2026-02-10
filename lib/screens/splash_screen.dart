import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/api_service.dart';
import '../services/invoice_service.dart';
import '../utils/app_assets.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

const _kPrimaryBlue = Color(0xFF1e3a8a);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _dotsController;
  late Animation<double> _fade;
  late Animation<double> _scale;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) precacheImage(AssetImage(AppAssets.logo), context);
    });
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic)));
    _controller.forward();
    _initNotifications();
    _initApp();
    // Precalentar conexión a facturas (para que Historial funcione sin abrir Wompi primero)
    InvoiceService.findWorkingUrl().then((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('app_icon');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse res) async {
        if (res.payload == 'products_invite' && mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
        }
      },
    );

    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _showNotification(int id, String title, String body, String payload) async {
    const android = AndroidNotificationDetails(
      'oral_plus_channel',
      'ORAL-PLUS',
      channelDescription: 'Notificaciones ORAL-PLUS',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const details = NotificationDetails(android: android);
    await _notifications.show(id, title, body, details, payload: payload);
  }

  Future<void> _initApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 2200));

      final hasSession = await ApiService.hasActiveSession();

      if (!mounted) return;
      if (hasSession) {
        _goTo(const DashboardScreen());
      } else {
        _goTo(const LoginScreen());
      }

      await _showNotification(0, '¡Motivación para tu día!', 'Tu sonrisa es tu mejor accesorio. Sigue brillando.', 'motivational_message');
      await Future.delayed(const Duration(seconds: 2));
      await _showNotification(1, '¡Nuevos Productos!', 'Descubre nuestros productos exclusivos para tu salud bucal.', 'products_invite');
    } catch (_) {
      if (mounted) _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _dotsController]),
            builder: (context, _) {
              return Opacity(
                opacity: _fade.value.clamp(0.0, 1.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: _scale.value,
                      child: const _SplashLogo(),
                    ),
                    const SizedBox(height: 40),
                    _LoadingDots(controller: _dotsController, color: _kPrimaryBlue),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      alignment: Alignment.center,
      child: Image.asset(
        AppAssets.logo,
        width: 160,
        height: 160,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.medical_services_outlined, size: 80, color: _kPrimaryBlue.withOpacity(0.6)),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _LoadingDots({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        const dotSize = 8.0;
        const spacing = 10.0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (controller.value + (i / 3)) % 1.0;
            final opacity = phase < 0.4 ? (1.0 - (phase / 0.4) * 0.6) : 0.4;
            final scale = phase < 0.4 ? (0.9 + (1 - phase / 0.4) * 0.1) : 0.9;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : spacing),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color.withOpacity(opacity.clamp(0.0, 1.0)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
