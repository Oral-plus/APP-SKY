import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart'; // Añade esta importación
import '../models/invoice_model.dart';

class InvoiceService {
  static const List<String> possibleUrls = [
    'https://invoice.oral-plus.com/api',  
    'https://invoice.oral-plus.com/api',      
    'https://invoice.oral-plus.com/api',   
    'https://invoice.oral-plus.com/api',   
    'https://invoice.oral-plus.com/api',  
    'https://invoice.oral-plus.com/api', 
  ];
  
  static String? _workingUrl;
  static const Duration timeout = Duration(seconds: 15);

  /// Inicializa el formato de fechas
  static Future<void> initialize() async {
    await initializeDateFormatting(); // Inicializa los formatos de fecha
  }

  /// Encuentra la URL que funciona
  static Future<String?> findWorkingUrl() async {
    if (_workingUrl != null) {
      print('🔄 Usando URL en cache: $_workingUrl');
      return _workingUrl;
    }

    print('🔍 Buscando servidor ORAL-PLUS...');
    print('📡 Probando ${possibleUrls.length} URLs posibles...');
    
    for (int i = 0; i < possibleUrls.length; i++) {
      final url = possibleUrls[i];
      try {
        print('🔄 [${i + 1}/${possibleUrls.length}] Probando: $url');
        
        final response = await http.get(
          Uri.parse('$url/test'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            _workingUrl = url;
            print('✅ Servidor encontrado en: $url');
            print('📊 Estado: ${data['status']}');
            print('🌐 Host: ${data['server']?['host'] ?? 'N/A'}');
            print('🔧 Node.js: ${data['server']?['nodeVersion'] ?? 'N/A'}');
          
            // Mostrar IPs disponibles si las hay
            if (data['network'] != null && data['network']['interfaces'] != null) {
              final interfaces = data['network']['interfaces'] as List;
              if (interfaces.isNotEmpty) {
                print('📍 IPs disponibles del servidor:');
                for (var iface in interfaces) {
                  print('   ${iface['interface']}: ${iface['url']}');
                }
              }
            }
          
            return url;
          }
        }
      } catch (e) {
        final errorMsg = e.toString();
        if (errorMsg.length > 100) {
          print('❌ Error en $url: ${errorMsg.substring(0, 100)}...');
        } else {
          print('❌ Error en $url: $errorMsg');
        }
        continue;
      }
    }
  
    print('❌ No se pudo encontrar el servidor en ninguna URL');
    print('💡 Verifica que el servidor esté ejecutándose con: node server.js');
    return null;
  }

  /// Prueba la conexión con diagnóstico completo
  static Future<Map<String, dynamic>> testConnectionWithDiagnostic() async {
    final diagnostic = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
      'workingUrl': null,
      'recommendations': <String>[],
      'urlsTested': <String>[],
      'serverInfo': null,
    };

    // Test 1: Buscar URL que funcione
    print('🧪 Iniciando diagnóstico completo...');
  
    for (final url in possibleUrls) {
      diagnostic['urlsTested'].add(url);
    }
  
    final workingUrl = await findWorkingUrl();
    diagnostic['workingUrl'] = workingUrl;

    if (workingUrl == null) {
      diagnostic['recommendations'].addAll([
        '1. Verifica que el servidor Node.js esté ejecutándose',
        '2. Ejecuta: node server.js en la carpeta del servidor',
        '3. Verifica que el puerto 3005 esté libre',
        '4. Revisa la configuración del firewall',
        '5. Asegúrate de estar en la misma red WiFi',
        '6. Prueba cambiar la IP en possibleUrls[]',
      ]);
      return diagnostic;
    }

    // Test 2: Prueba detallada de la API
    try {
      print('🧪 Probando endpoint /test...');
      final response = await http.get(
        Uri.parse('$workingUrl/test'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      diagnostic['tests']['api_test'] = {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'responseTime': DateTime.now().millisecondsSinceEpoch,
        'bodyLength': response.body.length,
      };

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        diagnostic['serverInfo'] = data;
        print('✅ Test de API exitoso');
        print('📊 Base de datos: ${data['database']}');
        print('⏱️ Tiempo de respuesta: ${data['queryTime']}ms');
      }
    } catch (e) {
      print('❌ Error en test de API: $e');
      diagnostic['tests']['api_test'] = {
        'success': false,
        'error': e.toString(),
      };
    }

    // Test 3: Prueba consulta de facturas
    try {
      print('🧪 Probando consulta de facturas...');
      final response = await http.get(
        Uri.parse('$workingUrl/invoices/by-cardcode/TEST123'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      diagnostic['tests']['invoice_query'] = {
        'success': response.statusCode == 200 || response.statusCode == 404,
        'statusCode': response.statusCode,
        'canQueryInvoices': response.statusCode != 500,
      };
    
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Test de consulta exitoso');
        print('📄 Respuesta: ${data['message']}');
      }
    } catch (e) {
      print('❌ Error en test de consulta: $e');
      diagnostic['tests']['invoice_query'] = {
        'success': false,
        'error': e.toString(),
      };
    }

    // Test 4: Prueba diagnóstico del servidor
    try {
      print('🧪 Probando endpoint /diagnostic...');
      final response = await http.get(
        Uri.parse('$workingUrl/diagnostic'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      diagnostic['tests']['server_diagnostic'] = {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
      };
    
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        diagnostic['serverDiagnostic'] = data;
        print('✅ Diagnóstico del servidor obtenido');
        print('💾 Base de datos: ${data['database']?['status']}');
        print('🖥️ Sistema: ${data['server']?['platform']}');
      }
    } catch (e) {
      print('❌ Error en diagnóstico del servidor: $e');
      diagnostic['tests']['server_diagnostic'] = {
        'success': false,
        'error': e.toString(),
      };
    }

    print('🎯 Diagnóstico completado');
    return diagnostic;
  }

  /// Prueba la conexión básica
  static Future<bool> testConnection() async {
    try {
      final workingUrl = await findWorkingUrl();
      return workingUrl != null;
    } catch (e) {
      print('❌ Error en test de conexión: $e');
      return false;
    }
  }

  /// Obtiene las facturas de un CardCode específico con reintentos
  static Future<List<InvoiceModel>> getInvoicesByCardCode(String cardCode) async {
    if (cardCode.isEmpty) {
      throw Exception('CardCode no puede estar vacío');
    }

    print('🔍 Iniciando consulta de facturas...');
    print('📋 CardCode solicitado: $cardCode');

    // Buscar URL que funcione
    final workingUrl = await findWorkingUrl();
    if (workingUrl == null) {
      throw Exception('No se pudo conectar con el servidor ORAL-PLUS. Verifica que esté ejecutándose.');
    }

    try {
      print('🔍 Consultando facturas para CardCode: $cardCode');
      print('🌐 URL: $workingUrl/invoices/by-cardcode/$cardCode');
    
      final startTime = DateTime.now();
      final response = await http.get(
        Uri.parse('$workingUrl/invoices/by-cardcode/$cardCode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeout);
    
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      print('📡 Respuesta HTTP: ${response.statusCode} (${responseTime}ms)');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
      
        if (data['success'] == true) {
          print('✅ Respuesta exitosa de la API');
          print('📄 Facturas encontradas: ${data['count']}');
          print('⏱️ Tiempo de consulta en servidor: ${data['queryTime']}ms');
        
          if (data['count'] == 0) {
            print('🎉 Usuario a paz y salvo: ${data['message']}');
            return [];
          }

          final List<dynamic> invoicesJson = data['invoices'] ?? [];
          final List<InvoiceModel> invoices = [];
          int processedCount = 0;
          int validCount = 0;

          // Asegurarse de que el formato de fecha está inicializado
          await initializeDateFormatting();

          for (var invoiceJson in invoicesJson) {
            try {
              processedCount++;
              final invoice = InvoiceModel.fromJson(invoiceJson);
            
              if (invoice.cardCode.trim().toUpperCase() == cardCode.trim().toUpperCase()) {
                invoices.add(invoice);
                validCount++;
                print('✅ Factura $validCount: ${invoice.docNum} - ${invoice.formattedAmount}');
              } else {
                print('⚠️ Factura ${invoice.docNum} no coincide con CardCode (tiene: ${invoice.cardCode})');
              }
            } catch (e) {
              print('❌ Error procesando factura $processedCount: $e');
            }
          }

          print('🎯 Resumen de procesamiento:');
          print('   📥 Recibidas: ${invoicesJson.length}');
          print('   🔄 Procesadas: $processedCount');
          print('   ✅ Válidas: $validCount');
          print('   📊 Estadísticas: ${data['statistics']}');
        
          return invoices;
        } else {
          throw Exception(data['message'] ?? 'Error en la respuesta de la API');
        }
      } else if (response.statusCode == 404) {
        print('📭 No se encontraron facturas para CardCode: $cardCode');
        return [];
      } else {
        print('❌ Error HTTP ${response.statusCode}');
        print('📄 Respuesta: ${response.body}');
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error obteniendo facturas por CardCode: $e');
    
      if (e is SocketException) {
        throw Exception('Error de conexión: El servidor no está disponible. Verifica que esté ejecutándose.');
      } else if (e is HttpException) {
        throw Exception('Error HTTP: $e');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: La consulta tardó demasiado tiempo (>${timeout.inSeconds}s)');
      } else {
        rethrow;
      }
    }
  }

  /// Método para limpiar la URL en cache (útil para reconectar)
  static void resetConnection() {
    final previousUrl = _workingUrl;
    _workingUrl = null;
    print('🔄 Cache de conexión limpiado');
    if (previousUrl != null) {
      print('🗑️ URL anterior: $previousUrl');
    }
    print('🔍 Próxima consulta buscará servidor automáticamente');
  }

  /// Obtiene información del servidor
  static Future<Map<String, dynamic>?> getServerInfo() async {
    try {
      print('📊 Obteniendo información del servidor...');
      final workingUrl = await findWorkingUrl();
      if (workingUrl == null) {
        print('❌ No se pudo conectar para obtener info del servidor');
        return null;
      }

      final response = await http.get(
        Uri.parse('$workingUrl/test'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Información del servidor obtenida');
        print('🖥️ Host: ${data['server']?['host']}');
        print('🔧 Node.js: ${data['server']?['nodeVersion']}');
        print('💾 Base de datos: ${data['database_info']?['database']}');
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo info del servidor: $e');
      return null;
    }
  }

  /// Valida si un CardCode existe
  static Future<bool> validateCardCode(String cardCode) async {
    try {
      await getInvoicesByCardCode(cardCode);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene estadísticas de un CardCode
  static Future<Map<String, dynamic>?> getCardCodeStatistics(String cardCode) async {
    try {
      print('📊 Obteniendo estadísticas para CardCode: $cardCode');
      final workingUrl = await findWorkingUrl();
      if (workingUrl == null) return null;

      final response = await http.get(
        Uri.parse('$workingUrl/invoices/by-cardcode/$cardCode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final stats = {
            'count': data['count'] ?? 0,
            'totalAmount': data['totalAmount'] ?? 0.0,
            'overdueCount': data['overdueCount'] ?? 0,
            'urgentCount': data['urgentCount'] ?? 0,
            'upcomingCount': data['upcomingCount'] ?? 0,
            'normalCount': data['normalCount'] ?? 0,
            'cardCode': data['cardCode'],
            'timestamp': data['timestamp'],
            'queryTime': data['queryTime'],
          };
        
          print('✅ Estadísticas obtenidas:');
          print('   📄 Total facturas: ${stats['count']}');
          print('   💰 Monto total: \$${stats['totalAmount']}');
          print('   ⚠️ Vencidas: ${stats['overdueCount']}');
          print('   🔥 Urgentes: ${stats['urgentCount']}');
        
          return stats;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return null;
    }
  }
}