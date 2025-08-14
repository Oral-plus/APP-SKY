
/// Adaptador para conectar con ApiService del dashboard
class ApiServiceAdapter {
  /// Verifica si hay una sesión activa en el dashboard
  static Future<bool> hasActiveSession() async {
    try {
      // Implementación real: conectar con ApiService del dashboard
      // Ejemplo:
      // return await ApiService.hasActiveSession();
      
      // Simulación para pruebas
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      print('Error verificando sesión: $e');
      return false;
    }
  }
  
  /// Obtiene el perfil del usuario desde el dashboard
  static Future<UserModel?> getUserProfile() async {
    try {
      // Implementación real: conectar con ApiService del dashboard
      // Ejemplo:
      // return await ApiService.getUserProfile();
      
      // Simulación para pruebas
      await Future.delayed(const Duration(milliseconds: 300));
      return UserModel(
        nombre: 'Usuario de Prueba',
        documento: 'C39536225',
        email: 'usuario@ejemplo.com',
      );
    } catch (e) {
      print('Error obteniendo perfil: $e');
      return null;
    }
  }
}

/// Modelo simple para usuario (para compatibilidad con el dashboard)
class UserModel {
  final String nombre;
  final String documento;
  final String email;
  
  UserModel({
    required this.nombre,
    required this.documento,
    required this.email,
  });
}
