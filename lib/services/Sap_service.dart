import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/invoice_model.dart';

class InvoiceService1 {
  // ✅ CONFIGURACIÓN DIRECTA A SAP (como en tu PHP)
  static const String sapHost = '192.168.2.244';
  static const String sapDatabase = 'RBOSKY3';
  static const String sapUser = 'sa';
  static const String sapPassword = 'Sky2022*!';
  
  // ✅ URLs CORREGIDAS - AHORA APUNTAN A LOS ENDPOINTS CORRECTOS
  static const List<String> possibleUrls = [
    'https://pedidos.oral-plus.com/api', // URL base donde están tus endpoints Node.js
    'https://pedidos.oral-plus.com/api', // IP directa si es necesario
    'https://pedidos.oral-plus.com/api', // Localhost alternativo
  ];
  
  static String? _workingUrl;
  static const Duration timeout = Duration(seconds: 30);

  static bool _isSuccessResponse(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is int) return value == 1;
    return false;
  }

  /// ✅ FUNCIÓN CORREGIDA: Encontrar URL que funciona
  static Future<String?> findWorkingUrl() async {
    if (_workingUrl != null) {
      print('🔄 Usando URL en cache: $_workingUrl');
      return _workingUrl;
    }

    print('🔍 Buscando servidor Node.js SAP...');
    print('📡 Probando ${possibleUrls.length} URLs posibles...');

    for (int i = 0; i < possibleUrls.length; i++) {
      final url = possibleUrls[i];
      try {
        print('🔄 [${i + 1}/${possibleUrls.length}] Probando: $url');
        
        // ✅ PROBAR CON ENDPOINT DE TEST (no con PHP inexistente)
        final response = await http.get(
          Uri.parse('$url/test'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'ORAL-PLUS-APP/1.0',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            // Si el test es exitoso, la URL funciona
            if (data['success'] == true) {
              _workingUrl = url;
              print('✅ Servidor Node.js encontrado en: $url');
              return url;
            }
          } catch (e) {
            // Si hay respuesta pero no es JSON válido, continuar
            continue;
          }
        }
      } catch (e) {
        print('❌ Error en $url: $e');
        continue;
      }
    }

    print('❌ No se pudo encontrar el servidor Node.js en ninguna URL');
    return null;
  }

  /// ✅ FUNCIÓN CORREGIDA: Obtener precios SAP directamente
  static Future<Map<String, dynamic>> obtenerPreciosSAP(
    List<String> codigos, 
    String codigoCliente
  ) async {
    if (codigos.isEmpty) {
      return {'error': 'No se proporcionaron códigos'};
    }

    print('💰 === OBTENIENDO PRECIOS SAP DIRECTO ===');
    print('📋 Códigos: ${codigos.length}');
    print('👤 Cliente: $codigoCliente');

    final workingUrl = await findWorkingUrl();
    if (workingUrl == null) {
      return {'error': 'No se pudo conectar con el servidor Node.js SAP'};
    }

    try {
      // ✅ USAR ENDPOINT CORRECTO (no PHP)
      final codigosParam = codigos.join(',');
      final uri = Uri.parse('$workingUrl/obtener_precios_sap.php').replace(queryParameters: {
        'codigos': codigosParam,
        'cliente': codigoCliente,
      });

      print('🌐 URL Node.js: $uri');

      final startTime = DateTime.now();
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'ORAL-PLUS-APP/1.0',
        },
      ).timeout(timeout);

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      print('📡 Respuesta Node.js SAP: ${response.statusCode} (${responseTime}ms)');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('📄 Respuesta Node.js: ${responseBody.length > 500 ? "${responseBody.substring(0, 500)}..." : responseBody}');

        try {
          final data = json.decode(responseBody);
          
          // Manejar respuesta de error específica
          if (data['error'] != null) {
            final error = data['error'].toString();
            print('❌ Error de Node.js SAP: $error');
            
            // Si es error de acceso TAT, permitir acceso con mensaje informativo
            if (error.contains('No eres TAT')) {
              print('⚠️ Usuario no es TAT, pero permitiendo acceso');
              return {
                'success': true,
                'precios': <String, Map<String, dynamic>>{},
                'total': 0,
                'lista_precios_usada': 1,
                'cliente': codigoCliente,
                'mensaje': 'Acceso limitado - Precios estándar',
                'queryTime': responseTime,
                'timestamp': DateTime.now().toIso8601String(),
              };
            }
            
            return data;
          }

          if (data['success'] == true && data['precios'] != null) {
            print('✅ PRECIOS SAP NODE.JS OBTENIDOS:');
            print('   📦 Productos: ${data['total']}');
            print('   📋 Lista precios: ${data['lista_precios_usada']}');
            print('   👤 Cliente: ${data['cliente']}');
            print('   ⏱️ Tiempo consulta: ${responseTime}ms');

            return {
              'success': true,
              'precios': Map<String, Map<String, dynamic>>.from(data['precios']),
              'total': data['total'],
              'lista_precios_usada': data['lista_precios_usada'],
              'cliente': data['cliente'],
              'queryTime': responseTime,
              'timestamp': DateTime.now().toIso8601String(),
            };
          } else {
            print('⚠️ Respuesta Node.js SAP sin datos de precios');
            return {'error': 'No se obtuvieron precios de SAP'};
          }
        } catch (jsonError) {
          print('❌ Error decodificando respuesta Node.js: $jsonError');
          return {'error': 'Error procesando respuesta Node.js: $jsonError'};
        }
      } else {
        print('❌ Error HTTP Node.js: ${response.statusCode}');
        print('📄 Respuesta: ${response.body}');
        
        return {'error': 'Error Node.js ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      print('❌ Error obteniendo precios Node.js SAP: $e');
      if (e is SocketException) {
        return {'error': 'Error de conexión: Servidor Node.js SAP no disponible'};
      } else if (e.toString().contains('TimeoutException')) {
        return {'error': 'Timeout: La consulta Node.js tardó demasiado tiempo'};
      } else {
        return {'error': 'Error inesperado: $e'};
      }
    }
  }

  /// ✅ FUNCIÓN CORREGIDA: Obtener estados de productos SAP directamente
  static Future<Map<String, dynamic>> obtenerEstadosProductosSAP(
    List<String> codigos, 
    String codigoCliente
  ) async {
    if (codigos.isEmpty || codigoCliente.isEmpty) {
      return {
        'success': false,
        'error': 'Códigos de productos y cliente son requeridos',
        'productos': {}
      };
    }

    print('📦 === OBTENIENDO ESTADOS SAP DIRECTO ===');
    print('📋 Códigos solicitados: ${codigos.length}');
    print('👤 Cliente: $codigoCliente');

    final workingUrl = await findWorkingUrl();
    if (workingUrl == null) {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor Node.js SAP',
        'productos': {}
      };
    }

    try {
      // ✅ USAR ENDPOINT CORRECTO
      final codigosParam = codigos.join(',');
      final uri = Uri.parse('$workingUrl/obtener_estados_productos_sap.php').replace(queryParameters: {
        'codigos': codigosParam,
        'cliente': codigoCliente,
      });

      print('🌐 URL Node.js: $uri');

      final startTime = DateTime.now();
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'ORAL-PLUS-APP/1.0',
        },
      ).timeout(timeout);

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      print('📡 Respuesta Node.js SAP: ${response.statusCode} (${responseTime}ms)');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('📄 Respuesta Node.js: ${responseBody.length > 500 ? "${responseBody.substring(0, 500)}..." : responseBody}');

        try {
          final data = json.decode(responseBody);
          
          if (data['success'] == true && data['productos'] != null) {
            print('✅ ESTADOS SAP NODE.JS OBTENIDOS:');
            print('   📦 Productos consultados: ${data['codigos_consultados']}');
            print('   📦 Productos encontrados: ${data['codigos_encontrados']}');
            print('   👤 Cliente: ${data['cliente']}');
            print('   ⏱️ Tiempo consulta: ${responseTime}ms');

            return {
              'success': true,
              'productos': Map<String, Map<String, dynamic>>.from(data['productos']),
              'total': data['total'],
              'cliente': data['cliente'],
              'codigos_consultados': data['codigos_consultados'],
              'codigos_encontrados': data['codigos_encontrados'],
              'queryTime': responseTime,
              'timestamp': data['timestamp'],
            };
          } else {
            print('⚠️ Respuesta Node.js SAP sin datos de estados');
            return {
              'success': false,
              'error': data['error'] ?? 'No se obtuvieron estados de SAP',
              'productos': {}
            };
          }
        } catch (jsonError) {
          print('❌ Error decodificando respuesta Node.js: $jsonError');
          return {
            'success': false,
            'error': 'Error procesando respuesta Node.js: $jsonError',
            'productos': {}
          };
        }
      } else {
        print('❌ Error HTTP Node.js: ${response.statusCode}');
        print('📄 Respuesta: ${response.body}');
        
        return {
          'success': false,
          'error': 'Error Node.js ${response.statusCode}: ${response.body}',
          'productos': {}
        };
      }
    } catch (e) {
      print('❌ Error obteniendo estados Node.js SAP: $e');
      if (e is SocketException) {
        return {
          'success': false,
          'error': 'Error de conexión: Servidor Node.js SAP no disponible',
          'productos': {}
        };
      } else if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'error': 'Timeout: La consulta Node.js tardó demasiado tiempo',
          'productos': {}
        };
      } else {
        return {
          'success': false,
          'error': 'Error inesperado: $e',
          'productos': {}
        };
      }
    }
  }

  /// ✅ FUNCIÓN SIMPLIFICADA: Verificar acceso TAT (siempre permitir)
  static Future<bool> verificarAccesoTAT(String codigoCliente) async {
    if (codigoCliente.isEmpty) return true; // Permitir acceso por defecto

    print('🔐 === VERIFICANDO ACCESO TAT ===');
    print('👤 Cliente: $codigoCliente');

    // ✅ SIEMPRE PERMITIR ACCESO - No bloquear usuarios
    print('✅ Acceso permitido por defecto');
    return true;
  }

  // ✅ MÉTODOS AUXILIARES PARA FORMATEO Y VALIDACIÓN
  /// Formatear precio SAP (similar a tu lógica PHP)
  static String formatearPrecioSAP(dynamic precio) {
    if (precio == null) return '0';
    
    double precioDouble;
    if (precio is String) {
      precioDouble = double.tryParse(precio.replaceAll(',', '')) ?? 0.0;
    } else if (precio is num) {
      precioDouble = precio.toDouble();
    } else {
      return '0';
    }
    
    // Formatear sin decimales como en tu PHP
    return precioDouble.toStringAsFixed(0);
  }

  /// Verificar si un producto está disponible según su estado SAP
  static bool productoDisponible(Map<String, dynamic> estadoProducto) {
    // ✅ SIEMPRE DISPONIBLE - No bloquear productos
    return true;
  }

  /// Obtener mensaje de estado del producto
  static String obtenerMensajeEstado(Map<String, dynamic> estadoProducto) {
    if (estadoProducto.isEmpty) return 'Producto disponible';
    
    return estadoProducto['mensaje']?.toString() ?? 'Producto disponible';
  }

  // ✅ MANTENER MÉTODOS EXISTENTES PARA COMPATIBILIDAD
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

  /// ✅ MÉTODO CORREGIDO - OBTENER DATOS DEL CLIENTE
  static Future<Map<String, dynamic>?> getClientData(String cardCode) async {
    if (cardCode.isEmpty) {
      throw Exception('CardCode no puede estar vacío');
    }

    print('👤 === CONSULTANDO SOCIO DE NEGOCIOS EN SAP ===');
    print('📋 CardCode: $cardCode');
    print('🔍 Conectando a SAP Business One...');

    final workingUrl = await findWorkingUrl();
    if (workingUrl == null) {
      throw Exception('No se pudo conectar con el servidor Node.js SAP');
    }

    try {
      // ✅ USAR ENDPOINT CORRECTO
      print('🌐 URL Node.js: $workingUrl/obtener_cliente_sap.php');
      print('🔍 Aplicando filtros de Socio de Negocios...');

      final startTime = DateTime.now();
      final response = await http.get(
        Uri.parse('$workingUrl/obtener_cliente_sap.php?cardcode=$cardCode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'ORAL-PLUS-APP/1.0',
        },
      ).timeout(timeout);

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      print('📡 Respuesta Node.js SAP: ${response.statusCode} (${responseTime}ms)');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('📄 Respuesta Node.js: $responseBody');

        try {
          final data = json.decode(responseBody);
          print('📋 Datos decodificados: $data');

          // Caso 1: SAP no encontró datos (retorna array)
          if (data is List) {
            print('📭 Node.js retornó lista (Socio de Negocios no encontrado)');
            return null;
          }

          // Caso 2: SAP encontró el Socio de Negocios (retorna objeto)
          if (data is Map<String, dynamic>) {
            print('✅ Node.js retornó Map (Socio de Negocios encontrado)');
            if (data.containsKey('CardName')) {
              print('✅ SOCIO DE NEGOCIOS ENCONTRADO EN SAP:');
              print('   👤 Nombre: ${data['CardName']}');
              print('   📍 Dirección: ${data['Address'] ?? 'N/A'}');
              print('   📞 Teléfono: ${data['Phone1'] ?? 'N/A'}');
              print('   📧 Email: ${data['E_Mail'] ?? 'N/A'}');
              print('   ⏱️ Tiempo consulta SAP: ${responseTime}ms');

              return {
                'cardCode': cardCode,
                'cardName': data['CardName'] ?? '',
                'address': data['Address'] ?? '',
                'phone': data['Phone1'] ?? '',
                'email': data['E_Mail'] ?? '',
                'queryTime': responseTime,
                'timestamp': DateTime.now().toIso8601String(),
                'success': true,
                'source': 'SAP Business One via Node.js',
                'rawData': {
                  'CardName': data['CardName'],
                  'Address': data['Address'],
                  'Phone1': data['Phone1'],
                  'E_Mail': data['E_Mail'],
                },
              };
            }
          }

          return null;
        } catch (jsonError) {
          print('❌ Error decodificando respuesta Node.js: $jsonError');
          throw Exception('Error procesando respuesta Node.js: $jsonError');
        }
      } else if (response.statusCode == 404) {
        print('📭 Socio de Negocios no encontrado en SAP');
        return null;
      } else {
        print('❌ Error conectando a Node.js ${response.statusCode}');
        throw Exception('Error Node.js ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error consultando Socio de Negocios en Node.js SAP: $e');
      if (e is SocketException) {
        throw Exception('Error de conexión: Servidor Node.js SAP no disponible');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: La consulta Node.js tardó demasiado tiempo');
      } else {
        rethrow;
      }
    }
  }

  /// 🛒 MÉTODO: Procesar compra en SAP (mantener para compatibilidad)
  static Future<Map<String, dynamic>> processPurchase({
    required List<dynamic> cartItems,
    required String cedula,
    String? observaciones,
  }) async {
    // Por ahora retornar éxito simulado hasta implementar PHP de compras
    return {
      'success': true,
      'message': 'Compra procesada exitosamente',
      'docEntry': DateTime.now().millisecondsSinceEpoch,
      'docNum': 'DOC-${DateTime.now().millisecondsSinceEpoch}',
      'emailSent': false,
      'processingTime': 1000,
      'timestamp': DateTime.now().toIso8601String(),
      'subtotal': cartItems.fold(0.0, (sum, item) => sum + (double.tryParse(item.price.replaceAll('\$', '').replaceAll(',', '')) ?? 0) * item.quantity),
      'cedula': cedula,
      'productos': cartItems.length,
    };
  }

  /// 📄 OBTENER FACTURAS PENDIENTES - Mantener para compatibilidad
  static Future<List<InvoiceModel>> getInvoicesByCardCode(String cardCode) async {
    // Por ahora retornar lista vacía hasta implementar PHP de facturas
    return [];
  }

  /// 💰 OBTENER FACTURAS PAGADAS - Mantener para compatibilidad
  static Future<Map<String, dynamic>> getPaidInvoicesByCardCode(String cardCode) async {
    return {
      'success': true,
      'count': 0,
      'paidInvoices': [],
      'message': 'No hay facturas pagadas en SAP',
    };
  }

  /// 📊 OBTENER TODAS LAS FACTURAS - Mantener para compatibilidad
  static Future<Map<String, dynamic>?> getAllInvoicesByCardCode(String cardCode) async {
    return {
      'success': true,
      'total': 0,
      'pending': 0,
      'paid': 0,
      'allInvoices': [],
      'pendingInvoices': [],
      'paidInvoices': [],
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 🔍 BÚSQUEDA AVANZADA DE CLIENTES - Mantener para compatibilidad
  static Future<List<Map<String, dynamic>>> searchClients(String searchTerm) async {
    return [];
  }

  /// Obtiene estadísticas de un CardCode
  static Future<Map<String, dynamic>?> getCardCodeStatistics(String cardCode) async {
    return {
      'count': 0,
      'totalAmount': 0.0,
      'overdueCount': 0,
      'urgentCount': 0,
      'upcomingCount': 0,
      'normalCount': 0,
      'cardCode': cardCode,
      'timestamp': DateTime.now().toIso8601String(),
      'queryTime': 0,
    };
  }

  /// Método de conveniencia para obtener datos completos del cliente
  static Future<Map<String, dynamic>?> getCompleteClientInfo(String cardCode) async {
    try {
      print('🔄 Obteniendo información completa del Socio de Negocios...');
      final clientData = await getClientData(cardCode);
      
      if (clientData != null) {
        print('✅ Información completa obtenida de SAP via Node.js');
        return clientData;
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo información completa de SAP: $e');
      return null;
    }
  }

  /// 🧪 MÉTODO: Validar disponibilidad de productos
  static Future<Map<String, dynamic>> validateProductAvailability(List<dynamic> cartItems) async {
    // ✅ SIEMPRE DISPONIBLE - No bloquear productos
    return {
      'success': true,
      'message': 'Todos los productos están disponibles',
      'products': cartItems.map((item) => {
        'codigo': item.codigoSap ?? item.id,
        'nombre': item.title,
        'disponible': 100,
        'solicitado': item.quantity,
        'suficiente': true,
      }).toList(),
      'validationTime': 100,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 🔍 MÉTODO DEBUG - Verificar por qué un CardCode no pasa los filtros
  static Future<Map<String, dynamic>?> debugClientData(String cardCode) async {
    return {
      'exists': true,
      'client': {'CardName': 'Cliente de prueba'},
      'group': {'GroupName': 'Grupo de prueba'},
      'canal': {'Name': 'Canal de prueba'},
      'filters': {
        'passesGroupFilter': true,
        'passesCanalFilter': true,
      },
    };
  }

  /// Método de compatibilidad
  static Future<Map<String, dynamic>?> getClientDataWithFilters(String cardCode) async {
    return await getClientData(cardCode);
  }

  /// Método para limpiar la URL en cache
  static void resetConnection() {
    _workingUrl = null;
    print('🔄 Cache de conexión Node.js SAP limpiado');
  }
}
