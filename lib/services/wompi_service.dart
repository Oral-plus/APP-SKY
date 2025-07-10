import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class WompiService {
  // Configuración de Wompi
  static const String baseUrl = 'https://production.wompi.co/v1';
  static const String publicKey = 'pub_prod_vq6SWvyOjQMav2mrcWlKOye4BBueaS7Q';
  static const String integritySecret = 'prod_integrity_X5QR2RypaLStDR9fKzzJtWqrHmWMQTUn';
  
  // Para pruebas
  static const String testBaseUrl = 'https://sandbox.wompi.co/v1';
  static const String testPublicKey = 'pub_test_G9gzpEMKSGNMRBaGMUQTtGqNyGNMRBaG';
  static const String testIntegritySecret = 'test_integrity_HNxzVOFxyt8N9yUtBpn7zp8CDWOlVOFxyt8N9yUtBpn7zp8CDWOl';

  // Configuración de la base de datos adicional
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api'; // Tu API local
  
  static String getCurrentPublicKey(bool isTest) {
    return isTest ? testPublicKey : publicKey;
  }
  
  static String getCurrentIntegritySecret(bool isTest) {
    return isTest ? testIntegritySecret : integritySecret;
  }
  
  static String getCurrentBaseUrl(bool isTest) {
    return isTest ? testBaseUrl : baseUrl;
  }

  // Generar firma de integridad
  static String generateIntegritySignature({
    required String reference,
    required int amountInCents,
    required String currency,
    required bool isTest,
  }) {
    final secret = getCurrentIntegritySecret(isTest);
    final concatenated = '$reference$amountInCents$currency$secret';
    
    var bytes = utf8.encode(concatenated);
    var digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  // Crear transacción
  static Future<Map<String, dynamic>> createTransaction({
    required String reference,
    required int amountInCents,
    required String currency,
    required String customerEmail,
    required String customerFullName,
    String? customerPhone,
    String? description,
    bool isTest = false,
  }) async {
    try {
      print('🔄 Creando transacción en Wompi...');
      print('📄 Referencia: $reference');
      print('💰 Monto: $amountInCents centavos');
      
      final signature = generateIntegritySignature(
        reference: reference,
        amountInCents: amountInCents,
        currency: currency,
        isTest: isTest,
      );
      
      final url = '${getCurrentBaseUrl(isTest)}/transactions';
      
      final body = {
        'amount_in_cents': amountInCents,
        'currency': currency,
        'customer_email': customerEmail,
        'reference': reference,
        'signature': {
          'integrity': signature,
        },
        'customer_data': {
          'full_name': customerFullName,
          'phone_number': customerPhone,
        },
        'redirect_url': 'https://tu-app.com/payment-result',
        'payment_description': description ?? 'Pago desde ORAL-PLUS',
      };
      
      print('📤 Enviando datos: ${jsonEncode(body)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${getCurrentPublicKey(isTest)}',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Respuesta Wompi: ${response.statusCode}');
      print('📄 Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error desconocido',
          'details': errorData,
        };
      }
    } catch (e) {
      print('❌ Error creando transacción: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Consultar estado de transacción
  static Future<Map<String, dynamic>> getTransactionStatus({
    required String transactionId,
    bool isTest = false,
  }) async {
    try {
      print('🔍 Consultando estado de transacción: $transactionId');
      
      final url = '${getCurrentBaseUrl(isTest)}/transactions/$transactionId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${getCurrentPublicKey(isTest)}',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'transaction': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': 'Error consultando transacción',
        };
      }
    } catch (e) {
      print('❌ Error consultando transacción: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Guardar transacción en base de datos local
  static Future<Map<String, dynamic>> saveTransactionToDatabase({
    required String reference,
    required int amountInCents,
    required String status,
    required String wompiTransactionId,
    String? customerName,
    String? customerEmail,
  }) async {
    try {
      print('💾 Guardando transacción en base de datos...');
      
      final response = await http.post(
        Uri.parse('$apiBaseUrl/transactions/wompi'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reference': reference,
          'amount_in_cents': amountInCents,
          'status': status,
          'wompi_transaction_id': wompiTransactionId,
          'customer_name': customerName,
          'customer_email': customerEmail,
          'created_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Error guardando en base de datos',
        };
      }
    } catch (e) {
      print('❌ Error guardando transacción: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Obtener métodos de pago disponibles
  static Future<Map<String, dynamic>> getPaymentMethods({bool isTest = false}) async {
    try {
      final url = '${getCurrentBaseUrl(isTest)}/payment_methods';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${getCurrentPublicKey(isTest)}',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'payment_methods': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': 'Error obteniendo métodos de pago',
        };
      }
    } catch (e) {
      print('❌ Error obteniendo métodos de pago: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }
}
