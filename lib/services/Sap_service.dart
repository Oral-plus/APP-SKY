import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/invoice_model.dart';

class InvoiceService1 {
  static const String sapHost = '192.168.2.244';
  static const String sapDatabase = 'RBOSKY3';
  static const String sapUser = 'sa';
  static const String sapPassword = 'Sky2022*!';

  static const List<String> possibleUrls = [
    'https://pedidos.oral-plus.com/api',
    'https://pedidos.oral-plus.com/api',
  ];

  static String? _workingUrl;
  static const Duration timeout = Duration(seconds: 30);

  // Cache para listas de precios
  static List<Map<String, dynamic>>? _cachedPriceLists;
  static DateTime? _priceListsCacheTime;
  static const Duration cacheExpiration = Duration(minutes: 30);

  static String formatCardCode(String cardCode) {
    if (cardCode.isEmpty) return cardCode;
    
    // Remove any whitespace
    cardCode = cardCode.trim();
    
    // If it already starts with 'C', return as is
    if (cardCode.toUpperCase().startsWith('C')) {
      return cardCode.toUpperCase();
    }
    
    // If it's just numbers, add 'C' prefix
    if (RegExp(r'^\d+$').hasMatch(cardCode)) {
      return 'C$cardCode';
    }
    
    // For any other case, add 'C' prefix
    return 'C$cardCode';
  }

  static bool _isSuccessResponse(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is int) return value == 1;
    return false;
  }

  // Métodos auxiliares de compatibilidad
  static String formatearPrecioSAP(dynamic precio) {
    if (precio == null) return '0';
    double precioDouble;
    if (precio is String) {
      final cleaned = precio.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.-]'), '');
      precioDouble = double.tryParse(cleaned) ?? 0.0;
    } else if (precio is num) {
      precioDouble = precio.toDouble();
    } else {
      return '0';
    }
    return precioDouble.toStringAsFixed(0);
  }

  static String obtenerMensajeEstado(Map<String, dynamic> estadoProducto) {
    if (estadoProducto.isEmpty) return 'Producto no encontrado';
    return estadoProducto['mensaje']?.toString() ?? 'Producto disponible';
  }

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
        print('🔄 [${i + 1}/${possibleUrls.length}] Probando: $url/test');

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
            if (data['success'] == true) {
              _workingUrl = url;
              print('✅ Servidor Node.js encontrado en: $url');
              return url;
            }
          } catch (e) {
            print('❌ Error decodificando respuesta de $url: $e');
            continue;
          }
        } else {
          print('❌ Respuesta no exitosa desde $url: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Error en $url: $e');
        continue;
      }
    }

    print('❌ No se pudo encontrar el servidor Node.js en ninguna URL');
    return null;
  }

  // Método mejorado para obtener todas las listas de precios con cache
  static Future<List<Map<String, dynamic>>> obtenerTodasListasPrecios({bool forceRefresh = false}) async {
    print('📋 === OBTENIENDO TODAS LAS LISTAS DE PRECIOS ===');

    // Verificar cache si no se fuerza el refresh
    if (!forceRefresh && _cachedPriceLists != null && _priceListsCacheTime != null) {
      final cacheAge = DateTime.now().difference(_priceListsCacheTime!);
      if (cacheAge < cacheExpiration) {
        print('✅ Usando listas de precios desde cache (${cacheAge.inMinutes} min)');
        return _cachedPriceLists!;
      }
    }

    final workingUrl = await findWorkingUrl();
    if (workingUrl == null) {
      print('❌ No se pudo conectar con el servidor Node.js SAP');
      return [];
    }

    try {
      final uri = Uri.parse('$workingUrl/obtener_listas_precios');
      print('🌐 Consultando listas de precios en: $uri');

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
      print('📡 Respuesta Node.js: ${response.statusCode} (${responseTime}ms)');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['listasPrecios'] != null) {
          final listas = List<Map<String, dynamic>>.from(data['listasPrecios']);
          
          // Actualizar cache
          _cachedPriceLists = listas;
          _priceListsCacheTime = DateTime.now();
          
          print('✅ Listas de precios obtenidas y cacheadas: ${listas.length}');
          
          // Mostrar detalles de las listas
          for (var lista in listas) {
            print('   📋 Lista ${lista['id']}: ${lista['nombre']}');
          }
          
          return listas;
        } else {
          print('❌ Respuesta sin éxito o sin listas de precios');
          return [];
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error obteniendo listas de precios: $e');
      return [];
    }
  }

  // Método mejorado para obtener la lista de precios del cliente con detalles
  static Future<Map<String, dynamic>> obtenerListaPreciosClienteCompleta(String codigoCliente) async {
    if (codigoCliente.isEmpty) {
      print('⚠️ Código de cliente vacío, retornando lista por defecto (1)');
      return {
        'listaPrecios': 1,
        'nombreLista': 'Lista Base',
        'success': true,
        'isDefault': true,
      };
    }

    final formattedCardCode = formatCardCode(codigoCliente);
    print('📋 === OBTENIENDO LISTA DE PRECIOS COMPLETA SAP ===');
    print('👤 Cliente original: $codigoCliente');
    print('👤 Cliente formateado: $formattedCardCode');

    final workingUrl = await findWorkingUrl();
    if (workingUrl == null) {
      print('❌ No se pudo conectar con el servidor Node.js SAP');
      return {
        'listaPrecios': 1,
        'nombreLista': 'Lista Base (Error conexión)',
        'success': false,
        'error': 'No se pudo conectar con el servidor',
      };
    }

    try {
      final uri = Uri.parse('$workingUrl/obtener_lista_precios_cliente').replace(
        queryParameters: {'cardcode': formattedCardCode},
      );

      print('🌐 Consultando lista de precios en: $uri');

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
      print('📡 Respuesta Node.js: ${response.statusCode} (${responseTime}ms)');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['listaPrecios'] != null) {
          final listaPrecios = int.tryParse(data['listaPrecios'].toString()) ?? 1;
          
          // Obtener todas las listas para encontrar el nombre
          final todasLasListas = await obtenerTodasListasPrecios();
          final listaEncontrada = todasLasListas.firstWhere(
            (lista) => lista['id'] == listaPrecios,
            orElse: () => {'id': listaPrecios, 'nombre': 'Lista $listaPrecios'},
          );
          
          final nombreLista = listaEncontrada['nombre'] ?? 'Lista $listaPrecios';
          
          print('✅ Lista de precios obtenida: $listaPrecios - $nombreLista');
          
          return {
            'listaPrecios': listaPrecios,
            'nombreLista': nombreLista,
            'success': true,
            'cardCode': formattedCardCode,
            'originalCardCode': codigoCliente,
            'queryTime': responseTime,
            'timestamp': DateTime.now().toIso8601String(),
            'isDefault': listaPrecios == 1,
          };
        } else {
          print('❌ Respuesta sin éxito o sin listaPrecios');
          return {
            'listaPrecios': 1,
            'nombreLista': 'Lista Base (Error respuesta)',
            'success': false,
            'error': 'Respuesta sin datos válidos',
          };
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        return {
          'listaPrecios': 1,
          'nombreLista': 'Lista Base (Error HTTP)',
          'success': false,
          'error': 'Error HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error obteniendo lista de precios: $e');
      return {
        'listaPrecios': 1,
        'nombreLista': 'Lista Base (Excepción)',
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Método legacy mantenido para compatibilidad
  static Future<int> obtenerListaPreciosCliente(String codigoCliente) async {
    final resultado = await obtenerListaPreciosClienteCompleta(codigoCliente);
    return resultado['listaPrecios'] ?? 1;
  }

  // Método para obtener información detallada de una lista de precios específica
  static Future<Map<String, dynamic>?> obtenerDetallesListaPrecios(int numeroLista) async {
    print('📋 === OBTENIENDO DETALLES DE LISTA DE PRECIOS ===');
    print('📋 Lista: $numeroLista');

    final todasLasListas = await obtenerTodasListasPrecios();
    final listaEncontrada = todasLasListas.firstWhere(
      (lista) => lista['id'] == numeroLista,
      orElse: () => {},
    );

    if (listaEncontrada.isNotEmpty) {
      print('✅ Lista encontrada: ${listaEncontrada['nombre']}');
      return {
        'id': listaEncontrada['id'],
        'nombre': listaEncontrada['nombre'],
        'found': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else {
      print('❌ Lista $numeroLista no encontrada');
      return {
        'id': numeroLista,
        'nombre': 'Lista $numeroLista (No encontrada)',
        'found': false,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static Future<Map<String, dynamic>> obtenerPreciosSAP(
    List<String> codigos,
    String codigoCliente,
  ) async {
    if (codigos.isEmpty) {
      return {'error': 'No se proporcionaron códigos'};
    }

    final formattedCardCode = formatCardCode(codigoCliente);
    print('💰 === OBTENIENDO PRECIOS SAP ===');
    print('📋 Códigos: ${codigos.length}');
    print('👤 Cliente original: $codigoCliente');
    print('👤 Cliente formateado: $formattedCardCode');

    final workingUrl = await findWorkingUrl();
    if (workingUrl == null) {
      return {'error': 'No se pudo conectar con el servidor Node.js SAP'};
    }

    // Obtener información completa de la lista de precios del cliente
    final infoListaPrecios = await obtenerListaPreciosClienteCompleta(codigoCliente);
    final listaPrecios = infoListaPrecios['listaPrecios'] ?? 1;
    final nombreLista = infoListaPrecios['nombreLista'] ?? 'Lista $listaPrecios';
    
    print('📋 Lista de precios usada: $listaPrecios - $nombreLista');

    try {
      final codigosParam = codigos.join(',');
      final uri = Uri.parse('$workingUrl/obtener_precios_sap').replace(queryParameters: {
        'codigos': codigosParam,
        'cliente': formattedCardCode,
        'lista_precios': listaPrecios.toString(),
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

          if (data['error'] != null) {
            print('❌ Error de Node.js SAP: ${data['error']}');
            return data;
          }

          if (data['success'] == true && data['precios'] != null) {
            print('✅ PRECIOS SAP OBTENIDOS:');
            print('   📦 Productos: ${data['total']}');
            print('   📋 Lista precios: $listaPrecios - $nombreLista');
            print('   👤 Cliente: ${data['cliente']}');
            print('   ⏱️ Tiempo consulta: ${responseTime}ms');

            return {
              'success': true,
              'precios': Map<String, Map<String, dynamic>>.from(data['precios']),
              'total': data['total'],
              'lista_precios_usada': listaPrecios,
              'nombre_lista_precios': nombreLista,
              'info_lista_precios': infoListaPrecios,
              'cliente': formattedCardCode,
              'originalCliente': codigoCliente,
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
      } else if (e is TimeoutException) {
        return {'error': 'Timeout: La consulta Node.js tardó demasiado tiempo'};
      } else {
        return {'error': 'Error inesperado: $e'};
      }
    }
  }

  static Future<Map<String, dynamic>> obtenerEstadosProductosSAP(
    List<String> codigos,
    String codigoCliente,
  ) async {
    if (codigos.isEmpty || codigoCliente.isEmpty) {
      return {
        'success': false,
        'error': 'Códigos de productos y cliente son requeridos',
        'productos': {},
      };
    }

    final formattedCardCode = formatCardCode(codigoCliente);
    print('📦 === OBTENIENDO ESTADOS SAP ===');
    print('📋 Códigos solicitados: ${codigos.length}');
    print('👤 Cliente original: $codigoCliente');
    print('👤 Cliente formateado: $formattedCardCode');

    final workingUrl = await findWorkingUrl();
    if (workingUrl == null) {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor Node.js SAP',
        'productos': {},
      };
    }

    try {
      final codigosParam = codigos.join(',');
      final uri = Uri.parse('$workingUrl/obtener_estados_productos_sap').replace(queryParameters: {
        'codigos': codigosParam,
        'cliente': formattedCardCode,
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
            print('✅ ESTADOS SAP OBTENIDOS:');
            print('   📦 Productos consultados: ${data['codigos_consultados']}');
            print('   📦 Productos encontrados: ${data['codigos_encontrados']}');
            print('   👤 Cliente: ${data['cliente']}');
            print('   ⏱️ Tiempo consulta: ${responseTime}ms');

            return {
              'success': true,
              'productos': Map<String, Map<String, dynamic>>.from(data['productos']),
              'total': data['total'],
              'cliente': formattedCardCode,
              'originalCliente': codigoCliente,
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
              'productos': {},
            };
          }
        } catch (jsonError) {
          print('❌ Error decodificando respuesta Node.js: $jsonError');
          return {
            'success': false,
            'error': 'Error procesando respuesta Node.js: $jsonError',
            'productos': {},
          };
        }
      } else {
        print('❌ Error HTTP Node.js: ${response.statusCode}');
        print('📄 Respuesta: ${response.body}');
        return {
          'success': false,
          'error': 'Error Node.js ${response.statusCode}: ${response.body}',
          'productos': {},
        };
      }
    } catch (e) {
      print('❌ Error obteniendo estados Node.js SAP: $e');
      if (e is SocketException) {
        return {
          'success': false,
          'error': 'Error de conexión: Servidor Node.js SAP no disponible',
          'productos': {},
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'error': 'Timeout: La consulta Node.js tardó demasiado tiempo',
          'productos': {},
        };
      } else {
        return {
          'success': false,
          'error': 'Error inesperado: $e',
          'productos': {},
        };
      }
    }
  }

  static Future<Map<String, dynamic>?> getClientData(String cardCode) async {
    if (cardCode.isEmpty) {
      throw Exception('CardCode no puede estar vacío');
    }

    final formattedCardCode = formatCardCode(cardCode);
    print('👤 === CONSULTANDO SOCIO DE NEGOCIOS EN SAP ===');
    print('📋 CardCode original: $cardCode');
    print('📋 CardCode formateado: $formattedCardCode');

    final workingUrl = await findWorkingUrl();
    if (workingUrl == null) {
      throw Exception('No se pudo conectar con el servidor Node.js SAP');
    }

    try {
      final uri = Uri.parse('$workingUrl/obtener_cliente_sap').replace(
        queryParameters: {'cardcode': formattedCardCode},
      );

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
        print('📄 Respuesta Node.js: $responseBody');

        try {
          final data = json.decode(responseBody);

          if (data is List) {
            print('📭 Node.js retornó lista (Socio de Negocios no encontrado)');
            return null;
          }

          if (data is Map<String, dynamic> && data.containsKey('CardName')) {
            // Obtener información de la lista de precios del cliente
            final infoListaPrecios = await obtenerListaPreciosClienteCompleta(cardCode);
            
            print('✅ SOCIO DE NEGOCIOS ENCONTRADO EN SAP:');
            print('   👤 Nombre: ${data['CardName']}');
            print('   📍 Dirección: ${data['Address'] ?? 'N/A'}');
            print('   📞 Teléfono: ${data['Phone1'] ?? 'N/A'}');
            print('   📧 Email: ${data['E_Mail'] ?? 'N/A'}');
            print('   📋 Lista precios: ${infoListaPrecios['listaPrecios']} - ${infoListaPrecios['nombreLista']}');
            print('   ⏱️ Tiempo consulta SAP: ${responseTime}ms');

            return {
              'cardCode': formattedCardCode,
              'originalCardCode': cardCode,
              'cardName': data['CardName'] ?? '',
              'address': data['Address'] ?? '',
              'phone': data['Phone1'] ?? '',
              'email': data['E_Mail'] ?? '',
              'listaPrecios': infoListaPrecios['listaPrecios'],
              'nombreListaPrecios': infoListaPrecios['nombreLista'],
              'infoListaPrecios': infoListaPrecios,
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

          return null;
        } catch (jsonError) {
          print('❌ Error decodificando respuesta Node.js: $jsonError');
          throw Exception('Error procesando respuesta Node.js: $jsonError');
        }
      } else {
        print('❌ Error HTTP Node.js: ${response.statusCode}');
        print('📄 Respuesta: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error consultando Socio de Negocios en Node.js SAP: $e');
      if (e is SocketException) {
        throw Exception('Error de conexión: Servidor Node.js SAP no disponible');
      } else if (e is TimeoutException) {
        throw Exception('Timeout: La consulta Node.js tardó demasiado tiempo');
      } else {
        rethrow;
      }
    }
  }

  static Future<Map<String, dynamic>> processPurchase({
    required List<dynamic> cartItems,
    required String cedula,
    String? observaciones,
  }) async {
    final formattedCedula = formatCardCode(cedula);
    print('🛒 === PROCESANDO COMPRA EN SAP ===');
    print('📋 Cedula original: $cedula');
    print('📋 Cedula formateada: $formattedCedula');
    print('📦 Productos: ${cartItems.length}');
    print('📝 Observaciones: ${observaciones ?? 'N/A'}');

    final workingUrl = await findWorkingUrl();
    if (workingUrl == null) {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor Node.js SAP',
      };
    }

    Map<String, dynamic>? clientData;
    try {
      clientData = await getClientData(cedula);
    } catch (e) {
      print('⚠️ No se pudieron obtener datos del cliente: $e');
    }

    final nombre = clientData?['cardName'] ?? 'Cliente';
    final correo = clientData?['email'] ?? '';
    final direccion = clientData?['address'] ?? '';
    final telefono = clientData?['phone'] ?? '';

    final subtotal = cartItems.fold<double>(
      0.0,
      (sum, item) =>
          sum + (double.tryParse(item.price.replaceAll('\$', '').replaceAll(',', '')) ?? 0) * item.quantity,
    );

    try {
      final uri = Uri.parse('$workingUrl/purchase/process');
      final body = {
        'cedula': formattedCedula,
        'productos': cartItems.map((item) => {
              'codigo': item.codigoSap ?? item.id,
              'cantidad': item.quantity,
              'nombre': item.title,
              'precio': item.price.replaceAll('\$', '').replaceAll(',', ''),
            }).toList(),
        'correo': correo,
        'nombre': nombre,
        'subtotal': subtotal.toString(),
        'direccion': direccion,
        'telefono': telefono,
        if (observaciones != null && observaciones.isNotEmpty) 'observaciones': observaciones,
      };

      print('🌐 Enviando solicitud a: $uri');
      print('📦 Body: ${json.encode(body)}');

      final startTime = DateTime.now();
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'ORAL-PLUS-APP/1.0',
        },
        body: json.encode(body),
      ).timeout(timeout);

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      print('📡 Respuesta Node.js SAP: ${response.statusCode} (${responseTime}ms)');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('📄 Respuesta Node.js: $responseBody');

        try {
          final data = json.decode(responseBody);
          if (data['success'] == true) {
            print('✅ COMPRA PROCESADA EN SAP:');
            print('   📄 DocEntry: ${data['DocEntry']}');
            print('   📄 DocNum: ${data['DocNum']}');
            print('   📧 Email guardado: ${data['emailSent']}');
            print('   ⏱️ Tiempo procesamiento: ${data['processingTime']}ms');

            return {
              'success': true,
              'message': data['message'],
              'docEntry': data['DocEntry'],
              'docNum': data['DocNum'],
              'emailSent': data['emailSent'],
              'processingTime': data['processingTime'],
              'timestamp': DateTime.now().toIso8601String(),
              'subtotal': subtotal,
              'cedula': formattedCedula,
              'originalCedula': cedula,
              'productos': cartItems.length,
            };
          } else {
            print('❌ Error en respuesta Node.js: ${data['message']}');
            return {
              'success': false,
              'error': data['message'] ?? 'Error procesando compra en SAP',
            };
          }
        } catch (jsonError) {
          print('❌ Error decodificando respuesta Node.js: $jsonError');
          return {
            'success': false,
            'error': 'Error procesando respuesta Node.js: $jsonError',
          };
        }
      } else {
        print('❌ Error HTTP Node.js: ${response.statusCode}');
        print('📄 Respuesta: ${response.body}');
        return {
          'success': false,
          'error': 'Error Node.js ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error procesando compra en Node.js SAP: $e');
      if (e is SocketException) {
        return {
          'success': false,
          'error': 'Error de conexión: Servidor Node.js SAP no disponible',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'error': 'Timeout: La consulta Node.js tardó demasiado tiempo',
        };
      } else {
        return {
          'success': false,
          'error': 'Error inesperado: $e',
        };
      }
    }
  }


  // Métodos adicionales para manejo de listas de precios
  static Future<String> obtenerNombreListaPrecios(int numeroLista) async {
    final detalles = await obtenerDetallesListaPrecios(numeroLista);
    return detalles?['nombre'] ?? 'Lista $numeroLista';
  }

  static void limpiarCacheListasPrecios() {
    _cachedPriceLists = null;
    _priceListsCacheTime = null;
    print('🔄 Cache de listas de precios limpiado');
  }

  // Métodos legacy mantenidos para compatibilidad
  static Future<List<InvoiceModel>> getInvoicesByCardCode(String cardCode) async {
    final formattedCardCode = formatCardCode(cardCode);
    print('📄 === OBTENIENDO FACTURAS PENDIENTES ===');
    print('📋 CardCode original: $cardCode');
    print('📋 CardCode formateado: $formattedCardCode');
    return [];
  }

  static Future<Map<String, dynamic>> getPaidInvoicesByCardCode(String cardCode) async {
    final formattedCardCode = formatCardCode(cardCode);
    print('💰 === OBTENIENDO FACTURAS PAGADAS ===');
    print('📋 CardCode original: $cardCode');
    print('📋 CardCode formateado: $formattedCardCode');
    return {
      'success': true,
      'count': 0,
      'paidInvoices': [],
      'message': 'No hay facturas pagadas en SAP',
    };
  }

  static Future<Map<String, dynamic>?> getAllInvoicesByCardCode(String cardCode) async {
    final formattedCardCode = formatCardCode(cardCode);
    print('📊 === OBTENIENDO TODAS LAS FACTURAS ===');
    print('📋 CardCode original: $cardCode');
    print('📋 CardCode formateado: $formattedCardCode');
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

  static Future<List<Map<String, dynamic>>> searchClients(String searchTerm) async {
    print('🔍 === BUSCANDO CLIENTES ===');
    print('📋 Término: $searchTerm');
    return [];
  }

  static Future<Map<String, dynamic>?> getCardCodeStatistics(String cardCode) async {
    final formattedCardCode = formatCardCode(cardCode);
    print('📊 === OBTENIENDO ESTADÍSTICAS DE CLIENTE ===');
    print('📋 CardCode original: $cardCode');
    print('📋 CardCode formateado: $formattedCardCode');
    return {
      'count': 0,
      'totalAmount': 0.0,
      'overdueCount': 0,
      'urgentCount': 0,
      'upcomingCount': 0,
      'normalCount': 0,
      'cardCode': formattedCardCode,
      'originalCardCode': cardCode,
      'timestamp': DateTime.now().toIso8601String(),
      'queryTime': 0,
    };
  }

  static Future<Map<String, dynamic>?> getCompleteClientInfo(String cardCode) async {
    try {
      print('🔄 === OBTENIENDO INFORMACIÓN COMPLETA DEL CLIENTE ===');
      final clientData = await getClientData(cardCode);
      if (clientData != null) {
        print('✅ Información completa obtenida de SAP');
        return clientData;
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo información completa de SAP: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> debugClientData(String cardCode) async {
    final formattedCardCode = formatCardCode(cardCode);
    print('🔍 === DEPURANDO DATOS DE CLIENTE ===');
    print('📋 CardCode original: $cardCode');
    print('📋 CardCode formateado: $formattedCardCode');
    final clientData = await getClientData(cardCode);
    return clientData;
  }

  static Future<Map<String, dynamic>?> getClientDataWithFilters(String cardCode) async {
    return await getClientData(cardCode);
  }

  static void resetConnection() {
    _workingUrl = null;
    limpiarCacheListasPrecios();
    print('🔄 Cache de conexión Node.js SAP limpiado');
  }

}
