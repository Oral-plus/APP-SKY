class UserModel {
  final int id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String? email;
  final double saldo;
  final double limiteDiario;
  final double limiteMensual;
  final String? fotoPerfil;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    this.email,
    required this.saldo,
    required this.limiteDiario,
    required this.limiteMensual,
    this.fotoPerfil,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'],
      saldo: _parseDouble(json['saldo']),
      limiteDiario: _parseDouble(json['limite_diario']),
      limiteMensual: _parseDouble(json['limite_mensual']),
      fotoPerfil: json['foto_perfil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'email': email,
      'saldo': saldo,
      'limite_diario': limiteDiario,
      'limite_mensual': limiteMensual,
      'foto_perfil': fotoPerfil,
    };
  }

  // Métodos de utilidad
  String get nombreCompleto => '$nombre $apellido';

  String get iniciales {
    String initials = '';
    if (nombre.isNotEmpty) initials += nombre[0].toUpperCase();
    if (apellido.isNotEmpty) initials += apellido[0].toUpperCase();
    return initials.isEmpty ? 'U' : initials;
  }

  String get saldoFormateado => 'Bs. ${saldo.toStringAsFixed(2)}';

  String get limiteDiarioFormateado => 'Bs. ${limiteDiario.toStringAsFixed(2)}';

  String get limiteMensualFormateado => 'Bs. ${limiteMensual.toStringAsFixed(2)}';

  String get telefonoFormateado => '+591 $telefono';

  // Método para parsear double de forma segura
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Crear copia con modificaciones
  UserModel copyWith({
    int? id,
    String? nombre,
    String? apellido,
    String? telefono,
    String? email,
    double? saldo,
    double? limiteDiario,
    double? limiteMensual,
    String? fotoPerfil,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      saldo: saldo ?? this.saldo,
      limiteDiario: limiteDiario ?? this.limiteDiario,
      limiteMensual: limiteMensual ?? this.limiteMensual,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nombre: $nombreCompleto, telefono: $telefono, saldo: $saldoFormateado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
