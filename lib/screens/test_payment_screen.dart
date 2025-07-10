import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/simple_wompi_service.dart';

class SimpleWompiScreen extends StatefulWidget {
  const SimpleWompiScreen({super.key});

  @override
  State<SimpleWompiScreen> createState() => _SimpleWompiScreenState();
}

class _SimpleWompiScreenState extends State<SimpleWompiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '50000');
  final _descriptionController = TextEditingController(text: 'Pago ORAL-PLUS');
  final _customerNameController = TextEditingController(text: 'Cliente ORAL-PLUS');
  final _customerEmailController = TextEditingController(text: 'cliente@oral-plus.com');
  final _customerPhoneController = TextEditingController(text: '3001234567');
  
  bool _isLoading = false;
  
  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }
  
  Future<void> _openWompiPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.tryParse(_amountController.text) ?? 50000;
      final amountInCents = (amount * 100).toInt();
      final reference = 'ORAL-PLUS-${DateTime.now().millisecondsSinceEpoch}';
      
      print('🚀 Abriendo Wompi...');
      print('💰 Monto: $amountInCents centavos');
      print('📄 Referencia: $reference');
      
      final success = await SimpleWompiService.openPaymentInBrowser(
        reference: reference,
        amountInCents: amountInCents,
        currency: 'COP',
        customerName: _customerNameController.text.trim(),
        customerEmail: _customerEmailController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      
      if (mounted) {
        if (success) {
          _showMessage('Wompi abierto en el navegador', isError: false);
        } else {
          _showMessage('No se pudo abrir Wompi', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        title: const Text(
          'Pago con Wompi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4ECDC4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ECDC4).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                const Text(
                  'Pago Simple con Wompi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A4D68),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Se abrirá en tu navegador',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Formulario
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Pago',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A4D68),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Monto
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Monto (COP)',
                          prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF4ECDC4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un monto';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Ingresa un monto válido';
                          }
                          if (amount < 1000) {
                            return '';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Descripción
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          prefixIcon: const Icon(Icons.description, color: Color(0xFF4ECDC4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        maxLength: 100,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa una descripción';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Nombre del cliente
                      TextFormField(
                        controller: _customerNameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: const Icon(Icons.person, color: Color(0xFF4ECDC4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el nombre';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email del cliente
                      TextFormField(
                        controller: _customerEmailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email, color: Color(0xFF4ECDC4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el email';
                          }
                          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Teléfono del cliente
                      TextFormField(
                        controller: _customerPhoneController,
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFF4ECDC4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el teléfono';
                          }
                          if (value.length != 10) {
                            return 'El teléfono debe tener 10 dígitos';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Información
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Pago Seguro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Se abrirá Wompi en tu navegador para completar el pago de forma segura.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botón de pago
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _openWompiPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0xFF4ECDC4).withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.open_in_browser, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Abrir Wompi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Información de seguridad
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Color(0xFF4ECDC4),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Wompi es una pasarela de pagos segura y confiable.',
                          style: TextStyle(
                            color: Color(0xFF4ECDC4),
                            fontSize: 12,
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
  }
}
