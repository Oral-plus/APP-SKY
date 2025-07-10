import 'package:intl/intl.dart';

class TransactionModel {
  final int id;
  final String codigoTransaccion;
  final int tipoTransaccionId;
  final String tipoNombre;
  final double monto;
  final double comision;
  final String estado;
  final DateTime fechaTransaccion;
  final int? usuarioOrigenId;
  final int? usuarioDestinoId;
  final String? nombreDestino;
  final String? descripcion;

  TransactionModel({
    required this.id,
    required this.codigoTransaccion,
    required this.tipoTransaccionId,
    required this.tipoNombre,
    required this.monto,
    required this.comision,
    required this.estado,
    required this.fechaTransaccion,
    this.usuarioOrigenId,
    this.usuarioDestinoId,
    this.nombreDestino,
    this.descripcion,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      codigoTransaccion: json['codigo_transaccion'] ?? '',
      tipoTransaccionId: json['tipo_transaccion_id'] ?? 0,
      tipoNombre: json['tipo_nombre'] ?? '',
      monto: (json['monto'] ?? 0).toDouble(),
      comision: (json['comision'] ?? 0).toDouble(),
      estado: json['estado'] ?? '',
      fechaTransaccion: json['fecha_transaccion'] != null
          ? DateTime.parse(json['fecha_transaccion'])
          : DateTime.now(),
      usuarioOrigenId: json['usuario_origen_id'],
      usuarioDestinoId: json['usuario_destino_id'],
      nombreDestino: json['nombre_destino'],
      descripcion: json['descripcion'],
    );
  }

  String get fechaFormateada {
    return DateFormat('dd/MM/yyyy HH:mm', 'es_CO').format(fechaTransaccion);
  }

  String get montoFormateado {
    return '\$${NumberFormat('#,##0.00', 'es_CO').format(monto)}';
  }

  String get comisionFormateada {
    return '\$${NumberFormat('#,##0.00', 'es_CO').format(comision)}';
  }
}
