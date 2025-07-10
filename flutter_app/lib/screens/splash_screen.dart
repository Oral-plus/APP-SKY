import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  bool _connectionChecked = false;
  String _statusMessage = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _checkConnectionAndNavigate();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() {
    _logoController.forward();
    
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  Future<void> _checkConnectionAndNavigate() async {
    // Esperar un mínimo de tiempo para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _statusMessage = 'Verificando conexión...';
    });

    // Verificar conectividad a internet
    final hasInternet = await ApiService.checkConnectivity();
    
    if (!hasInternet) {
      setState(() {
        _statusMessage = 'Sin conexión a internet';
      });
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _showConnectionError();
        return;
      }
    }

    // Verificar conexión con el servidor
    setState(() {
      _statusMessage = 'Conectando al servidor...';
    });

    final serverConnected = await ApiService.testConnection();
    
    if (!serverConnected) {
      setState(() {
        _statusMessage = 'Error de conexión al servidor';
      });
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _showServerError();
        return;
      }
    }

    setState(() {
      _statusMessage = 'Conexión exitosa';
      _connectionChecked = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _showConnectionError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.wifi_off,
            color: AppTheme.errorColor,
            size: 48,
          ),
          title: const Text('Sin conexión'),
          content: const Text(
            'No se pudo conectar a internet. Verifica tu conexión y vuelve a intentar.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkConnectionAndNavigate();
              },
              child: const Text('Reintentar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
              child: const Text('Continuar sin conexión'),
            ),
          ],
        );
      },
    );
  }

  void _showServerError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.cloud_off,
            color: AppTheme.warningColor,
            size: 48,
          ),
          title: const Text('Error del servidor'),
          content: const Text(
            'No se pudo conectar al servidor de SkyPagos. Verifica que el servidor esté ejecutándose.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkConnectionAndNavigate();
              },
              child: const Text('Reintentar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
              AppTheme.accentColor,
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo animado
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Transform.rotate(
                              angle: _logoRotation.value * 0.1,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  size: 60,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Texto animado
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textFade,
                          child: Column(
                            children: [
                              const Text(
                                'SkyPagos',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tu billetera digital',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 60,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Indicador de estado en la parte inferior
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    if (!_connectionChecked) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Versión de la app
                    const Text(
                      'Versión 1.0.0',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
