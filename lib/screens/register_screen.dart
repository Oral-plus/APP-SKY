import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/app_assets.dart';

// Misma paleta que login_screen: limpia y consistente
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
        _showSnack(context, 'Registro exitoso', response['message'] ?? 'Cuenta creada correctamente', isError: false);
        await Future.delayed(const Duration(milliseconds: 1200));
        Navigator.of(context).pop();
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
    if (clean.contains('SocketException') || clean.contains('HandshakeException') || clean.contains('Connection refused')) {
      return 'Verifica tu conexión a internet.';
    }
    if (clean.contains('Timeout')) return 'La conexión tardó demasiado.';
    if (clean.contains('registrados') || clean.contains('exists') || clean.contains('409')) return 'El documento o teléfono ya están registrados.';
    if (clean.contains('inválido') || clean.contains('invalid') || clean.contains('400')) return 'Datos inválidos. Verifica la información.';
    if (clean.contains('500')) return 'Error del servidor. Intenta más tarde.';
    if (clean.contains('404')) return 'Servicio no encontrado.';
    return clean.isNotEmpty ? clean : 'Error. Intenta nuevamente.';
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
    HapticFeedback.lightImpact();
    _nombreController.clear();
    _apellidoController.clear();
    _telefonoController.clear();
    _emailController.clear();
    _documentoController.clear();
    _pinController.clear();
    _confirmPinController.clear();
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
          child: Column(
            children: [
              _RegisterHeader(
                onBack: () => Navigator.of(context).pop(),
                onClear: _isLoading ? null : _clearForm,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _Logo(primary: _kPrimaryBlue, secondary: _kSecondaryBlue, light: _kLightBlue),
                      const SizedBox(height: 20),
                      const Text(
                        'Únete a ORAL-PLUS',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kPrimaryBlue, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Crea tu cuenta para acceder',
                        style: TextStyle(fontSize: 14, color: _kTextSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 28),
                      _RegisterFormCard(
                        formKey: _formKey,
                        nombreController: _nombreController,
                        apellidoController: _apellidoController,
                        documentoController: _documentoController,
                        telefonoController: _telefonoController,
                        emailController: _emailController,
                        pinController: _pinController,
                        confirmPinController: _confirmPinController,
                        obscurePin: _obscurePin,
                        obscureConfirmPin: _obscureConfirmPin,
                        onTogglePin: () => setState(() => _obscurePin = !_obscurePin),
                        onToggleConfirmPin: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                        errorMessage: _errorMessage,
                        onDismissError: () => setState(() => _errorMessage = null),
                        isLoading: _isLoading,
                        onRegister: _register,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimaryBlue,
                          side: const BorderSide(color: _kPrimaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('¿Ya tienes cuenta? Inicia sesión', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      const SizedBox(height: 32),
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

class _RegisterHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onClear;

  const _RegisterHeader({required this.onBack, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _IconBtn(icon: Icons.arrow_back_rounded, onPressed: onBack),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Crear cuenta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kTextPrimary)),
          ),
          _IconBtn(icon: Icons.clear_all_rounded, onPressed: onClear),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _IconBtn({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: _kTextPrimary, size: 22),
        style: IconButton.styleFrom(
          backgroundColor: _kCardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _kPrimaryBlue.withOpacity(0.15))),
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
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.medical_services_outlined, size: 48, color: primary),
    );
  }
}

class _RegisterFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController apellidoController;
  final TextEditingController documentoController;
  final TextEditingController telefonoController;
  final TextEditingController emailController;
  final TextEditingController pinController;
  final TextEditingController confirmPinController;
  final bool obscurePin;
  final bool obscureConfirmPin;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleConfirmPin;
  final String? errorMessage;
  final VoidCallback onDismissError;
  final bool isLoading;
  final VoidCallback onRegister;

  const _RegisterFormCard({
    required this.formKey,
    required this.nombreController,
    required this.apellidoController,
    required this.documentoController,
    required this.telefonoController,
    required this.emailController,
    required this.pinController,
    required this.confirmPinController,
    required this.obscurePin,
    required this.obscureConfirmPin,
    required this.onTogglePin,
    required this.onToggleConfirmPin,
    required this.errorMessage,
    required this.onDismissError,
    required this.isLoading,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _kCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimaryBlue.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: _kPrimaryBlue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(icon: Icons.person_outline_rounded, label: 'Información personal'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: nombreController,
                    label: 'Nombre *',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')), LengthLimitingTextInputFormatter(30)],
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : (v.trim().length < 2 ? 'Mín. 2 caracteres' : null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    controller: apellidoController,
                    label: 'Apellido *',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')), LengthLimitingTextInputFormatter(30)],
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : (v.trim().length < 2 ? 'Mín. 2 caracteres' : null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Field(
              controller: documentoController,
              label: 'Documento (cédula) *',
              hint: 'Solo números',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (v.length < 6) return 'Mín. 6 dígitos';
                if (v.length > 15) return 'Máx. 15 dígitos';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _Field(
              controller: telefonoController,
              label: 'Teléfono *',
              hint: '10 dígitos',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (v.length != 10) return '10 dígitos';
                if (v.startsWith('0')) return 'No puede empezar con 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _Field(
              controller: emailController,
              label: 'Email',
              hint: 'opcional',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(icon: Icons.lock_outline_rounded, label: 'Seguridad'),
            const SizedBox(height: 18),
            _Field(
              controller: pinController,
              label: 'PIN (4 dígitos) *',
              hint: '••••',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePin,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              suffixIcon: IconButton(
                icon: Icon(obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _kPrimaryBlue, size: 22),
                onPressed: onTogglePin,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (v.length != 4) return '4 dígitos';
                if (RegExp(r'^(\d)\1{3}$').hasMatch(v)) return 'No todos iguales';
                if (['1234', '4321', '0123', '3210'].contains(v)) return 'No secuencial';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _Field(
              controller: confirmPinController,
              label: 'Confirmar PIN *',
              hint: '••••',
              icon: Icons.lock_outline_rounded,
              obscureText: obscureConfirmPin,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              suffixIcon: IconButton(
                icon: Icon(obscureConfirmPin ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _kPrimaryBlue, size: 22),
                onPressed: onToggleConfirmPin,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirma tu PIN';
                if (v != pinController.text) return 'No coinciden';
                return null;
              },
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              _ErrorChip(message: errorMessage!, onDismiss: onDismissError),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Text('Crear cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: _kPrimaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Campos * obligatorios. Tu información está protegida.', style: TextStyle(color: _kTextSecondary, fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _kPrimaryBlue.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _kPrimaryBlue),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: _kPrimaryBlue, size: 22),
        suffixIcon: suffixIcon,
        border: _kInputBorder,
        enabledBorder: _kInputBorder,
        focusedBorder: _kInputBorderFocused,
        errorBorder: _kInputBorderError,
        focusedErrorBorder: _kInputBorderError,
        filled: true,
        fillColor: _kBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
