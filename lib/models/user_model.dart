class UserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String email;
  final String? pin;
  late final String documento;
  final String? tipoDocumento;
  final String? fechaNacimiento;
  final String? estado;
  final double? saldo;
  final double? limiteDiario;
  final double? limiteMensual;
  final String? fotoPerfil;
  final String? fechaRegistro;
  final String? fechaActualizacion;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.email,
    this.pin,
    required this.documento,
    this.tipoDocumento,
    this.fechaNacimiento,
    this.estado,
    this.saldo,
    this.limiteDiario,
    this.limiteMensual,
    this.fotoPerfil,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      pin: json['pin']?.toString(),
      documento: json['documento'] ?? '',
      tipoDocumento: json['tipo_documento'] ?? json['tipoDocumento'],
      fechaNacimiento: json['fecha_nacimiento'] ?? json['fechaNacimiento'],
      estado: json['estado'] ?? 'activo',
      saldo: _parseDouble(json['saldo']),
      limiteDiario: _parseDouble(json['limite_diario'] ?? json['limiteDiario']),
      limiteMensual: _parseDouble(json['limite_mensual'] ?? json['limiteMensual']),
      fotoPerfil: json['foto_perfil'] ?? json['fotoPerfil'],
      fechaRegistro: json['fecha_registro'] ?? json['fechaRegistro'],
      fechaActualizacion: json['fecha_actualizacion'] ?? json['fechaActualizacion'],
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'email': email,
      'pin': pin,
      'documento': documento,
      'tipo_documento': tipoDocumento,
      'fecha_nacimiento': fechaNacimiento,
      'estado': estado,
      'saldo': saldo,
      'limite_diario': limiteDiario,
      'limite_mensual': limiteMensual,
      'foto_perfil': fotoPerfil,
      'fecha_registro': fechaRegistro,
      'fecha_actualizacion': fechaActualizacion,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
    
  String get saldoFormateado {
    if (saldo == null) return '\$0';
    return '\$${saldo!.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  bool get estaActivo => estado?.toLowerCase() == 'activo';
    
  bool get tieneFotoPerfil => fotoPerfil != null && fotoPerfil!.isNotEmpty;

  // Método adicional para obtener el CardCode SAP
  String get cardCodeSAP {
    final tipoDoc = tipoDocumento ?? 'C';
    return '$tipoDoc$documento';
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nombreCompleto: $nombreCompleto, documento: ${tipoDocumento ?? 'C'}$documento, email: $email, saldo: $saldoFormateado, activo: $estaActivo)';
  }
}
