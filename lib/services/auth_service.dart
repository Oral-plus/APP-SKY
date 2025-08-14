import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/user_session.dart';

class AuthService {
  // 🔧 CONFIGURACIÓN ACTUALIZADA - Apunta a tu API Node.js
  static const String _baseUrl = 'https://pedidos.oral-plus.com/api'; // Cambia por tu IP
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 🔍 Función para buscar usuario por cédula (conecta con tu API Node.js)
  static Future<bool> loginWithCedula(String cedula) async {
    try {
      print('🔍 AuthService: Buscando usuario con cédula: $cedula');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/get_customer.php?cedula=${Uri.encodeComponent(cedula)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      print('📡 AuthService: Respuesta recibida - Status: ${response.statusCode}');
      print('📄 AuthService: Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        
        // ⚠️ MANEJO MEJORADO: Verificar si es array con mensaje de error
        if (responseData is List && responseData.isNotEmpty) {
          final firstItem = responseData[0];
          if (firstItem is String && firstItem.contains('No se encontraron datos')) {
            print('❌ AuthService: Cliente no encontrado en SAP');
            return false;
          }
        }
        
        // ✅ CASO EXITOSO: Datos del cliente encontrados
        if (responseData != null && responseData is Map<String, dynamic>) {
          // Validar que tenga los campos mínimos requeridos
          if (responseData['CardName'] == null || responseData['CardName'].toString().trim().isEmpty) {
            print('❌ AuthService: Datos incompletos del cliente');
            return false;
          }

          // Crear UserModel desde los datos de SAP
          final fullName = responseData['CardName']?.toString().trim() ?? '';
          final nameParts = fullName.split(' ');
          
          final userModel = UserModel(
            id: cedula,
            nombre: nameParts.isNotEmpty ? nameParts.first : '',
            apellido: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
            telefono: responseData['Phone1']?.toString().trim() ?? '',
            email: responseData['E_Mail']?.toString().trim() ?? '',
            documento: cedula,
            tipoDocumento: cedula.isNotEmpty ? cedula.substring(0, 1).toUpperCase() : 'C',
          );
          
          print('✅ AuthService: Usuario creado - ${userModel.nombreCompleto}');
          
          // Guardar en la sesión
          final userSession = UserSession();
          userSession.setUser(userModel);
          
          return true;
        }
        
        print('❌ AuthService: Formato de respuesta inválido');
        return false;
      } else if (response.statusCode == 404) {
        print('❌ AuthService: Cliente no encontrado (404)');
        return false;
      } else {
        print('❌ AuthService: Error del servidor: ${response.statusCode}');
        throw Exception('Error al obtener datos del cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ AuthService: Error de conexión: $e');
      throw Exception('Error de conexión con SAP: $e');
    }
  }

  // 🔍 Función para obtener datos del usuario por cédula (sin login)
  static Future<Map<String, dynamic>?> getUserDataByCedula(String cedula) async {
    try {
      print('🔍 AuthService: Obteniendo datos para cédula: $cedula');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/get_customer.php?cedula=${Uri.encodeComponent(cedula)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      print('📡 AuthService: Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        
        // ⚠️ MANEJO DE ARRAY CON MENSAJE DE ERROR
        if (responseData is List && responseData.isNotEmpty) {
          final firstItem = responseData[0];
          if (firstItem is String && firstItem.contains('No se encontraron datos')) {
            print('❌ AuthService: Cliente no encontrado en SAP');
            return null;
          }
        }
        
        // ✅ CASO EXITOSO
        if (responseData != null && responseData is Map<String, dynamic>) {
          print('✅ AuthService: Datos obtenidos exitosamente');
          return responseData;
        }
        
        return null;
      } else if (response.statusCode == 404) {
        print('❌ AuthService: Cliente no encontrado (404)');
        return null;
      } else {
        print('❌ AuthService: Error del servidor: ${response.statusCode}');
        throw Exception('Error al obtener datos del cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ AuthService: Error de conexión: $e');
      throw Exception('Error de conexión con SAP: $e');
    }
  }

  // 🔄 Función para refrescar datos del usuario logueado
  static Future<bool> refreshUserData() async {
    final userSession = UserSession();
    if (!userSession.isLoggedIn || userSession.currentUser?.documento == null) {
      print('❌ AuthService: No hay usuario logueado para refrescar');
      return false;
    }

    try {
      print('🔄 AuthService: Refrescando datos del usuario: ${userSession.currentUser!.documento}');
      
      final userData = await getUserDataByCedula(userSession.currentUser!.documento);
      if (userData != null) {
        final fullName = userData['CardName']?.toString().trim() ?? '';
        final nameParts = fullName.split(' ');
        
        final updatedUser = UserModel(
          id: userSession.currentUser!.documento,
          nombre: nameParts.isNotEmpty ? nameParts.first : userSession.currentUser!.nombre,
          apellido: nameParts.length > 1 ? nameParts.skip(1).join(' ') : userSession.currentUser!.apellido,
          telefono: userData['Phone1']?.toString().trim() ?? userSession.currentUser!.telefono,
          email: userData['E_Mail']?.toString().trim() ?? userSession.currentUser!.email,
          documento: userSession.currentUser!.documento,
          tipoDocumento: userSession.currentUser!.tipoDocumento,
        );
        
        userSession.setUser(updatedUser);
        print('✅ AuthService: Datos refrescados exitosamente');
        return true;
      }
      
      print('❌ AuthService: No se pudieron obtener datos actualizados');
      return false;
    } catch (e) {
      print('❌ AuthService: Error al refrescar datos: $e');
      return false;
    }
  }

  // 🚪 Función para cerrar sesión
  static Future<void> logout() async {
    print('🚪 AuthService: Cerrando sesión');
    final userSession = UserSession();
    userSession.clearSession();
  }

  // ✅ Verificar si hay sesión activa
  static Future<bool> hasActiveSession() async {
    final userSession = UserSession();
    final hasSession = userSession.isLoggedIn;
    print('🔍 AuthService: Sesión activa: $hasSession');
    return hasSession;
  }

  // 🧪 Función para probar la conexión con la API
  static Future<bool> testConnection() async {
    try {
      print('🧪 AuthService: Probando conexión con API...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/test'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ AuthService: Conexión exitosa con API');
          return true;
        }
      }
      
      print('❌ AuthService: Error en conexión con API');
      return false;
    } catch (e) {
      print('❌ AuthService: Error de conexión: $e');
      return false;
    }
  }

  // 🔍 Verificar si un cliente existe (más rápido)
  static Future<bool> customerExists(String cedula) async {
    try {
      print('🔍 AuthService: Verificando existencia de cliente: $cedula');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/customer/exists/${Uri.encodeComponent(cedula)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final exists = responseData['exists'] == true;
        print('📄 AuthService: Cliente existe: $exists');
        return exists;
      }
      
      return false;
    } catch (e) { 
      print('❌ AuthService: Error verificando cliente: $e');
      return false;
    }
  }
}
