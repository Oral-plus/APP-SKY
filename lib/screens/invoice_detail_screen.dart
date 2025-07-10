import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/invoice_model.dart';
import '../services/simple_wompi_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isPaymentLoading = false;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );
    
    final daysLeft = widget.invoice.daysUntilDue;
    final isOverdue = widget.invoice.isOverdue;
    final isUrgent = widget.invoice.isUrgent;
    final isDueToday = widget.invoice.isDueToday;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        title: const Text(
          'Detalle de Factura',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4ECDC4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _shareInvoice(),
            icon: const Icon(Icons.share),
            tooltip: 'Compartir factura',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado principal de la factura
              _buildInvoiceHeader(formatter, isOverdue, isUrgent, isDueToday),
              
              const SizedBox(height: 24),
              
              // Estado de la factura
              _buildStatusCard(daysLeft, isOverdue, isUrgent, isDueToday),
              
              const SizedBox(height: 20),
              
              // Información del cliente
              _buildClientInfo(),
              
              const SizedBox(height: 20),
              
              // Detalles de la factura
              _buildInvoiceDetails(formatter),
              
              const SizedBox(height: 20),
              
              // Información de pago
              _buildPaymentInfo(),
              
              const SizedBox(height: 30),
              
              // Botones de acción
              _buildActionButtons(isOverdue, isUrgent),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader(NumberFormat formatter, bool isOverdue, bool isUrgent, bool isDueToday) {
    Color statusColor = const Color(0xFF4ECDC4);
    if (isOverdue) {
      statusColor = const Color(0xFFE74C3C);
    } else if (isDueToday) statusColor = const Color(0xFFE67E22);
    else if (isUrgent) statusColor = const Color(0xFFF39C12);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor,
            statusColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FACTURA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  '#${widget.invoice.docNum}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Text(
            widget.invoice.cardFName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Cliente: ${widget.invoice.cardName}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vencimiento',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.invoice.formattedDueDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.invoice.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total a Pagar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.invoice.formattedAmount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(int daysLeft, bool isOverdue, bool isUrgent, bool isDueToday) {
    IconData statusIcon;
    Color statusColor;
    String statusTitle;
    String statusDescription;

    if (isOverdue) {
      statusIcon = Icons.error_outline_rounded;
      statusColor = const Color(0xFFE74C3C);
      statusTitle = 'Factura Vencida';
      statusDescription = 'Esta factura está vencida desde hace ${daysLeft.abs()} días. Paga ahora para evitar recargos adicionales.';
    } else if (isDueToday) {
      statusIcon = Icons.warning_rounded;
      statusColor = const Color(0xFFE67E22);
      statusTitle = '¡Vence Hoy!';
      statusDescription = 'Esta factura vence hoy. Realiza el pago antes de las 11:59 PM para evitar recargos.';
    } else if (isUrgent) {
      statusIcon = Icons.access_time_rounded;
      statusColor = const Color(0xFFF39C12);
      statusTitle = 'Pago Próximo';
      statusDescription = 'Esta factura vence en $daysLeft días. Te recomendamos pagar pronto.';
    } else {
      statusIcon = Icons.check_circle_outline_rounded;
      statusColor = const Color(0xFF4ECDC4);
      statusTitle = 'Al Día';
      statusDescription = 'Tienes $daysLeft días para realizar el pago.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Información del Cliente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A4D68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Código de Cliente:', widget.invoice.cardCode),
          _buildInfoRow('Nombre Completo:', widget.invoice.cardFName),
          _buildInfoRow('Razón Social:', widget.invoice.cardName),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetails(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Detalles de la Factura',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A4D68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Número de Factura:', '#${widget.invoice.docNum}'),
          _buildInfoRow('Fecha de Vencimiento:', widget.invoice.formattedDueDate),
          _buildInfoRow('Días hasta vencimiento:', '${widget.invoice.daysUntilDue} días'),
          _buildInfoRow('Monto Total:', widget.invoice.formattedAmount),
          _buildInfoRow('Estado:', widget.invoice.statusText),
          
          if (widget.invoice.pdfUrl != null && widget.invoice.pdfUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openPDF(),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Ver Factura en PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4ECDC4),
                  side: const BorderSide(color: Color(0xFF4ECDC4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4ECDC4).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.payment_rounded,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Información de Pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A4D68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Referencia Wompi:', widget.invoice.wompiData.reference),
          _buildInfoRow('Moneda:', widget.invoice.wompiData.currency),
          _buildInfoRow('Cliente:', widget.invoice.wompiData.customerName),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: Color(0xFF4ECDC4),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pago 100% seguro con Wompi. Tus datos están protegidos.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4ECDC4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isOverdue, bool isUrgent) {
    return Column(
      children: [
        // Botón principal de pago
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isPaymentLoading ? null : () => _payWithWompi(),
            icon: _isPaymentLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.payment_rounded, size: 24),
            label: Text(
              _isPaymentLoading
                  ? 'Procesando...'
                  : isOverdue
                      ? 'Pagar Factura Vencida'
                      : isUrgent
                          ? 'Pagar Ahora'
                          : 'Realizar Pago',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isOverdue
                  ? const Color(0xFFE74C3C)
                  : const Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: (isOverdue
                      ? const Color(0xFFE74C3C)
                      : const Color(0xFF4ECDC4))
                  .withOpacity(0.3),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botones secundarios
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _contactSupport(),
                icon: const Icon(Icons.support_agent_rounded, size: 20),
                label: const Text('Soporte'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4ECDC4),
                  side: const BorderSide(color: Color(0xFF4ECDC4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareInvoice(),
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text('Compartir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[400]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A4D68),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _payWithWompi() async {
    try {
      setState(() {
        _isPaymentLoading = true;
      });

      final success = await SimpleWompiService.openPaymentInBrowser(
        reference: widget.invoice.wompiData.reference,
        amountInCents: widget.invoice.wompiData.amountInCents,
        currency: widget.invoice.wompiData.currency,
        customerName: widget.invoice.wompiData.customerName,
        customerEmail: 'cliente@oral-plus.com',
        customerPhone: '3001234567',
        description: widget.invoice.description,
      );

      if (mounted) {
        if (success) {
          _showMessage('Pago abierto en Wompi exitosamente', isError: false);
          // Retornar true para indicar éxito
          Navigator.of(context).pop(true);
        } else {
          _showMessage('No se pudo abrir Wompi', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPaymentLoading = false;
        });
      }
    }
  }

  Future<void> _openPDF() async {
    if (widget.invoice.pdfUrl == null || widget.invoice.pdfUrl!.isEmpty) {
      _showMessage('PDF no disponible', isError: true);
      return;
    }

    try {
      final Uri url = Uri.parse(widget.invoice.pdfUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('No se pudo abrir el PDF', isError: true);
      }
    } catch (e) {
      _showMessage('Error abriendo PDF: $e', isError: true);
    }
  }

  Future<void> _contactSupport() async {
    try {
      final Uri whatsappUrl = Uri.parse(
        'https://wa.me/573218290212?text=Hola, necesito ayuda con la factura ${widget.invoice.docNum} por valor de ${widget.invoice.formattedAmount}',
      );
      
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('No se pudo abrir WhatsApp', isError: true);
      }
    } catch (e) {
      _showMessage('Error contactando soporte: $e', isError: true);
    }
  }

  void _shareInvoice() {
    final text = '''
🦷 ORAL-PLUS - Factura #${widget.invoice.docNum}

👤 Cliente: ${widget.invoice.cardFName}
💰 Monto: ${widget.invoice.formattedAmount}
📅 Vence: ${widget.invoice.formattedDueDate}
📊 Estado: ${widget.invoice.statusText}

${widget.invoice.pdfUrl != null ? '📄 Ver PDF: ${widget.invoice.pdfUrl}' : ''}

¡Paga fácil y seguro con Wompi! 💳
    ''';

    // Aquí puedes implementar el share nativo o copiar al clipboard
    _showMessage('Información copiada para compartir', isError: false);
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
