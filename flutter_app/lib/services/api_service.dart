import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  // Configuración de la API
  static const String baseUrl = 'http://localhost:3000/api';
  static const Duration timeoutDuration = Duration(seconds: 30);
  
  static String? _token;

  // Gestión de tokens
  static void setToken(String token) {
    _token = token;
    _saveTokenToStorage(token);
  }

  static String? getToken() {
    return _token;
  }

  static void clearToken() {
    _token = null;
    _removeTokenFromStorage();
  }

  // Almacenamiento local del token
  static Future<void> _saveTokenToStorage(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      print('Error guardando token: $e');
    }
  }

  static Future<void> _removeTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      print('Error removiendo token: $e');
    }
  }

  // Headers para las peticiones
  static Map<String, String> get headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

  // Manejo de errores HTTP
  static String _handleHttpError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['error'] ?? 'Error desconocido';
    } catch (e) {
      switch (response.statusCode) {
        case 400:
          return 'Solicitud inválida';
        case 401:
          return 'No autorizado';
        case 403:
          return 'Acceso denegado';
        case 404:
          return 'Recurso no encontrado';
        case 500:
          return 'Error interno del servidor';
        default:
          return 'Error de conexión (${response.statusCode})';
      }
    }
  }

  // Método genérico para peticiones HTTP
  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(timeoutDuration);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(timeoutDuration);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_handleHttpError(response));
      }
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu conexión.');
    } on HttpException {
      throw Exception('Error de conexión HTTP');
    } on FormatException {
      throw Exception('Error en el formato de respuesta del servidor');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Tiempo de espera agotado. Intenta nuevamente.');
      }
      rethrow;
    }
  }

  // AUTENTICACIÓN

  static Future<Map<String, dynamic>> login(String telefono, String pin) async {
    final data = await _makeRequest('POST', '/auth/login', body: {
      'telefono': telefono,
      'pin': pin,
    });

    if (data['success'] && data['token'] != null) {
      setToken(data['token']);
    }

    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String telefono,
    required String email,
    required String pin,
    required String documento,
  }) async {
    return await _makeRequest('POST', '/auth/register', body: {
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'email': email,
      'pin': pin,
      'documento': documento,
    });
  }

  // USUARIO

  static Future<UserModel> getUserProfile() async {
    final data = await _makeRequest('GET', '/user/profile');
    
    if (data['success'] && data['user'] != null) {
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception('Error obteniendo perfil de usuario');
    }
  }

  static Future<double> getUserBalance() async {
    final data = await _makeRequest('GET', '/user/balance');
    
    if (data['success'] && data['saldo'] != null) {
      return double.parse(data['saldo'].toString());
    } else {
      throw Exception('Error obteniendo saldo');
    }
  }

  // TRANSACCIONES

  static Future<Map<String, dynamic>> sendMoney({
    required String telefonoDestino,
    required double monto,
    String? descripcion,
  }) async {
    return await _makeRequest('POST', '/transactions/send', body: {
      'telefono_destino': telefonoDestino,
      'monto': monto,
      'descripcion': descripcion,
    });
  }

  static Future<List<TransactionModel>> getTransactionHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _makeRequest('GET', '/transactions/history', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    
    if (data['success'] && data['transacciones'] != null) {
      final List<dynamic> transacciones = data['transacciones'];
      return transacciones.map((t) => TransactionModel.fromJson(t)).toList();
    } else {
      throw Exception('Error obteniendo historial de transacciones');
    }
  }

  // BENEFICIARIOS

  static Future<List<Map<String, dynamic>>> getBeneficiaries() async {
    final data = await _makeRequest('GET', '/beneficiaries');
    
    if (data['success'] && data['beneficiarios'] != null) {
      return List<Map<String, dynamic>>.from(data['beneficiarios']);
    } else {
      throw Exception('Error obteniendo beneficiarios');
    }
  }

  static Future<Map<String, dynamic>> addBeneficiary({
    required String nombre,
    required String telefono,
    String? alias,
  }) async {
    return await _makeRequest('POST', '/beneficiaries', body: {
      'nombre': nombre,
      'telefono': telefono,
      'alias': alias,
    });
  }

  // NOTIFICACIONES

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final data = await _makeRequest('GET', '/notifications');
    
    if (data['success'] && data['notificaciones'] != null) {
      return List<Map<String, dynamic>>.from(data['notificaciones']);
    } else {
      throw Exception('Error obteniendo notificaciones');
    }
  }

  // UTILIDADES

  static Future<bool> testConnection() async {
    try {
      final data = await _makeRequest('GET', '/test');
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getHealthStatus() async {
    return await _makeRequest('GET', '/health');
  }

  // Validar conectividad
  static Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
