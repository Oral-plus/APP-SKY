import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/simple_wompi_service.dart';
import '../services/invoice_service.dart';
import '../services/api_service.dart';
import '../models/invoice_model.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';

class SimpleWompiScreen extends StatefulWidget {
  final InvoiceModel? invoice;
  
  const SimpleWompiScreen({super.key, this.invoice});

  @override
  State<SimpleWompiScreen> createState() => _SimpleWompiScreenState();
}

class _SimpleWompiScreenState extends State<SimpleWompiScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _searchController = TextEditingController();
  final _partialAmountController = TextEditingController();
  
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _floatingController;
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _cardAnimation;
  
  bool _isLoading = false;
  bool _isLoadingInvoices = false;
  bool _isLoadingUserData = true;
  bool _isPartialPayment = false;
  bool _isOpeningPdf = false;
  List<InvoiceModel> _allInvoices = [];
  List<InvoiceModel> _filteredInvoices = [];
  InvoiceModel? _selectedInvoice;
  String _searchQuery = '';
  String? _connectionError;
  Map<String, dynamic>? _statistics;
  UserModel? _currentUser;
  String? _userCardCode;
  double _discountPercentage = 0.0;
  double _finalAmount = 0.0;
  
  // Filtros
  String _selectedFilter = 'TODAS';
  final List<String> _filterOptions = ['TODAS', 'VENCIDAS', 'URGENTES', 'PRÓXIMAS', 'VIGENTES'];
  
  // Blue & White Color Scheme
  static const Color primaryBlue = Color(0xFF1e3a8a);
  static const Color secondaryBlue = Color(0xFF3b82f6);
  static const Color lightBlue = Color(0xFF60a5fa);
  static const Color accentBlue = Color(0xFF2563eb);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1e293b);
  static const Color textSecondary = Color(0xFF64748b);
  
  // Función para asegurar que la opacidad esté en rango válido
  double _clampOpacity(double value) {
    return value.clamp(0.0, 1.0);
  }

  // Función para calcular días hasta vencimiento correctamente
  int _calculateDaysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  // Función para formatear números de forma segura
  String _formatCurrency(double amount) {
    try {
      return '\$${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } catch (e) {
      return '\$${amount.toInt()}';
    }
  }

  // Función para parsear números de forma segura
  double _parseAmount(String text) {
    try {
      // Remover caracteres no numéricos excepto punto y coma
      String cleanText = text.replaceAll(RegExp(r'[^\d.,]'), '');
      // Reemplazar comas por puntos para decimales
      cleanText = cleanText.replaceAll(',', '.');
      // Si hay múltiples puntos, mantener solo el último
      if (cleanText.contains('.')) {
        List<String> parts = cleanText.split('.');
        if (parts.length > 2) {
          cleanText = '${parts.sublist(0, parts.length - 1).join('')}.${parts.last}';
        }
      }
      return double.tryParse(cleanText) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupAnimations();
    
    _loadUserData();
    
    if (widget.invoice != null) {
      _setupInvoicePayment(widget.invoice!);
      _selectedInvoice = widget.invoice;
      _tabController.index = 0;
    }
    
    _startAnimations();
  }

  /// Carga los datos del usuario logueado y forma el CardCode
  /// CRÍTICO: Este CardCode debe coincidir exactamente con la BD
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoadingUserData = true;
      });
      print('🔄 Cargando datos del usuario logueado...');
      
      final user = await ApiService.getUserProfile();
      
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
          _isLoadingUserData = false;
          // CRÍTICO: Formar CardCode exactamente como en la BD
          // Ejemplo: tipo_documento="C" + documento="39536225" = "C39536225"
          _userCardCode = '${user.tipoDocumento}${user.documento}';
        });
        
        _setupUserData(user);
        
        print('✅ Datos del usuario cargados: ${user.nombreCompleto}');
        print('📋 CardCode SAP generado: $_userCardCode');
        print('📄 Tipo documento: ${user.tipoDocumento}');
        print('🆔 Documento: ${user.documento}');
        
        // IMPORTANTE: Solo cargar facturas después de tener el CardCode
        await _loadUserInvoices();
      } else {
        throw Exception('No se pudieron obtener los datos del usuario');
      }
    } catch (e) {
      print('❌ Error cargando datos del usuario: $e');
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
        
        _setupDefaultData();
        _showMessage('No se pudieron cargar los datos del usuario. Usando valores por defecto.', isError: true);
      }
    }
  }

  /// Configura los datos del usuario en los campos del formulario
  void _setupUserData(UserModel user) {
    _customerNameController.text = user.nombreCompleto;
    
    if (user.email.isNotEmpty) {
      _customerEmailController.text = user.email;
    } else {
      _customerEmailController.text = '${user.documento}@oral-plus.com';
    }
    
    _customerPhoneController.text = user.telefono;
    _descriptionController.text = 'Pago ORAL-PLUS - ${user.nombreCompleto}';
    _amountController.text = '50000';
    
    print('📝 Datos configurados para: ${user.nombreCompleto}');
    print('📧 Email: ${user.email}');
    print('📱 Teléfono: ${user.telefono}');
  }

  /// Configura datos por defecto si no se pueden cargar los del usuario
  void _setupDefaultData() {
    _customerNameController.text = 'Cliente ORAL-PLUS';
    _customerEmailController.text = 'cliente@oral-plus.com';
    _customerPhoneController.text = '3001234567';
    _descriptionController.text = 'Pago ORAL-PLUS';
    _amountController.text = '50000';
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() {
    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
    _floatingController.repeat(reverse: true);
    _backgroundController.repeat();
  }
  
  void _setupInvoicePayment(InvoiceModel invoice) {
    _amountController.text = invoice.amount.toStringAsFixed(0);
    _partialAmountController.text = (invoice.amount / 2).toStringAsFixed(0);
    _descriptionController.text = 'Pago factura ${invoice.docNum} - ${invoice.cardName}';
    _calculateDiscount(invoice.amount);
    
    if (_currentUser != null) {
      _customerNameController.text = _currentUser!.nombreCompleto;
    } else {
      _customerNameController.text = invoice.cardFName;
    }
  }

  /// Calcula el descuento basado en los días hasta el vencimiento
  /// IMPORTANTE: Los abonos parciales NO tienen descuento
  void _calculateDiscount(double amount) {
    if (_selectedInvoice == null) return;
    
    // Si es pago parcial, NO aplicar descuento
    if (_isPartialPayment) {
      setState(() {
        _discountPercentage = 0.0;
        _finalAmount = amount;
      });
      return;
    }
    
    final daysUntilDue = _calculateDaysUntilDue(_selectedInvoice!.docDueDate);
    double discount = 0.0;
    
    // Aplicar descuentos SOLO para pagos completos según los días
    if (daysUntilDue >= 1 && daysUntilDue <= 15) {
      discount = 2.5; // 2.5% por pago entre 1 y 15 días antes
    } else if (daysUntilDue >= 16 && daysUntilDue <= 30) {
      discount = 1.5; // 1.5% por pago entre 16 y 30 días antes
    }
    // Después de 30 días, no hay descuento
    
    setState(() {
      _discountPercentage = discount;
      _finalAmount = amount - (amount * discount / 100);
    });
  }

  /// Actualiza el monto final cuando cambia el monto parcial
  void _updatePartialAmount(String value) {
    try {
      final amount = _parseAmount(value);
      if (_selectedInvoice != null) {
        final maxAmount = _selectedInvoice!.amount;
        if (amount > maxAmount) {
          _partialAmountController.text = maxAmount.toStringAsFixed(0);
          _calculateDiscount(maxAmount);
        } else {
          _calculateDiscount(amount);
        }
      }
    } catch (e) {
      print('Error actualizando monto parcial: $e');
    }
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _searchController.dispose();
    _partialAmountController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _floatingController.dispose();
    _backgroundController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  /// MÉTODO CRÍTICO: Carga SOLO las facturas del usuario específico
  /// Equivalente a: SELECT * FROM CONSULTA_CARTERA WHERE CardCode = ?
  Future<void> _loadUserInvoices() async {
    // Validación estricta del CardCode
    if (_userCardCode == null || _userCardCode!.isEmpty) {
      print('❌ CRÍTICO: CardCode del usuario no disponible');
      _showMessage('Error: No se pudo identificar el usuario', isError: true);
      return;
    }

    try {
      setState(() {
        _isLoadingInvoices = true;
        _connectionError = null;
      });
      
      print('🔄 CONSULTANDO FACTURAS PARA CardCode: $_userCardCode');
      print('🔍 Equivalente SQL: SELECT * FROM CONSULTA_CARTERA WHERE CardCode = "$_userCardCode"');
      
      // Verificar conexión con la API
      final isConnected = await InvoiceService.testConnection();
      if (!isConnected) {
        throw Exception('No se pudo conectar con la API ORAL-PLUS en puerto 3005');
      }
      
      // CONSULTA ESPECÍFICA: Solo facturas de este CardCode
      final response = await InvoiceService.getInvoicesByCardCode(_userCardCode!);
      
      // Validación adicional: Filtrar en el cliente por seguridad
      final filteredResponse = response.where((invoice) {
        final matches = invoice.cardCode.trim().toUpperCase() == _userCardCode!.trim().toUpperCase();
        if (!matches) {
          print('⚠️ ADVERTENCIA: Factura ${invoice.docNum} no coincide con CardCode $_userCardCode (tiene: ${invoice.cardCode})');
        }
        return matches;
      }).toList();
      
      print('📄 Facturas encontradas para $_userCardCode: ${filteredResponse.length}');
      print('📋 Facturas filtradas correctamente: ${filteredResponse.map((f) => f.docNum).join(', ')}');
      
      if (mounted) {
        setState(() {
          _allInvoices = filteredResponse;
          _filteredInvoices = filteredResponse;
          _isLoadingInvoices = false;
          _calculateStatistics();
        });
        
        _cardController.forward();
        
        if (filteredResponse.isNotEmpty) {
          _showMessage('${filteredResponse.length} facturas cargadas para su cuenta $_userCardCode', isError: false);
        } else {
          // Equivalente al mensaje "Te encuentras a paz y salvo" del PHP
          _showMessage('¡Felicitaciones! Te encuentras a paz y salvo', isError: false);
        }
      }
    } catch (e) {
      print('❌ Error cargando facturas del usuario: $e');
      if (mounted) {
        setState(() {
          _isLoadingInvoices = false;
          _connectionError = e.toString();
          // Solo mostrar datos mock si hay error de conexión
          _allInvoices = _getMockInvoicesForUser();
          _filteredInvoices = _allInvoices;
          _calculateStatistics();
        });
        _cardController.forward();
        _showMessage('Error de conexión. Mostrando datos de ejemplo para $_userCardCode.', isError: true);
      }
    }
  }

  /// Recarga las facturas del usuario actual
  Future<void> _reloadUserInvoices() async {
    if (_userCardCode != null && _userCardCode!.isNotEmpty) {
      await _loadUserInvoices();
    } else {
      _showMessage('No se puede recargar: usuario no identificado', isError: true);
    }
  }

  /// Genera facturas de ejemplo SOLO para el usuario actual
  /// IMPORTANTE: Todas las facturas mock deben tener el mismo CardCode
  List<InvoiceModel> _getMockInvoicesForUser() {
    if (_currentUser == null || _userCardCode == null) return [];
    
    final now = DateTime.now();
    
    return [
      InvoiceModel(
        cardCode: _userCardCode!, // CRÍTICO: Usar el CardCode exacto del usuario
        cardName: _currentUser!.nombreCompleto,
        cardFName: _currentUser!.nombreCompleto,
        docNum: 'FAC-2024-001',
        docDueDate: now.add(const Duration(days: 5)),
        amount: 125000,
        formattedAmount: _formatCurrency(125000),
        pdfUrl: 'https://example.com/invoice-001.pdf',
        daysUntilDue: 5,
        formattedDueDate: '${(now.add(const Duration(days: 5)).day).toString().padLeft(2, '0')}/${(now.add(const Duration(days: 5)).month).toString().padLeft(2, '0')}/${now.add(const Duration(days: 5)).year}',
        status: 'Pendiente',
        wompiData: WompiData(
          reference: 'ORAL-FAC-2024-001-${DateTime.now().millisecondsSinceEpoch}',
          amountInCents: 12500000,
          currency: 'COP',
          customerName: _currentUser!.nombreCompleto,
        ),
      ),
      InvoiceModel(
        cardCode: _userCardCode!, // CRÍTICO: Usar el CardCode exacto del usuario
        cardName: _currentUser!.nombreCompleto,
        cardFName: _currentUser!.nombreCompleto,
        docNum: 'FAC-2024-002',
        docDueDate: now.add(const Duration(days: 2)),
        amount: 89500,
        formattedAmount: _formatCurrency(89500),
        pdfUrl: 'https://example.com/invoice-002.pdf',
        daysUntilDue: 2,
        formattedDueDate: '${(now.add(const Duration(days: 2)).day).toString().padLeft(2, '0')}/${(now.add(const Duration(days: 2)).month).toString().padLeft(2, '0')}/${now.add(const Duration(days: 2)).year}',
        status: 'Urgente',
        wompiData: WompiData(
          reference: 'ORAL-FAC-2024-002-${DateTime.now().millisecondsSinceEpoch}',
          amountInCents: 8950000,
          currency: 'COP',
          customerName: _currentUser!.nombreCompleto,
        ),
      ),
    ];
  }

  void _calculateStatistics() {
    if (_allInvoices.isEmpty) return;
    
    final overdue = _allInvoices.where((i) => _calculateDaysUntilDue(i.docDueDate) < 0).length;
    final urgent = _allInvoices.where((i) {
      final days = _calculateDaysUntilDue(i.docDueDate);
      return days >= 0 && days <= 7;
    }).length;
    final upcoming = _allInvoices.where((i) {
      final days = _calculateDaysUntilDue(i.docDueDate);
      return days > 7 && days <= 30;
    }).length;
    final normal = _allInvoices.length - overdue - urgent - upcoming;
    final totalAmount = _allInvoices.fold(0.0, (sum, invoice) => sum + invoice.amount);
    final overdueAmount = _allInvoices.where((i) => _calculateDaysUntilDue(i.docDueDate) < 0).fold(0.0, (sum, invoice) => sum + invoice.amount);
    
    setState(() {
      _statistics = {
        'total': _allInvoices.length,
        'overdue': overdue,
        'urgent': urgent,
        'upcoming': upcoming,
        'normal': normal,
        'totalAmount': totalAmount,
        'overdueAmount': overdueAmount,
      };
    });
  }

  void _filterInvoices() {
    List<InvoiceModel> filtered = List.from(_allInvoices);
    // IMPORTANTE: Todas las facturas ya están filtradas por CardCode
    // Este filtro adicional es solo por estado y búsqueda
    
    // Aplicar filtro por estado
    if (_selectedFilter != 'TODAS') {
      switch (_selectedFilter) {
        case 'VENCIDAS':
          filtered = filtered.where((i) => _calculateDaysUntilDue(i.docDueDate) < 0).toList();
          break;
        case 'URGENTES':
          filtered = filtered.where((i) {
            final days = _calculateDaysUntilDue(i.docDueDate);
            return days >= 0 && days <= 7;
          }).toList();
          break;
        case 'PRÓXIMAS':
          filtered = filtered.where((i) {
            final days = _calculateDaysUntilDue(i.docDueDate);
            return days > 7 && days <= 30;
          }).toList();
          break;
        case 'VIGENTES':
          filtered = filtered.where((i) {
            final days = _calculateDaysUntilDue(i.docDueDate);
            return days > 30;
          }).toList();
          break;
      }
    }

    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((invoice) {
        final query = _searchQuery.toLowerCase();
        return invoice.cardCode.toLowerCase().contains(query) ||
               invoice.cardName.toLowerCase().contains(query) ||
               invoice.cardFName.toLowerCase().contains(query) ||
               invoice.docNum.toLowerCase().contains(query);
      }).toList();
    }

    // Ordenar por días hasta vencimiento (más urgentes primero)
    filtered.sort((a, b) {
      final daysA = _calculateDaysUntilDue(a.docDueDate);
      final daysB = _calculateDaysUntilDue(b.docDueDate);
      return daysA.compareTo(daysB);
    });

    setState(() {
      _filteredInvoices = filtered;
    });
  }

  /// Abre el PDF directamente en el navegador usando la URL
  /// Igual que en el código PHP: target="_blank"
  Future<void> _openPDFInBrowser(InvoiceModel invoice) async {
    if (invoice.pdfUrl == null || invoice.pdfUrl!.isEmpty) {
      _showMessage('PDF no disponible para esta factura', isError: true);
      return;
    }

    setState(() {
      _isOpeningPdf = true;
    });

    try {
      // Verificar si la URL es válida
      final uri = Uri.tryParse(invoice.pdfUrl!);
      if (uri == null) {
        throw Exception('URL del PDF no válida');
      }

      print('🔗 Abriendo PDF en navegador: ${invoice.pdfUrl}');
      
      // Abrir la URL directamente en el navegador externo
      // Equivalente a target="_blank" en HTML
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Abre en navegador externo
      );
      
      if (success) {
        _showMessage('PDF abierto en el navegador', isError: false);
      } else {
        throw Exception('No se pudo abrir el navegador');
      }
      
    } catch (e) {
      String errorMessage = 'Error al abrir el PDF';
      if (e.toString().contains('No se pudo abrir el navegador')) {
        errorMessage = 'No se pudo abrir el navegador. Verifique que tenga un navegador instalado.';
      } else if (e.toString().contains('URL del PDF no válida')) {
        errorMessage = 'La URL del PDF no es válida.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      _showMessage(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningPdf = false;
        });
      }
    }
  }

  Future<void> _openWompiPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = _parseAmount(_amountController.text);
      if (amount <= 0) {
        throw Exception('Monto inválido');
      }
      
      final amountInCents = (amount * 100).toInt();
      final reference = 'ORAL-PLUS-MANUAL-${DateTime.now().millisecondsSinceEpoch}';
      
      final success = await SimpleWompiService.openPaymentInBrowser(
        reference: reference,
        amountInCents: amountInCents,
        currency: 'COP',
        customerName: _customerNameController.text.trim(),
        customerEmail: _customerEmailController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      
      if (mounted) {
        if (success) {
          _showMessage('Transacción procesada exitosamente', isError: false);
        } else {
          _showMessage('No se pudo procesar la transacción', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error en la transacción: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _payInvoiceWithWompi(InvoiceModel invoice) async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validación adicional: Verificar que la factura pertenece al usuario
    if (invoice.cardCode.trim().toUpperCase() != _userCardCode!.trim().toUpperCase()) {
      _showMessage('Error: Esta factura no pertenece a su cuenta', isError: true);
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Usar el monto final (con descuento aplicado) si es pago completo
      // Los abonos parciales NO tienen descuento
      final paymentAmount = _isPartialPayment ? _parseAmount(_partialAmountController.text) : _finalAmount;
      final amountInCents = (paymentAmount * 100).toInt();
      
      final description = _isPartialPayment 
          ? 'Abono factura ${invoice.docNum} - ${invoice.cardName} (Sin descuento)'
          : 'Pago completo factura ${invoice.docNum} - ${invoice.cardName} ${_discountPercentage > 0 ? "(Descuento $_discountPercentage% aplicado)" : "(Sin descuento)"}';

      final success = await SimpleWompiService.openPaymentInBrowser(
        reference: invoice.wompiData.reference,
        amountInCents: amountInCents,
        currency: invoice.wompiData.currency,
        customerName: _customerNameController.text.trim(),
        customerEmail: _customerEmailController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        description: description,
      );
      
      if (mounted) {
        if (success) {
          _showMessage('Pago de factura ${invoice.docNum} procesado exitosamente', isError: false);
        } else {
          _showMessage('Error al procesar el pago de la factura', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error en la transacción: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectInvoiceForPayment(InvoiceModel invoice) {
    // Validación adicional: Solo permitir seleccionar facturas del usuario actual
    if (invoice.cardCode.trim().toUpperCase() != _userCardCode!.trim().toUpperCase()) {
      _showMessage('Error: Esta factura no pertenece a su cuenta', isError: true);
      return;
    }
    
    setState(() {
      _selectedInvoice = invoice;
      _setupInvoicePayment(invoice);
      _tabController.animateTo(0);
    });
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isError
                  ? Colors.red.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isError
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: isError ? Colors.red : Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isError ? 'Error' : 'Éxito',
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = (index * 0.1) % 1.0;
    final size = 2.0 + (random * 4.0);
    final left = (index * 47.0) % MediaQuery.of(context).size.width;
    final animationDelay = (index * 300.0) % 4000.0;
    
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        final progress = (_floatingController.value + (animationDelay / 4000.0)) % 1.0;
        final top = MediaQuery.of(context).size.height * progress;
        
        return Positioned(
          left: left,
          top: top,
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _clampOpacity((0.1 + (random * 0.2)) * _fadeAnimation.value),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryBlue.withOpacity(0.4),
                        lightBlue.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(size / 2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.2),
                        blurRadius: size * 2,
                        spreadRadius: size / 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Configurar barra de estado para tema claro
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Partículas flotantes azules
          ...List.generate(12, (index) => _buildFloatingParticle(index)),
          
          // Contenido principal
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  backgroundColor,
                  Color(0xFFF1F5F9),
                  Color(0xFFE2E8F0),
                ],
              ),
            ),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (_statistics != null) _buildStatistics(),
                      _buildTabs(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.68,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPaymentSection(),
                            _buildInvoicesSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _clampOpacity(_fadeAnimation.value),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back_rounded, color: textPrimary, size: 20),
              ),
            ),
          );
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                backgroundColor,
                Color(0xFFF1F5F9),
                Colors.transparent,
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: primaryBlue.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _clampOpacity(_fadeAnimation.value),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _clampOpacity(_pulseAnimation.value),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [primaryBlue, secondaryBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: primaryBlue.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.asset(
                                    'assets/logo-pagos.png',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error cargando imagen: $error');
                                      return const Center(
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [primaryBlue, secondaryBlue],
                                ).createShader(bounds),
                                child: Text(
                                  'ORAL-PLUS',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentUser != null
                                    ? 'Bienvenido, ${_currentUser!.nombreCompleto.split(' ')[0]} ($_userCardCode)'
                                    : 'Sistema de Gestión Financiera',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primaryBlue.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _isLoadingInvoices ? null : _reloadUserInvoices,
                            icon: _isLoadingInvoices
                                ? SizedBox(
                                   width: 20,
                                   height: 20,
                                   child: CircularProgressIndicator(
                                     strokeWidth: 2,
                                     valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                   ),
                                 )
                                : Icon(Icons.refresh_rounded, color: textPrimary, size: 22),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 370;
    final titleFontSize = (screenWidth * 0.05).clamp(14.0, 20.0);
    final subtitleFontSize = (screenWidth * 0.035).clamp(10.0, 14.0);
    final codeFontSize = (screenWidth * 0.025).clamp(9.0, 11.0);
    final paddingSize = (screenWidth * 0.07).clamp(16.0, 28.0);
    final iconContainerSize = (screenWidth * 0.11).clamp(36.0, 48.0);

    Widget buildStatCard(
      String title,
      String value,
      String subtitle,
      Color color,
      IconData icon,
    ) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: _slideAnimation.value * screenHeight * 0.3,
            child: Opacity(
              opacity: _clampOpacity(_fadeAnimation.value),
              child: Container(
                padding: EdgeInsets.all(paddingSize),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: iconContainerSize,
                          height: iconContainerSize,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryBlue, secondaryBlue],
                            ),
                            borderRadius: BorderRadius.circular(iconContainerSize / 2),
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mi Cartera Personal',
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (!isSmallScreen)
                                Text(
                                  _currentUser != null
                                      ? 'Facturas de ${_currentUser!.nombreCompleto.split(' ')[0]}'
                                      : 'Dashboard financiero personal',
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                            ],
                          ),
                        ),
                        if (!isSmallScreen)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryBlue, secondaryBlue],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _userCardCode ?? 'CARGANDO',
                              style: TextStyle(
                                fontSize: codeFontSize,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Estadísticas adaptables
                    isSmallScreen
                        ? Column(
                            children: [
                              buildStatCard(
                                'Total',
                                '${_statistics!['total']}',
                                'facturas',
                                primaryBlue,
                                Icons.receipt_long_rounded,
                              ),
                              const SizedBox(height: 16),
                              buildStatCard(
                                'Vencidas',
                                '${_statistics!['overdue']}',
                                'críticas',
                                Colors.red,
                                Icons.warning_rounded,
                              ),
                              const SizedBox(height: 16),
                              buildStatCard(
                                'Urgentes',
                                '${_statistics!['urgent']}',
                                'próximas',
                                Colors.orange,
                                Icons.schedule_rounded,
                              ),
                              const SizedBox(height: 16),
                              buildStatCard(
                                'Vigentes',
                                '${_statistics!['upcoming']}',
                                'normales',
                                Colors.green,
                                Icons.check_circle_rounded,
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: buildStatCard(
                                      'Total',
                                      '${_statistics!['total']}',
                                      'facturas',
                                      primaryBlue,
                                      Icons.receipt_long_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildStatCard(
                                      'Vencidas',
                                      '${_statistics!['overdue']}',
                                      'críticas',
                                      Colors.red,
                                      Icons.warning_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildStatCard(
                                      'Urgentes',
                                      '${_statistics!['urgent']}',
                                      'próximas',
                                      Colors.orange,
                                      Icons.schedule_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildStatCard(
                                      'Vigentes',
                                      '${_statistics!['upcoming']}',
                                      'normales',
                                      Colors.green,
                                      Icons.check_circle_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _clampOpacity(_cardAnimation.value),
          child: Opacity(
            opacity: _clampOpacity(_cardAnimation.value),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 370;
    final tabHeight = 50.0;
    final iconSize = isSmallScreen ? 18.0 : 20.0;
    final fontSize = isSmallScreen ? 12.0 : 14.0;
    final spacing = isSmallScreen ? 6.0 : 10.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryBlue.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryBlue, secondaryBlue],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorPadding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: textSecondary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: fontSize,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            height: tabHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_rounded, size: iconSize),
                if (!isSmallScreen) ...[
                  SizedBox(width: spacing),
                  Flexible(
                    child: Text(
                      _selectedInvoice != null ? 'Procesar Pago' : 'Seleccionar Factura',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            height: tabHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: iconSize),
                if (!isSmallScreen) ...[
                  SizedBox(width: spacing),
                  Flexible(
                    child: Text(
                      'Mi Cartera (${_allInvoices.length})',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    if (_selectedInvoice == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _clampOpacity(_scaleAnimation.value),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _clampOpacity(_pulseAnimation.value),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryBlue, secondaryBlue],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.touch_app_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Seleccione una Factura',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Para procesar un pago, primero debe\nseleccionar una factura de su cartera personal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryBlue, secondaryBlue],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _tabController.animateTo(1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Ver Mi Cartera',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSelectedInvoiceCard(),
            const SizedBox(height: 24),
            _buildPaymentOptionsCard(),
            const SizedBox(height: 24),
            _buildContactFormCard(),
            const SizedBox(height: 24),
            _buildProcessPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedInvoiceCard() {
    final invoice = _selectedInvoice!;
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _clampOpacity(_fadeAnimation.value),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Parte superior: ícono + texto + estado + PDF
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryBlue, secondaryBlue],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getInvoiceStatusIcon(invoice),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info de texto expandible
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.cardFName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Factura ${invoice.docNum}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Información de vencimiento mejorada
                              
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón PDF
                        if (invoice.pdfUrl != null && invoice.pdfUrl!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isOpeningPdf 
                                    ? null 
                                    : () => _openPDFInBrowser(invoice),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: _isOpeningPdf
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                          ),
                                        )
                                      : Icon(
                                          Icons.picture_as_pdf_rounded,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        // Estado (limitar ancho para evitar overflow)
                        Container(
                          constraints: const BoxConstraints(maxWidth: 80),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryBlue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getInvoiceStatusText(invoice),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Contenedor inferior con info de monto
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryBlue.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [primaryBlue, secondaryBlue],
                            ).createShader(bounds),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatCurrency(invoice.amount),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 2,
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryBlue, secondaryBlue],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 18,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Vencimiento: ${invoice.docDueDate}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getDueDateText(invoice),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getDueDateColor(invoice),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Genera texto descriptivo para la fecha de vencimiento

String _getDueDateText(InvoiceModel invoice) {
  final days = _calculateDaysUntilDue(invoice.docDueDate);
  if (days == 999) return 'Fecha no válida';
  if (days < 0) {
    final overdueDays = -days;
    return 'Vencida hace $overdueDays día${overdueDays == 1 ? '' : 's'}';
  }
  if (days == 0) return 'Vence hoy';
  if (days == 1) return 'Vence mañana';
  if (days <= 7) return 'Vence en $days días (Urgente)';
  if (days <= 15) return 'Vence en $days días (Próxima)';
  return 'Vence en $days días';
}

/// Obtiene el color según los días de vencimiento
Color _getDueDateColor(InvoiceModel invoice) {
  final days = _calculateDaysUntilDue(invoice.docDueDate);
  if (days == 999) return Colors.grey;
  if (days < 0) return Colors.red;
  if (days <= 7) return Colors.orange;
  return Colors.green;
}

/// Obtiene el ícono según el estado de la factura
IconData _getInvoiceStatusIcon(InvoiceModel invoice) {
  final days = _calculateDaysUntilDue(invoice.docDueDate);
  if (days == 999) return Icons.error_outline_rounded;
  if (days < 0) return Icons.warning_rounded;
  if (days <= 7) return Icons.schedule_rounded;
  return Icons.receipt_long_rounded;
}

/// Obtiene el texto del estado de la factura
String _getInvoiceStatusText(InvoiceModel invoice) {
  final days = _calculateDaysUntilDue(invoice.docDueDate);
  if (days == 999) return 'Error';
  if (days < 0) return 'Vencida';
  if (days <= 7) return 'Urgente';
  if (days <= 30) return 'Próxima';
  return 'Vigente';
}

/// Formatea una fecha en formato DD/MM/YYYY
/// Formatea una fecha en formato DD/MM/YYYY, aceptando múltiples formatos de entrada
String _formatDate(dynamic date) {
  if (date == null) return 'Fecha no válida';

  // Si ya es DateTime, usamos directamente
  if (date is DateTime) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Si es string, intentamos parsear
  if (date is String) {
    // Normalizar string
    String cleanDate = date.trim();

    // Lista de formatos soportados (en inglés y español)
    final List<DateFormat> formatters = [
      DateFormat("d MMM yyyy", "en_US"),  // 28 Aug 2025
      DateFormat("dd MMM yyyy", "en_US"), // 28 Aug 2025
      DateFormat("d MMMM yyyy", "en_US"), // 28 August 2025
      DateFormat("dd MMMM yyyy", "en_US"), // 28 August 2025
      DateFormat("d MMM yyyy", "es_ES"),  // 28 ago 2025
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

    // Intentar cada formato
    for (final formatter in formatters) {
      try {
        final DateTime parsed = formatter.parse(cleanDate);
        return DateFormat('dd/MM/yyyy').format(parsed);
      } catch (e) {
        continue;
      }
    }

    // Último intento: usar DateTime.parse (ISO)
    try {
      final DateTime parsed = DateTime.parse(cleanDate);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (e) {
      // Si todo falla, logueamos
      print('❌ Error parseando fecha: $cleanDate - Formato no reconocido');
      return cleanDate; // Mostrar el original como fallback
    }
  }

  // Otros tipos
  return date.toString();
}
   

  Widget _buildPaymentOptionsCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * MediaQuery.of(context).size.height * 0.1,
          child: Opacity(
            opacity: _clampOpacity(_fadeAnimation.value),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryBlue.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
              )],
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryBlue, secondaryBlue],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.payment_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opciones de Pago',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Seleccione el tipo de pago que desea realizar',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // Opciones de pago
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPartialPayment = false;
                              if (_selectedInvoice != null) {
                                _calculateDiscount(_selectedInvoice!.amount);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: !_isPartialPayment
                                  ? const LinearGradient(
                                      colors: [primaryBlue, secondaryBlue],
                                    )
                                  : null,
                              color: _isPartialPayment ? backgroundColor : null,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: !_isPartialPayment
                                    ? primaryBlue.withOpacity(0.3)
                                    : primaryBlue.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: !_isPartialPayment
                                  ? [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.payment_rounded,
                                  color: !_isPartialPayment ? Colors.white : textPrimary,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pago Completo',
                                  style: TextStyle(
                                    color: !_isPartialPayment ? Colors.white : textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPartialPayment = true;
                              if (_selectedInvoice != null) {
                                final halfAmount = _selectedInvoice!.amount / 2;
                                _partialAmountController.text = halfAmount.toStringAsFixed(0);
                                _calculateDiscount(halfAmount);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: _isPartialPayment
                                  ? const LinearGradient(
                                      colors: [primaryBlue, secondaryBlue],
                                    )
                                  : null,
                              color: !_isPartialPayment ? backgroundColor : null,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isPartialPayment
                                    ? primaryBlue.withOpacity(0.3)
                                    : primaryBlue.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: _isPartialPayment
                                  ? [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: _isPartialPayment ? Colors.white : textPrimary,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Abono Parcial',
                                  style: TextStyle(
                                    color: _isPartialPayment ? Colors.white : textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Campo de monto parcial
                  if (_isPartialPayment) ...[
                    const SizedBox(height: 24),
                    _buildFormField(
                      controller: _partialAmountController,
                      label: 'Monto del Abono',
                      hint: 'Ingrese el monto a pagar',
                      icon: Icons.attach_money_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        LengthLimitingTextInputFormatter(12),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El monto es requerido';
                        }
                        final amount = _parseAmount(value);
                        if (amount <= 0) {
                          return 'Ingrese un monto válido';
                        }
                        if (_selectedInvoice != null && amount > _selectedInvoice!.amount) {
                          return 'El monto no puede ser mayor al total';
                        }
                        return null;
                      },
                      onChanged: _updatePartialAmount,
                    ),
                    
                    // Información importante sobre abonos parciales
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.blue.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Los abonos parciales no tienen descuento por pronto pago',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Información de descuentos SOLO para pagos completos
                  if (!_isPartialPayment && _discountPercentage > 0) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.1),
                            Colors.green.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.discount_rounded,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '¡Descuento por Pronto Pago!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                              Text(
                                '${_discountPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monto original:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatCurrency(_selectedInvoice!.amount),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monto final:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _formatCurrency(_finalAmount),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _getDiscountDescription(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Obtiene la descripción del descuento aplicado
  String _getDiscountDescription() {
    if (_selectedInvoice == null) return '';
    
    final days = _calculateDaysUntilDue(_selectedInvoice!.docDueDate);
    
    if (days >= 1 && days <= 15) {
      return 'Descuento por pago anticipado (1-15 días antes del vencimiento)';
    } else if (days >= 16 && days <= 30) {
      return 'Descuento por pago anticipado (16-30 días antes del vencimiento)';
    }
    
    return 'Descuento aplicado según política de pagos';
  }

  Widget _buildContactFormCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * MediaQuery.of(context).size.height * 0.2,
          child: Opacity(
            opacity: _clampOpacity(_fadeAnimation.value),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryBlue.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
              )],
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryBlue, secondaryBlue],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.contact_mail_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información de Contacto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              _currentUser != null
                                  ? 'Datos de ${_currentUser!.nombreCompleto.split(' ')[0]} ($_userCardCode)'
                                  : 'Datos requeridos para el procesamiento',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingUserData)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 28),
                  
                  _buildFormField(
                    controller: _customerEmailController,
                    label: 'Correo Electrónico',
                    hint: 'correo@ejemplo.com',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El correo electrónico es requerido';
                      }
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Formato de correo electrónico inválido';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildFormField(
                    controller: _customerPhoneController,
                    label: 'Número de Teléfono',
                    hint: '300 123 4567',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El número de teléfono es requerido';
                      }
                      if (value.length != 10) {
                        return 'El teléfono debe tener exactamente 10 dígitos';
                      }
                      if (!value.startsWith('3')) {
                        return 'El número debe comenzar con 3';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    bool enabled = true,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return TextFormField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: primaryBlue.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: primaryBlue.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: primaryBlue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                hintStyle: TextStyle(
                  color: textSecondary.withOpacity(0.6),
                  fontSize: 16,
                ),
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                errorMaxLines: 2,
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              maxLength: maxLength,
              validator: validator,
              onChanged: onChanged,
              maxLines: 1,
             
            );
          },
        ),
      ],
    );
  }

  Widget _buildProcessPaymentButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isLoading ? 1.0 : _clampOpacity(_pulseAnimation.value),
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, secondaryBlue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading || _selectedInvoice == null
                  ? null
                  : () => _payInvoiceWithWompi(_selectedInvoice!),
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.payment_rounded, size: 24, color: Colors.white),
              label: LayoutBuilder(
                builder: (context, constraints) {
                  String buttonText;
                  if (_isLoading) {
                    buttonText = 'Procesando...';
                  } else if (_isPartialPayment) {
                    final amount = _parseAmount(_partialAmountController.text);
                    buttonText = 'Procesar Abono (${_formatCurrency(amount)})';
                  } else {
                    buttonText = 'Procesar Pago Completo (${_formatCurrency(_finalAmount)})';
                  }
                  
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoicesSection() {
    return Column(
      children: [
        _buildSearch(),
        Expanded(
          child: _isLoadingInvoices
              ? _buildLoadingState()
              : _connectionError != null && _allInvoices.isEmpty
                  ? _buildErrorState()
                  : _filteredInvoices.isEmpty
                      ? _buildEmptyState()
                      : _buildInvoicesList(),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryBlue.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en mis facturas...',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _filterInvoices();
                        },
                        icon: Icon(Icons.clear_rounded, color: textPrimary, size: 20),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: textSecondary.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterInvoices();
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      _filterInvoices();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [primaryBlue, secondaryBlue],
                              )
                            : null,
                        color: isSelected ? null : backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryBlue.withOpacity(0.3)
                              : primaryBlue.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _clampOpacity(_pulseAnimation.value),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Cargando sus facturas...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _userCardCode != null
                ? 'Consultando cartera para $_userCardCode'
                : 'Por favor espere un momento',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Error de Conexión',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _connectionError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _reloadUserInvoices,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Reintentar Conexión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                _searchQuery.isNotEmpty || _selectedFilter != 'TODAS'
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'TODAS'
                  ? 'Sin Resultados'
                  : 'Sin Facturas Pendientes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'TODAS'
                  ? 'No se encontraron facturas que coincidan\ncon los criterios de búsqueda'
                  : _currentUser != null
                      ? '¡Excelente! No tiene facturas pendientes\nen su cuenta $_userCardCode'
                      : 'No hay facturas disponibles\nen este momento',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesList() {
    return RefreshIndicator(
      onRefresh: _reloadUserInvoices,
      color: primaryBlue,
      backgroundColor: cardBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Obtener el ancho disponible y calcular padding responsivo
          final screenWidth = constraints.maxWidth;
          final horizontalPadding = screenWidth > 600 ? 32.0 : 16.0;
          final itemSpacing = screenWidth > 600 ? 20.0 : 12.0;
          
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            itemCount: _filteredInvoices.length,
            itemBuilder: (context, index) {
              final invoice = _filteredInvoices[index];
              
              return AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _clampOpacity(_cardAnimation.value),
                    child: Opacity(
                      opacity: _clampOpacity(_cardAnimation.value),
                      child: Container(
                        margin: EdgeInsets.only(bottom: itemSpacing),
                        constraints: BoxConstraints(
                          maxWidth: screenWidth > 800 ? 700 : double.infinity,
                        ),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => _selectInvoiceForPayment(invoice),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
                            child: Row(
                              children: [
                                // Ícono con tamaño responsivo
                                Container(
                                  width: screenWidth > 600 ? 60 : 50,
                                  height: screenWidth > 600 ? 60 : 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [primaryBlue, secondaryBlue],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      screenWidth > 600 ? 30 : 25,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _getInvoiceStatusIcon(invoice),
                                    color: Colors.white,
                                    size: screenWidth > 600 ? 26 : 22,
                                  ),
                                ),
                                
                                SizedBox(width: screenWidth > 600 ? 20 : 16),
                                
                                // Contenido principal con flex
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Nombre con tamaño de texto responsivo
                                      Text(
                                        invoice.cardFName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: screenWidth > 600 ? 16 : 14,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      
                                      SizedBox(height: screenWidth > 600 ? 8 : 6),
                                      
                                      // Número de factura
                                      Text(
                                        'Factura: ${invoice.docNum}',
                                        style: TextStyle(
                                          fontSize: screenWidth > 600 ? 14 : 12,
                                          color: textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      
                                      SizedBox(height: screenWidth > 600 ? 6 : 4),
                                      
                                      // Fecha de vencimiento mejorada
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: screenWidth > 600 ? 14 : 12,
                                            color: _getDueDateColor(invoice),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _getDueDateText(invoice),
                                              style: TextStyle(
                                                fontSize: screenWidth > 600 ? 13 : 11,
                                                color: _getDueDateColor(invoice),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(width: screenWidth > 600 ? 16 : 12),
                                
                                // Botón PDF si está disponible
                                if (invoice.pdfUrl != null && invoice.pdfUrl!.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isOpeningPdf 
                                            ? null 
                                            : () => _openPDFInBrowser(invoice),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: _isOpeningPdf
                                              ? SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.picture_as_pdf_rounded,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Información del precio y estado
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Monto con ShaderMask responsivo
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [primaryBlue, secondaryBlue],
                                      ).createShader(bounds),
                                      child: Text(
                                        _formatCurrency(invoice.amount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: screenWidth > 600 ? 18 : 16,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    
                                    SizedBox(height: screenWidth > 600 ? 8 : 6),
                                    
                                    // Estado con contenedor responsivo
                                    Container(
                                      constraints: const BoxConstraints(maxWidth: 80),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth > 600 ? 12 : 8,
                                        vertical: screenWidth > 600 ? 6 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: backgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primaryBlue.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getInvoiceStatusText(invoice),
                                        style: TextStyle(
                                          fontSize: screenWidth > 600 ? 11 : 9,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
