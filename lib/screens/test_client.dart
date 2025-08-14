import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/Datos_service.dart';
import 'dart:convert';

class TestClientScreen extends StatefulWidget {
  const TestClientScreen({super.key});

  @override
  _TestClientScreenState createState() => _TestClientScreenState();
}

class _TestClientScreenState extends State<TestClientScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _clientData;
  List<dynamic>? _invoices;
  Map<String, dynamic>? _paidInvoices;
  String? _error;
  final String _defaultTestCardCode = 'C39536225';

  final TextEditingController _cardCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardCodeController.text = _defaultTestCardCode;
  }

  @override
  void dispose() {
    _cardCodeController.dispose();
    super.dispose();
  }

  /// Función para probar cualquier CardCode
  Future<void> _testCardCode([String? customCardCode]) async {
    final cardCode = customCardCode ?? _cardCodeController.text.trim();
    
    if (cardCode.isEmpty) {
      _showSnackBar('Por favor ingresa un CardCode', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _clientData = null;
      _invoices = null;
      _paidInvoices = null;
      _error = null;
    });

    try {
      print('🧪 === INICIANDO TEST PARA $cardCode ===');

      // Test 1: Probar conexión
      print('🔌 Test 1: Probando conexión...');
      final connectionOk = await InvoiceService1.testConnection();
      print('🔌 Conexión: ${connectionOk ? "✅ OK" : "❌ FALLÓ"}');

      if (!connectionOk) {
        throw Exception('No se pudo establecer conexión con el servidor');
      }

      // Test 2: Obtener datos del cliente (EXACTO COMO PHP)
      print('👤 Test 2: Obteniendo datos del cliente (PHP replica)...');
      final clientData = await InvoiceService1.getClientDataWithFilters(cardCode);

      if (clientData != null) {
        print('✅ DATOS DEL CLIENTE OBTENIDOS (PHP REPLICA):');
        print('   👤 CardName: ${clientData['cardName']}');
        print('   📍 Address: ${clientData['address']}');
        print('   📞 Phone1: ${clientData['phone']}');
        print('   📧 E_Mail: ${clientData['email']}');
        print('   ⏱️ Tiempo consulta: ${clientData['queryTime']}ms');
        
        // Mostrar mensaje de éxito específico para el cliente
        _showSnackBar('✅ Cliente encontrado: ${clientData['cardName']}', isError: false);
      } else {
        print('❌ No se encontraron datos para la cédula proporcionada');
        print('💡 Cliente filtrado por criterios PHP o no existe');
        _showSnackBar('❌ No se encontró el cliente o no cumple los filtros', isError: true);
      }

      // Test 3: Obtener facturas pendientes
      print('📄 Test 3: Obteniendo facturas pendientes...');
      final invoices = await InvoiceService1.getInvoicesByCardCode(cardCode);
      print('📄 Facturas encontradas: ${invoices.length}');

      // Test 4: Obtener facturas pagadas
      print('💰 Test 4: Obteniendo facturas pagadas...');
      final paidInvoices = await InvoiceService1.getPaidInvoicesByCardCode(cardCode);
      print('💰 Facturas pagadas: ${paidInvoices['count']}');

      setState(() {
        _clientData = clientData;
        _invoices = invoices;
        _paidInvoices = paidInvoices;
        _isLoading = false;
      });

      _showSnackBar('✅ Test completado exitosamente', isError: false);
      print('🎉 === TEST COMPLETADO EXITOSAMENTE ===');

    } catch (e) {
      print('❌ === ERROR EN TEST ===');
      print('Error: $e');

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      _showSnackBar('❌ Error: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('📋 Copiado al portapapeles', isError: false);
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pagada':
        return Colors.green;
      case 'vencida':
        return Colors.red;
      case 'urgente':
        return Colors.orange;
      case 'próxima':
      case 'proxima':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pagada':
        return Icons.check_circle;
      case 'vencida':
        return Icons.warning;
      case 'urgente':
        return Icons.schedule;
      case 'próxima':
      case 'proxima':
        return Icons.schedule;
      default:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Cliente ORAL-PLUS (PHP Replica)'),
        backgroundColor: Colors.blue,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _testCardCode(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input para CardCode personalizado
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'Consultar Cliente (Replica PHP)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Consulta exacta: CardName, Address, Phone1, E_Mail\nFiltros PHP aplicados automáticamente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _cardCodeController,
                      decoration: InputDecoration(
                        labelText: 'CardCode (Cédula)',
                        hintText: 'Ej: C39536225',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_search),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => _cardCodeController.clear(),
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _testCardCode(),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testCardCode,
                            icon: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(Icons.search),
                            label: Text(_isLoading ? 'Consultando...' : 'Consultar Cliente'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _testCardCode('C39536225'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text('Test\nC39536225'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Resultados
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error
                    if (_error != null) ...[
                      Card(
                        color: Colors.red[50],
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Error en la Consulta',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SelectableText(
                                  _error!,
                                  style: TextStyle(
                                    color: Colors.red[800],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Datos del cliente (EXACTO COMO PHP)
                    if (_clientData != null) ...[
                      Card(
                        color: Colors.green[50],
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.green[300]!, width: 2),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Encabezado con animación
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cliente Encontrado',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                          Text(
                                            'Datos obtenidos exitosamente de SAP',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.copy, size: 24, color: Colors.green[700]),
                                      onPressed: () => _copyToClipboard(
                                        'CardCode: ${_clientData!['cardCode']}\n'
                                        'CardName: ${_clientData!['cardName']}\n'
                                        'Address: ${_clientData!['address']}\n'
                                        'Phone1: ${_clientData!['phone']}\n'
                                        'E_Mail: ${_clientData!['email']}'
                                      ),
                                      tooltip: 'Copiar datos',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // Información principal del cliente - Destacada
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Nombre del cliente destacado
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green[200]!),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nombre del Cliente:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          SelectableText(
                                            _clientData!['cardName'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    
                                    // Datos de contacto
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Columna izquierda
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildClientInfoField(
                                                'CardCode',
                                                _clientData!['cardCode'] ?? 'N/A',
                                                Icons.badge,
                                              ),
                                              SizedBox(height: 12),
                                              _buildClientInfoField(
                                                'Dirección',
                                                _clientData!['address'] ?? 'N/A',
                                                Icons.location_on,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        // Columna derecha
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildClientInfoField(
                                                'Teléfono',
                                                _clientData!['phone'] ?? 'N/A',
                                                Icons.phone,
                                              ),
                                              SizedBox(height: 12),
                                              _buildClientInfoField(
                                                'Email',
                                                _clientData!['email'] ?? 'N/A',
                                                Icons.email,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 16),
                              Divider(color: Colors.green[300]),
                              SizedBox(height: 8),
                              
                              // Información técnica
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildTechInfo('⏱️ Tiempo', '${_clientData!['queryTime']}ms'),
                                  _buildTechInfo('🔗 Fuente', _clientData!['source'] ?? 'SAP'),
                                  _buildTechInfo('✅ Estado', 'Encontrado'),
                                ],
                              ),
                              
                              // Mostrar datos raw si están disponibles
                              if (_clientData!.containsKey('rawData')) ...[
                                SizedBox(height: 12),
                                ExpansionTile(
                                  title: Row(
                                    children: [
                                      Icon(Icons.code, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Datos Raw (como PHP)',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: SelectableText(
                                        JsonEncoder.withIndent('  ').convert(_clientData!['rawData']),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Facturas pendientes
                    if (_invoices != null) ...[
                      Card(
                        color: Colors.orange[50],
                        elevation: 3,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.receipt_long, color: Colors.orange, size: 24),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Facturas Pendientes (${_invoices!.length})',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ),
                                  if (_invoices!.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_invoices!.length}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 12),
                              
                              if (_invoices!.isEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.celebration, color: Colors.green[700]),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '¡Excelente! No hay facturas pendientes\nCliente a paz y salvo',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                // Mostrar resumen de facturas
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange[200]!),
                                  ),
                                  child: Column(
                                    children: [
                                      // Calcular totales
                                      Builder(
                                        builder: (context) {
                                          double totalAmount = 0;
                                          int vencidas = 0;
                                          int urgentes = 0;
                                          int proximas = 0;
                                          
                                          for (var invoice in _invoices!) {
                                            if (invoice.amount != null) {
                                              totalAmount += invoice.amount;
                                            }
                                            
                                            String status = invoice.status?.toLowerCase() ?? '';
                                            if (status.contains('vencida')) {
                                              vencidas++;
                                            } else if (status.contains('urgente')) urgentes++;
                                            else if (status.contains('próxima') || status.contains('proxima')) proximas++;
                                          }
                                          
                                          return Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: [
                                                  _buildStatCard('💰 Total', _formatCurrency(totalAmount), Colors.orange),
                                                  _buildStatCard('⚠️ Vencidas', '$vencidas', Colors.red),
                                                  _buildStatCard('🔥 Urgentes', '$urgentes', Colors.deepOrange),
                                                  _buildStatCard('📅 Próximas', '$proximas', Colors.amber),
                                                ],
                                              ),
                                              SizedBox(height: 12),
                                              Divider(),
                                            ],
                                          );
                                        },
                                      ),
                                      
                                      // Lista de facturas (primeras 10)
                                      ...(_invoices!.take(10).map((invoice) => Container(
                                        margin: EdgeInsets.symmetric(vertical: 2),
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border(
                                            left: BorderSide(
                                              color: _getStatusColor(invoice.status ?? ''),
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getStatusIcon(invoice.status ?? ''),
                                              color: _getStatusColor(invoice.status ?? ''),
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Factura ${invoice.docNum}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  if (invoice.formattedDueDate != null)
                                                    Text(
                                                      'Vence: ${invoice.formattedDueDate}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  invoice.formattedAmount ?? '\$0',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: _getStatusColor(invoice.status ?? ''),
                                                  ),
                                                ),
                                                if (invoice.status != null)
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(invoice.status!).withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      invoice.status!,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w500,
                                                        color: _getStatusColor(invoice.status!),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ))),
                                      
                                      if (_invoices!.length > 10) ...[
                                        SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '... y ${_invoices!.length - 10} facturas más',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.orange[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Facturas pagadas
                    if (_paidInvoices != null) ...[
                      Card(
                        color: Colors.purple[50],
                        elevation: 3,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.paid, color: Colors.purple, size: 24),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Facturas Pagadas (${_paidInvoices!['count'] ?? 0})',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple[700],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_paidInvoices!['count'] ?? 0}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple[200]!),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Total facturas pagadas: ${_paidInvoices!['count'] ?? 0}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    if (_paidInvoices!.containsKey('statistics')) ...[
                                      SizedBox(height: 8),
                                      Divider(),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildStatCard(
                                            '💰 Total Pagado',
                                            _formatCurrency(_paidInvoices!['statistics']['totalPaidAmount'] ?? 0.0),
                                            Colors.green,
                                          ),
                                          _buildStatCard(
                                            '📅 Este Mes',
                                            '${_paidInvoices!['statistics']['thisMonthPaid'] ?? 0}',
                                            Colors.blue,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Información sobre filtros PHP
                    Card(
                      color: Colors.grey[50],
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.filter_list, color: Colors.grey[700]),
                                SizedBox(width: 8),
                                Text(
                                  'Filtros PHP Aplicados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🚫 Grupos Excluidos:',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 4),
                                  Text('• GroupName ≠ "Droguerias Cadenas"'),
                                  Text('• GroupName ≠ "Canal Grandes Superf"'),
                                  SizedBox(height: 8),
                                  Text(
                                    '🚫 Canales Excluidos:',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 4),
                                  Text('• Distribution ≠ "HARD DISCOUNT NACIONALES"'),
                                  Text('• Distribution ≠ "HARD DISCOUNT INDEPENDIENTES"'),
                                  SizedBox(height: 8),
                                  Divider(),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.verified, color: Colors.green, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Campos consultados: CardName, Address, Phone1, E_Mail',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.code, color: Colors.blue, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Consulta exacta como tu código PHP',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value ?? 'N/A',
              style: TextStyle(
                color: value != null && value.isNotEmpty ? Colors.black87 : Colors.grey,
                fontWeight: value != null && value.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoField(String label, String value, IconData icon) {
    final bool isEmpty = value == 'N/A' || value.isEmpty;
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isEmpty ? Colors.grey[100] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEmpty ? Colors.grey[300]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isEmpty ? Colors.grey[500] : Colors.green[700],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isEmpty ? Colors.grey[600] : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isEmpty ? FontWeight.normal : FontWeight.w500,
                    color: isEmpty ? Colors.grey[500] : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
