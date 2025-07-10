import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _documentoController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  String? _errorMessage;

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _formController;

  // Animaciones
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _formAnimation;

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

    _formController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Animaciones con valores seguros
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
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

    _formAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutBack,
    ));

    // Iniciar animaciones
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _formController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _formController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _documentoController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validar conexión primero
      final isConnected = await ApiService.testConnection();
      if (!isConnected) {
        throw Exception('No se puede conectar al servidor. Verifica tu conexión a internet.');
      }

      final response = await ApiService.register(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim(),
        pin: _pinController.text.trim(),
        documento: _documentoController.text.trim(),
      );

      if (mounted && response['success'] == true) {
        _showSuccessMessage(response['message'] ?? 'Registro exitoso');
        
        // Esperar un momento para que el usuario vea el mensaje
        await Future.delayed(const Duration(seconds: 2));
        
        // Volver a la pantalla de login
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error en registro: $e');
      
      if (mounted) {
        final errorMessage = _parseErrorMessage(e.toString());
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
    } else if (cleanError.contains('registrados') || cleanError.contains('exists')) {
      return 'El documento o teléfono ya están registrados.';
    } else if (cleanError.contains('inválido') || cleanError.contains('invalid')) {
      return 'Datos inválidos. Verifica la información ingresada.';
    } else if (cleanError.contains('500')) {
      return 'Error del servidor. Intenta más tarde.';
    }
    
    return cleanError.isNotEmpty ? cleanError : 'Error desconocido. Intenta nuevamente.';
  }

  void _showSuccessMessage(String message) {
    HapticFeedback.lightImpact();
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
                      '¡Registro Exitoso!',
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
    HapticFeedback.lightImpact();
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _clearForm() {
    HapticFeedback.lightImpact();
    _nombreController.clear();
    _apellidoController.clear();
    _telefonoController.clear();
    _emailController.clear();
    _documentoController.clear();
    _pinController.clear();
    _confirmPinController.clear();
    setState(() {
      _errorMessage = null;
    });
  }

  // Función para asegurar que la opacidad esté en rango válido
  double _clampOpacity(double value) {
    return value.clamp(0.0, 1.0);
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
          child: Column(
            children: [
              // AppBar personalizado
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _clampOpacity(_fadeAnimation.value),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: primaryBlue.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [primaryBlue, secondaryBlue],
                              ).createShader(bounds),
                              child: Text(
                                'Crear Cuenta',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: primaryBlue.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _isLoading ? null : _clearForm,
                              icon: Icon(
                                Icons.clear_all_rounded,
                                color: textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Logo con animación
                      AnimatedBuilder(
                        animation: Listenable.merge([_slideAnimation, _fadeAnimation, _pulseAnimation]),
                        builder: (context, child) {
                          return Transform.translate(
                            offset: _slideAnimation.value * MediaQuery.of(context).size.height,
                            child: Opacity(
                              opacity: _clampOpacity(_fadeAnimation.value),
                              child: Hero(
                                tag: 'app_logo',
                                child: Transform.scale(
                                  scale: _clampOpacity(_pulseAnimation.value),
                                  child: Container(
                                    width: 120,
                                    height: 120,
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
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryBlue.withOpacity(0.3),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
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
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Título con gradiente
                      AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _clampOpacity(_fadeAnimation.value),
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [primaryBlue, secondaryBlue],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Únete a ORAL-PLUS',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: textPrimary,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Crea tu cuenta para acceder a nuestros servicios',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Formulario con diseño moderno
                      AnimatedBuilder(
                        animation: _formAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _clampOpacity(_formAnimation.value),
                            child: Opacity(
                              opacity: _clampOpacity(_formAnimation.value),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Sección de información personal
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [primaryBlue, secondaryBlue],
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.person_outline_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Información Personal',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Nombre y Apellido
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _nombreController,
                                              label: 'Nombre *',
                                              icon: Icons.person_outline_rounded,
                                              textCapitalization: TextCapitalization.words,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                                                LengthLimitingTextInputFormatter(30),
                                              ],
                                              validator: (value) {
                                                if (value == null || value.trim().isEmpty) {
                                                  return 'Requerido';
                                                }
                                                if (value.trim().length < 2) {
                                                  return 'Mín. 2 caracteres';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _apellidoController,
                                              label: 'Apellido *',
                                              icon: Icons.person_outline_rounded,
                                              textCapitalization: TextCapitalization.words,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                                                LengthLimitingTextInputFormatter(30),
                                              ],
                                              validator: (value) {
                                                if (value == null || value.trim().isEmpty) {
                                                  return 'Requerido';
                                                }
                                                if (value.trim().length < 2) {
                                                  return 'Mín. 2 caracteres';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Documento
                                      _buildTextField(
                                        controller: _documentoController,
                                        label: 'Documento (Cédula) *',
                                        hint: '',
                                        icon: Icons.badge_rounded,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(15),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Documento es requerido';
                                          }
                                          if (value.length < 6) {
                                            return 'Mínimo 6 dígitos';
                                          }
                                          if (value.length > 15) {
                                            return 'Máximo 15 dígitos';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Teléfono
                                      _buildTextField(
                                        controller: _telefonoController,
                                        label: 'Teléfono ',
                                        hint: '',
                                        icon: Icons.phone_rounded,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Teléfono es requerido';
                                          }
                                          if (value.length != 10) {
                                            return 'Debe tener exactamente 10 dígitos';
                                          }
                                          if (value.startsWith('0')) {
                                            return 'No puede empezar con 0';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Email
                                      _buildTextField(
                                        controller: _emailController,
                                        label: 'Email*',
                                        hint: 'ejemplo@correo.com',
                                        icon: Icons.email_rounded,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value != null && value.trim().isNotEmpty) {
                                            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                            if (!emailRegex.hasMatch(value.trim())) {
                                              return 'Email inválido';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Sección de seguridad
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [primaryBlue, secondaryBlue],
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.security_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Seguridad',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // PIN
                                      _buildTextField(
                                        controller: _pinController,
                                        label: 'PIN (4 dígitos) *',
                                        hint: '••••',
                                        icon: Icons.lock_rounded,
                                        obscureText: _obscurePin,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                        ],
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePin ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                            color: primaryBlue,
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePin = !_obscurePin;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'PIN es requerido';
                                          }
                                          if (value.length != 4) {
                                            return 'Debe tener exactamente 4 dígitos';
                                          }
                                          if (RegExp(r'^(\d)\1{3}$').hasMatch(value)) {
                                            return 'No puede tener todos los dígitos iguales';
                                          }
                                          if (value == '1234' || value == '4321' || value == '0123' || value == '3210') {
                                            return 'No puede ser secuencial';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Confirmar PIN
                                      _buildTextField(
                                        controller: _confirmPinController,
                                        label: 'Confirmar PIN *',
                                        hint: '••••',
                                        icon: Icons.lock_rounded,
                                        obscureText: _obscureConfirmPin,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                        ],
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPin ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                            color: primaryBlue,
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPin = !_obscureConfirmPin;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Confirma tu PIN';
                                          }
                                          if (value != _pinController.text) {
                                            return 'Los PINs no coinciden';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      // Mostrar error si existe
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
                                      
                                      // Botón de registro
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
                                          onPressed: _isLoading ? null : _register,
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
                                                  'Crear Cuenta',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Información adicional
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: primaryBlue.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: primaryBlue.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              color: primaryBlue,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Los campos marcados con * son obligatorios. Tu información está protegida.',
                                                style: TextStyle(
                                                  color: textSecondary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
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
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Botón para volver al login
                      AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _clampOpacity(_fadeAnimation.value),
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
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryBlue,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '¿Ya tienes cuenta? Inicia sesión',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
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
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        suffixIcon: suffixIcon,
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
        errorStyle: const TextStyle(
          color: Color(0xFFE53E3E),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: validator,
    );
  }
}