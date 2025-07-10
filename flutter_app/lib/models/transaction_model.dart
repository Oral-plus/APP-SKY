import 'package:intl/intl.dart';

class TransactionModel {
  final int id;
  final String codigoTransaccion;
  final int usuarioOrigenId;
  final int? usuarioDestinoId;
  final int tipoTransaccionId;
  final double monto;
  final double comision;
  final double montoTotal;
  final String? descripcion;
  final String? referencia;
  final String? telefonoDestino;
  final String? nombreDestino;
  final String estado;
  final DateTime fechaTransaccion;
  final DateTime? fechaProcesamiento;
  final String? tipoNombre;

  TransactionModel({
    required this.id,
    required this.codigoTransaccion,
    required this.usuarioOrigenId,
    this.usuarioDestinoId,
    required this.tipoTransaccionId,
    required this.monto,
    required this.comision,
    required this.montoTotal,
    this.descripcion,
    this.referencia,
    this.telefonoDestino,
    this.nombreDestino,
    required this.estado,
    required this.fechaTransaccion,
    this.fechaProcesamiento,
    this.tipoNombre,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      codigoTransaccion: json['codigo_transaccion'] ?? '',
      usuarioOrigenId: json['usuario_origen_id'] ?? 0,
      usuarioDestinoId: json['usuario_destino_id'],
      tipoTransaccionId: json['tipo_transaccion_id'] ?? 0,
      monto: _parseDouble(json['monto']),
      comision: _parseDouble(json['comision']),
      montoTotal: _parseDouble(json['monto_total']),
      descripcion: json['descripcion'],
      referencia: json['referencia'],
      telefonoDestino: json['telefono_destino'],
      nombreDestino: json['nombre_destino'],
      estado: json['estado'] ?? 'PENDIENTE',
      fechaTransaccion: _parseDateTime(json['fecha_transaccion']),
      fechaProcesamiento: _parseDateTime(json['fecha_procesamiento']),
      tipoNombre: json['tipo_nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_transaccion': codigoTransaccion,
      'usuario_origen_id': usuarioOrigenId,
      'usuario_destino_id': usuarioDestinoId,
      'tipo_transaccion_id': tipoTransaccionId,
      'monto': monto,
      'comision': comision,
      'monto_total': montoTotal,
      'descripcion': descripcion,
      'referencia': referencia,
      'telefono_destino': telefonoDestino,
      'nombre_destino': nombreDestino,
      'estado': estado,
      'fecha_transaccion': fechaTransaccion.toIso8601String(),
      'fecha_procesamiento': fechaProcesamiento?.toIso8601String(),
      'tipo_nombre': tipoNombre,
    };
  }

  // Métodos de utilidad para formateo
  String get montoFormateado => 'Bs. ${monto.toStringAsFixed(2)}';
  String get comisionFormateada => 'Bs. ${comision.toStringAsFixed(2)}';
  String get montoTotalFormateado => 'Bs. ${montoTotal.toStringAsFixed(2)}';

  String get fechaFormateada {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(fechaTransaccion);
  }

  String get fechaCorta {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(fechaTransaccion);
  }

  String get horaFormateada {
    final formatter = DateFormat('HH:mm');
    return formatter.format(fechaTransaccion);
  }

  String get fechaRelativa {
    final now = DateTime.now();
    final difference = now.difference(fechaTransaccion);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Ahora';
        }
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return fechaCorta;
    }
  }

  // Obtener el nombre para mostrar
  String get nombreParaMostrar {
    if (nombreDestino != null && nombreDestino!.isNotEmpty) {
      return nombreDestino!;
    }
    if (tipoNombre != null && tipoNombre!.isNotEmpty) {
      return tipoNombre!;
    }
    return 'Transacción';
  }

  // Obtener el teléfono formateado
  String get telefonoFormateado {
    if (telefonoDestino != null && telefonoDestino!.isNotEmpty) {
      return '+57 $telefonoDestino';
    }
    return '';
  }

  // Verificar si es una transacción saliente
  bool isOutgoing(int currentUserId) {
    return usuarioOrigenId == currentUserId;
  }

  // Obtener el signo del monto según el tipo de transacción
  String getMontoConSigno(int currentUserId) {
    final isOut = isOutgoing(currentUserId);
    return '${isOut ? '-' : '+'}$montoFormateado';
  }

  // Obtener el estado formateado
  String get estadoFormateado {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
        return 'Completada';
      case 'PENDIENTE':
        return 'Pendiente';
      case 'FALLIDA':
        return 'Fallida';
      case 'CANCELADA':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  // Métodos de parsing seguros
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Crear copia con modificaciones
  TransactionModel copyWith({
    int? id,
    String? codigoTransaccion,
    int? usuarioOrigenId,
    int? usuarioDestinoId,
    int? tipoTransaccionId,
    double? monto,
    double? comision,
    double? montoTotal,
    String? descripcion,
    String? referencia,
    String? telefonoDestino,
    String? nombreDestino,
    String? estado,
    DateTime? fechaTransaccion,
    DateTime? fechaProcesamiento,
    String? tipoNombre,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      codigoTransaccion: codigoTransaccion ?? this.codigoTransaccion,
      usuarioOrigenId: usuarioOrigenId ?? this.usuarioOrigenId,
      usuarioDestinoId: usuarioDestinoId ?? this.usuarioDestinoId,
      tipoTransaccionId: tipoTransaccionId ?? this.tipoTransaccionId,
      monto: monto ?? this.monto,
      comision: comision ?? this.comision,
      montoTotal: montoTotal ?? this.montoTotal,
      descripcion: descripcion ?? this.descripcion,
      referencia: referencia ?? this.referencia,
      telefonoDestino: telefonoDestino ?? this.telefonoDestino,
      nombreDestino: nombreDestino ?? this.nombreDestino,
      estado: estado ?? this.estado,
      fechaTransaccion: fechaTransaccion ?? this.fechaTransaccion,
      fechaProcesamiento: fechaProcesamiento ?? this.fechaProcesamiento,
      tipoNombre: tipoNombre ?? this.tipoNombre,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, codigo: $codigoTransaccion, monto: $montoFormateado, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
