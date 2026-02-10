import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/invoice_service.dart';
import '../models/user_model.dart';
import 'package:video_player/video_player.dart';
import '../models/invoice_model.dart';
import 'invoice_history_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'simple-wompi-screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'invoice_detail_screen.dart';
import 'products.dart';
import 'shopping_loading_screen.dart';
import 'test_client.dart';
import '../utils/app_assets.dart';
import '../utils/route_observer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  UserModel? _user;
  List<InvoiceModel> _pendingInvoices = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  bool _showWelcome = true;
  bool _isDisposed = false;
  bool _isMounted = false;
  int? _pressedActionIndex;

  // Video Player Controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showVideoControls = true;
  bool _isFullScreen = false;

  // Animaciones ligeras (solo entrada = carga rápida y fluida)
  AnimationController? _welcomeController;
  AnimationController? _mainController;
  Animation<double>? _welcomeFadeAnimation;
  Animation<Offset>? _welcomeSlideAnimation;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _cardFadeAnimation;
  Animation<Offset>? _cardSlideAnimation;
  AnimationController? _cardController;

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
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _initializeVideo();
    _loadUserData();
    // Pre-calienta la conexión al API de facturas para que el historial funcione
    // sin necesidad de abrir "Pagar con Wompi" primero
    Future.microtask(() => InvoiceService.findWorkingUrl());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_isMounted || _isDisposed) return;

    if (state == AppLifecycleState.paused) {
      _videoController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_videoController?.value.isInitialized == true) {
        _videoController?.play();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isMounted || _isDisposed) return;
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _videoController?.pause();
  }

  @override
  void didPopNext() {
    if (_videoController?.value.isInitialized == true &&
        !_videoController!.value.isPlaying) {
      _videoController?.play();
    }
  }

  void _initializeVideo() async {
    if (_isDisposed || !_isMounted) return;

    try {
      _videoController = VideoPlayerController.asset('assets/Videos/VIDEO.mp4');
      await _videoController!.initialize();

      if (_isDisposed || !_isMounted) {
        _videoController?.dispose();
        return;
      }

      _videoController!.setLooping(true);
      _videoController!.setVolume(0.7); 
      _videoController!.addListener(_videoListener);
      safeSetState(() {
        _isVideoInitialized = true;
        _showVideoControls = true;
      });
      _videoController!.play();
      _autoHideControls();
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (_isMounted && !_isDisposed) {
        safeSetState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  void _videoListener() {
    if (!_isDisposed && _isMounted) {
      safeSetState(() {});
    }
  }

  void _autoHideControls() {
    if (_isDisposed || !_isMounted) return;

    Future.delayed(const Duration(seconds: 3), () {
      if (!_isDisposed &&
          _isMounted &&
          _videoController != null &&
          _videoController!.value.isInitialized &&
          _videoController!.value.isPlaying) {
        safeSetState(() {
          _showVideoControls = false;
        });
      }
    });
  }

  void _toggleVideoControls() {
    if (!_isDisposed && _isMounted) {
      safeSetState(() {
        _showVideoControls = !_showVideoControls;
      });
      if (_showVideoControls) {
        _autoHideControls();
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        !_isDisposed &&
        _isMounted) {
      safeSetState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
    }
  }

  void _toggleFullScreen() {
    if (_isDisposed || !_isMounted) return;

    safeSetState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void safeSetState(VoidCallback fn) {
    if (!_isDisposed && _isMounted && mounted) {
      try {
        setState(fn);
      } catch (e) {
        debugPrint('setState error: $e');
      }
    }
  }

  void _setupAnimations() {
    if (_isDisposed || !_isMounted) return;
    try {
      _welcomeController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
      _mainController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _cardController = AnimationController(
        duration: const Duration(milliseconds: 450),
        vsync: this,
      );

      _welcomeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _welcomeController!, curve: Curves.easeOut),
      );
      _welcomeSlideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _welcomeController!, curve: Curves.easeOutCubic));

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainController!, curve: Curves.easeOut),
      );
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _mainController!, curve: Curves.easeOutCubic));

      _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _cardController!, curve: Curves.easeOut),
      );
      _cardSlideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _cardController!, curve: Curves.easeOutCubic));

      _welcomeController?.forward();
    } catch (e) {
      debugPrint('Error setting up animations: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isMounted = false;
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);

    _welcomeController?.dispose();
    _mainController?.dispose();
    _cardController?.dispose();

    // Dispose video controller safely
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();

    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_isDisposed || !_isMounted) return;

    try {
      safeSetState(() => _isLoading = true);
      final hasSession = await ApiService.hasActiveSession();
      if (!hasSession) {
        _redirectToLogin();
        return;
      }

      final user = await ApiService.getUserProfile();
      final pendingInvoices = await ApiService.getPendingInvoices();

      if (!_isDisposed && _isMounted) {
        safeSetState(() {
          _user = user;
          _pendingInvoices = pendingInvoices ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!_isDisposed && _isMounted) {
        safeSetState(() => _isLoading = false);
        _showErrorSnackBar('Error cargando información: ${e.toString()}');
      }
    }
  }

  void _redirectToLogin() {
    if (!_isDisposed && _isMounted && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await _loadUserData();
  }

  void _showErrorSnackBar(String message) {
    if (!_isMounted || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!_isMounted || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendAutoWhatsAppMessage() async {
    HapticFeedback.mediumImpact();

    if (!_isMounted || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Enviando Mensaje',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Preparando mensaje de soporte automático...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF25D366)),
                ),
              ],
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 2));

    try {
      final userName = _user?.nombre ?? 'Usuario';
      final userDoc = _user?.documento ?? 'Sin documento';
      final timestamp =
          DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

      final message = Uri.encodeComponent(
          '🔧 SOLICITUD DE SOPORTE TÉCNICO - ORAL PLUS\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '👤 INFORMACIÓN DEL USUARIO:\n'
          '• Nombre: $userName\n'
          '• Documento: $userDoc\n'
          '• Fecha/Hora: $timestamp\n'
          '• Plataforma: App Móvil \n\n'
          '📱 DETALLES TÉCNICOS:\n'
          '• Versión App: 2.0.0\n'
          '• Tipo Solicitud: Soporte General\n'
          '• Canal: WhatsApp Automático\n\n'
          '💬 MENSAJE:\n'
          'Hola! Necesito asistencia técnica con mi cuenta de ORAL PLUS. '
          'Este mensaje fue enviado automáticamente desde la aplicación móvil.\n\n'
          '⚡ Por favor, responde a este mensaje para iniciar el soporte.\n\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '🦷 ORAL PLUS 🦷');

      final whatsappUrls = [
        'whatsapp://send?phone=573024037819&text=$message&app_absent=0',
        'https://api.whatsapp.com/send/?phone=573024037819&text=$message&type=phone_number&app_absent=0',
        'https://wa.me/573024037819/?text=$message',
      ];

      if (_isMounted && mounted) Navigator.of(context).pop();

      bool messageSent = false;
      for (String url in whatsappUrls) {
        try {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            messageSent = true;
            _showWhatsAppSuccessDialog();
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (!messageSent) {
        _showWhatsAppManualOptions();
      }
    } catch (e) {
      if (_isMounted && mounted) Navigator.of(context).pop();
      _showWhatsAppManualOptions();
    }
  }

  void _showWhatsAppSuccessDialog() {
    if (!_isMounted || !mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¡Mensaje Preparado!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'WhatsApp se ha abierto con tu mensaje de soporte pre-escrito.\n\n'
                  '📱 Solo presiona "Enviar" en WhatsApp para contactar al equipo de soporte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Perfecto',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 1), () {
      _showSuccessSnackBar('Mensaje de soporte preparado en WhatsApp');
    });
  }

  void _showWhatsAppManualOptions() {
    if (!_isMounted || !mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.support_agent_rounded,
                    size: 60, color: primaryBlue),
                const SizedBox(height: 20),
                const Text(
                  'Contacto Alternativo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'No se pudo abrir WhatsApp automáticamente. Usa estas opciones:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 20),
                _buildContactOption(
                  icon: Icons.phone_rounded,
                  title: 'Llamar Ahora',
                  subtitle: '+57 300 646 7135',
                  gradient: const [Color(0xFF25D366), Color(0xFF128C7E)],
                  onTap: () async {
                    final Uri phoneUrl = Uri.parse('tel:+573006467135');
                    if (await canLaunchUrl(phoneUrl)) {
                      await launchUrl(phoneUrl);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildContactOption(
                  icon: Icons.copy_rounded,
                  title: 'Copiar Número',
                  subtitle: 'Para WhatsApp manual',
                  gradient: const [primaryBlue, secondaryBlue],
                  onTap: () {
                    Clipboard.setData(
                        const ClipboardData(text: '+573006467135'));
                    Navigator.of(context).pop();
                    _showSuccessSnackBar('Número copiado: +57 300 646 7135');
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cerrar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWebPortalWithStyle() async {
    HapticFeedback.mediumImpact();

    if (!_isMounted || !mounted) return;

    final Uri url = Uri.parse('https://oral-plus.com/index.html');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 2 * 3.14159,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [primaryBlue, secondaryBlue]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.language_rounded,
                            color: Colors.white, size: 40),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Abriendo Portal Web',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Conectando con ORAL PLUS...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 20),
                const LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (_isMounted && mounted) Navigator.of(context).pop();
        _showSuccessSnackBar('Portal web abierto exitosamente');
      } else {
        if (_isMounted && mounted) Navigator.of(context).pop();
        _showWebPortalErrorDialog();
      }
    } catch (e) {
      if (_isMounted && mounted) Navigator.of(context).pop();
      _showWebPortalErrorDialog();
    }
  }

  void _showWebPortalErrorDialog() {
    if (!_isMounted || !mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error de Conexión'),
          content: const Text(
              'No se pudo acceder al portal web. Verifica tu conexión a internet e inténtalo nuevamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openWebPortalWithStyle();
              },
              child: const Text('Reintentar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _logout() {
    HapticFeedback.mediumImpact();
    if (!_isMounted || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    AppAssets.logo,
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.logout_rounded, size: 48, color: primaryBlue),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cerrar sesión',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  '¿Salir de tu cuenta? Tendrás que volver a iniciar sesión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryBlue,
                          side: BorderSide(color: primaryBlue.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await ApiService.clearToken();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          } catch (e) {
                            if (mounted) {
                              Navigator.of(context).pop();
                              _showErrorSnackBar('Error al cerrar sesión: ${e.toString()}');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Salir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _enterDashboard() {
    HapticFeedback.mediumImpact();
    safeSetState(() => _showWelcome = false);
    _mainController?.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isMounted && !_isDisposed) {
        _cardController?.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Verificar pantalla completa primero
    if (_isFullScreen) {
      return _buildFullScreenVideo();
    }

    // Verificar estado de carga
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    // Pantalla principal del dashboard
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                _showWelcome ? _buildWelcomeScreen() : _buildMainDashboard(),
                if (!_showWelcome) _buildTransparentBottomNav(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFullScreenVideo() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isVideoInitialized && _videoController != null
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                : const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  ),
          ),
          if (_showVideoControls)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _toggleFullScreen,
                            icon: const Icon(Icons.fullscreen_exit_rounded,
                                color: Colors.white, size: 32),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              if (_videoController != null) {
                                safeSetState(() {
                                  _videoController!.setVolume(
                                      _videoController!.value.volume > 0
                                          ? 0.0
                                          : 0.7);
                                });
                              }
                            },
                            icon: Icon(
                              _videoController?.value.volume == 0
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            _videoController?.value.isPlaying == true
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_videoController != null &&
                        _videoController!.value.isInitialized)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: VideoProgressIndicator(
                          _videoController!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: primaryBlue,
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (!_showVideoControls)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleVideoControls,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: _welcomeFadeAnimation != null && _welcomeSlideAnimation != null
              ? SlideTransition(
                  position: _welcomeSlideAnimation!,
                  child: FadeTransition(
                    opacity: _welcomeFadeAnimation!,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Image.asset(
                          AppAssets.logo,
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.medical_services_outlined, size: 80, color: primaryBlue),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Tu cartera',
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gestiona, paga y controla tus facturas\ncon seguridad y simplicidad.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: textSecondary.withOpacity(0.95), height: 1.5, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 36),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildWelcomeFeature(0, Icons.shield_rounded, 'Seguro'),
                            const SizedBox(width: 20),
                            _buildWelcomeFeature(1, Icons.bolt_rounded, 'Rápido'),
                            const SizedBox(width: 20),
                            _buildWelcomeFeature(2, Icons.support_rounded, 'Soporte'),
                          ],
                        ),
                        const SizedBox(height: 44),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _enterDashboard,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: primaryBlue.withOpacity(0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Entrar al dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryBlue.withOpacity(0.08)),
                            boxShadow: [
                              BoxShadow(color: primaryBlue.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.person_outline_rounded, size: 18, color: primaryBlue),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  _user?.nombre ?? 'Usuario',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildWelcomeFeature(int index, IconData icon, String label) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: primaryBlue.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: primaryBlue.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(icon, color: primaryBlue, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainDashboard() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundColor, Color(0xFFF1F5F9)],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryBlue,
        backgroundColor: cardBackground,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildProfessionalAppBar(),
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.logo,
              width: 64,
              height: 64,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.dashboard_rounded, size: 48, color: primaryBlue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cargando...',
              style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 56,
      title: AppAssets.logoImage(width: 140, height: 36),
      actions: [
        SizedBox(
          width: 56,
          child: IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout_rounded, color: textPrimary, size: 22),
            tooltip: 'Cerrar sesión',
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundColor, Color(0xFFF1F5F9)],
            ),
          ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 6),
                  child: _fadeAnimation != null && _slideAnimation != null
                      ? FadeTransition(
                          opacity: _fadeAnimation!,
                          child: SlideTransition(
                            position: _slideAnimation!,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProfessionalHeader(),
                                const SizedBox(height: 12),
                                _buildProfessionalWelcomeCard(),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfessionalHeader(),
                            const SizedBox(height: 12),
                            _buildProfessionalWelcomeCard(),
                          ],
                        ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bienvenido, ${_user?.nombre ?? 'Usuario'}',
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryBlue.withOpacity(0.12)),
                    ),
                    child: Text(
                      _user?.documento ?? 'ID: ••••••••',
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalWelcomeCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryBlue.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryBlue.withOpacity(0.12),
                      secondaryBlue.withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.dashboard_customize_rounded,
                    color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bienvenido de nuevo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Aquí está tu resumen',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return SliverToBoxAdapter(
      child: _cardFadeAnimation != null && _cardSlideAnimation != null
          ? FadeTransition(
              opacity: _cardFadeAnimation!,
              child: SlideTransition(
                position: _cardSlideAnimation!,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Acciones Rápidas'),
                      const SizedBox(height: 20),
                      _buildProfessionalActionsGrid(),
                      const SizedBox(height: 24),
                      _buildInvoicesList(),
                      const SizedBox(height: 100), // Espacio para el bottom nav
                    ],
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Acciones Rápidas'),
                  const SizedBox(height: 20),
                  _buildProfessionalActionsGrid(),
                  const SizedBox(height: 24),
                  _buildInvoicesList(),
                  const SizedBox(height: 100), // Espacio para el bottom nav
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalActionsGrid() {
    final actions = [
      ActionData(
        icon: Icons.payment_rounded,
        title: 'Pagar con Wompi',
        subtitle: 'Pagos seguros y rápidos',
        gradient: const [primaryBlue, secondaryBlue],
        onTap: () => _handleWompiPayment(),
      ),
      ActionData(
        icon: Icons.receipt_long_rounded,
        title: 'Historial Completo',
        subtitle: 'Todas tus transacciones',
        gradient: const [secondaryBlue, lightBlue],
        onTap: () => _handleHistoryNavigation(),
      ),
      

      ActionData(
        icon: Icons.shopping_bag_rounded,
        title: 'Nuestros Productos',
        subtitle: 'Catálogo completo',
        gradient: const [Color(0xFF1E88E5), Color(0xFF42A5F5)],
        onTap: () => _handleProductsNavigation(),
      ),
      ActionData(
        icon: Icons.language_rounded,
        title: 'Portal Web',
        subtitle: 'Plataforma completa',
        gradient: const [accentBlue, primaryBlue],
        onTap: () => _openWebPortalWithStyle(),
      ),
      ActionData(
        icon: Icons.support_agent_rounded,
        title: 'Soporte Automático',
        subtitle: 'WhatsApp instantáneo',
        gradient: const [Color(0xFF25D366), Color(0xFF128C7E)],
        onTap: _sendAutoWhatsAppMessage,
      ),
      ActionData(
        icon: Icons.article_rounded,
        title: 'Noticias Oral-plus',
        subtitle: 'Web, productos, facturas y más',
        gradient: const [secondaryBlue, lightBlue],
        onTap: _showNoticiasOralPlusDialog,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final spacing = 12.0;
        final cardWidth = ((screenWidth - spacing) / 2).clamp(120.0, 200.0);
        final cardHeight = cardWidth * 1.25;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            final isPressed = _pressedActionIndex == index;
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 350 + (index * 80)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.88 + (0.12 * value),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: GestureDetector(
                      onTapDown: (_) => safeSetState(() => _pressedActionIndex = index),
                      onTapUp: (_) => safeSetState(() => _pressedActionIndex = null),
                      onTapCancel: () => safeSetState(() => _pressedActionIndex = null),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        action.onTap();
                        safeSetState(() => _pressedActionIndex = null);
                      },
                      child: AnimatedScale(
                        scale: isPressed ? 0.96 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeInOut,
                        child: _buildActionCard(action, cardWidth, cardHeight),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionCard(ActionData action, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: action.gradient[0].withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: action.gradient[0].withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: action.gradient,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: action.gradient[0].withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(action.icon, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                action.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  height: 1.22,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              action.subtitle,
              style: TextStyle(
                fontSize: 11,
                color: textSecondary.withOpacity(0.95),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: action.gradient[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: action.gradient[0],
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleWompiPayment() async {
    HapticFeedback.mediumImpact();

    if (!_isMounted || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: _WompiProcessingDialog(),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (_isMounted && mounted) Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 100));

    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SimpleWompiScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );

    if (result == true) {
      _showSuccessSnackBar('¡Pago procesado exitosamente!');
      _refreshData();
    }
  }

  Future<void> _handleHistoryNavigation() async {
    try {
      await HapticFeedback.selectionClick();

      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return const InvoiceHistoryScreen();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Deslizamiento desde la derecha
            final slide = Tween<Offset>(
              begin: const Offset(0.4, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack, // Más elástica
              reverseCurve: Curves.easeInCubic,
            ));

            // Escalado desde 90% a 100%
            final scale = Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.decelerate,
            ));

            // Opacidad progresiva
            final fade = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
            ));

            return SlideTransition(
              position: slide,
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
        ),
      );
    } catch (error) {
      debugPrint('Error en navegación al historial: $error');
      if (_isMounted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al acceder al historial'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleProductsNavigation() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OptimizedOralPlusLoadingScreen(destination: const ProductsTab()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildInvoicesList() {
    if (_pendingInvoices.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Video Player
            Container(
              width: double.infinity,
              height: 250,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: [primaryBlue, secondaryBlue]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isVideoInitialized && _videoController != null
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController!.value.size.width,
                                    height: _videoController!.value.size.height,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                              ),
                              if (_showVideoControls)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.4),
                                        Colors.transparent,
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.6),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'ORAL PLUS',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildVideoControlButton(
                                                  icon: _videoController
                                                              ?.value.volume ==
                                                          0
                                                      ? Icons.volume_off_rounded
                                                      : Icons.volume_up_rounded,
                                                  onTap: () {
                                                    if (_videoController !=
                                                        null) {
                                                      safeSetState(() {
                                                        _videoController!.setVolume(
                                                            _videoController!
                                                                        .value
                                                                        .volume >
                                                                    0
                                                                ? 0.0
                                                                : 0.7);
                                                      });
                                                    }
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                _buildVideoControlButton(
                                                  icon:
                                                      Icons.fullscreen_rounded,
                                                  onTap: _toggleFullScreen,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Center(
                                        child: GestureDetector(
                                          onTap: _togglePlayPause,
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.95),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _videoController!.value.isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              color: primaryBlue,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_videoController!.value.isInitialized)
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: VideoProgressIndicator(
                                              _videoController!,
                                              allowScrubbing: true,
                                              colors: VideoProgressColors(
                                                playedColor: Colors.white,
                                                bufferedColor: Colors.white
                                                    .withOpacity(0.3),
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              if (!_showVideoControls)
                                GestureDetector(
                                  onTap: _toggleVideoControls,
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.transparent,
                                  ),
                                ),
                            ],
                          );
                        },
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [primaryBlue, secondaryBlue]),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Cargando video...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [primaryBlue, secondaryBlue]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '¡ORAL-PLUS!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SALUD Y BELLEZA EN TU SONRISA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _pendingInvoices.take(3).map((invoice) {
        final index = _pendingInvoices.indexOf(invoice);
        final daysLeft = invoice.daysUntilDue;
        final isUrgent = daysLeft <= 3;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 40 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: ProfessionalInvoiceCard(
                  invoice: invoice,
                  isUrgent: isUrgent,
                  daysLeft: daysLeft,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            InvoiceDetailScreen(invoice: invoice),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 1.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  onPayment: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => const SimpleWompiScreen(),
                      ),
                    );
                    if (result == true) {
                      _showSuccessSnackBar('¡Pago procesado exitosamente!');
                      _refreshData();
                    }
                  },
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildVideoControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildTransparentBottomNav() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 56 + bottomPadding,
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildTransparentNavItem(Icons.payment_rounded, 'Pagar', 0)),
              Expanded(child: _buildTransparentNavItem(Icons.receipt_long_rounded, 'Facturas', 1)),
              Expanded(child: _buildTransparentNavItem(Icons.person_rounded, 'Perfil', 2)),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoticiasOralPlusDialog() {
    if (!_isMounted || !mounted) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.article_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Noticias ORAL-PLUS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('Todo sobre nuestra app', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNoticiaItem(Icons.language_rounded, 'Portal Web', 'Visita oral-plus.com para acceder a la plataforma completa: productos, facturas, historial y más.'),
                      _buildNoticiaItem(Icons.shopping_bag_rounded, 'Productos', 'Descubre nuestro catálogo de productos para tu salud bucal. Cuida tu sonrisa con los mejores tratamientos.'),
                      _buildNoticiaItem(Icons.receipt_long_rounded, 'Importancia de pagar facturas', 'Mantén tus pagos al día para evitar cargos adicionales y disfrutar de todos los beneficios. Usa "Pagar con Wompi" para pagos seguros y rápidos.'),
                      _buildNoticiaItem(Icons.apps_rounded, 'Sobre la app', 'La app ORAL-PLUS te permite: pagar facturas, ver historial, comprar productos y contactar soporte por WhatsApp. ¡Todo en un solo lugar!'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Entendido'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticiaItem(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransparentNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        safeSetState(() => _selectedIndex = index);

        switch (index) {
          case 0:
            _handleWompiPayment();
            break;
          case 1:
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const InvoiceHistoryScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
              ),
            );
            break;
          case 2:
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ProfileScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
              ),
            );
            break;
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? primaryBlue : primaryBlue.withOpacity(0.5),
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? primaryBlue : primaryBlue.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTestClient() {
    if (!_isMounted || !mounted) return;

    // Opcional: mostrar un mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirigiendo a prueba de cliente...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Redirigir a la pantalla de test_client.dart
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TestClientScreen()),
    );
  }
}

// Professional Invoice Card
class ProfessionalInvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isUrgent;
  final int daysLeft;
  final VoidCallback onTap;
  final VoidCallback onPayment;

  const ProfessionalInvoiceCard({
    super.key,
    required this.invoice,
    required this.isUrgent,
    required this.daysLeft,
    required this.onTap,
    required this.onPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _DashboardScreenState.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFE53E3E).withOpacity(0.3)
              : _DashboardScreenState.primaryBlue.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? const Color(0xFFE53E3E).withOpacity(0.1)
                : _DashboardScreenState.primaryBlue.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUrgent
                              ? [
                                  const Color(0xFFE53E3E),
                                  const Color(0xFFDC2626)
                                ]
                              : [
                                  _DashboardScreenState.primaryBlue,
                                  _DashboardScreenState.secondaryBlue
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isUrgent
                                    ? const Color(0xFFE53E3E)
                                    : _DashboardScreenState.primaryBlue)
                                .withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isUrgent
                            ? Icons.warning_rounded
                            : Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Factura #${invoice.toString()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _DashboardScreenState.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? const Color(0xFFE53E3E).withOpacity(0.1)
                                  : _DashboardScreenState.primaryBlue
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isUrgent ? 'URGENTE' : 'PENDIENTE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isUrgent
                                    ? const Color(0xFFE53E3E)
                                    : _DashboardScreenState.primaryBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${NumberFormat('#,###').format(invoice.hashCode)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _DashboardScreenState.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: _DashboardScreenState.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vence en $daysLeft días',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _DashboardScreenState.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: onPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUrgent
                              ? const Color(0xFFE53E3E)
                              : _DashboardScreenState.primaryBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payment_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Pagar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo con datáfono realista, tarjeta real y animaciones premium para Wompi.
class _WompiProcessingDialog extends StatefulWidget {
  static const Color _primary = Color(0xFF1a1f36);
  static const Color _accent = Color(0xFF00c853);
  static const Color _screenGlow = Color(0xFF4ade80);

  const _WompiProcessingDialog();

  @override
  State<_WompiProcessingDialog> createState() => _WompiProcessingDialogState();
}

class _WompiProcessingDialogState extends State<_WompiProcessingDialog>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _cardSlideController;
  late AnimationController _ledController;
  late AnimationController _scanController;
  late Animation<double> _fadeEntrance;
  late Animation<double> _scaleEntrance;
  late Animation<double> _cardSlide;
  late Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardSlideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _ledController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _fadeEntrance = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _scaleEntrance = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _cardSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardSlideController,
        curve: const Interval(0.2, 0.85, curve: Curves.easeInOutCubic),
      ),
    );
    _cardOpacity = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _cardSlideController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _entranceController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardSlideController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _cardSlideController.dispose();
    _ledController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeEntrance,
      child: ScaleTransition(
        scale: _scaleEntrance,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFf8fafc),
                const Color(0xFFe2e8f0),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: _WompiProcessingDialog._primary.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Procesando pago seguro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _WompiProcessingDialog._primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Redirigiendo a Wompi...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              _buildDataphoneWithCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataphoneWithCard() {
    const dataphoneW = 220.0;
    const dataphoneH = 180.0;
    const cardW = 140.0;
    const cardH = 88.0;

    return SizedBox(
      width: dataphoneW + 60,
      height: dataphoneH + 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Datáfono físico
          Transform.translate(
            offset: const Offset(0, 30),
            child: _buildDataphone(dataphoneW, dataphoneH),
          ),
          // Tarjeta que se desliza hacia la ranura
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_cardSlideController, _cardOpacity]),
                builder: (context, _) {
                  final slide = _cardSlide.value;
                  final opacity = _cardOpacity.value;
                  return Transform.translate(
                    offset: Offset(slide * (dataphoneW * 0.6), 20),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: -0.08,
                        child: _buildCreditCard(cardW, cardH),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataphone(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2d3748),
            const Color(0xFF1a202c),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Ranura de tarjeta
            Container(
              height: 14,
              margin: const EdgeInsets.only(top: 8, left: 20, right: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0d1117),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF374151), width: 1),
              ),
            ),
            // Pantalla LCD
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFa7f3d0),
                      const Color(0xFF6ee7b7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _WompiProcessingDialog._screenGlow.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064e3b),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _scanController,
                          builder: (context, _) {
                            final scan = _scanController.value;
                            return ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF4ade80),
                                  const Color(0xFF4ade80)
                                      .withOpacity(0.3 + 0.7 * (1 - scan)),
                                ],
                              ).createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                'PROCESANDO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        AnimatedBuilder(
                          animation: _ledController,
                          builder: (context, _) {
                            final led = (_ledController.value * 2).clamp(0.0, 1.0);
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLedDot(
                                  _WompiProcessingDialog._accent,
                                  led > 1 ? 0.4 + 0.6 * (2 - led) : 0.4,
                                ),
                                const SizedBox(width: 8),
                                _buildLedDot(
                                  const Color(0xFFfbbf24),
                                  0.6,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _scanController,
                          builder: (context, _) {
                            final p = 0.2 + 0.6 * ((_scanController.value * 1.5) % 1.0);
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: p.clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFF065f46),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF34d399),
                                ),
                                minHeight: 4,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Teclas
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey(Colors.grey.shade700, 20),
                  _buildKey(Colors.grey.shade700, 20),
                  _buildKey(const Color(0xFF059669), 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedDot(Color color, double intensity) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color.withOpacity(intensity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(intensity * 0.8),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildKey(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e3a5f),
            const Color(0xFF0f172a),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Chip dorado
            Positioned(
              left: 10,
              top: 14,
              child: Container(
                width: 28,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFd4af37),
                      const Color(0xFFb8860b),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFf4d03f), width: 0.5),
                ),
                child: CustomPaint(
                  painter: ChipLinesPainter(),
                  size: const Size(28, 22),
                ),
              ),
            ),
            // Número de tarjeta
            Positioned(
              left: 10,
              bottom: 28,
              child: Text(
                '•••• •••• •••• 4242',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            // Expiry
            Positioned(
              left: 10,
              bottom: 12,
              child: Text(
                '12/28',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Logo Visa
            Positioned(
              right: 8,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'VISA',
                  style: TextStyle(
                    color: const Color(0xFF1a1f36),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Líneas del chip de tarjeta
class ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8b7355)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 4; i++) {
      final y = 4.0 + i * 4.0;
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), paint);
    }
    for (var i = 0; i < 5; i++) {
      final x = 4.0 + i * 5.0;
      canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Action Data Model
class ActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  ActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}
