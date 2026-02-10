import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/app_assets.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

// Colores y estilos compartidos (una sola definición = menos memoria, carga rápida)
const _kPrimaryBlue = Color(0xFF1e3a8a);
const _kSecondaryBlue = Color(0xFF3b82f6);
const _kLightBlue = Color(0xFF60a5fa);
const _kBackgroundColor = Color(0xFFF8FAFC);
const _kCardBackground = Colors.white;
const _kTextPrimary = Color(0xFF1e293b);
const _kTextSecondary = Color(0xFF64748b);
const _kErrorRed = Color(0xFFDC2626);

const _kInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  borderSide: BorderSide(color: Color(0xFFE2E8F0)),
);
const _kInputBorderFocused = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
);
const _kInputBorderError = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  borderSide: BorderSide(color: _kErrorRed, width: 2),
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _documentoController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    try {
      final hasSession = await ApiService.hasActiveSession();
      if (hasSession && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (_) {}
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

      final isConnected = await ApiService.testConnection();
      if (!isConnected) {
        throw Exception('No se puede conectar al servidor. Verifica tu conexión a internet.');
      }

      final variaciones = [
        documentoOriginal,
        documentoOriginal.toLowerCase(),
        documentoOriginal.toUpperCase(),
        documentoOriginal.isNotEmpty && RegExp(r'^[a-zA-Z]').hasMatch(documentoOriginal)
            ? documentoOriginal[0].toUpperCase() + documentoOriginal.substring(1).toLowerCase()
            : null,
        documentoOriginal.isNotEmpty && RegExp(r'^[a-zA-Z]').hasMatch(documentoOriginal)
            ? documentoOriginal[0].toLowerCase() + documentoOriginal.substring(1).toLowerCase()
            : null,
      ].where((doc) => doc != null).cast<String>().toSet().toList();

      Map<String, dynamic>? response;
      String documentoUsado = '';

      for (final documento in variaciones) {
        try {
          response = await ApiService.loginWithDocumento(documento, pin);
          if (response['success'] == true) {
            documentoUsado = documento;
            break;
          }
        } catch (_) {
          continue;
        }
      }

      if (response == null || response['success'] != true) {
        throw Exception('Documento o PIN incorrectos. Verifica tus datos.');
      }

      if (mounted) {
        _showSnack(context, 'Bienvenido', documentoUsado, isError: false);
        await Future.delayed(const Duration(milliseconds: 400));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = _parseErrorMessage(e.toString());
        setState(() => _errorMessage = msg);
        _showSnack(context, 'Error', msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _parseErrorMessage(String error) {
    final clean = error.replaceAll('Exception: ', '');
    if (clean.contains('conexión') || clean.contains('connection')) return 'Verifica tu conexión e intenta de nuevo.';
    if (clean.contains('timeout')) return 'La conexión tardó demasiado.';
    if (clean.contains('404')) return 'Servicio no disponible.';
    if (clean.contains('500')) return 'Error del servidor. Intenta más tarde.';
    if (clean.contains('incorrectos') || clean.contains('invalid')) return 'Documento o PIN incorrectos.';
    return clean.isNotEmpty ? clean : 'Error. Intenta de nuevo.';
  }

  static void _showSnack(BuildContext context, String title, String message, {required bool isError}) {
    final color = isError ? _kErrorRed : const Color(0xFF16A34A);
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: _kTextPrimary, fontSize: 14)),
                  Text(message, style: const TextStyle(color: _kTextSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _kCardBackground,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 5 : 2),
      ),
    );
  }

  void _clearForm() {
    _documentoController.clear();
    _pinController.clear();
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _kBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      _Logo(primary: _kPrimaryBlue, secondary: _kSecondaryBlue, light: _kLightBlue),
                      const SizedBox(height: 24),
                      const Text(
                        'Ingresa con tu documento y PIN',
                        style: TextStyle(fontSize: 15, color: _kTextSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 40),
                      _FormCard(
                        formKey: _formKey,
                        documentoController: _documentoController,
                        pinController: _pinController,
                        obscurePin: _obscurePin,
                        onTogglePin: () => setState(() => _obscurePin = !_obscurePin),
                        errorMessage: _errorMessage,
                        onDismissError: () => setState(() => _errorMessage = null),
                        isLoading: _isLoading,
                        onLogin: _login,
                        onClear: _clearForm,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contacta al administrador para recuperar tu PIN'),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.all(16),
                            ),
                          );
                        },
                        child: const Text('¿Olvidaste tu PIN?', style: TextStyle(color: _kPrimaryBlue, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimaryBlue,
                          side: const BorderSide(color: _kPrimaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('¿No tienes cuenta? Regístrate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      const SizedBox(height: 24),
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
}

class _Logo extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color light;

  const _Logo({required this.primary, required this.secondary, required this.light});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      width: 180,
      height: 180,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.medical_services_outlined, size: 80, color: primary),
    );
  }
}

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController documentoController;
  final TextEditingController pinController;
  final bool obscurePin;
  final VoidCallback onTogglePin;
  final String? errorMessage;
  final VoidCallback onDismissError;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onClear;

  const _FormCard({
    required this.formKey,
    required this.documentoController,
    required this.pinController,
    required this.obscurePin,
    required this.onTogglePin,
    required this.errorMessage,
    required this.onDismissError,
    required this.isLoading,
    required this.onLogin,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimaryBlue.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: _kPrimaryBlue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: documentoController,
              keyboardType: TextInputType.text,
              inputFormatters: [LengthLimitingTextInputFormatter(15), FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-_]'))],
              style: const TextStyle(color: _kTextPrimary, fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Documento',
                labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 14),
                hintText: 'Ej. CC 123456789',
                prefixIcon: const Icon(Icons.badge_outlined, color: _kPrimaryBlue, size: 22),
                border: _kInputBorder,
                enabledBorder: _kInputBorder,
                focusedBorder: _kInputBorderFocused,
                errorBorder: _kInputBorderError,
                focusedErrorBorder: _kInputBorderError,
                filled: true,
                fillColor: _kBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa tu documento';
                if (v.trim().length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: pinController,
              obscureText: obscurePin,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              style: const TextStyle(color: _kTextPrimary, fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'PIN',
                labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 14),
                hintText: '4 dígitos',
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: _kPrimaryBlue, size: 22),
                suffixIcon: IconButton(
                  icon: Icon(obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _kPrimaryBlue, size: 22),
                  onPressed: onTogglePin,
                ),
                border: _kInputBorder,
                enabledBorder: _kInputBorder,
                focusedBorder: _kInputBorderFocused,
                errorBorder: _kInputBorderError,
                focusedErrorBorder: _kInputBorderError,
                filled: true,
                fillColor: _kBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu PIN';
                if (v.length != 4) return 'El PIN tiene 4 dígitos';
                return null;
              },
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorChip(message: errorMessage!, onDismiss: onDismissError),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isLoading ? null : onClear,
              child: const Text('Limpiar campos', style: TextStyle(color: _kTextSecondary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorChip extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorChip({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kErrorRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kErrorRed.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _kErrorRed, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: _kErrorRed, fontSize: 13, fontWeight: FontWeight.w500))),
          IconButton(icon: const Icon(Icons.close, size: 18, color: _kErrorRed), onPressed: onDismiss, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
        ],
      ),
    );
  }
}
