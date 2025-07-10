import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'package:video_player/video_player.dart';
import '../models/invoice_model.dart';
import '../models/appointment_model.dart';
import 'invoice_history_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'simple-wompi-screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'invoice_detail_screen.dart';
import 'products.dart';
import 'shopping_loading_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with TickerProviderStateMixin {
  UserModel? _user;
  List<InvoiceModel> _pendingInvoices = [];
  List<AppointmentModel> _upcomingAppointments = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  bool _showWelcome = true;

  // Video Player Controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showVideoControls = true;
  bool _isFullScreen = false;

  // Animation Controllers
  late AnimationController _mainController;
  late AnimationController _cardController;
  late AnimationController _floatingController;
  late AnimationController _welcomeController;
  late AnimationController _shimmerController;
  late AnimationController _breathingController;
  late AnimationController _particleController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _welcomeFadeAnimation;
  late Animation<Offset> _welcomeSlideAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _breathingAnimation;

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
    _setupAnimations();
    _initializeVideo();
    _loadUserData();
    _initializeParticles();
  }

  void _initializeParticles() {
    _particlePositions = List.generate(50, (index) => 
      Offset(Random().nextDouble(), Random().nextDouble())
    );
  }

 void _initializeVideo() async {
  try {
    _videoController = VideoPlayerController.asset('assets/Videos/VIDEO.mp4');
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.setVolume(0.7);
    
    _videoController!.addListener(_videoListener);
    
    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
        _showVideoControls = true; // Mostrar controles al principio
      });
      _videoController!.play();
      _autoHideControls();
    }
  } catch (e) {
    print('Error initializing video: $e');  
    if (mounted) {
      setState(() {
        _isVideoInitialized = false;
      });
    }
  }
}

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _videoController != null && _videoController!.value.isPlaying) {
        setState(() {
          _showVideoControls = false;
        });
      }
    });
  }

  void _toggleVideoControls() {
    setState(() {
      _showVideoControls = !_showVideoControls;
    });
    
    if (_showVideoControls) {
      _autoHideControls();
    }
  }

 void _togglePlayPause() {
  if (_videoController != null && _videoController!.value.isInitialized) {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }
}

  void _toggleFullScreen() {
    setState(() {
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

  void _setupAnimations() {
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
    
    // Setup Animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutQuart),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController, 
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );
    
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutQuint),
    );
    
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController, 
      curve: Curves.easeOutBack,
    ));
    
    _floatingAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _welcomeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeOutQuart),
    );

    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _welcomeController, 
      curve: Curves.easeOutCubic,
    ));

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    
    // Start Animations
    _welcomeController.forward();
    _floatingController.repeat(reverse: true);
    _shimmerController.repeat();
    _breathingController.repeat(reverse: true);
    _particleController.repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _cardController.dispose();
    _floatingController.dispose();
    _welcomeController.dispose();
    _shimmerController.dispose();
    _breathingController.dispose();
    _particleController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      
      final hasSession = await ApiService.hasActiveSession();
      if (!hasSession) {
        _redirectToLogin();
        return;
      }

      final user = await ApiService.getUserProfile();
      final pendingInvoices = await ApiService.getPendingInvoices();
      final upcomingAppointments = await ApiService.getUpcomingAppointments();
      
      if (mounted) {
        setState(() {
          _user = user;
          _pendingInvoices = pendingInvoices ?? [];
          _upcomingAppointments = upcomingAppointments ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error cargando información: ${e.toString()}');
      }
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await _loadUserData();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50), // PlayStation curved
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53E3E).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50), // PlayStation curved
                ),
                child: const Icon(
                  Icons.error_outline_rounded, 
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
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50), // PlayStation curved
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50), // PlayStation curved
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded, 
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
                    const Text(
                      'Éxito',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // TODOS LOS MÉTODOS ORIGINALES MANTENIDOS
  Future<void> _sendAutoWhatsAppMessage() async {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(50), // PlayStation curved
              border: Border.all(
                color: const Color(0xFF25D366).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Enviando Mensaje',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparando mensaje de soporte automático...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF25D366)),
                    strokeWidth: 4,
                  ),
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
      final timestamp = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
      
      final message = Uri.encodeComponent(
        '🔧 SOLICITUD DE SOPORTE TÉCNICO - ORAL PLUS\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
        '👤 INFORMACIÓN DEL USUARIO:\n'
        '• Nombre: $userName\n'
        '• Documento: $userDoc\n'
        '• Fecha/Hora: $timestamp\n'
        '• Plataforma: App Móvil Premium\n\n'
        '📱 DETALLES TÉCNICOS:\n'
        '• Versión App: 2.0.0\n'
        '• Tipo Solicitud: Soporte General\n'
        '• Canal: WhatsApp Automático\n\n'
        '💬 MENSAJE:\n'
        'Hola! Necesito asistencia técnica con mi cuenta de ORAL PLUS. '
        'Este mensaje fue enviado automáticamente desde la aplicación móvil.\n\n'
        '⚡ Por favor, responde a este mensaje para iniciar el soporte.\n\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '🏥 ORAL PLUS - Sistema de Gestión Médica'
      );
      
      final whatsappUrls = [
        'whatsapp://send?phone=573024037819&text=$message&app_absent=0',
        'https://api.whatsapp.com/send/?phone=573024037819&text=$message&type=phone_number&app_absent=0',
        'https://wa.me/573024037819/?text=$message',
        'whatsapp://send?phone=+573024037819&text=$message',
        'https://web.whatsapp.com/send?phone=573024037819&text=$message',
      ];
      
      Navigator.of(context).pop();
      
      bool messageSent = false;
      
      for (int i = 0; i < whatsappUrls.length; i++) {
        try {
          final Uri uri = Uri.parse(whatsappUrls[i]);
          
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
              webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true,
                enableDomStorage: true,
              ),
            );
            
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
      Navigator.of(context).pop();
      _showWhatsAppManualOptions();
    }
  }

  void _showWhatsAppSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(50), // PlayStation curved
              border: Border.all(
                color: const Color(0xFF25D366).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '¡Mensaje Preparado!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'WhatsApp se ha abierto con tu mensaje de soporte pre-escrito.\n\n'
                  '📱 Solo presiona "Enviar" en WhatsApp para contactar al equipo de soporte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    borderRadius: BorderRadius.circular(50), // PlayStation curved
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                      ),
                    ),
                    child: const Text(
                      'Perfecto',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(50), // PlayStation curved
              border: Border.all(
                color: primaryBlue.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Contacto Alternativo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudo abrir WhatsApp automáticamente. Usa estas opciones:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),
                
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
                
                const SizedBox(height: 16),
                
                _buildContactOption(
                  icon: Icons.copy_rounded,
                  title: 'Copiar Número',
                  subtitle: 'Para WhatsApp manual',
                  gradient: const [primaryBlue, secondaryBlue],
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: '+573006467135'));
                    Navigator.of(context).pop();
                    _showSuccessSnackBar('Número copiado: +57 300 646 7135');
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildContactOption(
                  icon: Icons.message_rounded,
                  title: 'Abrir WhatsApp',
                  subtitle: 'Buscar contacto manualmente',
                  gradient: const [accentBlue, primaryBlue],
                  onTap: () async {
                    final Uri whatsappApp = Uri.parse('whatsapp://');
                    if (await canLaunchUrl(whatsappApp)) {
                      await launchUrl(whatsappApp);
                    }
                    Navigator.of(context).pop();
                  },
                ),
                
                const SizedBox(height: 32),
                
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(50), // PlayStation curved
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                      ),
                    ),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(50), // PlayStation curved
              border: Border.all(
                color: primaryBlue.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
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
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryBlue, secondaryBlue],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                  ).createShader(bounds),
                  child: Text(
                    'Abriendo Portal Web',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Conectando con la plataforma completa de ORAL PLUS...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),
                
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(50), // PlayStation curved
                  ),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 2000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50), // PlayStation curved
                        ),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50), // PlayStation curved
                    border: Border.all(
                      color: primaryBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50), // PlayStation curved
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conexión Segura',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Acceso protegido con SSL',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
      
      Navigator.of(context).pop();
      
      await _showWebPortalSuccessDialog();
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url, 
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 500), () {
          _showSuccessSnackBar('Portal web abierto exitosamente');
        });
        
      } else {
        _showWebPortalErrorDialog();
      }
      
    } catch (e) {
      Navigator.of(context).pop();
      _showWebPortalErrorDialog();
    }
  }

  Future<void> _showWebPortalSuccessDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(50), // PlayStation curved
              border: Border.all(
                color: primaryBlue.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryBlue, secondaryBlue],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                  ).createShader(bounds),
                  child: Text(
                    '¡Portal Listo!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'El portal web de ORAL PLUS se abrirá en tu navegador predeterminado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50), // PlayStation curved
                    border: Border.all(
                      color: primaryBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildPortalFeature(Icons.dashboard_rounded, 'Panel Completo', 'Acceso total a todas las funciones'),
                      const SizedBox(height: 16),
                      _buildPortalFeature(Icons.analytics_rounded, 'Reportes Avanzados', 'Estadísticas detalladas y gráficos'),
                      const SizedBox(height: 16),
                      _buildPortalFeature(Icons.settings_rounded, 'Configuración', 'Personaliza tu experiencia'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(50), // PlayStation curved
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Continuar al Portal',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50), // PlayStation curved
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
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
      },
    );
  }

  Widget _buildPortalFeature(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50), // PlayStation curved
          ),
          child: Icon(
            icon,
            color: primaryBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWebPortalErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(50), // PlayStation curved
              border: Border.all(
                color: const Color(0xFFE53E3E).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53E3E).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Error de Conexión',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudo acceder al portal web. Verifica tu conexión a internet e inténtalo nuevamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(50), // PlayStation curved
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50), // PlayStation curved
                            ),
                          ),
                          child: Text(
                            'Cerrar',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryBlue, secondaryBlue],
                          ),
                          borderRadius: BorderRadius.circular(50), // PlayStation curved
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _openWebPortalWithStyle();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50), // PlayStation curved
                            ),
                          ),
                          child: const Text(
                            'Reintentar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
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
        borderRadius: BorderRadius.circular(50), // PlayStation curved
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50), // PlayStation curved
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50), // PlayStation curved
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(50), // PlayStation curved
              border: Border.all(
                color: const Color(0xFFE53E3E).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53E3E).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Estás seguro que deseas cerrar la sesión actual?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(50), // PlayStation curved
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50), // PlayStation curved
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryBlue, secondaryBlue],
                          ),
                          borderRadius: BorderRadius.circular(50), // PlayStation curved
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            await ApiService.clearToken();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50), // PlayStation curved
                            ),
                          ),
                          child: const Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
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
    setState(() => _showWelcome = false);
    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _cardController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenVideo();
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          // PlayStation Floating Particles
          _buildFloatingParticles(),
          _showWelcome ? _buildWelcomeScreen() : _buildMainDashboard(),
          if (!_showWelcome) _buildTransparentBottomNav(),
        ],
      ),
    );
  }

  // PlayStation Floating Particles
  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: PlayStationParticlePainter(_particlePositions, _particleController.value),
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
                            icon: const Icon(
                              Icons.fullscreen_exit_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              if (_videoController != null) {
                                setState(() {
                                  _videoController!.setVolume(
                                    _videoController!.value.volume > 0 ? 0.0 : 0.7
                                  );
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
                            borderRadius: BorderRadius.circular(50), // PlayStation curved
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
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
                    
                    if (_videoController != null && _videoController!.value.isInitialized)
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

  Widget _buildVideoControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(50), // PlayStation curved
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              FadeTransition(
                opacity: _welcomeFadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryBlue, secondaryBlue],
                        ),
                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_circle_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                        border: Border.all(
                          color: primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'BIENVENIDO',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              SlideTransition(
                position: _welcomeSlideAnimation,
                child: FadeTransition(
                  opacity: _welcomeFadeAnimation,
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([_floatingAnimation, _breathingAnimation]),
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingAnimation.value),
                            child: Transform.scale(
                              scale: _breathingAnimation.value,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50), // PlayStation curved
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
                                      color: primaryBlue.withOpacity(0.4),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.dashboard_customize_rounded,
                                  color: Colors.white,
                                  size: 70,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 60),
                      
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [primaryBlue, secondaryBlue],
                        ).createShader(bounds),
                        child: const Text(
                          'Tu Cartera\nSky Premium',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Gestiona, paga y controla todas tus facturas\ncon la máxima seguridad y simplicidad',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: textSecondary,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 80),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfessionalFeature(Icons.shield_rounded, 'Seguro'),
                          _buildProfessionalFeature(Icons.bolt_rounded, 'Instantáneo'),
                          _buildProfessionalFeature(Icons.headset_mic_rounded, 'Soporte'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              FadeTransition(
                opacity: _welcomeFadeAnimation,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryBlue, secondaryBlue],
                        ),
                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _enterDashboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50), // PlayStation curved
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Comenzar Experiencia',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50), // PlayStation curved
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                        border: Border.all(
                          color: primaryBlue.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Bienvenido, ${_user?.nombre ?? 'Usuario'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildProfessionalFeature(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(50), // PlayStation curved
            border: Border.all(
              color: primaryBlue.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: primaryBlue,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
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
          colors: [
            backgroundColor,
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryBlue,
        backgroundColor: cardBackground,
        strokeWidth: 3,
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
            colors: [
              backgroundColor,
              Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathingAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                        gradient: const LinearGradient(
                          colors: [primaryBlue, secondaryBlue],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.dashboard_customize_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              Text(
                'Cargando...',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Preparando tu experiencia premium',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  strokeWidth: 4,
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
              colors: [
                backgroundColor,
                Color(0xFFF1F5F9),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfessionalHeader(),
                      const SizedBox(height: 24),
                      _buildProfessionalWelcomeCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _breathingAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _breathingAnimation.value,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50), // PlayStation curved
                  gradient: const LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _user?.nombre.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${_user?.nombre ?? 'Usuario'}',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(50), // PlayStation curved
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  _user?.documento ?? 'ID: ••••••••',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
            borderRadius: BorderRadius.circular(50), // PlayStation curved
            border: Border.all(
              color: primaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: _logout,
            icon: Icon(
              Icons.logout_rounded,
              color: textSecondary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(50), // PlayStation curved
        border: Border.all(
          color: primaryBlue.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.1),
                  secondaryBlue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(50), // PlayStation curved
            ),
            child: const Icon(
              Icons.dashboard_customize_rounded,
              color: primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de Control Premium',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Administra tus finanzas de manera inteligente',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: SlideTransition(
          position: _cardSlideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Acciones Rápidas'),
                const SizedBox(height: 24),
                _buildProfessionalActionsGrid(),
                const SizedBox(height: 40),
                
                _buildInvoicesList(),
                const SizedBox(height: 120), // Espacio para el bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: textPrimary,
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
  onTap: () async {
    HapticFeedback.mediumImpact();
    
    // Mostrar animación de carga tipo datáfono
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animación del datáfono
                Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      // Slot de la tarjeta
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // Pantalla del datáfono
                      Positioned(
                        bottom: 10,
                        left: 15,
                        right: 15,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: Text(
                              'PROCESANDO...',
                              style: TextStyle(
                                fontSize: 6,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Animación de la tarjeta deslizándose
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween(begin: -100.0, end: 0.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(value, 0),
                      child: Container(
                        width: 80,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.blueAccent],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Indicador de carga
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
                
                const SizedBox(height: 15),
                
                const Text(
                  'Insertando tarjeta...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    // Simular tiempo de procesamiento y cerrar automáticamente
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.of(context).pop(); // Cerrar el diálogo de carga
    });
    
    // Esperar un poco más antes de navegar
    await Future.delayed(const Duration(milliseconds: 2700));
    
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
  },
),
   ActionData(
  icon: Icons.receipt_long_rounded,
  title: 'Historial Completo',
  subtitle: 'Todas tus transacciones',
  gradient: const [secondaryBlue, lightBlue],
  onTap: () {
    HapticFeedback.lightImpact();
    
    // Mostrar pantalla de carga con icono animado
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.black.withOpacity(0.5),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: AlwaysStoppedAnimation(DateTime.now().second / 60),
                  builder: (_, child) {
                    return Transform.rotate(
                      angle: 2 * pi * DateTime.now().second / 60,
                      child: Icon(
                        Icons.history_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Buscando tu historial...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
              ),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );

    // Simular carga de datos
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      
      // Navegar a pantalla de historial con animación personalizada
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const InvoiceHistoryScreen(),
          transitionsBuilder: (context, animation, _, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.9,
                  end: 1.0,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  },
),
   ActionData(
  icon: Icons.shopping_bag_rounded,
  title: 'Nuestros Productos',
  subtitle: 'Nuestro catalogo de productos',
  gradient: const [Color(0xFF1E88E5), Color(0xFF42A5F5)],
  onTap: () {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ShoppingLoadingScreen(destination: const ProductsTab()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  },
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
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(50), // PlayStation curved
                  border: Border.all(
                    color: action.gradient[0].withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: action.gradient[0].withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                    borderRadius: BorderRadius.circular(50), // PlayStation curved
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: action.gradient),
                              borderRadius: BorderRadius.circular(50), // PlayStation curved
                              boxShadow: [
                                BoxShadow(
                                  color: action.gradient[0].withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              action.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            action.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            action.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: action.gradient[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50), // PlayStation curved
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: action.gradient[0],
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInvoicesList() {
    if (_pendingInvoices.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(50), // PlayStation curved
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Video Player - Más pegado y grande
            Container(
              width: double.infinity,
              height: 350, // Más grande
              margin: const EdgeInsets.all(8), // Margen mínimo
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                ),
                borderRadius: BorderRadius.circular(50), // PlayStation curved
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50), // PlayStation curved
                child: _isVideoInitialized && _videoController != null
                    ? Stack(
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16, 
                                            vertical: 8
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(50), // PlayStation curved
                                          ),
                                          child: const Text(
                                            'ORAL PLUS',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            _buildVideoControlButton(
                                              icon: _videoController?.value.volume == 0 
                                                  ? Icons.volume_off_rounded 
                                                  : Icons.volume_up_rounded,
                                              onTap: () {
                                                if (_videoController != null) {
                                                  setState(() {
                                                    _videoController!.setVolume(
                                                      _videoController!.value.volume > 0 ? 0.0 : 0.7
                                                    );
                                                  });
                                                }
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            _buildVideoControlButton(
                                              icon: Icons.fullscreen_rounded,
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
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.95),
                                          borderRadius: BorderRadius.circular(50), // PlayStation curved
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _videoController!.value.isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: primaryBlue,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const Spacer(),
                                  
                                  if (_videoController!.value.isInitialized)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                                        child: VideoProgressIndicator(
                                          _videoController!,
                                          allowScrubbing: true,
                                          colors: VideoProgressColors(
                                            playedColor: Colors.white,
                                            bufferedColor: Colors.white.withOpacity(0.3),
                                            backgroundColor: Colors.white.withOpacity(0.2),
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
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryBlue, secondaryBlue],
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 4,
                              ),
                              SizedBox(height: 24),
                              Text(
                                'Cargando video...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryBlue, secondaryBlue],
                      ),
                      borderRadius: BorderRadius.circular(50), // PlayStation curved
                    ),
                    child: const Text(
                      '¡ORAL-PLUS!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SALUD Y BELLEZA EN TU SONRISA ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
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
                opacity: value,
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
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 1.0),
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

  // Transparent Bottom Navigation with Blue Accents
  Widget _buildTransparentBottomNav() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          // Transparent background with blue tint
          color: Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
          // Blue gradient overlay with transparency
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryBlue.withOpacity(0.1),
              primaryBlue.withOpacity(0.2),
              primaryBlue.withOpacity(0.3),
            ],
          ),
          border: Border.all(
            color: primaryBlue.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, -15),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTransparentNavItem(Icons.home_rounded, 'Inicio', 0),
                _buildTransparentNavItem(Icons.receipt_long_rounded, 'Facturas', 1),
                _buildTransparentNavItem(Icons.person_rounded, 'Perfil', 2),
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
        setState(() => _selectedIndex = index);
        
        switch (index) {
          case 0:
            // Inicio - no hacer nada, ya estamos aquí
            break;
          case 1:
            // Facturas - navegar a InvoiceHistoryScreen
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const InvoiceHistoryScreen(),
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
            break;
          case 2:
            // Perfil - navegar a ProfileScreen
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ProfileScreen(),
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
            break;
        }
      },
      child: Container(
        width: 90,
        height: 85,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            
            // Icono principal con fondo azul transparente cuando está seleccionado
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected 
                    ? primaryBlue.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: isSelected 
                    ? Border.all(
                        color: primaryBlue.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryBlue : textSecondary,
                size: 22,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Indicador de selección - línea azul
            Container(
              width: 70,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Texto del label
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? primaryBlue : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PlayStation Particle Painter
class PlayStationParticlePainter extends CustomPainter {
  final List<Offset> particlePositions;
  final double animationValue;

  PlayStationParticlePainter(this.particlePositions, this.animationValue);
  
  get primaryBlue => null;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryBlue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (var position in particlePositions) {
      final x = position.dx * size.width;
      final y = position.dy * size.height + (sin(position.dx * 10 + animationValue * 2 * pi) * 10);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PlayStationParticlePainter oldDelegate) {
    return true;
  }
}

// Helper Classes
class ActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const ActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}

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
        borderRadius: BorderRadius.circular(50), // PlayStation curved
        border: Border.all(
          color: isUrgent 
              ? const Color(0xFFE53E3E).withOpacity(0.3)
              : _DashboardScreenState.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent 
                ? const Color(0xFFE53E3E).withOpacity(0.1)
                : _DashboardScreenState.primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50), // PlayStation curved
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUrgent 
                              ? [const Color(0xFFE53E3E), const Color(0xFFDC2626)]
                              : [_DashboardScreenState.primaryBlue, _DashboardScreenState.secondaryBlue],
                        ),
                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                        boxShadow: [
                          BoxShadow(
                            color: isUrgent 
                                ? const Color(0xFFE53E3E).withOpacity(0.3)
                                : _DashboardScreenState.primaryBlue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        isUrgent ? Icons.warning_rounded : Icons.receipt_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.description,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: _DashboardScreenState.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _DashboardScreenState.backgroundColor,
                              borderRadius: BorderRadius.circular(50), // PlayStation curved
                              border: Border.all(
                                color: _DashboardScreenState.primaryBlue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Vence: ${invoice.formattedDueDate}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _DashboardScreenState.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${NumberFormat('#,##0', 'es_CO').format(invoice.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: _DashboardScreenState.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isUrgent
                                  ? [const Color(0xFFE53E3E), const Color(0xFFDC2626)]
                                  : [_DashboardScreenState.primaryBlue, _DashboardScreenState.secondaryBlue],
                            ),
                            borderRadius: BorderRadius.circular(50), // PlayStation curved
                          ),
                          child: Text(
                            isUrgent
                                ? daysLeft == 0 ? '¡HOY!' : '$daysLeft días'
                                : '$daysLeft días',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUrgent
                          ? [const Color(0xFFE53E3E), const Color(0xFFDC2626)]
                          : [_DashboardScreenState.primaryBlue, _DashboardScreenState.secondaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(50), // PlayStation curved
                    boxShadow: [
                      BoxShadow(
                        color: isUrgent 
                            ? const Color(0xFFE53E3E).withOpacity(0.3)
                            : _DashboardScreenState.primaryBlue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50), // PlayStation curved
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isUrgent ? Icons.warning_rounded : Icons.payment_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isUrgent ? 'PAGAR AHORA' : 'PAGAR FACTURA',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
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
      ),
    );
  }
}