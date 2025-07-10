import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/wompi_service.dart';
import 'dart:convert';

class WompiPaymentScreen extends StatefulWidget {
  final String reference;
  final int amountInCents;
  final String description;
  final bool isTest;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;

  const WompiPaymentScreen({
    super.key,
    required this.reference,
    required this.amountInCents,
    required this.description,
    this.isTest = true,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
  });

  @override
  State<WompiPaymentScreen> createState() => _WompiPaymentScreenState();
}

class _WompiPaymentScreenState extends State<WompiPaymentScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String? _paymentUrl;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🚀 Inicializando pago con Wompi...');
      
      // Generar URL de pago
      final signature = WompiService.generateIntegritySignature(
        reference: widget.reference,
        amountInCents: widget.amountInCents,
        currency: 'COP',
        isTest: widget.isTest,
      );

      final publicKey = WompiService.getCurrentPublicKey(widget.isTest);
      
      // Crear URL del widget de Wompi
      final baseUrl = widget.isTest 
          ? 'https://checkout.wompi.co/widget.js'
          : 'https://checkout.wompi.co/widget.js';
      
      final paymentHtml = _generatePaymentHtml(
        publicKey: publicKey,
        reference: widget.reference,
        amountInCents: widget.amountInCents,
        signature: signature,
        customerName: widget.customerName ?? 'Usuario ORAL-PLUS',
        customerEmail: widget.customerEmail ?? 'usuario@oral-plus.com',
        customerPhone: widget.customerPhone ?? '3001234567',
      );

      // Configurar WebView
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('🌐 Cargando página: $url');
            },
            onPageFinished: (String url) {
              print('✅ Página cargada: $url');
              setState(() {
                _isLoading = false;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              print('🔗 Navegación solicitada: ${request.url}');
              
              // Manejar URLs de resultado
              if (request.url.contains('payment-result') || 
                  request.url.contains('success') || 
                  request.url.contains('error')) {
                _handlePaymentResult(request.url);
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
          ),
        )
        ..addJavaScriptChannel(
          'PaymentResult',
          onMessageReceived: (JavaScriptMessage message) {
            print('📨 Mensaje de JavaScript: ${message.message}');
            _handlePaymentMessage(message.message);
          },
        );

      // Cargar HTML del pago
      await _controller.loadHtmlString(paymentHtml);

    } catch (e) {
      print('❌ Error inicializando pago: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error inicializando el pago: $e';
      });
    }
  }

  String _generatePaymentHtml({
    required String publicKey,
    required String reference,
    required int amountInCents,
    required String signature,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pago ORAL-PLUS</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #4ECDC4 0%, #44A08D 100%);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }
        
        .payment-container {
            background: white;
            border-radius: 16px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            max-width: 400px;
            width: 100%;
            text-align: center;
        }
        
        .logo {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #4ECDC4, #44A08D);
            border-radius: 50%;
            margin: 0 auto 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 24px;
            font-weight: bold;
        }
        
        h1 {
            color: #0A4D68;
            margin-bottom: 10px;
            font-size: 24px;
        }
        
        .amount {
            font-size: 32px;
            font-weight: bold;
            color: #4ECDC4;
            margin: 20px 0;
        }
        
        .description {
            color: #666;
            margin-bottom: 30px;
            font-size: 16px;
        }
        
        .payment-info {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 20px;
            text-align: left;
        }
        
        .payment-info div {
            margin-bottom: 8px;
            font-size: 14px;
        }
        
        .payment-info strong {
            color: #0A4D68;
        }
        
        .loading {
            text-align: center;
            padding: 20px;
            color: #666;
        }
        
        .error {
            background: #fee;
            border: 1px solid #fcc;
            border-radius: 8px;
            padding: 15px;
            color: #c33;
            margin-top: 20px;
        }
        
        .test-banner {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 8px;
            padding: 10px;
            margin-bottom: 20px;
            color: #856404;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="payment-container">
        <div class="logo">OP</div>
        <h1>ORAL-PLUS</h1>
        
        ${widget.isTest ? '<div class="test-banner">🧪 <strong>MODO PRUEBA</strong> - No se realizará ningún cobro real</div>' : ''}
        
        <div class="amount">\$${(amountInCents / 100).toStringAsFixed(0)} COP</div>
        <div class="description">${widget.description}</div>
        
        <div class="payment-info">
            <div><strong>Referencia:</strong> $reference</div>
            <div><strong>Cliente:</strong> $customerName</div>
            <div><strong>Email:</strong> $customerEmail</div>
        </div>
        
        <div id="payment-button-container">
            <div class="loading">Cargando método de pago...</div>
        </div>
        
        ${widget.isTest ? '''
        <div style="margin-top: 20px; padding: 15px; background: #e3f2fd; border-radius: 8px; font-size: 12px; text-align: left;">
            <strong>Tarjetas de prueba:</strong><br>
            • VISA: 4242 4242 4242 4242<br>
            • MASTERCARD: 5031 7557 3453 0604<br>
            • CVC: Cualquier 3 dígitos<br>
            • Fecha: Cualquier fecha futura
        </div>
        ''' : ''}
    </div>

    <script src="https://checkout.wompi.co/widget.js"
        data-render="button"
        data-public-key="$publicKey"
        data-reference="$reference"
        data-amount-in-cents="$amountInCents"
        data-currency="COP"
        data-signature:integrity="$signature"
        data-customer-data:full-name="$customerName"
        data-customer-data:email="$customerEmail"
        data-customer-data:phone-number="$customerPhone"
        data-redirect-url="https://oral-plus.com/payment-result">
    </script>

    <script>
        // Manejar eventos de Wompi
        window.addEventListener('message', function(event) {
            console.log('Evento recibido:', event.data);
            
            if (event.data && event.data.type) {
                switch(event.data.type) {
                    case 'PAYMENT_SUCCESS':
                        PaymentResult.postMessage(JSON.stringify({
                            status: 'success',
                            data: event.data
                        }));
                        break;
                    case 'PAYMENT_ERROR':
                        PaymentResult.postMessage(JSON.stringify({
                            status: 'error',
                            data: event.data
                        }));
                        break;
                    case 'PAYMENT_PENDING':
                        PaymentResult.postMessage(JSON.stringify({
                            status: 'pending',
                            data: event.data
                        }));
                        break;
                }
            }
        });
        
        // Verificar si el widget se cargó correctamente
        setTimeout(function() {
            const container = document.getElementById('payment-button-container');
            const wompiButton = document.querySelector('[data-render="button"]');
            
            if (wompiButton && wompiButton.innerHTML.trim() !== '') {
                container.innerHTML = '';
                container.appendChild(wompiButton);
            } else {
                container.innerHTML = '<div class="error">Error cargando el método de pago. Intenta nuevamente.</div>';
            }
        }, 3000);
    </script>
</body>
</html>
    ''';
  }

  void _handlePaymentResult(String url) {
    print('🎯 Manejando resultado de pago: $url');
    
    // Extraer parámetros de la URL
    final uri = Uri.parse(url);
    final status = uri.queryParameters['status'];
    final transactionId = uri.queryParameters['id'];
    
    if (status == 'APPROVED') {
      _showPaymentSuccess(transactionId);
    } else if (status == 'DECLINED') {
      _showPaymentError('Pago rechazado');
    } else {
      _showPaymentError('Estado de pago desconocido: $status');
    }
  }

  void _handlePaymentMessage(String message) {
    try {
      final data = jsonDecode(message);
      final status = data['status'];
      
      switch (status) {
        case 'success':
          _showPaymentSuccess(data['data']['transaction_id']);
          break;
        case 'error':
          _showPaymentError(data['data']['message'] ?? 'Error en el pago');
          break;
        case 'pending':
          _showPaymentPending();
          break;
      }
    } catch (e) {
      print('❌ Error procesando mensaje: $e');
    }
  }

  void _showPaymentSuccess(String? transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('¡Pago Exitoso!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu pago ha sido procesado exitosamente.'),
            const SizedBox(height: 16),
            if (transactionId != null) ...[
              const Text('ID de Transacción:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(transactionId),
              const SizedBox(height: 8),
            ],
            const Text('Referencia:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.reference),
            const SizedBox(height: 8),
            const Text('Monto:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('\$${(widget.amountInCents / 100).toStringAsFixed(0)} COP'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(true); // Volver con resultado exitoso
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Error en el Pago'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
            },
            child: const Text('Reintentar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(false); // Volver con resultado fallido
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentPending() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Pago Pendiente'),
          ],
        ),
        content: const Text('Tu pago está siendo procesado. Te notificaremos cuando se complete.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(null); // Volver con resultado pendiente
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTest ? 'Pago de Prueba' : 'Realizar Pago'),
        backgroundColor: const Color(0xFF4ECDC4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.isTest)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PRUEBA',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                  ),
                  SizedBox(height: 16),
                  Text('Cargando método de pago...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _initializePayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : WebViewWidget(controller: _controller),
    );
  }
}
