import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import for notifications
import '../services/api_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;

  // Notification plugin instance
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Blue & White Color Scheme
  static const Color primaryBlue = Color(0xFF1e3a8a);
  static const Color secondaryBlue = Color(0xFF3b82f6);
  static const Color lightBlue = Color(0xFF60a5fa);
  static const Color accentBlue = Color(0xFF2563eb);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1e293b);
  static const Color textSecondary = Color(0xFF64748b);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeNotifications(); // Initialize notifications
    _initializeApp();
  }

  void _setupAnimations() {
    // Controlador principal
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Controlador de pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Controlador de rotación
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 15000),
      vsync: this,
    );

    // Controlador de partículas
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Animaciones principales
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    // Animación de pulso
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animación de rotación
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Animación de partículas
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Replace 'app_icon' with your app's icon name

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
    
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tapped when app is in background/terminated
        if (notificationResponse.payload != null) {
          debugPrint('notification payload: ${notificationResponse.payload}');
          if (notificationResponse.payload == 'products_invite') {
            // Navigate to products screen or similar
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DashboardScreen()), // Assuming DashboardScreen can lead to products
              );
            }
          }
        }
      },
    );

    // Request permissions for Android 13+ and iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _showNotification(
      int id, String title, String body, String payload) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Change this to a unique ID for your app
      'Your Channel Name',
      channelDescription: 'Your channel description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> _initializeApp() async {
    try {
      // Iniciar todas las animaciones
      _animationController.forward();
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
      _particleController.repeat(reverse: true);

      // Esperar un mínimo de tiempo para mostrar el splash
      await Future.delayed(const Duration(milliseconds: 3000));

      // Verificar si hay sesión activa
      print('🔍 Verificando sesión activa...');
      final hasSession = await ApiService.hasActiveSession();

      if (mounted) {
        if (hasSession) {
          print('✅ Sesión activa encontrada, navegando al dashboard');
          _navigateToMain();
        } else {
          print('❌ No hay sesión activa, navegando al login');
          _navigateToLogin();
        }
        // Schedule notifications after navigation decision
        _showNotification(
          0,
          '¡Motivación para tu día!',
          '¡Tu sonrisa es tu mejor accesorio! Sigue brillando.',
          'motivational_message',
        );
        await Future.delayed(const Duration(seconds: 2)); // Small delay
        _showNotification(
          1,
          '¡Nuevos Productos!',
          'Descubre nuestros productos exclusivos. ¡Tu salud bucal te lo agradecerá!',
          'products_invite',
        );
      }
    } catch (e) {
      print('❌ Error en splash: $e');
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Configurar barra de estado para tema claro
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Cambiado a dark para tema claro
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark, // Cambiado a dark
      ),
    );
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor,
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(20, (index) => _buildAnimatedParticle(index)),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: AnimatedBuilder(
                                    animation: _rotationController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _rotationAnimation.value * 0.5,
                                        child: Container(
                                          width: 180,
                                          height: 180,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(45),
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                primaryBlue,
                                                secondaryBlue,
                                                lightBlue,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryBlue.withOpacity(0.3),
                                                blurRadius: 40,
                                                spreadRadius: 10,
                                                offset: const Offset(0, 15),
                                              ),
                                              BoxShadow(
                                                color: secondaryBlue.withOpacity(0.2),
                                                blurRadius: 60,
                                                spreadRadius: 20,
                                                offset: const Offset(0, 25),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(45),
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.center,
                                                      colors: [
                                                        Colors.white.withOpacity(0.3),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(35),
                                                  child: Image.asset(
                                                    'assets/logo-pagos.png',
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(
                                                        Icons.warning_amber_rounded,
                                                        size: 60,
                                                        color: Colors.white,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 50),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [primaryBlue, secondaryBlue],
                              ).createShader(bounds),
                              child: Text(
                                'ORAL-PLUS',
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardBackground,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primaryBlue.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBlue.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Text(
                                'SALUD Y BELLEZA EN TU SONRISA\nSKY S.A.S',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: cardBackground,
                                border: Border.all(
                                  color: primaryBlue.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBlue.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _rotationController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _rotationAnimation.value * 2 * 3.14159,
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(17),
                                        gradient: const LinearGradient(
                                          colors: [primaryBlue, secondaryBlue],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.sync_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            AnimatedBuilder(
                              animation: _particleController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: 0.7 + (_particleAnimation.value * 0.3),
                                  child: Text(
                                    'Inicializando...',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 200,
                              height: 4,
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: primaryBlue.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _animationController.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [primaryBlue, secondaryBlue],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryBlue.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Versión 1.0.0',
                          style: TextStyle(
                            color: textSecondary.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedParticle(int index) {
    final random = (index * 0.1) % 1.0;
    final size = 2.0 + (random * 4.0);
    final left = (index * 37.0) % MediaQuery.of(context).size.width;
    final animationDelay = (index * 200.0) % 2000.0;

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + (animationDelay / 2000.0)) % 1.0;
        final top = MediaQuery.of(context).size.height * progress;

        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: (0.2 + (random * 0.3)) * _fadeAnimation.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.4),
                    lightBlue.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(size / 2),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.2),
                    blurRadius: size * 2,
                    spreadRadius: size / 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
