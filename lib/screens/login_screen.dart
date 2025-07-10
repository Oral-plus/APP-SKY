import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  String? _errorMessage;

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  // Animaciones
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

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
    _checkExistingSession();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Iniciar animaciones
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _documentoController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    try {
      final hasSession = await ApiService.hasActiveSession();
      if (hasSession && mounted) {
        print('✅ Sesión activa encontrada, redirigiendo al dashboard');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      print('❌ Error verificando sesión: $e');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final documentoOriginal = _documentoController.text.trim();
      final pin = _pinController.text.trim();
      
      print('🔐 Iniciando login...');
      print('📄 Documento original: $documentoOriginal');
      
      // Validar conexión primero
      final isConnected = await ApiService.testConnection();
      if (!isConnected) {
        throw Exception('No se puede conectar al servidor. Verifica tu conexión a internet.');
      }
      
      // Intentar login con diferentes variaciones del documento
      Map<String, dynamic>? response;
      String documentoUsado = '';
      
      // Lista de variaciones a probar
      final variaciones = [
        documentoOriginal, // Original tal como se escribió
        documentoOriginal.toLowerCase(), // Todo en minúsculas
        documentoOriginal.toUpperCase(), // Todo en mayúsculas
        // Si empieza con letra, probar con la primera letra en mayúscula
        documentoOriginal.isNotEmpty && RegExp(r'^[a-zA-Z]').hasMatch(documentoOriginal)
            ? documentoOriginal[0].toUpperCase() + documentoOriginal.substring(1).toLowerCase()
            : null,
        // Si empieza con letra, probar con la primera letra en minúscula
        documentoOriginal.isNotEmpty && RegExp(r'^[a-zA-Z]').hasMatch(documentoOriginal)
            ? documentoOriginal[0].toLowerCase() + documentoOriginal.substring(1).toLowerCase()
            : null,
      ].where((doc) => doc != null).cast<String>().toSet().toList(); // Eliminar duplicados
      
      print('🔄 Probando ${variaciones.length} variaciones del documento:');
      for (int i = 0; i < variaciones.length; i++) {
        print('   ${i + 1}. "${variaciones[i]}"');
      }
      
      // Probar cada variación
      for (final documento in variaciones) {
        try {
          print('🔍 Probando con documento: "$documento"');
          response = await ApiService.loginWithDocumento(documento, pin);
          
          if (response['success'] == true) {
            documentoUsado = documento;
            print('✅ Login exitoso con documento: "$documento"');
            break;
          } else {
            print('❌ Falló con documento: "$documento" - ${response['error']}');
          }
        } catch (e) {
          print('❌ Error con documento "$documento": $e');
          // Continuar con la siguiente variación
          continue;
        }
      }
      
      // Verificar si alguna variación funcionó
      if (response == null || response['success'] != true) {
        throw Exception('Documento o PIN incorrectos. Verifica tus datos.\n\nSe probaron las siguientes variaciones:\n${variaciones.map((d) => '• "$d"').join('\n')}');
      }
      
      if (mounted) {
        print('🎉 Login exitoso con documento: "$documentoUsado"');
        
        // Mostrar mensaje de éxito con el documento que funcionó
        _showSuccessMessage('Login exitoso con documento: "$documentoUsado"');
        
        // Pequeña pausa para que el usuario vea el mensaje
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navegar al dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      print('❌ Error en login: $e');
      
      if (mounted) {
        String errorMessage = _parseErrorMessage(e.toString());
        setState(() {
          _errorMessage = errorMessage;
        });
        
        _showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _parseErrorMessage(String error) {
    String cleanError = error.replaceAll('Exception: ', '');
    
    if (cleanError.contains('conexión') || cleanError.contains('connection')) {
      return 'Error de conexión. Verifica tu internet e intenta nuevamente.';
    } else if (cleanError.contains('timeout')) {
      return 'La conexión tardó demasiado. Intenta nuevamente.';
    } else if (cleanError.contains('404')) {
      return 'Servicio no disponible. Contacta al soporte técnico.';
    } else if (cleanError.contains('500')) {
      return 'Error del servidor. Intenta más tarde.';
    } else if (cleanError.contains('incorrectas') || cleanError.contains('invalid')) {
      return 'Documento o PIN incorrectos. Verifica tus datos.';
    }
    
    return cleanError.isNotEmpty ? cleanError : 'Error desconocido. Intenta nuevamente.';
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '¡Bienvenido!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
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
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
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
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _clearForm() {
    _documentoController.clear();
    _pinController.clear();
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Configurar barra de estado para tema claro
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
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
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Logo con animación mejorada
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Hero(
                        tag: 'app_logo',
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primaryBlue,
                                      secondaryBlue,
                                      lightBlue,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(35),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: secondaryBlue.withOpacity(0.2),
                                      blurRadius: 50,
                                      spreadRadius: 10,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(35),
                                  child: Image.asset(
                                    'assets/logo-pagos.png',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error cargando imagen: $error');
                                      return const Center(
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Título con gradiente
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [primaryBlue, secondaryBlue],
                      ).createShader(bounds),
                      child: Text(
                        'ORAL-PLUS',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Ingresa con tu documento y PIN',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Formulario con diseño moderno
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Campo de documento mejorado
                              TextFormField(
                                controller: _documentoController,
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(15),
                                  // Permitir letras, números y algunos caracteres especiales comunes
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-_]')),
                                ],
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Documento',
                                  labelStyle: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  hintText: '',
                                  hintStyle: TextStyle(
                                    color: textSecondary.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                  helperText: 'Se probará automáticamente con mayúsculas y minúsculas',
                                  helperStyle: TextStyle(
                                    color: textSecondary.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [primaryBlue, secondaryBlue],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.badge_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryBlue.withOpacity(0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryBlue.withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: primaryBlue,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE53E3E),
                                      width: 2,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE53E3E),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: backgroundColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa tu documento';
                                  }
                                  if (value.trim().length < 6) {
                                    return 'El documento debe tener al menos 6 caracteres';
                                  }
                                  if (value.trim().length > 15) {
                                    return 'El documento no puede tener más de 15 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Campo de PIN moderno
                              TextFormField(
                                controller: _pinController,
                                obscureText: _obscurePin,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'PIN',
                                  labelStyle: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  hintText: 'Ingresa tu PIN de 4 dígitos',
                                  hintStyle: TextStyle(
                                    color: textSecondary.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [primaryBlue, secondaryBlue],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.lock_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePin
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: primaryBlue,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePin = !_obscurePin;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryBlue.withOpacity(0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryBlue.withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: primaryBlue,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE53E3E),
                                      width: 2,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE53E3E),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: backgroundColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu PIN';
                                  }
                                  if (value.length != 4) {
                                    return 'El PIN debe tener exactamente 4 dígitos';
                                  }
                                  return null;
                                },
                              ),
                              
                              // Mostrar error moderno
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: Color(0xFFE53E3E),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: Color(0xFFE53E3E),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: Color(0xFFE53E3E),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _errorMessage = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              const SizedBox(height: 32),
                              
                              // Botón de login moderno
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [primaryBlue, secondaryBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Botón para limpiar formulario
                              TextButton(
                                onPressed: _isLoading ? null : _clearForm,
                                child: Text(
                                  'Limpiar campos',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Enlaces modernos
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: primaryBlue.withOpacity(0.2), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBlue.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(Icons.info_outline_rounded, color: primaryBlue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Contacta al administrador para recuperar tu PIN',
                                      style: TextStyle(color: textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            backgroundColor: Colors.transparent,
                            behavior: SnackBarBehavior.floating,
                            elevation: 0,
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      child: const Text(
                        '¿Olvidaste tu PIN?',
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botón de registro moderno
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryBlue,
                          width: 2,
                        ),
                      ),
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryBlue,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '¿No tienes cuenta? Regístrate',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}