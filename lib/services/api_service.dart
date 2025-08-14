import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/invoice_model.dart';

class ApiService {
  static const String baseUrl = 'https://sky.oral-plus.com/api';
  static const _storage = FlutterSecureStorage();

  static Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
    await _storage.delete(key: 'user_documento');
    print('🗑️ Datos de sesión eliminados');
  }

  static Future<Map<String, String>> get headers async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final token = await getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // AUTENTICACIÓN

  // Login con documento (cédula) - MEJORADO
  static Future<Map<String, dynamic>> loginWithDocumento(String documento, String pin) async {
    try {
      print('🔐 Intentando login con documento: $documento');
      print('🔑 PIN length: ${pin.length}');
      
      // Validar entrada
      if (documento.trim().isEmpty) {
        throw Exception('El documento no puede estar vacío');
      }
      
      if (pin.trim().isEmpty) {
        throw Exception('El PIN no puede estar vacío');
      }
      
      if (pin.length != 4) {
        throw Exception('El PIN debe tener exactamente 4 dígitos');
      }
      
      // Preparar datos para enviar
      final requestBody = {
        'documento': documento.trim(),
        'pin': pin.trim(),
      };
      
      print('📤 Enviando datos: ${jsonEncode(requestBody)}');
      
      // Configurar timeout
      final client = http.Client();
      
      try {
        final response = await client.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Timeout: La conexión tardó demasiado tiempo');
          },
        );

        print('📡 Status Code: ${response.statusCode}');
        print('📡 Response Headers: ${response.headers}');
        print('📄 Response Body: ${response.body}');

        // Verificar si la respuesta está vacía
        if (response.body.isEmpty) {
          throw Exception('El servidor devolvió una respuesta vacía');
        }

        // Intentar decodificar JSON
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          print('❌ Error decodificando JSON: $e');
          print('📄 Raw response: ${response.body}');
          throw Exception('Respuesta del servidor no válida: ${response.body}');
        }

        print('📋 Datos decodificados: $data');

        // Manejar diferentes códigos de estado
        if (response.statusCode == 200) {
          if (data['success'] == true) {
            // Login exitoso
            print('✅ Login exitoso');
            
            // Guardar token si existe
            if (data['token'] != null) {
              await setToken(data['token']);
              print('🔑 Token guardado');
            }
            
            // Guardar documento para futuras consultas
            await _storage.write(key: 'user_documento', value: documento.trim());
            print('📄 Documento guardado');
            
            // Guardar datos del usuario si vienen en la respuesta
            final userData = data['user'] ?? data['usuario'] ?? data['data'];
            if (userData != null) {
              await _storage.write(key: 'user_data', value: jsonEncode(userData));
              print('✅ Usuario guardado: ${userData['nombre']} ${userData['apellido']}');
            }
            
            return {
              'success': true,
              'message': data['message'] ?? 'Login exitoso',
              'user': userData,
              'token': data['token'],
            };
          } else {
            // Login fallido pero con respuesta 200
            final errorMessage = data['error'] ?? data['message'] ?? 'Credenciales incorrectas';
            print('❌ Login fallido: $errorMessage');
            throw Exception(errorMessage);
          }
        } else if (response.statusCode == 401) {
          // No autorizado
          final errorMessage = data['error'] ?? data['message'] ?? 'Documento o PIN incorrectos';
          print('❌ No autorizado: $errorMessage');
          throw Exception(errorMessage);
        } else if (response.statusCode == 400) {
          // Bad request
          final errorMessage = data['error'] ?? data['message'] ?? 'Datos inválidos';
          print('❌ Bad request: $errorMessage');
          throw Exception(errorMessage);
        } else if (response.statusCode == 404) {
          // Not found
          throw Exception('Servicio no disponible. Contacta al soporte técnico.');
        } else if (response.statusCode == 500) {
          // Server error
          throw Exception('Error del servidor. Intenta más tarde.');
        } else {
          // Otros códigos de estado
          final errorMessage = data['error'] ?? data['message'] ?? 'Error desconocido del servidor';
          print('❌ Error ${response.statusCode}: $errorMessage');
          throw Exception('Error del servidor (${response.statusCode}): $errorMessage');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('❌ Error en loginWithDocumento: $e');
      
      // Re-lanzar excepciones conocidas
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      
      // Manejar errores de conexión
      if (e.toString().contains('SocketException') || 
          e.toString().contains('HandshakeException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('No se puede conectar al servidor. Verifica tu conexión a internet.');
      }
      
      if (e.toString().contains('TimeoutException') || 
          e.toString().contains('Timeout')) {
        throw Exception('La conexión tardó demasiado tiempo. Intenta nuevamente.');
      }
      
      // Error genérico
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  // Registro
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String telefono,
    required String email,
    required String pin,
    required String documento,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await headers,
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'telefono': telefono,
          'email': email,
          'pin': pin,
          'documento': documento,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Error en el registro');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // USUARIOS

  // Obtener todos los usuarios
  static Future<List<UserModel>?> getAllUsers({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      print('👥 Obteniendo todos los usuarios...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users?page=$page&limit=$limit'),
        headers: await headers,
      );

      print('📡 Respuesta usuarios: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          final usersData = data['users'] ?? data['usuarios'] ?? data['data'] ?? [];
          
          if (usersData is List) {
            final users = usersData.map((user) => UserModel.fromJson(user)).toList();
            print('✅ Usuarios cargados: ${users.length}');
            return users;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo usuarios: $e');
      return null;
    }
  }

  // Obtener usuario específico por documento
  static Future<UserModel?> getUserByDocumento(String documento) async {
    try {
      print('🔍 Buscando usuario por documento: $documento');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/$documento'),
        headers: await headers,
      );

      print('📡 Respuesta getUserByDocumento: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          final userData = data['user'] ?? data['usuario'] ?? data;
          
          // Guardar datos del usuario
          await _storage.write(key: 'user_data', value: jsonEncode(userData));
          
          final user = UserModel.fromJson(userData);
          print('✅ Usuario encontrado: ${user.nombre} ${user.apellido}');
          return user;
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error en getUserByDocumento: $e');
      return null;
    }
  }

  // Obtener usuario específico por ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      print('🔍 Buscando usuario por ID: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/id/$userId'),
        headers: await headers,
      );

      print('📡 Respuesta getUserById: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          final userData = data['user'] ?? data['usuario'] ?? data;
          final user = UserModel.fromJson(userData);
          print('✅ Usuario encontrado por ID: ${user.nombre} ${user.apellido}');
          return user;
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error en getUserById: $e');
      return null;
    }
  }

  // Obtener perfil del usuario actual
  static Future<UserModel?> getUserProfile() async {
    try {
      print('👤 Obteniendo perfil del usuario...');
      
      // Primero intentar obtener datos guardados localmente
      final savedUserData = await _storage.read(key: 'user_data');
      if (savedUserData != null) {
        print('📱 Datos del usuario encontrados localmente');
        final userData = jsonDecode(savedUserData);
        final user = UserModel.fromJson(userData);
        print('✅ Usuario cargado desde caché: ${user.nombre} ${user.apellido}');
        return user;
      }

      // Si no hay datos locales, obtener usando el documento guardado
      final documento = await _storage.read(key: 'user_documento');
      if (documento != null) {
        print('🔍 Obteniendo usuario por documento guardado: $documento');
        return await getUserByDocumento(documento);
      }

      // Fallback: intentar obtener del endpoint original
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: await headers,
      );

      print('📡 Respuesta del perfil: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final userData = data['user'] ?? data['usuario'] ?? data;
          
          // Guardar datos actualizados
          await _storage.write(key: 'user_data', value: jsonEncode(userData));
          
          final user = UserModel.fromJson(userData);
          print('✅ Perfil obtenido del servidor: ${user.nombre} ${user.apellido}');
          return user;
        }
      }
      
      print('❌ No se pudo obtener el perfil del usuario');
      return null;
    } catch (e) {
      print('❌ Error en getUserProfile: $e');
      
      // Como fallback, intentar usar datos guardados
      final savedUserData = await _storage.read(key: 'user_data');
      if (savedUserData != null) {
        final userData = jsonDecode(savedUserData);
        return UserModel.fromJson(userData);
      }
      
      return null;
    }
  }

  // Obtener usuario en caché
  static Future<UserModel?> getCachedUser() async {
    try {
      final savedUserData = await _storage.read(key: 'user_data');
      if (savedUserData != null) {
        final userData = jsonDecode(savedUserData);
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Error obteniendo usuario en caché: $e');
      return null;
    }
  }

  // Buscar usuarios por nombre
  static Future<List<UserModel>?> searchUsers(String query) async {
    try {
      print('🔍 Buscando usuarios: $query');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/search?q=${Uri.encodeComponent(query)}'),
        headers: await headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          final usersData = data['users'] ?? data['usuarios'] ?? data['data'] ?? [];
          
          if (usersData is List) {
            final users = usersData.map((user) => UserModel.fromJson(user)).toList();
            print('✅ Usuarios encontrados: ${users.length}');
            return users;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error buscando usuarios: $e');
      return null;
    }
  }

  // Saldo del usuario
  static Future<double> getUserBalance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/balance'),
        headers: await headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return double.parse(data['saldo'].toString());
      } else {
        throw Exception(data['error'] ?? 'Error obteniendo saldo');
      }
    } catch (e) {
      print('❌ Error obteniendo saldo: $e');
      throw Exception('Error obteniendo saldo: $e');
    }
  }

  // FACTURAS

  // Obtener facturas pendientes
  static Future<List<InvoiceModel>?> getPendingInvoices() async {
    try {
      print('📄 Obteniendo facturas pendientes...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/invoices/pending'),
        headers: await headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          final invoicesData = data['invoices'] ?? data['facturas'] ?? data['data'] ?? [];
          
          if (invoicesData is List) {
            final invoices = invoicesData.map((invoice) => InvoiceModel.fromJson(invoice)).toList();
            print('✅ Facturas pendientes cargadas: ${invoices.length}');
            return invoices;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo facturas: $e');
      return null;
    }
  }

  // Obtener historial de facturas
  static Future<List<InvoiceModel>?> getInvoiceHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invoices/history?page=$page&limit=$limit'),
        headers: await headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          final invoicesData = data['invoices'] ?? data['facturas'] ?? data['data'] ?? [];
          
          if (invoicesData is List) {
            final invoices = invoicesData.map((invoice) => InvoiceModel.fromJson(invoice)).toList();
            print('✅ Historial de facturas cargado: ${invoices.length}');
            return invoices;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo historial de facturas: $e');
      return null;
    }
  }

  // CITAS

  // Obtener citas próximas
  

  // TRANSACCIONES

  static Future<Map<String, dynamic>> sendMoney({
    required String telefonoDestino,
    required double monto,
    String? descripcion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/send'),
        headers: await headers,
        body: jsonEncode({
          'telefono_destino': telefonoDestino,
          'monto': monto,
          'descripcion': descripcion,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Error enviando dinero');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<TransactionModel>> getTransactionHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/history?page=$page&limit=$limit'),
        headers: await headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        final List<dynamic> transacciones = data['transacciones'];
        return transacciones.map((t) => TransactionModel.fromJson(t)).toList();
      } else {
        throw Exception(data['error'] ?? 'Error obteniendo historial');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // BENEFICIARIOS

  static Future<List<Map<String, dynamic>>> getBeneficiaries() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/beneficiaries'),
        headers: await headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return List<Map<String, dynamic>>.from(data['beneficiarios']);
      } else {
        throw Exception(data['error'] ?? 'Error obteniendo beneficiarios');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> addBeneficiary({
    required String nombre,
    required String telefono,
    String? alias,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/beneficiaries'),
        headers: await headers,
        body: jsonEncode({
          'nombre': nombre,
          'telefono': telefono,
          'alias': alias,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Error agregando beneficiario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // UTILIDADES

  // Verificar si hay sesión activa
  static Future<bool> hasActiveSession() async {
    final token = await getToken();
    final userData = await _storage.read(key: 'user_data');
    return token != null && userData != null;
  }

  // Test de conexión - MEJORADO
  static Future<bool> testConnection() async {
    try {
      print('🔗 Probando conexión a: $baseUrl/test');
      
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout en test de conexión');
        },
      );

      print('📡 Test connection status: ${response.statusCode}');
      print('📄 Test connection body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final isSuccess = data['success'] == true;
          print('✅ Test de conexión: ${isSuccess ? 'exitoso' : 'fallido'}');
          return isSuccess;
        } catch (e) {
          print('❌ Error decodificando respuesta del test: $e');
          return false;
        }
      } else {
        print('❌ Test de conexión falló con código: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error en test de conexión: $e');
      return false;
    }
  }
}
