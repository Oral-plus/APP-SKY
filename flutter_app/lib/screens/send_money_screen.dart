import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoController = TextEditingController();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  bool _isLoading = false;
  double _saldoActual = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final saldo = await ApiService.getUserBalance();
      setState(() {
        _saldoActual = saldo;
      });
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> _sendMoney() async {
    if (!_formKey.currentState!.validate()) return;

    final monto = double.tryParse(_montoController.text) ?? 0;
    final comision = monto * 0.005; // 0.5% de comisión
    final total = monto + comision;

    // Confirmar transacción
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Envío'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Destino: +591 ${_telefonoController.text}'),
              Text('Monto: Bs. ${monto.toStringAsFixed(2)}'),
              Text('Comisión: Bs. ${comision.toStringAsFixed(2)}'),
              const Divider(),
              Text(
                'Total: Bs. ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.sendMoney(
        telefonoDestino: _telefonoController.text.trim(),
        monto: monto,
        descripcion: _descripcionController.text.trim(),
      );

      if (mounted) {
        // Mostrar resultado exitoso
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: const Icon(
                Icons.check_circle,
                color: AppTheme.accentColor,
                size: 64,
              ),
              title: const Text('¡Envío Exitoso!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Código: ${response['transaccion']['codigo']}'),
                  Text('Enviado a: ${response['transaccion']['destino']}'),
                  Text('Monto: Bs. ${response['transaccion']['monto']}'),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar diálogo
                    Navigator.of(context).pop(); // Volver al dashboard
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Dinero'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saldo disponible
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Saldo Disponible',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bs. ${_saldoActual.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Formulario
              const Text(
                'Datos del Envío',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Teléfono destino
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: const InputDecoration(
                  labelText: 'Número de destino',
                  hintText: '70123456',
                  prefixIcon: Icon(Icons.phone),
                  prefixText: '+591 ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el número de destino';
                  }
                  if (value.length < 8) {
                    return 'El número debe tener 8 dígitos';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Monto
              TextFormField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Monto a enviar',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'Bs. ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el monto';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null || monto <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  if (monto > _saldoActual) {
                    return 'Saldo insuficiente';
                  }
                  if (monto < 1) {
                    return 'El monto mínimo es Bs. 1.00';
                  }
                  if (monto > 10000) {
                    return 'El monto máximo es Bs. 10,000.00';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // Para actualizar la vista previa
                },
              ),
              
              const SizedBox(height: 20),
              
              // Descripción
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Motivo del envío...',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Resumen de costos
              if (_montoController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Monto:'),
                          Text('Bs. ${_montoController.text}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Comisión (0.5%):'),
                          Text('Bs. ${((double.tryParse(_montoController.text) ?? 0) * 0.005).toStringAsFixed(2)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Bs. ${((double.tryParse(_montoController.text) ?? 0) * 1.005).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 30),
              
              // Botón de envío
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendMoney,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          'Enviar Dinero',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
