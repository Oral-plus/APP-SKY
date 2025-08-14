import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
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


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  UserModel? _user;
  List<InvoiceModel> _pendingInvoices = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  bool _showWelcome = true;
  bool _isDisposed = false;
  bool _isMounted = false;

  // Video Player Controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showVideoControls = true;
  bool _isFullScreen = false;

  // Animation Controllers
  AnimationController? _mainController;
  AnimationController? _cardController;
  AnimationController? _floatingController;
  AnimationController? _welcomeController;
  AnimationController? _shimmerController;
  AnimationController? _breathingController;
  AnimationController? _particleController;

  // Animations
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _cardFadeAnimation;
  Animation<Offset>? _cardSlideAnimation;
  Animation<double>? _floatingAnimation;
  Animation<double>? _welcomeFadeAnimation;
  Animation<Offset>? _welcomeSlideAnimation;
  Animation<double>? _shimmerAnimation;
  Animation<double>? _breathingAnimation;

  // PlayStation Color Scheme - White & Blue
  static const Color primaryBlue = Color(0xFF1e3a8a);
  static const Color secondaryBlue = Color(0xFF3b82f6);
  static const Color lightBlue = Color(0xFF60a5fa);
  static const Color accentBlue = Color(0xFF2563eb);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1e293b);
  static const Color textSecondary = Color(0xFF64748b);

  // PlayStation Particles
  List<Offset> _particlePositions = [];

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _initializeVideo();
    _loadUserData();
    _initializeParticles();
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

    // Handle orientation changes safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted && !_isDisposed) {
        final orientation = MediaQuery.of(context).orientation;
        if (orientation == Orientation.landscape && !_isFullScreen) {
          // Handle landscape mode if needed
        }
      }
    });
  }

  void _initializeParticles() {
    if (!_isMounted || _isDisposed) return;

    try {
      _particlePositions = List.generate(
          50, (index) => Offset(Random().nextDouble(), Random().nextDouble()));
    } catch (e) {
      debugPrint('Error initializing particles: $e');
      _particlePositions = [];
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
      _mainController = AnimationController(
        duration: const Duration(milliseconds: 1600),
        vsync: this,
      );
      _cardController = AnimationController(
        duration: const Duration(milliseconds: 1400),
        vsync: this,
      );
      _floatingController = AnimationController(
        duration: const Duration(milliseconds: 3500),
        vsync: this,
      );

      _welcomeController = AnimationController(
        duration: const Duration(milliseconds: 1800),
        vsync: this,
      );

      _shimmerController = AnimationController(
        duration: const Duration(milliseconds: 2500),
        vsync: this,
      );

      _breathingController = AnimationController(
        duration: const Duration(milliseconds: 2800),
        vsync: this,
      );

      _particleController = AnimationController(
        duration: const Duration(seconds: 60),
        vsync: this,
      );

      // Setup Animations with null safety
      if (_mainController != null) {
        _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _mainController!, curve: Curves.easeOutQuart),
        );
        _slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _mainController!,
          curve: Curves.easeOutCubic,
        ));
        _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: _mainController!, curve: Curves.elasticOut),
        );
      }

      if (_cardController != null) {
        _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _cardController!, curve: Curves.easeOutQuint),
        );
        _cardSlideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _cardController!,
          curve: Curves.easeOutBack,
        ));
      }

      if (_floatingController != null) {
        _floatingAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
          CurvedAnimation(
              parent: _floatingController!, curve: Curves.easeInOut),
        );
      }

      if (_welcomeController != null) {
        _welcomeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
              parent: _welcomeController!, curve: Curves.easeOutQuart),
        );

        _welcomeSlideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _welcomeController!,
          curve: Curves.easeOutCubic,
        ));
      }

      if (_shimmerController != null) {
        _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
          CurvedAnimation(parent: _shimmerController!, curve: Curves.easeInOut),
        );
      }

      if (_breathingController != null) {
        _breathingAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
          CurvedAnimation(
              parent: _breathingController!, curve: Curves.easeInOut),
        );
      }

      // Start Animations safely
      _welcomeController?.forward();
      _floatingController?.repeat(reverse: true);
      _shimmerController?.repeat();
      _breathingController?.repeat(reverse: true);
      _particleController?.repeat();
    } catch (e) {
      debugPrint('Error setting up animations: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);

    // Dispose animation controllers safely
    _mainController?.dispose();
    _cardController?.dispose();
    _floatingController?.dispose();
    _welcomeController?.dispose();
    _shimmerController?.dispose();
    _breathingController?.dispose();
    _particleController?.dispose();

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
                  duration: const Duration(milliseconds: 2000),
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
                  'Conectando con la plataforma completa de ORAL PLUS...',
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

    await Future.delayed(const Duration(milliseconds: 2500));

    try {
      final Uri url = Uri.parse('https://oral-plus.com/index.html');

      if (_isMounted && mounted) Navigator.of(context).pop();

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _showSuccessSnackBar('Portal web abierto exitosamente');
      } else {
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
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content:
              const Text('¿Estás seguro que deseas cerrar la sesión actual?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.clearToken();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  _showErrorSnackBar('Error al cerrar sesión: ${e.toString()}');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cerrar Sesión',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
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
                // PlayStation Floating Particles
                _buildFloatingParticles(),

                // Contenido principal: pantalla de bienvenida o dashboard
                _showWelcome ? _buildWelcomeScreen() : _buildMainDashboard(),

                // Navegación inferior transparente (solo si no está en pantalla de bienvenida)
                if (!_showWelcome) _buildTransparentBottomNav(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    if (_particleController == null || _particlePositions.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _particleController!,
      builder: (context, child) {
        return CustomPaint(
          painter: PlayStationParticlePainter(
              _particlePositions, _particleController!.value),
          size: Size.infinite,
        );
      },
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
          GestureDetector(
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundColor, Color(0xFFF1F5F9)],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_welcomeFadeAnimation != null)
              FadeTransition(
                opacity: _welcomeFadeAnimation!,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [primaryBlue, secondaryBlue]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_circle_rounded,
                          color: Colors.white, size: 28),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryBlue.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'BIENVENIDO',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
            if (_welcomeSlideAnimation != null && _welcomeFadeAnimation != null)
              SlideTransition(
                position: _welcomeSlideAnimation!,
                child: FadeTransition(
                  opacity: _welcomeFadeAnimation!,
                  child: Column(
                    children: [
                      if (_floatingAnimation != null &&
                          _breathingAnimation != null)
                        AnimatedBuilder(
                          animation: Listenable.merge(
                              [_floatingAnimation!, _breathingAnimation!]),
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatingAnimation!.value),
                              child: Transform.scale(
                                scale: _breathingAnimation!.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        primaryBlue,
                                        secondaryBlue,
                                        lightBlue
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.4),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.dashboard_customize_rounded,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 40),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [primaryBlue, secondaryBlue],
                        ).createShader(bounds),
                        child: const Text(
                          'Tu Cartera\n Oral-Plus',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Gestiona, paga y controla todas tus facturas\ncon la máxima seguridad y simplicidad',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfessionalFeature(
                              Icons.shield_rounded, 'Seguro'),
                          _buildProfessionalFeature(
                              Icons.bolt_rounded, 'Instantáneo'),
                          _buildProfessionalFeature(
                              Icons.headset_mic_rounded, 'Soporte'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 60),
            if (_welcomeFadeAnimation != null)
              FadeTransition(
                opacity: _welcomeFadeAnimation!,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _enterDashboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Comenzar Experiencia',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryBlue.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Bienvenido, ${_user?.nombre ?? 'Usuario'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: textPrimary,
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
      ),
    );
  }

  Widget _buildProfessionalFeature(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryBlue.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: primaryBlue, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor, Color(0xFFF1F5F9)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_breathingAnimation != null)
                AnimatedBuilder(
                  animation: _breathingAnimation!,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _breathingAnimation!.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                              colors: [primaryBlue, secondaryBlue]),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.dashboard_customize_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 40),
              const Text(
                'Cargando...',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Preparando tu experiencia',
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 30),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: backgroundColor,
      elevation: 0,
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
              padding: const EdgeInsets.all(24),
              child: _fadeAnimation != null && _slideAnimation != null
                  ? FadeTransition(
                      opacity: _fadeAnimation!,
                      child: SlideTransition(
                        position: _slideAnimation!,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfessionalHeader(),
                            const SizedBox(height: 20),
                            _buildProfessionalWelcomeCard(),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfessionalHeader(),
                        const SizedBox(height: 20),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            if (_breathingAnimation != null)
              AnimatedBuilder(
                animation: _breathingAnimation!,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathingAnimation!.value,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                            colors: [primaryBlue, secondaryBlue]),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (_user?.nombre.isNotEmpty == true)
                              ? _user!.nombre.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue]),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (_user?.nombre.isNotEmpty == true)
                        ? _user!.nombre.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bienvenido, ${_user?.nombre ?? 'Usuario'}',
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryBlue.withOpacity(0.2)),
                    ),
                    child: Text(
                      _user?.documento ?? 'ID: ••••••••',
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue.withOpacity(0.2)),
              ),
              child: IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded,
                    color: textSecondary, size: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfessionalWelcomeCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryBlue.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                    colors: [
                      primaryBlue.withOpacity(0.1),
                      secondaryBlue.withOpacity(0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dashboard_customize_rounded,
                    color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bienvenido de nuevo',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Aquí está tu resumen profesional',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Acciones Rápidas'),
                      const SizedBox(height: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Acciones Rápidas'),
                  const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
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
  subtitle: 'Nuestras Noticias Oral-Plus',
  gradient: const [secondaryBlue, lightBlue],
  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Esta sección está en desarrollo'),
        backgroundColor: Colors.orangeAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  },


      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final spacing = 12.0;
        final cardWidth = ((screenWidth - spacing) / 2).clamp(120.0, 200.0);
        final cardHeight = cardWidth * 1.1;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: _buildActionCard(action, cardWidth, cardHeight),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: action.gradient[0].withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: action.gradient[0].withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            action.onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: action.gradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: action.gradient[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(action.icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Text(
                  action.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  action.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSecondary,
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
                      borderRadius: BorderRadius.circular(14),
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
          child: StatefulBuilder(
            builder: (context, setState) {
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Título con icono
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1000),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.bounceOut,
                                builder: (context, iconScale, child) {
                                  return Transform.scale(
                                    scale: iconScale,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.credit_card,
                                        color: Colors.green.shade600,
                                        size: 24,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Procesando Pago',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Contenedor principal de la animación
                          Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade50,
                                  Colors.indigo.shade50,
                                  Colors.purple.shade50,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blue.shade100,
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Partículas de fondo animadas
                                ...List.generate(12, (index) {
                                  return TweenAnimationBuilder<double>(
                                    duration: Duration(
                                        milliseconds: 3000 + (index * 150)),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    curve: Curves.easeInOut,
                                    builder: (context, particleValue, child) {
                                      final xPos = 20 +
                                          (index * 25) +
                                          (particleValue * 15);
                                      final yPos = 20 + (particleValue * 140);
                                      return Positioned(
                                        left: xPos % 280,
                                        top: yPos % 160,
                                        child: Opacity(
                                          opacity:
                                              (0.5 - (particleValue * 0.3)) *
                                                  (index % 2 == 0 ? 1 : 0.7),
                                          child: Container(
                                            width: index % 3 == 0 ? 6 : 4,
                                            height: index % 3 == 0 ? 6 : 4,
                                            decoration: BoxDecoration(
                                              color: index % 2 == 0
                                                  ? Colors.blue.shade300
                                                  : const Color.fromARGB(
                                                      255, 45, 35, 180),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.blue
                                                      .withOpacity(0.3),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),

                                // Datafono (lado derecho)
                                Positioned(
                                  right: 25,
                                  top: 25,
                                  child: TweenAnimationBuilder<double>(
                                    duration:
                                        const Duration(milliseconds: 1000),
                                    tween: Tween(begin: 1.0, end: 0.0),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, slideValue, child) {
                                      return Transform.translate(
                                        offset: Offset(slideValue * 100, 0),
                                        child: TweenAnimationBuilder<double>(
                                          duration: const Duration(
                                              milliseconds: 2500),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, bobValue, child) {
                                            return Transform.translate(
                                              offset:
                                                  Offset(0, (bobValue * 6) * 2),
                                              child: Container(
                                                width: 55,
                                                height: 75,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.grey.shade800,
                                                      Colors.grey.shade900,
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                      blurRadius: 12,
                                                      offset:
                                                          const Offset(0, 6),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  children: [
                                                    const SizedBox(height: 8),
                                                    // Pantalla del datafono
                                                    Container(
                                                      width: 40,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .green.shade400,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(3),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.green
                                                                .withOpacity(
                                                                    0.5),
                                                            blurRadius: 6,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Center(
                                                        child:
                                                            TweenAnimationBuilder<
                                                                double>(
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      1500),
                                                          tween: Tween(
                                                              begin: 0.0,
                                                              end: 1.0),
                                                          builder: (context,
                                                              textOpacity,
                                                              child) {
                                                            return Opacity(
                                                              opacity:
                                                                  textOpacity,
                                                              child: Text(
                                                                'APROBADO',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 6,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Ranura para tarjeta
                                                    Container(
                                                      width: 45,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(2),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Teclado del datafono
                                                    Container(
                                                      width: 35,
                                                      height: 25,
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey.shade700,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(3),
                                                      ),
                                                      child: GridView.count(
                                                        crossAxisCount: 3,
                                                        shrinkWrap: true,
                                                        physics:
                                                            const NeverScrollableScrollPhysics(),
                                                        children: List.generate(
                                                            9, (index) {
                                                          return Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .all(1),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.grey
                                                                  .shade600,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          1),
                                                            ),
                                                          );
                                                        }),
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

                                // Tarjeta ingresándose
                                Positioned(
                                  left: 20,
                                  top: 50,
                                  child: TweenAnimationBuilder<double>(
                                    duration:
                                        const Duration(milliseconds: 2000),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    curve: Curves.easeInOut,
                                    builder: (context, insertValue, child) {
                                      return Transform.translate(
                                        offset: Offset(insertValue * 120, 0),
                                        child: TweenAnimationBuilder<double>(
                                          duration: const Duration(
                                              milliseconds: 3000),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, glowValue, child) {
                                            return Container(
                                              width: 65,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.blue.shade600,
                                                    const Color.fromARGB(
                                                        255, 36, 61, 170),
                                                    Colors.indigo.shade700,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.blue
                                                        .withOpacity(0.4),
                                                    blurRadius:
                                                        12 + (glowValue * 8),
                                                    offset: const Offset(0, 6),
                                                  ),
                                                  BoxShadow(
                                                    color: const Color.fromARGB(
                                                            255, 24, 104, 170)
                                                        .withOpacity(0.3),
                                                    blurRadius:
                                                        20 + (glowValue * 10),
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Stack(
                                                children: [
                                                  // Chip dorado
                                                  Positioned(
                                                    left: 8,
                                                    top: 8,
                                                    child: Container(
                                                      width: 12,
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            Colors
                                                                .amber.shade300,
                                                            Colors.orange
                                                                .shade400,
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(2),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.amber
                                                                .withOpacity(
                                                                    0.6),
                                                            blurRadius: 4,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  // Banda magnética
                                                  Positioned(
                                                    left: 0,
                                                    top: 20,
                                                    right: 0,
                                                    child: Container(
                                                      height: 4,
                                                      color: Colors.black
                                                          .withOpacity(0.8),
                                                    ),
                                                  ),
                                                  // Número de tarjeta
                                                  Positioned(
                                                    left: 8,
                                                    bottom: 8,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          width: 25,
                                                          height: 1.5,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.9),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        0.5),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Container(
                                                          width: 35,
                                                          height: 1.5,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.7),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        0.5),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Logo de la tarjeta
                                                  Positioned(
                                                    right: 8,
                                                    top: 8,
                                                    child: Container(
                                                      width: 16,
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.9),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(2),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          'VISA',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .blue.shade800,
                                                            fontSize: 4,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Indicador de progreso central
                                Center(
                                  child: TweenAnimationBuilder<double>(
                                    duration:
                                        const Duration(milliseconds: 1200),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    curve: Curves.easeInOut,
                                    builder: (context, progressScale, child) {
                                      return Transform.scale(
                                        scale: progressScale,
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 35,
                                              height: 35,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(primaryBlue),
                                                strokeWidth: 3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Ondas de comunicación
                                Positioned.fill(
                                  child: TweenAnimationBuilder<double>(
                                    duration:
                                        const Duration(milliseconds: 2500),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, waveValue, child) {
                                      return CustomPaint();
                                    },
                                  ),
                                ),

                                // Texto de estado dinámico
                                Positioned(
                                  bottom: 10,
                                  left: 20,
                                  right: 20,
                                  child: TweenAnimationBuilder<double>(
                                    duration:
                                        const Duration(milliseconds: 3000),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, statusValue, child) {
                                      String statusText = '';
                                      Color statusColor = Colors.grey.shade600;

                                      if (statusValue < 0.3) {
                                        statusText = 'Insertando tarjeta...';
                                        statusColor = Colors.blue.shade600;
                                      } else if (statusValue < 0.6) {
                                        statusText = 'Leyendo datos...';
                                        statusColor = const Color.fromARGB(
                                            255, 10, 56, 117);
                                      } else if (statusValue < 0.9) {
                                        statusText = 'Procesando...';
                                        statusColor = const Color.fromARGB(
                                            255, 28, 110, 158);
                                      } else {
                                        statusText = 'Validando...';
                                        statusColor = Colors.green.shade600;
                                      }

                                      return Center(
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Texto principal con animación
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1200),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOut,
                            builder: (context, fadeValue, child) {
                              return Opacity(
                                opacity: fadeValue,
                                child: Column(
                                  children: [
                                    const Text(
                                      'Preparando tu pago...',
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 19, 33, 163),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Por favor mantén tu tarjeta en posición',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );

// Painter para las ondas de comunicación

    await Future.delayed(const Duration(milliseconds: 2500));
    if (_isMounted && mounted) Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));

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
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryBlue.withOpacity(0.1),
              primaryBlue.withOpacity(0.2),
              primaryBlue.withOpacity(0.3),
            ],
          ),
          border: Border.all(color: primaryBlue.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                    child: _buildTransparentNavItem(
                        Icons.home_rounded, 'Inicio', 0)),
                Expanded(
                    child: _buildTransparentNavItem(
                        Icons.receipt_long_rounded, 'Facturas', 1)),
                Expanded(
                    child: _buildTransparentNavItem(
                        Icons.person_rounded, 'Perfil', 2)),
              ],
            ),
          ),
        ),
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
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 120,
          minHeight: 60,
          maxHeight: 70,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryBlue.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(color: primaryBlue.withOpacity(0.3))
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryBlue : textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                color: isSelected ? primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to resolve the missing method error
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

// PlayStation Particle Painter
class PlayStationParticlePainter extends CustomPainter {
  final List<Offset> particlePositions;
  final double animationValue;

  PlayStationParticlePainter(this.particlePositions, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _DashboardScreenState.primaryBlue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (var position in particlePositions) {
      final x = position.dx * size.width;
      final y = position.dy * size.height +
          (sin(position.dx * 10 + animationValue * 2 * pi) * 10);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
