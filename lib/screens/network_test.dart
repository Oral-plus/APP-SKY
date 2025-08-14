import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class NetworkTestScreen extends StatelessWidget {
  const NetworkTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await NetworkTest.testServerConnection();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prueba de conectividad completada. Ver consola.')),
                );
              },
              child: const Text('🔍 Probar Conectividad'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await NetworkTest.testPurchaseEndpoint();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prueba de compra completada. Ver consola.')),
                );
              },
              child: const Text('🛒 Probar Endpoint de Compra'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await NetworkTest.testFullPurchaseFlow();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prueba completa realizada. Ver consola.')),
                );
              },
              child: const Text('🎯 Prueba Completa de Compra'),
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkTest {
  // ✅ IPs CORRECTAS según el test del servidor
  static const List<String> serverUrls = [
    'http://192.168.100.21:3006/api',  // IP principal del servidor
    'http://192.168.1.147:3006/api',   // IP alternativa del servidor
    'http://192.168.2.244:3006/api',   // IP anterior (probablemente no funcione)
  ];

  static Future<void> testServerConnection() async {
    print('🔍 === DIAGNÓSTICO DE CONECTIVIDAD ===');
    
    for (String baseUrl in serverUrls) {
      await _testSingleUrl('$baseUrl/test');
    }
    
    await _testBasicConnectivity();
  }

  static Future<void> _testSingleUrl(String url) async {
    try {
      print('\n🧪 Probando: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('✅ Status: \x1b[32m${response.statusCode}\x1b[0m');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('📦 Respuesta: ${data['status']}');
          print('🗄️ Base de datos: ${data['database']}');
          print('🌐 Servidor: ${data['server']['host']}:${data['server']['port']}');
          print('🎉 \x1b[32mCONEXIÓN EXITOSA!\x1b[0m');
          
          // Si esta URL funciona, la marcamos como la correcta
          print('✅ \x1b[33mUSAR ESTA URL: ${url.replaceAll('/test', '')}\x1b[0m');
        } catch (e) {
          print('❌ Error parseando JSON: $e');
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('📄 Body: ${response.body}');
      }
    } on SocketException catch (e) {
      print('❌ Error de socket: $e');
      print('💡 El servidor no está disponible en esta dirección');
    } on HttpException catch (e) {
      print('❌ Error HTTP: $e');
    } on FormatException catch (e) {
      print('❌ Error de formato: $e');
    } catch (e) {
      print('❌ Error general: $e');
    }
  }

  static Future<void> _testBasicConnectivity() async {
    print('\n🌐 === PRUEBA DE CONECTIVIDAD BÁSICA ===');
    
    // Probar internet
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ Conexión a internet: OK');
      }
    } on SocketException catch (_) {
      print('❌ Sin conexión a internet');
    }

    // Probar cada IP del servidor
    final ips = ['192.168.100.21', '192.168.1.147', '192.168.2.244'];
    for (String ip in ips) {
      try {
        final result = await InternetAddress.lookup(ip);
        if (result.isNotEmpty) {
          print('✅ Conectividad a $ip: OK');
        }
      } on SocketException catch (_) {
        print('❌ No se puede alcanzar $ip');
      }
    }
  }

  static Future<void> testPurchaseEndpoint() async {
    print('\n🛒 === PRUEBA DEL ENDPOINT DE COMPRA ===');
    
    // Datos de prueba exactamente como los envía Flutter
    final testData = {
      'cedula': 'C16613170',  // Usar la cédula real del test
      'nombre': 'MOLINA LOPEZ JUAN DE JESUS',
      'correo': 'SISTEMAS@ORAL-PLUS.COM',
      'telefono': '3148545310',
      'direccion': '',
      'subtotal': '\$27371',
      'productos': [
        {
          'nombre': 'Cepillo Dental Original Ristro',
          'codigo': '50360251',
          'textura': 'Suave',
          'precio': 14109,
          'cantidad': 2,
          'total': 28218,
          'img': 'assets/CEPILLOS/RISTRACEPILLO.png'
        }
      ]
    };

    // Probar cada URL del servidor
    for (String baseUrl in serverUrls) {
      await _testPurchaseOnUrl('$baseUrl/purchase/process', testData);
    }
  }

  static Future<void> _testPurchaseOnUrl(String url, Map<String, dynamic> testData) async {
    try {
      print('\n🛒 Probando compra en: $url');
      print('📤 Enviando datos: ${json.encode(testData)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(testData),
      ).timeout(const Duration(seconds: 60)); // Timeout largo para SAP

      print('📡 Status: ${response.statusCode}');
      print('📄 Headers: ${response.headers}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('🎉 \x1b[32m¡COMPRA DE PRUEBA EXITOSA!\x1b[0m');
            print('📄 DocEntry: ${responseData['DocEntry']}');
            print('📄 DocNum: ${responseData['DocNum']}');
            print('📧 Email enviado: ${responseData['emailSent']}');
            print('✅ \x1b[33mESTA URL FUNCIONA PARA COMPRAS: $url\x1b[0m');
          } else {
            print('❌ Error en respuesta: ${responseData['message']}');
          }
        } catch (e) {
          print('❌ Error parseando respuesta: $e');
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en prueba de compra: $e');
    }
  }

  static Future<void> testFullPurchaseFlow() async {
    print('\n🎯 === PRUEBA COMPLETA DEL FLUJO DE COMPRA ===');
    
    // 1. Probar conexión básica
    print('1️⃣ Probando conexión básica...');
    await testServerConnection();
    
    // 2. Probar endpoint de test
    print('\n2️⃣ Probando endpoint de test...');
    for (String baseUrl in serverUrls) {
      await _testSingleUrl('$baseUrl/test');
    }
    
    // 3. Probar endpoint de compra
    print('\n3️⃣ Probando endpoint de compra...');
    await testPurchaseEndpoint();
    
    // 4. Probar validación de productos
    print('\n4️⃣ Probando validación de productos...');
    await _testProductValidation();
    
    print('\n🏁 === PRUEBA COMPLETA FINALIZADA ===');
    print('💡 Revisa los logs para ver qué URLs funcionan');
    print('💡 Usa la URL marcada como exitosa en api_service1.dart');
  }

  static Future<void> _testProductValidation() async {
    final testData = {
      'productos': [
        {
          'codigo': '50360251',
          'cantidad': 2,
          'precio': 14109,
          'descripcion': 'Cepillo Dental Original Ristro',
        }
      ]
    };

    for (String baseUrl in serverUrls) {
      try {
        print('\n🧪 Probando validación en: $baseUrl/purchase/validate');
        
        final response = await http.post(
          Uri.parse('$baseUrl/purchase/validate'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(testData),
        ).timeout(const Duration(seconds: 15));

        print('📡 Status validación: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print('✅ Validación exitosa: ${responseData['success']}');
          print('📦 Productos validados: ${responseData['products']?.length ?? 0}');
        }
      } catch (e) {
        print('❌ Error en validación: $e');
      }
    }
  }
}
