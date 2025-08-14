import 'package:flutter/foundation.dart';
import 'user_model.dart';

class UserSession extends ChangeNotifier {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // Compat: acceso como singleton vía `UserSession.instance`
  static UserSession get instance => _instance;

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _esTAT = false; // Compat: indicador TAT

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn && _currentUser != null;
  
  // Getters de compatibilidad con código existente
  bool get sesionActiva => isLoggedIn;
  String? get codigoCliente => cardCodeSAP;
  bool get esTAT => _esTAT;
  
  // Getters de compatibilidad con el código anterior
  String? get userName => _currentUser?.nombreCompleto;
  String? get userCedula => _currentUser?.documento;
  String? get userEmail => _currentUser?.email;
  String? get userPhone => _currentUser?.telefono;
  String? get userAddress => null; // No disponible en UserModel

  // Función para establecer el usuario
  void setUser(UserModel user) {
    _currentUser = user;
    _isLoggedIn = true;
    notifyListeners();
  }

  // Compat: permitir establecer TAT manualmente
  void setEsTAT(bool value) {
    _esTAT = value;
    notifyListeners();
  }

  // Función de compatibilidad con el código anterior
  void setUserData({
    required String userId,
    required String cedula,
    String? name,
    String? email,
    String? phone,
    String? address,
  }) {
    final userModel = UserModel(
      id: userId,
      nombre: name?.split(' ').first ?? '',
      apellido: name?.split(' ').skip(1).join(' ') ?? '',
      telefono: phone ?? '',
      email: email ?? '',
      documento: cedula,
      tipoDocumento: cedula.isNotEmpty ? cedula.substring(0, 1) : 'C',
    );
    
    setUser(userModel);
  }

  // Función para actualizar datos del usuario
  void updateUserData({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) {
    if (_currentUser != null) {
      final updatedUser = UserModel(
        id: _currentUser!.id,
        nombre: name?.split(' ').first ?? _currentUser!.nombre,
        apellido: name?.split(' ').skip(1).join(' ') ?? _currentUser!.apellido,
        telefono: phone ?? _currentUser!.telefono,
        email: email ?? _currentUser!.email,
        documento: _currentUser!.documento,
        tipoDocumento: _currentUser!.tipoDocumento,
        fechaNacimiento: _currentUser!.fechaNacimiento,
        estado: _currentUser!.estado,
        saldo: _currentUser!.saldo,
        limiteDiario: _currentUser!.limiteDiario,
        limiteMensual: _currentUser!.limiteMensual,
        fotoPerfil: _currentUser!.fotoPerfil,
        fechaRegistro: _currentUser!.fechaRegistro,
        fechaActualizacion: _currentUser!.fechaActualizacion,
        pin: _currentUser!.pin,
      );
      
      setUser(updatedUser);
    }
  }

  // Función para limpiar la sesión
  void clearSession() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // Función para obtener el CardCode SAP
  String? get cardCodeSAP => _currentUser?.cardCodeSAP;
}
