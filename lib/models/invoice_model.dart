import 'package:flutter/material.dart';

class InvoiceModel {
  final String cardCode;
  final String cardName;
  final String cardFName;
  final String docNum;
  final DateTime docDueDate;
  final double amount;
  final String formattedAmount;
  final String? pdfUrl;
  final int daysUntilDue;
  final String formattedDueDate;
  final String status;
  final WompiData wompiData;

  InvoiceModel({
    required this.cardCode,
    required this.cardName,
    required this.cardFName,
    required this.docNum,
    required this.docDueDate,
    required this.amount,
    required this.formattedAmount,
    this.pdfUrl,
    required this.daysUntilDue,
    required this.formattedDueDate,
    required this.status,
    required this.wompiData,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔄 Procesando factura desde API: ${json['numeroFactura'] ?? json['docNum'] ?? 'SIN-NUMERO'}');
      
      // Mapear campos de la API a campos del modelo
      final cardCode = (json['codigoCliente'] ?? json['cardCode'] ?? 'SIN-CODIGO').toString();
      final cardName = (json['nombreCliente'] ?? json['cardName'] ?? 'Cliente sin nombre').toString();
      final cardFName = (json['nombreFactura'] ?? json['cardFName'] ?? cardName).toString();
      final docNum = (json['numeroFactura'] ?? json['docNum'] ?? 'SIN-NUMERO').toString();
      final status = (json['estado'] ?? json['status'] ?? 'Pendiente').toString();
      
      // Procesar fecha de vencimiento
      DateTime dueDate;
      try {
        String? dateStr = json['fechaVencimiento'] ?? json['docDueDate'] ?? json['fechaVencimientoFormateada'];
        if (dateStr != null) {
          // Intentar diferentes formatos de fecha
          if (dateStr.contains('T')) {
            dueDate = DateTime.parse(dateStr);
          } else if (dateStr.contains('-')) {
            dueDate = DateTime.parse(dateStr);
          } else {
            // Formato DD/MM/YYYY
            final parts = dateStr.split('/');
            if (parts.length == 3) {
              dueDate = DateTime(
                int.parse(parts[2]), // año
                int.parse(parts[1]), // mes
                int.parse(parts[0])  // día
              );
            } else {
              throw const FormatException('Formato de fecha no reconocido');
            }
          }
        } else {
          dueDate = DateTime.now().add(const Duration(days: 30));
        }
      } catch (e) {
        print('⚠️ Error parseando fecha: ${json['fechaVencimiento'] ?? json['docDueDate']} - $e');
        dueDate = DateTime.now().add(const Duration(days: 30));
      }

      // Procesar monto
      double amount = 0.0;
      try {
        var valorField = json['valor'] ?? json['amount'];
        if (valorField != null) {
          if (valorField is num) {
            amount = valorField.toDouble();
          } else if (valorField is String) {
            // Limpiar string de formato de moneda
            String cleanValue = valorField
                .replaceAll(RegExp(r'[^\d.,]'), '') // Remover todo excepto dígitos, puntos y comas
                .replaceAll(',', '.'); // Reemplazar comas por puntos
            
            // Si hay múltiples puntos, mantener solo el último como decimal
            if (cleanValue.split('.').length > 2) {
              final parts = cleanValue.split('.');
              cleanValue = '${parts.sublist(0, parts.length - 1).join('')}.${parts.last}';
            }
            
            amount = double.tryParse(cleanValue) ?? 0.0;
          }
        }
      } catch (e) {
        print('⚠️ Error parseando monto: ${json['valor'] ?? json['amount']} - $e');
        amount = 0.0;
      }

      // Calcular días hasta vencimiento
      int daysUntilDue = 0;
      try {
        if (json['diasVencimiento'] != null) {
          daysUntilDue = (json['diasVencimiento'] as num).toInt();
        } else if (json['daysUntilDue'] != null) {
          daysUntilDue = (json['daysUntilDue'] as num).toInt();
        } else {
          // Calcular manualmente
          final today = DateTime.now();
          daysUntilDue = dueDate.difference(DateTime(today.year, today.month, today.day)).inDays;
        }
      } catch (e) {
        print('⚠️ Error calculando días: $e');
        final today = DateTime.now();
        daysUntilDue = dueDate.difference(DateTime(today.year, today.month, today.day)).inDays;
      }

      // URL del PDF
      String? pdfUrl = json['enlacePdf'] ?? json['pdfUrl'];
      if (pdfUrl != null && pdfUrl.isNotEmpty && pdfUrl != 'null') {
        // Asegurar que la URL sea válida
        if (!pdfUrl.startsWith('http')) {
          pdfUrl = null;
        }
      } else {
        pdfUrl = null;
      }

      // Crear datos de Wompi
      final reference = 'ORAL-$docNum-${DateTime.now().millisecondsSinceEpoch}';
      final wompiData = WompiData(
        reference: reference,
        amountInCents: (amount * 100).toInt(),
        currency: json['moneda'] ?? 'COP',
        customerName: cardFName,
      );

      final invoice = InvoiceModel(
        cardCode: cardCode,
        cardName: cardName,
        cardFName: cardFName,
        docNum: docNum,
        docDueDate: dueDate,
        amount: amount,
        formattedAmount: _formatCurrency(amount),
        pdfUrl: pdfUrl,
        daysUntilDue: daysUntilDue,
        formattedDueDate: _formatDate(dueDate),
        status: status,
        wompiData: wompiData,
      );

      print('✅ Factura procesada: ${invoice.docNum} - ${invoice.formattedAmount} - ${invoice.statusText}');
      return invoice;

    } catch (e) {
      print('❌ Error creando InvoiceModel desde JSON: $e');
      print('📄 JSON problemático: $json');
      rethrow;
    }
  }

  // 🚀 NUEVO CONSTRUCTOR PARA FACTURAS PAGADAS
  factory InvoiceModel.fromPaidInvoiceJson(Map<String, dynamic> json) {
    try {
      print('💰 Procesando factura PAGADA desde API: ${json['DocNum'] ?? 'SIN-NUMERO'}');
      
      final cardCode = (json['CardCode'] ?? 'SIN-CODIGO').toString();
      final cardName = (json['CardName'] ?? 'Cliente sin nombre').toString();
      final cardFName = (json['CardFName'] ?? cardName).toString();
      final docNum = (json['DocNum'] ?? 'SIN-NUMERO').toString();
      
      // Procesar fecha de vencimiento
      DateTime dueDate;
      try {
        String? dateStr = json['DocDueDate'];
        if (dateStr != null) {
          dueDate = DateTime.parse(dateStr);
        } else {
          dueDate = DateTime.now().subtract(const Duration(days: 30));
        }
      } catch (e) {
        print('⚠️ Error parseando fecha: ${json['DocDueDate']} - $e');
        dueDate = DateTime.now().subtract(const Duration(days: 30));
      }
      
      // Procesar monto
      double amount = 0.0;
      try {
        var valorField = json['DocTotal'];
        if (valorField != null) {
          amount = (valorField as num).toDouble();
        }
      } catch (e) {
        print('⚠️ Error parseando monto: ${json['DocTotal']} - $e');
        amount = 0.0;
      }
      
      final today = DateTime.now();
      final daysUntilDue = dueDate.difference(DateTime(today.year, today.month, today.day)).inDays;
      
      String? pdfUrl = json['PdfUrl'];
      if (pdfUrl != null && pdfUrl.isNotEmpty && pdfUrl != 'null') {
        if (!pdfUrl.startsWith('http')) {
          pdfUrl = null;
        }
      } else {
        pdfUrl = null;
      }
      
      final reference = 'PAID-$docNum-${DateTime.now().millisecondsSinceEpoch}';
      final wompiData = WompiData(
        reference: reference,
        amountInCents: (amount * 100).toInt(),
        currency: 'COP',
        customerName: cardFName,
      );
      
      final invoice = InvoiceModel(
        cardCode: cardCode,
        cardName: cardName,
        cardFName: cardFName,
        docNum: docNum,
        docDueDate: dueDate,
        amount: amount,
        formattedAmount: _formatCurrency(amount),
        pdfUrl: pdfUrl,
        daysUntilDue: daysUntilDue,
        formattedDueDate: _formatDate(dueDate),
        status: 'Pagada',
        wompiData: wompiData,
      );
      
      print('✅ Factura PAGADA procesada: ${invoice.docNum} - ${invoice.formattedAmount}');
      return invoice;
      
    } catch (e) {
      print('❌ Error creando InvoiceModel PAGADA desde JSON: $e');
      print('📄 JSON problemático: $json');
      rethrow;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatCurrency(double amount) {
    if (amount == 0) return '\$0';
    
    final formatted = amount.toStringAsFixed(0);
    return '\$${formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]},'
    )}';
  }

  Map<String, dynamic> toJson() {
    return {
      'cardCode': cardCode,
      'cardName': cardName,
      'cardFName': cardFName,
      'docNum': docNum,
      'docDueDate': docDueDate.toIso8601String(),
      'amount': amount,
      'formattedAmount': formattedAmount,
      'pdfUrl': pdfUrl,
      'daysUntilDue': daysUntilDue,
      'formattedDueDate': formattedDueDate,
      'status': status,
      'wompiData': wompiData.toJson(),
    };
  }

  // Getters para estados de la factura
  bool get isOverdue => daysUntilDue < 0;
  bool get isUrgent => daysUntilDue >= 0 && daysUntilDue <= 3;
  bool get isUpcoming => daysUntilDue > 3 && daysUntilDue <= 7;
  bool get isDueToday => daysUntilDue == 0;

  String get statusText {
    // Usar el status de la API si está disponible
    if (status.toLowerCase().contains('vencida') || status.toLowerCase().contains('overdue')) {
      return 'VENCIDA';
    }
    
    // Calcular basado en días
    if (isOverdue) return 'VENCIDA';
    if (isDueToday) return 'VENCE HOY';
    if (isUrgent) return 'URGENTE';
    if (isUpcoming) return 'PRÓXIMA';
    return 'VIGENTE';
  }

  Color get statusColor {
    if (isOverdue || status.toLowerCase().contains('vencida')) {
      return const Color(0xFFE74C3C); // Rojo
    }
    if (isDueToday) return const Color(0xFFE67E22); // Naranja oscuro
    if (isUrgent) return const Color(0xFFF39C12); // Naranja
    if (isUpcoming) return const Color(0xFF3498DB); // Azul
    return const Color(0xFF27AE60); // Verde
  }

  IconData get statusIcon {
    if (isOverdue || status.toLowerCase().contains('vencida')) {
      return Icons.warning_rounded;
    }
    if (isDueToday) return Icons.today_rounded;
    if (isUrgent) return Icons.access_time_rounded;
    if (isUpcoming) return Icons.schedule_rounded;
    return Icons.check_circle_rounded;
  }

  String get description => 'Pago factura $docNum - $cardName';

  int get priority {
    if (isOverdue || status.toLowerCase().contains('vencida')) return 1;
    if (isDueToday) return 2;
    if (isUrgent) return 3;
    if (isUpcoming) return 4;
    return 5;
  }

  // Método para obtener información de vencimiento
  String get dueInfo {
    if (isOverdue) {
      final daysPast = daysUntilDue.abs();
      return 'Vencida hace $daysPast día${daysPast == 1 ? '' : 's'}';
    }
    if (isDueToday) return 'Vence hoy';
    if (daysUntilDue == 1) return 'Vence mañana';
    return 'Vence en $daysUntilDue días';
  }

  // Método para verificar si tiene PDF disponible
  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;
}

class WompiData {
  final String reference;
  final int amountInCents;
  final String currency;
  final String customerName;

  WompiData({
    required this.reference,
    required this.amountInCents,
    required this.currency,
    required this.customerName,
  });

  factory WompiData.fromJson(Map<String, dynamic> json) {
    return WompiData(
      reference: json['reference'] ?? 'ORAL-PLUS-${DateTime.now().millisecondsSinceEpoch}',
      amountInCents: (json['amountInCents'] as num?)?.toInt() ?? 0,
      currency: json['currency'] ?? 'COP',
      customerName: json['customerName'] ?? 'Cliente ORAL-PLUS',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'amountInCents': amountInCents,
      'currency': currency,
      'customerName': customerName,
    };
  }

  // Getter para el monto en formato legible
  String get formattedAmount {
    final amount = amountInCents / 100;
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]},'
    )}';
  }
}
