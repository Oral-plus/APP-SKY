import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/simple_wompi_service.dart';
import '../services/invoice_service.dart';
import '../services/api_service.dart';
import '../models/invoice_model.dart';
import '../models/user_model.dart';

class SimpleWompiScreen extends StatefulWidget {
  final InvoiceModel? invoice;
  
  const SimpleWompiScreen({super.key, this.invoice});

  @override
  State<SimpleWompiScreen> createState() => _SimpleWompiScreenState();
}

class _SimpleWompiScreenState extends State<SimpleWompiScreen> 
    with TickerProviderStateMixin {
  
  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _searchController = TextEditingController();
  
  // Tab and Animation Controllers
  late TabController _tabController;
  late AnimationController _primaryAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _shimmerAnimationController;
  late AnimationController _floatingAnimationController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatingAnimation;
  
  // State Variables
  bool _isLoading = false;
  bool _isLoadingInvoices = false;
  bool _isLoadingUserData = true;
  List<InvoiceModel> _allInvoices = [];
  List<InvoiceModel> _filteredInvoices = [];
  InvoiceModel? _selectedInvoice;
  String _searchQuery = '';
  String? _connectionError;
  Map<String, dynamic>? _statistics;
  UserModel? _currentUser;
  String? _userCardCode;
  
  // Filter Options
  String _selectedFilter = 'TODAS';
  final List<String> _filterOptions = [
    'TODAS', 'VENCIDAS', 'URGENTES', 'PRÓXIMAS', 'VIGENTES'
  ];
  
  // Enhanced Color Scheme
  static const Color primaryBlue = Color(0xFF1e3a8a);
  static const Color secondaryBlue = Color(0xFF3b82f6);
  static const Color lightBlue = Color(0xFF60a5fa);
  static const Color accentBlue = Color(0xFF2563eb);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1e293b);
  static const Color textSecondary = Color(0xFF64748b);
  static const Color successColor = Color(0xFF10b981);
  static const Color warningColor = Color(0xFFf59e0b);
  static const Color errorColor = Color(0xFFef4444);
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _loadUserData();
    
    if (widget.invoice != null) {
      _setupInvoicePayment(widget.invoice!);
      _selectedInvoice = widget.invoice;
      _tabController.index = 0;
    }
    
    _startAnimations();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 2, vsync: this);
    
    _primaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _shimmerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _floatingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
  }

  void _setupAnimations() {
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: Curves.easeOutQuart,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _primaryAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
    _shimmerAnimationController.repeat();
    _floatingAnimationController.repeat(reverse: true);
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoadingUserData = true);
      
      final user = await ApiService.getUserProfile();
      
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
          _isLoadingUserData = false;
          _userCardCode = '${user.tipoDocumento}${user.documento}';
        });
        
        _setupUserData(user);
        await _loadUserInvoices();
      } else {
        throw Exception('No se pudieron obtener los datos del usuario');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUserData = false);
        _setupDefaultData();
        _showMessage('Error cargando datos del usuario', isError: true);
      }
    }
  }

  void _setupUserData(UserModel user) {
    _customerNameController.text = user.nombreCompleto;
    _customerEmailController.text = user.email.isNotEmpty 
        ? user.email 
        : '${user.documento}@oral-plus.com';
    _customerPhoneController.text = user.telefono;
    _descriptionController.text = 'Pago ORAL-PLUS - ${user.nombreCompleto}';
    _amountController.text = '50000';
  }

  void _setupDefaultData() {
    _customerNameController.text = 'Cliente ORAL-PLUS';
    _customerEmailController.text = 'cliente@oral-plus.com';
    _customerPhoneController.text = '3001234567';
    _descriptionController.text = 'Pago ORAL-PLUS';
    _amountController.text = '50000';
  }

  Future<void> _loadUserInvoices() async {
    if (_userCardCode == null || _userCardCode!.isEmpty) {
      _showMessage('Error: No se pudo identificar el usuario', isError: true);
      return;
    }

    try {
      setState(() {
        _isLoadingInvoices = true;
        _connectionError = null;
      });

      final isConnected = await InvoiceService.testConnection();
      if (!isConnected) {
        throw Exception('No se pudo conectar con la API');
      }

      final response = await InvoiceService.getInvoicesByCardCode(_userCardCode!);
      final filteredResponse = response.where((invoice) =>
          invoice.cardCode.trim().toUpperCase() == _userCardCode!.trim().toUpperCase()
      ).toList();

      if (mounted) {
        setState(() {
          _allInvoices = filteredResponse;
          _filteredInvoices = filteredResponse;
          _isLoadingInvoices = false;
          _calculateStatistics();
        });

        final message = filteredResponse.isNotEmpty
            ? '${filteredResponse.length} facturas cargadas'
            : '¡Felicitaciones! Te encuentras a paz y salvo';
        _showMessage(message, isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInvoices = false;
          _connectionError = e.toString();
          _allInvoices = _getMockInvoicesForUser();
          _filteredInvoices = _allInvoices;
          _calculateStatistics();
        });
        _showMessage('Error de conexión. Mostrando datos de ejemplo.', isError: true);
      }
    }
  }

  List<InvoiceModel> _getMockInvoicesForUser() {
    if (_currentUser == null || _userCardCode == null) return [];
    
    return [
      InvoiceModel(
        cardCode: _userCardCode!,
        cardName: _currentUser!.nombreCompleto,
        cardFName: _currentUser!.nombreCompleto,
        docNum: 'FAC-2024-001',
        docDueDate: DateTime.now().add(const Duration(days: 5)),
        amount: 125000,
        formattedAmount: '\$125,000',
        pdfUrl: null,
        daysUntilDue: 5,
        formattedDueDate: '25/12/2024',
        status: 'Pendiente',
        wompiData: WompiData(
          reference: 'ORAL-FAC-2024-001-${DateTime.now().millisecondsSinceEpoch}',
          amountInCents: 12500000,
          currency: 'COP',
          customerName: _currentUser!.nombreCompleto,
        ),
      ),
    ];
  }

  void _calculateStatistics() {
    if (_allInvoices.isEmpty) return;

    final overdue = _allInvoices.where((i) => i.isOverdue).length;
    final urgent = _allInvoices.where((i) => i.isUrgent && !i.isOverdue).length;
    final upcoming = _allInvoices.where((i) => i.isUpcoming).length;
    final normal = _allInvoices.length - overdue - urgent - upcoming;
    final totalAmount = _allInvoices.fold(0.0, (sum, invoice) => sum + invoice.amount);

    setState(() {
      _statistics = {
        'total': _allInvoices.length,
        'overdue': overdue,
        'urgent': urgent,
        'upcoming': upcoming,
        'normal': normal,
        'totalAmount': totalAmount,
      };
    });
  }

  void _filterInvoices() {
    List<InvoiceModel> filtered = List.from(_allInvoices);

    if (_selectedFilter != 'TODAS') {
      switch (_selectedFilter) {
        case 'VENCIDAS':
          filtered = filtered.where((i) => i.isOverdue).toList();
          break;
        case 'URGENTES':
          filtered = filtered.where((i) => i.isUrgent && !i.isOverdue).toList();
          break;
        case 'PRÓXIMAS':
          filtered = filtered.where((i) => i.isUpcoming).toList();
          break;
        case 'VIGENTES':
          filtered = filtered.where((i) => !i.isOverdue && !i.isUrgent && !i.isUpcoming).toList();
          break;
      }
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((invoice) {
        final query = _searchQuery.toLowerCase();
        return invoice.cardCode.toLowerCase().contains(query) ||
               invoice.cardName.toLowerCase().contains(query) ||
               invoice.docNum.toLowerCase().contains(query);
      }).toList();
    }

    filtered.sort((a, b) => a.priority.compareTo(b.priority));
    setState(() => _filteredInvoices = filtered);
  }

  void _setupInvoicePayment(InvoiceModel invoice) {
    _amountController.text = invoice.amount.toStringAsFixed(0);
    _descriptionController.text = 'Pago factura ${invoice.docNum} - ${invoice.cardName}';
    
    if (_currentUser != null) {
      _customerNameController.text = _currentUser!.nombreCompleto;
    } else {
      _customerNameController.text = invoice.cardFName;
    }
  }

  Future<void> _payInvoiceWithWompi(InvoiceModel invoice) async {
    if (!_formKey.currentState!.validate()) return;

    if (invoice.cardCode.trim().toUpperCase() != _userCardCode!.trim().toUpperCase()) {
      _showMessage('Error: Esta factura no pertenece a su cuenta', isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      final success = await SimpleWompiService.openPaymentInBrowser(
        reference: invoice.wompiData.reference,
        amountInCents: invoice.wompiData.amountInCents,
        currency: invoice.wompiData.currency,
        customerName: _customerNameController.text.trim(),
        customerEmail: _customerEmailController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        description: invoice.description,
      );

      if (mounted) {
        final message = success
            ? 'Pago de factura ${invoice.docNum} procesado exitosamente'
            : 'Error al procesar el pago de la factura';
        _showMessage(message, isError: !success);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error en la transacción: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectInvoiceForPayment(InvoiceModel invoice) {
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
        content: _buildMessageContent(message, isError),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildMessageContent(String message, bool isError) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError ? errorColor.withOpacity(0.3) : successColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isError ? errorColor.withOpacity(0.1) : successColor.withOpacity(0.1),
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
              color: isError ? errorColor.withOpacity(0.1) : successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? errorColor : successColor,
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
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
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _primaryAnimationController.dispose();
    _pulseAnimationController.dispose();
    _shimmerAnimationController.dispose();
    _floatingAnimationController.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          _buildFloatingParticles(),
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return Stack(
      children: List.generate(8, (index) => _buildFloatingParticle(index)),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = (index * 0.1) % 1.0;
    final size = 2.0 + (random * 3.0);
    final left = (index * 60.0) % MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        final progress = (_floatingAnimationController.value + (index * 0.1)) % 1.0;
        final top = MediaQuery.of(context).size.height * progress;

        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: (0.1 + (random * 0.2)) * _fadeAnimation.value,
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
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Container(
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
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildAppBarContent(),
      ),
    );
  }

  Widget _buildBackButton() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
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
              icon: const Icon(Icons.arrow_back_rounded, color: textPrimary, size: 20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBarContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundColor, Color(0xFFF1F5F9), Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Row(
                  children: [
                    _buildLogo(),
                    const SizedBox(width: 20),
                    _buildAppBarTitle(),
                    _buildRefreshButton(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: primaryBlue.withOpacity(0.3), width: 2),
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
                  return const Center(
                    child: Icon(Icons.payment, size: 30, color: Colors.white),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBarTitle() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [primaryBlue, secondaryBlue],
            ).createShader(bounds),
            child: const Text(
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
            style: const TextStyle(
              fontSize: 14,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryBlue.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _isLoadingInvoices ? null : _loadUserInvoices,
        icon: _isLoadingInvoices
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              )
            : const Icon(Icons.refresh_rounded, color: textPrimary, size: 22),
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: _slideAnimation.value * MediaQuery.of(context).size.height * 0.3,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryBlue.withOpacity(0.1), width: 1),
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
                    _buildStatisticsHeader(),
                    const SizedBox(height: 28),
                    _buildStatisticsGrid(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mi Cartera Personal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              Text(
                _currentUser != null
                    ? 'Facturas de ${_currentUser!.nombreCompleto.split(' ')[0]}'
                    : 'Dashboard financiero personal',
                style: const TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _userCardCode ?? 'CARGANDO',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                '${_statistics!['total']}',
                'facturas',
                primaryBlue,
                Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Vencidas',
                '${_statistics!['overdue']}',
                'críticas',
                errorColor,
                Icons.warning_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Urgentes',
                '${_statistics!['urgent']}',
                'próximas',
                warningColor,
                Icons.schedule_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Vigentes',
                '${_statistics!['upcoming']}',
                'normales',
                successColor,
                Icons.check_circle_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
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
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.1), width: 1),
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
          gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment_rounded, size: 20),
                const SizedBox(width: 10),
                Text(_selectedInvoice != null ? 'Procesar Pago' : 'Seleccionar Factura'),
              ],
            ),
          ),
          Tab(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 20),
                const SizedBox(width: 10),
                Text('Mi Cartera (${_allInvoices.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    if (_selectedInvoice == null) {
      return _buildSelectInvoicePrompt();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSelectedInvoiceCard(),
            const SizedBox(height: 24),
            _buildContactFormCard(),
            const SizedBox(height: 24),
            _buildProcessPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectInvoicePrompt() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPromptIcon(),
                  const SizedBox(height: 32),
                  const Text(
                    'Seleccione una Factura',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
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
                  _buildViewPortfolioButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPromptIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(Icons.touch_app_rounded, size: 60, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildViewPortfolioButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }

  Widget _buildSelectedInvoiceCard() {
    final invoice = _selectedInvoice!;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryBlue.withOpacity(0.1), width: 1),
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
                _buildInvoiceHeader(invoice),
                const SizedBox(height: 32),
                _buildInvoiceAmount(invoice),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceHeader(InvoiceModel invoice) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(invoice.statusIcon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.cardFName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Factura ${invoice.docNum}',
                style: const TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryBlue.withOpacity(0.2), width: 1),
          ),
          child: Text(
            invoice.statusText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceAmount(InvoiceModel invoice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [primaryBlue, secondaryBlue],
            ).createShader(bounds),
            child: Text(
              invoice.formattedAmount,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 2,
            width: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule_rounded, size: 18, color: textSecondary),
              const SizedBox(width: 8),
              Text(
                'Vencimiento: ${invoice.formattedDueDate}',
                style: const TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            invoice.dueInfo,
            style: const TextStyle(
              fontSize: 14,
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactFormCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * MediaQuery.of(context).size.height * 0.2,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryBlue.withOpacity(0.1), width: 1),
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
                  _buildContactFormHeader(),
                  const SizedBox(height: 28),
                  _buildEmailField(),
                  const SizedBox(height: 24),
                  _buildPhoneField(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactFormHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.contact_mail_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
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
                style: const TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingUserData)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
          ),
      ],
    );
  }

  Widget _buildEmailField() {
    return _buildFormField(
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
    );
  }

  Widget _buildPhoneField() {
    return _buildFormField(
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
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryBlue.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryBlue.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: errorColor, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: errorColor, width: 2),
            ),
            filled: true,
            fillColor: backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            hintStyle: TextStyle(
              color: textSecondary.withOpacity(0.6),
              fontSize: 16,
            ),
            errorStyle: const TextStyle(
              color: errorColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildProcessPaymentButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isLoading ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
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
              label: Text(
                _isLoading ? 'Procesando Transacción...' : 'Procesar Pago con Wompi',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        _buildSearchSection(),
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

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 20),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.1), width: 1),
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
              gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _filterInvoices();
                  },
                  icon: const Icon(Icons.clear_rounded, color: textPrimary, size: 20),
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
        style: const TextStyle(
          fontSize: 16,
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _filterInvoices();
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
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
                setState(() => _selectedFilter = filter);
                _filterInvoices();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [primaryBlue, secondaryBlue])
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
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLoadingIcon(),
          const SizedBox(height: 32),
          const Text(
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
            style: const TextStyle(
              fontSize: 16,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
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
                gradient: const LinearGradient(colors: [errorColor, Colors.redAccent]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: errorColor.withOpacity(0.3),
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
            const Text(
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
              style: const TextStyle(
                fontSize: 16,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
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
                onPressed: _loadUserInvoices,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Reintentar Conexión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
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
              style: const TextStyle(
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
              style: const TextStyle(
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
      onRefresh: _loadUserInvoices,
      color: primaryBlue,
      backgroundColor: cardBackground,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _filteredInvoices.length,
        itemBuilder: (context, index) {
          final invoice = _filteredInvoices[index];

          return AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryBlue.withOpacity(0.1), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ListTile(
                    onTap: () => _selectInvoiceForPayment(invoice),
                    contentPadding: const EdgeInsets.all(20),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(invoice.statusIcon, color: Colors.white, size: 26),
                    ),
                    title: Text(
                      invoice.cardFName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Factura: ${invoice.docNum}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: textSecondary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Vence: ${invoice.formattedDueDate}',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary.withOpacity(0.7),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [primaryBlue, secondaryBlue],
                          ).createShader(bounds),
                          child: Text(
                            invoice.formattedAmount,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryBlue.withOpacity(0.2), width: 1),
                          ),
                          child: Text(
                            invoice.statusText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
