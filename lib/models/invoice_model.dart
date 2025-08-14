// models/invoice_model.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

      // Mapear campos de la API
      final cardCode = (json['codigoCliente'] ?? json['cardCode'] ?? 'SIN-CODIGO').toString().trim();
      final cardName = (json['nombreCliente'] ?? json['cardName'] ?? 'Cliente sin nombre').toString().trim();
      final cardFName = (json['nombreFactura'] ?? json['cardFName'] ?? cardName).toString().trim();
      final docNum = (json['numeroFactura'] ?? json['docNum'] ?? 'SIN-NUMERO').toString().trim();
      final status = (json['estado'] ?? json['status'] ?? 'Pendiente').toString().trim();

      // 📅 Parsear fecha de vencimiento con soporte para "28 Aug 2025"
      DateTime dueDate = DateTime.now().add(const Duration(days: 30));
      try {
        String? dateStr = json['fechaVencimiento'] ?? json['docDueDate'];
        if (dateStr != null) {
          dueDate = _parseDate(dateStr) ?? dueDate;
        }
      } catch (e) {
        print('⚠️ Error parseando fecha: ${json['docDueDate']} - $e');
      }

      // 💰 Parsear monto
      double amount = 0.0;
      try {
        var valorField = json['valor'] ?? json['amount'];
        if (valorField != null) {
          if (valorField is num) {
            amount = valorField.toDouble();
          } else if (valorField is String) {
            String cleanValue = valorField
                .replaceAll(RegExp(r'[^\d.,]'), '')
                .replaceAll(',', '.');
            if (cleanValue.split('.').length > 2) {
              final parts = cleanValue.split('.');
              cleanValue = '${parts.sublist(0, parts.length - 1).join('')}.${parts.last}';
            }
            amount = double.tryParse(cleanValue) ?? 0.0;
          }
        }
      } catch (e) {
        print('⚠️ Error parseando monto: ${json['amount']} - $e');
      }

      // 📆 Calcular días hasta vencimiento
      int daysUntilDue;
      try {
        if (json['diasVencimiento'] != null) {
          daysUntilDue = (json['diasVencimiento'] as num).toInt();
        } else if (json['daysUntilDue'] != null) {
          daysUntilDue = (json['daysUntilDue'] as num).toInt();
        } else {
          final today = DateTime.now();
          daysUntilDue = dueDate.difference(DateTime(today.year, today.month, today.day)).inDays;
        }
      } catch (e) {
        print('⚠️ Error calculando días: $e');
        final today = DateTime.now();
        daysUntilDue = dueDate.difference(DateTime(today.year, today.month, today.day)).inDays;
      }

      // 📄 URL del PDF
      String? pdfUrl = json['enlacePdf'] ?? json['pdfUrl'];
      if (pdfUrl != null && (pdfUrl.isEmpty || pdfUrl == 'null' || !pdfUrl.startsWith('http'))) {
        pdfUrl = null;
      }

      // 💳 Crear datos de Wompi
      final reference = 'ORAL-$docNum-${DateTime.now().millisecondsSinceEpoch}';
      final wompiData = WompiData(
        reference: reference,
        amountInCents: (amount * 100).toInt(),
        currency: json['moneda'] ?? 'COP',
        customerName: cardFName,
      );

      // ✅ Crear instancia del modelo
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
        formattedDueDate: DateFormat('dd/MM/yyyy').format(dueDate), // ✅ Formato estándar
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

  /// Constructor para facturas ya pagadas (ej. historial)
  factory InvoiceModel.fromPaidInvoiceJson(Map<String, dynamic> json) {
    try {
      print('💰 Procesando factura PAGADA desde API: ${json['DocNum'] ?? 'SIN-NUMERO'}');

      final cardCode = (json['CardCode'] ?? 'SIN-CODIGO').toString().trim();
      final cardName = (json['CardName'] ?? 'Cliente sin nombre').toString().trim();
      final cardFName = (json['CardFName'] ?? cardName).toString().trim();
      final docNum = (json['DocNum'] ?? 'SIN-NUMERO').toString().trim();

      // 📅 Parsear fecha
      DateTime dueDate = DateTime.now().subtract(const Duration(days: 30));
      try {
        String? dateStr = json['DocDueDate'];
        if (dateStr != null) {
          dueDate = _parseDate(dateStr) ?? dueDate;
        }
      } catch (e) {
        print('⚠️ Error parseando fecha: ${json['DocDueDate']} - $e');
      }

      // 💰 Monto
      double amount = 0.0;
      try {
        amount = (json['DocTotal'] as num?)?.toDouble() ?? 0.0;
      } catch (e) {
        print('⚠️ Error parseando monto: ${json['DocTotal']} - $e');
      }

      final today = DateTime.now();
      final daysUntilDue = dueDate.difference(DateTime(today.year, today.month, today.day)).inDays;

      String? pdfUrl = json['PdfUrl'];
      if (pdfUrl != null && (pdfUrl.isEmpty || pdfUrl == 'null' || !pdfUrl.startsWith('http'))) {
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
        formattedDueDate: DateFormat('dd/MM/yyyy').format(dueDate),
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

  // ✅ NUEVA FUNCIÓN: Parsea fechas en múltiples formatos, incluyendo "28 Aug 2025"
  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    // Eliminar espacios extra
    dateStr = dateStr.trim();

    // Lista de formatos soportados
    final List<DateFormat> formatters = [
      DateFormat("d MMM yyyy", "en_US"),
      DateFormat("dd MMM yyyy", "en_US"),
      DateFormat("d MMMM yyyy", "en_US"),
      DateFormat("dd MMMM yyyy", "en_US"),
      DateFormat("d MMM yyyy", "es_ES"),
      DateFormat("dd MMM yyyy", "es_ES"),
      DateFormat("d MMMM yyyy", "es_ES"),
      DateFormat("dd MMMM yyyy", "es_ES"),
      DateFormat("yyyy-MM-dd"),
      DateFormat("dd/MM/yyyy"),
      DateFormat("MM/dd/yyyy"),
      DateFormat("d/M/yyyy"),
      DateFormat("yyyy/MM/dd"),
      DateFormat("d-M-yyyy"),
      DateFormat("dd-MM-yyyy"),
    ];

    for (final formatter in formatters) {
      try {
        return formatter.parse(dateStr);
      } catch (_) {
        continue;
      }
    }

    // Último intento: DateTime.parse (ISO)
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  // ✅ Formatear moneda
  static String _formatCurrency(double amount) {
    if (amount == 0) return '\$0';
    final formatted = amount.toStringAsFixed(0);
    return '\$${formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
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

  // 🟢 Estado de la factura
  bool get isOverdue => daysUntilDue < 0;
  bool get isDueToday => daysUntilDue == 0;
  bool get isUrgent => daysUntilDue > 0 && daysUntilDue <= 7;
  bool get isUpcoming => daysUntilDue > 7 && daysUntilDue <= 30;
  bool get isNormal => daysUntilDue > 30;

  String get statusText {
    if (status.toLowerCase().contains('vencida') || isOverdue) return 'VENCIDA';
    if (isDueToday) return 'VENCE HOY';
    if (isUrgent) return 'URGENTE';
    if (isUpcoming) return 'PRÓXIMA';
    return 'VIGENTE';
  }

  Color get statusColor {
    if (isOverdue) return const Color(0xFFE74C3C); // Rojo
    if (isDueToday) return const Color(0xFFE67E22); // Naranja
    if (isUrgent) return const Color(0xFFF39C12); // Amarillo
    if (isUpcoming) return const Color(0xFF3498DB); // Azul
    return const Color(0xFF27AE60); // Verde
  }

  IconData get statusIcon {
    if (isOverdue) return Icons.warning_rounded;
    if (isDueToday) return Icons.today_rounded;
    if (isUrgent) return Icons.access_time_rounded;
    if (isUpcoming) return Icons.schedule_rounded;
    return Icons.check_circle_rounded;
  }

  String get description => 'Pago factura $docNum - $cardName';

  int get priority {
    if (isOverdue) return 1;
    if (isDueToday) return 2;
    if (isUrgent) return 3;
    if (isUpcoming) return 4;
    return 5;
  }

  String get dueInfo {
    if (isOverdue) {
      final daysPast = daysUntilDue.abs();
      return 'Vencida hace $daysPast día${daysPast == 1 ? '' : 's'}';
    }
    if (isDueToday) return 'Vence hoy';
    if (daysUntilDue == 1) return 'Vence mañana';
    return 'Vence en $daysUntilDue días';
  }

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

  String get formattedAmount {
    final amount = amountInCents / 100;
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}