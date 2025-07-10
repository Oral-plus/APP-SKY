import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/pago_service.dart';
import '../services/api_service.dart';
import '../models/invoice_model.dart';
import '../models/user_model.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen>
    with TickerProviderStateMixin {
  
  // Controladores
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _searchAnimationController;
  
  // Animaciones
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _searchAnimation;
  
  // Estado
  bool _isLoading = false;
  bool _isLoadingUser = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _connectionError;
  
  // Datos del usuario y facturas
  UserModel? _currentUser;
  String? _userCardCode;
  List<InvoiceModel> _allPaidInvoices = [];
  List<InvoiceModel> _filteredInvoices = [];
  Map<String, dynamic>? _statistics;
  
  // Filtros de tiempo
  String _selectedTimeFilter = 'Todos';
  final List<String> _timeFilterOptions = [
    'Todos', 'Último mes', 'Últimos 3 meses', 'Último año'
  ];
  
  // Colores del tema
  static const Color primaryBlue = Color(0xFF1e3a8a);
  static const Color secondaryBlue = Color(0xFF3b82f6);
  static const Color lightBlue = Color(0xFF60a5fa);
  static const Color accentBlue = Color(0xFF2563eb);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1e293b);
  static const Color textSecondary = Color(0xFF64748b);
  static const Color successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserAndInvoices();
    _searchController.addListener(_onSearchChanged);
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuint,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutExpo,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    ));

    _floatingAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOutSine,
    ));

    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Iniciar animaciones
    _fadeController.forward();
    _slideController.forward();
    _shimmerController.repeat();
    _pulseController.repeat(reverse: true);
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  /// Carga los datos del usuario y sus facturas pagadas
  Future<void> _loadUserAndInvoices() async {
    try {
      setState(() {
        _isLoadingUser = true;
        _connectionError = null;
      });

      print('🔄 Cargando datos del usuario para historial...');
      
      // Cargar datos del usuario
      final user = await ApiService.getUserProfile();
      
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
          _userCardCode = '${user.tipoDocumento}${user.documento}';
          _isLoadingUser = false;
        });
        
        print('✅ Usuario cargado: ${user.nombreCompleto}');
        print('📋 CardCode: $_userCardCode');
        
        // Cargar facturas pagadas
        await _loadPaidInvoices();
      } else {
        throw Exception('No se pudieron obtener los datos del usuario');
      }
    } catch (e) {
      print('❌ Error cargando usuario: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _connectionError = e.toString();
        });
        _showMessage('Error cargando datos del usuario', isError: true);
      }
    }
  }

  /// Carga SOLO las facturas pagadas del usuario
  Future<void> _loadPaidInvoices() async {
    if (_userCardCode == null || _userCardCode!.isEmpty) {
      print('❌ No se puede cargar facturas: CardCode no disponible');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _connectionError = null;
      });

      print('🔍 Cargando facturas pagadas para CardCode: $_userCardCode');
      
      // Verificar conexión
      final isConnected = await InvoiceService1.testConnection();
      if (!isConnected) {
        throw Exception('No se pudo conectar con la API ORAL-PLUS');
      }

      // Obtener todas las facturas del usuario
      final allInvoices = await InvoiceService1.getInvoicesByCardCode(_userCardCode!);
      
      // FILTRAR SOLO LAS FACTURAS PAGADAS
      // En un sistema real, esto vendría de la base de datos con un campo 'status' o 'paid'
      // Por ahora, simulamos que las facturas con fecha de vencimiento pasada están pagadas
      final paidInvoices = allInvoices.where((invoice) {
        // Lógica para determinar si está pagada
        // En tu sistema real, tendrás un campo específico para esto
        return _isInvoicePaid(invoice);
      }).toList();

      print('📄 Total facturas encontradas: ${allInvoices.length}');
      print('✅ Facturas pagadas: ${paidInvoices.length}');

      if (mounted) {
        setState(() {
          _allPaidInvoices = paidInvoices;
          _filteredInvoices = paidInvoices;
          _isLoading = false;
          _calculateStatistics();
        });

        if (paidInvoices.isNotEmpty) {
          _showMessage('${paidInvoices.length} facturas pagadas cargadas', isError: false);
        } else {
          _showMessage('No tienes facturas pagadas aún', isError: false);
        }
      }
    } catch (e) {
      print('❌ Error cargando facturas pagadas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _connectionError = e.toString();
          // Mostrar datos mock solo en caso de error
          _allPaidInvoices = _getMockPaidInvoices();
          _filteredInvoices = _allPaidInvoices;
          _calculateStatistics();
        });
        _showMessage('Error de conexión. Mostrando datos de ejemplo.', isError: true);
      }
    }
  }

  /// Determina si una factura está pagada
  /// En tu sistema real, esto vendría de un campo específico en la base de datos
  bool _isInvoicePaid(InvoiceModel invoice) {
    // TEMPORAL: Simulamos que las facturas vencidas hace más de 30 días están pagadas
    // En tu sistema real, tendrás un campo 'status' o 'paid' en la base de datos
    final daysSinceVencimiento = DateTime.now().difference(invoice.docDueDate).inDays;
    return daysSinceVencimiento > 30; // Simulación temporal
  }

  /// Genera facturas pagadas de ejemplo para el usuario actual
  List<InvoiceModel> _getMockPaidInvoices() {
    if (_currentUser == null || _userCardCode == null) return [];
    
    return [
      InvoiceModel(
        cardCode: _userCardCode!,
        cardName: _currentUser!.nombreCompleto,
        cardFName: _currentUser!.nombreCompleto,
        docNum: 'FAC-PAID-001',
        docDueDate: DateTime.now().subtract(const Duration(days: 45)),
        amount: 125000,
        formattedAmount: '\$125,000',
        pdfUrl: null,
        daysUntilDue: -45,
        formattedDueDate: DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 45))),
        status: 'Pagada',
        wompiData: WompiData(
          reference: 'PAID-001-${DateTime.now().millisecondsSinceEpoch}',
          amountInCents: 12500000,
          currency: 'COP',
          customerName: _currentUser!.nombreCompleto,
        ),
      ),
      InvoiceModel(
        cardCode: _userCardCode!,
        cardName: _currentUser!.nombreCompleto,
        cardFName: _currentUser!.nombreCompleto,
        docNum: 'FAC-PAID-002',
        docDueDate: DateTime.now().subtract(const Duration(days: 60)),
        amount: 89500,
        formattedAmount: '\$89,500',
        pdfUrl: null,
        daysUntilDue: -60,
        formattedDueDate: DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 60))),
        status: 'Pagada',
        wompiData: WompiData(
          reference: 'PAID-002-${DateTime.now().millisecondsSinceEpoch}',
          amountInCents: 8950000,
          currency: 'COP',
          customerName: _currentUser!.nombreCompleto,
        ),
      ),
      InvoiceModel(
        cardCode: _userCardCode!,
        cardName: _currentUser!.nombreCompleto,
        cardFName: _currentUser!.nombreCompleto,
        docNum: 'FAC-PAID-003',
        docDueDate: DateTime.now().subtract(const Duration(days: 90)),
        amount: 250000,
        formattedAmount: '\$250,000',
        pdfUrl: null,
        daysUntilDue: -90,
        formattedDueDate: DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 90))),
        status: 'Pagada',
        wompiData: WompiData(
          reference: 'PAID-003-${DateTime.now().millisecondsSinceEpoch}',
          amountInCents: 25000000,
          currency: 'COP',
          customerName: _currentUser!.nombreCompleto,
        ),
      ),
    ];
  }

  /// Calcula estadísticas de las facturas pagadas
  void _calculateStatistics() {
    if (_allPaidInvoices.isEmpty) return;
  
    final now = DateTime.now();
    final totalAmount = _allPaidInvoices.fold(0.0, (sum, invoice) => sum + invoice.amount);
  
    final thisMonth = _allPaidInvoices.where((i) => 
      i.docDueDate.month == now.month && 
      i.docDueDate.year == now.year
    ).fold(0.0, (sum, invoice) => sum + invoice.amount);
  
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = _allPaidInvoices.where((i) => 
      i.docDueDate.month == lastMonthDate.month && 
      i.docDueDate.year == lastMonthDate.year
    ).fold(0.0, (sum, invoice) => sum + invoice.amount);

    setState(() {
      _statistics = {
        'total': _allPaidInvoices.length,
        'totalAmount': totalAmount,
        'thisMonth': thisMonth,
        'lastMonth': lastMonth,
        'averageAmount': totalAmount / _allPaidInvoices.length,
      };
    });
  }

  /// Maneja cambios en la búsqueda en tiempo real
  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    
    if (_isSearching) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
    
    _filterInvoices();
  }

  /// Filtra las facturas según búsqueda y filtros de tiempo
  void _filterInvoices() {
    List<InvoiceModel> filtered = List.from(_allPaidInvoices);

    // Aplicar filtro de tiempo
    if (_selectedTimeFilter != 'Todos') {
      final now = DateTime.now();
      filtered = filtered.where((invoice) {
        switch (_selectedTimeFilter) {
          case 'Último mes':
            return invoice.docDueDate.isAfter(now.subtract(const Duration(days: 30)));
          case 'Últimos 3 meses':
            return invoice.docDueDate.isAfter(now.subtract(const Duration(days: 90)));
          case 'Último año':
            return invoice.docDueDate.isAfter(now.subtract(const Duration(days: 365)));
          default:
            return true;
        }
      }).toList();
    }

    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((invoice) {
        return invoice.docNum.toLowerCase().contains(query) ||
               invoice.cardName.toLowerCase().contains(query) ||
               invoice.cardFName.toLowerCase().contains(query) ||
               invoice.description.toLowerCase().contains(query);
      }).toList();
    }

    // Ordenar por fecha más reciente primero
    filtered.sort((a, b) => b.docDueDate.compareTo(a.docDueDate));

    setState(() {
      _filteredInvoices = filtered;
    });
  }

  /// Refresca los datos
  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await _loadPaidInvoices();
  }

  /// Muestra mensajes al usuario
  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError 
                  ? Colors.red.withOpacity(0.3) 
                  : successGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : successGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: Container(
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
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: primaryBlue,
          backgroundColor: cardBackground,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(),
              _buildSearchSection(),
              if (_statistics != null) _buildStatsSection(),
              _buildFilterSection(),
              _buildInvoicesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: Container(
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
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textPrimary,
            size: 22,
          ),
        ),
      ),
      actions: [
        Container(
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
            onPressed: _isLoading ? null : _refreshData,
            icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    color: textPrimary,
                    size: 22,
                  ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                backgroundColor,
                Color(0xFFF1F5F9),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _floatingAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingAnimation.value),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    successGreen,
                                    Color(0xFF059669),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: successGreen.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: Colors.white,
                                size: 28,
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
                                colors: [
                                  successGreen,
                                  Color(0xFF059669),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'Facturas Pagadas',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currentUser != null 
                                  ? 'Historial de ${_currentUser!.nombreCompleto.split(' ')[0]} ($_userCardCode)'
                                  : 'Historial de pagos realizados',
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buscar en tu historial',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _searchAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isSearching 
                            ? primaryBlue.withOpacity(0.3)
                            : primaryBlue.withOpacity(0.1),
                        width: _isSearching ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isSearching 
                              ? primaryBlue.withOpacity(0.15)
                              : primaryBlue.withOpacity(0.08),
                          blurRadius: _isSearching ? 20 : 10,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por número, descripción o cliente...',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isSearching 
                                  ? [primaryBlue, secondaryBlue]
                                  : [primaryBlue.withOpacity(0.7), secondaryBlue.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.search_rounded, 
                            color: Colors.white, 
                            size: 20
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                                icon: Icon(
                                  Icons.clear_rounded, 
                                  color: textSecondary, 
                                  size: 20
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, 
                          vertical: 18
                        ),
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
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _statistics!;
    
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: successGreen.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: successGreen.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
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
                          colors: [successGreen, Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
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
                            'Resumen de Pagos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Estadísticas de tus facturas pagadas',
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Pagado',
                        stats['totalAmount'],
                        Icons.payments_rounded,
                        successGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Facturas',
                        stats['total'].toDouble(),
                        Icons.receipt_long_rounded,
                        primaryBlue,
                        isCount: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Este Mes',
                        stats['thisMonth'],
                        Icons.calendar_today_rounded,
                        accentBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Promedio',
                        stats['averageAmount'],
                        Icons.trending_up_rounded,
                        lightBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, double value, IconData icon, Color color, {bool isCount = false}) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
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
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isCount 
                    ? value.toInt().toString()
                    : '\$${NumberFormat('#,##0', 'es_CO').format(value)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar por período',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _timeFilterOptions.length,
                  itemBuilder: (context, index) {
                    final option = _timeFilterOptions[index];
                    final isSelected = _selectedTimeFilter == option;
                    
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedTimeFilter = option;
                          });
                          _filterInvoices();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [successGreen, Color(0xFF059669)],
                                  )
                                : null,
                            color: isSelected ? null : cardBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? successGreen.withOpacity(0.3)
                                  : primaryBlue.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: successGreen.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            option,
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
        ),
      ),
    );
  }

  Widget _buildInvoicesList() {
    if (_isLoadingUser) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
              const SizedBox(height: 24),
              Text(
                'Cargando datos del usuario...',
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

    if (_isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: List.generate(3, (index) => _buildShimmerCard()),
          ),
        ),
      );
    }

    if (_connectionError != null && _filteredInvoices.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildErrorState(),
        ),
      );
    }

    if (_filteredInvoices.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildEmptyState(),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final invoice = _filteredInvoices[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: _buildInvoiceCard(invoice),
                  ),
                );
              },
            );
          },
          childCount: _filteredInvoices.length,
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 120,
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryBlue.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              final progress = _shimmerAnimation.value;
              return LinearGradient(
                colors: [
                  Colors.transparent,
                  primaryBlue.withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: [
                  (progress - 0.3).clamp(0.0, 1.0),
                  progress.clamp(0.0, 1.0),
                  (progress + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.1),
                  Colors.redAccent.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error de Conexión',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se pudo conectar con el servidor.\nMostrando datos de ejemplo.',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  successGreen.withOpacity(0.1),
                  successGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 50,
              color: successGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Sin resultados'
                : 'Sin facturas pagadas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No se encontraron facturas que coincidan\ncon "${_searchQuery}"'
                : _currentUser != null
                    ? 'Aún no tienes facturas pagadas\nen tu cuenta $_userCardCode'
                    : 'No hay facturas pagadas disponibles',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: successGreen.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: successGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            _showInvoiceDetails(invoice);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [successGreen, Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: successGreen.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.cardFName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Factura: ${invoice.docNum}',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          invoice.formattedAmount,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'PAGADA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: successGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: successGreen.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pagada: ${invoice.formattedDueDate}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: successGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Completada',
                        style: TextStyle(
                          fontSize: 13,
                          color: successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInvoiceDetails(InvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: successGreen.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: successGreen.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [successGreen, Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Factura Pagada',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Pago completado exitosamente',
                          style: TextStyle(
                            fontSize: 14,
                            color: successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildDetailRow('Número de Factura', invoice.docNum),
              _buildDetailRow('Cliente', invoice.cardFName),
              _buildDetailRow('Monto Pagado', invoice.formattedAmount),
              _buildDetailRow('Fecha de Pago', invoice.formattedDueDate),
              _buildDetailRow('Estado', 'PAGADA ✓'),
              _buildDetailRow('Método de Pago', 'Wompi - Tarjeta'),
              const Spacer(),
              if (invoice.pdfUrl != null && invoice.pdfUrl!.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Aquí abrir el PDF
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Ver Comprobante PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
