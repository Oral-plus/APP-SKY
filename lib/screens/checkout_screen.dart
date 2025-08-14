  import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart_item.dart';
import '../models/user_session.dart';
import '../services/api_service1.dart';
import '../services/auth_service.dart';
import '../services/Datos_service.dart';
import 'loading_overlay.dart';

  class CheckoutScreen extends StatefulWidget {
    final List<CartItem> cartItems;

    const CheckoutScreen({
      super.key,
      required this.cartItems,
    });

    @override
    State<CheckoutScreen> createState() => _CheckoutScreenState();
  }

  class _CheckoutScreenState extends State<CheckoutScreen>
      with TickerProviderStateMixin {
    final UserSession _userSession = UserSession();
    final _formKey = GlobalKey<FormState>();

    // Controladores de texto
    final _cedulaController = TextEditingController();
    final _nombreController = TextEditingController();
    final _emailController = TextEditingController();
    final _telefonoController = TextEditingController();
    final _direccionController = TextEditingController();

    // Estados
    bool _isProcessingOrder = false;
    bool _isSearchingUser = false;
    bool _acceptTerms = false;
    bool _isLoadingUserData = true;
    bool _clientFoundInSAP = false;
    Map<String, dynamic>? _sapClientData;

    // Animaciones
    late AnimationController _fadeController;
    late AnimationController _slideController;
    late AnimationController _pulseController;
    late Animation<double> _fadeAnimation;
    late Animation<Offset> _slideAnimation;
    late Animation<double> _pulseAnimation;

    // Colores profesionales
    static const Color primaryColor = Color(0xFF1E40AF);
    static const Color secondaryColor = Color(0xFF059669);
    static const Color accentColor = Color(0xFFF59E0B);
    static const Color errorColor = Color(0xFFDC2626);
    static const Color backgroundColor = Color(0xFFF8FAFC);
    static const Color cardColor = Colors.white;
    static const Color textPrimary = Color(0xFF1F2937);
    static const Color textSecondary = Color(0xFF6B7280);

    @override
    void initState() {
      super.initState();
      _initializeAnimations();
      _loadUserData();
      _startAnimations();
    }

    void _initializeAnimations() {
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _slideController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
      );
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
      );
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );
    }

    void _startAnimations() {
      _fadeController.forward();
      _slideController.forward();
    }

    @override
    void dispose() {
      _fadeController.dispose();
      _slideController.dispose();
      _pulseController.dispose();
      _cedulaController.dispose();
      _nombreController.dispose();
      _emailController.dispose();
      _telefonoController.dispose();
      _direccionController.dispose();
      super.dispose();
    }

    Future<void> _loadUserData() async {
      if (!mounted) return;
      try {
        setState(() => _isLoadingUserData = true);
        final hasSession = await AuthService.hasActiveSession();
        if (hasSession) {
          final user = _userSession.currentUser;
          if (user != null) {
            _cedulaController.text = user.documento;
            _nombreController.text = user.nombreCompleto;
            _emailController.text = user.email;
            _telefonoController.text = user.telefono;
            await _searchUserByCedula(user.documento, showMessages: false);
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error al cargar información del usuario');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingUserData = false);
        }
      }
    }
String formatPrice(num price) {
  final formatter = NumberFormat("#,##0", "es_CO");
  return formatter.format(price);
}
    Future<void> _searchUserByCedula(String cedula, {bool showMessages = true}) async {
      if (cedula.isEmpty) return;

      try {
        setState(() => _isSearchingUser = true);
        final clientData = await InvoiceService1.getClientDataWithFilters(cedula);

        if (clientData != null && mounted) {
          setState(() {
            _clientFoundInSAP = true;
            _sapClientData = clientData;
          });

          _nombreController.text = clientData['cardName']?.toString() ?? '';
          _emailController.text = clientData['email']?.toString() ?? '';
          _telefonoController.text = clientData['phone']?.toString() ?? '';
          _direccionController.text = clientData['address']?.toString() ?? '';

          if (showMessages) {
            _showSuccessSnackBar('✅ Cliente verificado exitosamente');
            _pulseController.forward().then((_) => _pulseController.reverse());
          }
        } else if (mounted) {
          setState(() {
            _clientFoundInSAP = false;
            _sapClientData = null;
          });

          if (_userSession.currentUser?.documento != cedula) {
            _nombreController.text = '';
            _emailController.text = '';
            _telefonoController.text = '';
            _direccionController.text = '';
          }

          if (showMessages) {
            _showWarningSnackBar('⚠️ Cliente no encontrado en el sistema');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _clientFoundInSAP = false;
            _sapClientData = null;
          });
          if (showMessages) {
            _showErrorSnackBar('❌ Error al buscar cliente');
          }
        }
      } finally {
        if (mounted) {
          setState(() => _isSearchingUser = false);
        }
      }
    }

    double get _subtotal {
      return widget.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    }

    double get _total => _subtotal;

    // ✅ MÉTODO CORREGIDO: Procesar compra con estructura de datos correcta
    Future<void> _processOrder() async {
      if (!_formKey.currentState!.validate()) {
        _showErrorSnackBar('❌ Por favor completa todos los campos requeridos');
        return;
      }

      if (!_acceptTerms) {
        _showErrorSnackBar('❌ Debes aceptar los términos y condiciones');
        return;
      }

      if (widget.cartItems.isEmpty) {
        _showErrorSnackBar('❌ El carrito está vacío');
        return;
      }

      if (!_clientFoundInSAP) {
        _showErrorSnackBar('❌ El cliente debe estar registrado en SAP para procesar la compra');
        return;
      }

      setState(() => _isProcessingOrder = true);

      try {
        print('🛒 === INICIANDO PROCESO DE COMPRA (como JavaScript/PHP) ===');
        
        final cedula = _cedulaController.text.trim();
        final nombre = _nombreController.text.trim();
        final correo = _emailController.text.trim();
        final telefono = _telefonoController.text.trim();
        final direccion = _direccionController.text.trim(); // ✅ Agregar dirección

        print('📋 Datos del cliente:');
        print('   Cédula: $cedula');
        print('   Nombre: $nombre');
        print('   Correo: $correo');
        print('   Teléfono: $telefono');
        print('   Dirección: $direccion');
        print('📦 Productos: ${widget.cartItems.length}');
        print('💰 Total: \$${_total.toStringAsFixed(0)}');

        // ✅ PROCESAR COMPRA con todos los datos necesarios
        final result = await ApiService1.processPurchase(
          cartItems: widget.cartItems,
          cedula: cedula,
          nombre: nombre,
          correo: correo,
          telefono: telefono,
          observaciones: '', // Puedes agregar un campo para observaciones si lo necesitas
        );

        if (result['success'] == true && mounted) {
          print('✅ === COMPRA COMPLETADA ===');
          print('📄 DocEntry: ${result['docEntry']}');
          print('📄 DocNum: ${result['docNum']}');
          print('📧 Correo enviado: ${result['emailSent']}');
          
          _showSuccessDialog(result);
        } else {
          throw Exception(result['message'] ?? 'Error desconocido en la respuesta');
        }

      } catch (e) {
        print('❌ === ERROR EN COMPRA ===');
        print('🔧 Error: $e');
        
        if (mounted) {
          String errorMessage = 'Error al procesar la compra';
          
          if (e.toString().contains('conexión') || e.toString().contains('internet')) {
            errorMessage = 'Error de conexión. Verifica tu internet e intenta nuevamente.';
          } else if (e.toString().contains('tiempo') || e.toString().contains('Timeout')) {
            errorMessage = 'La operación tardó demasiado. El servidor SAP puede estar ocupado.';
          } else if (e.toString().contains('servidor')) {
            errorMessage = 'Error del servidor. Intenta más tarde.';
          } else {
            errorMessage = e.toString().replaceAll('Exception: ', '');
          }
          
          _showErrorSnackBar('❌ $errorMessage');
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessingOrder = false);
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      if (_isLoadingUserData) {
        return _buildLoadingScreen();
      }

      return Scaffold(
        backgroundColor: backgroundColor,
        body: LoadingOverlay(
          isLoading: _isProcessingOrder,
          message: 'Procesando tu compra...',
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildOrderSummary(),
                                const SizedBox(height: 24),
                                _buildCustomerInfo(),
                                const SizedBox(height: 24),
                                _buildTermsAndConditions(),
                                const SizedBox(height: 32),
                                _buildProcessButton(),
                                const SizedBox(height: 32),
                              ],
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
      );
    }

    Widget _buildLoadingScreen() {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cargando información...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Conectando con el sistema',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildAppBar() {
      return SliverAppBar(
        expandedHeight: 120,
        floating: false,
        pinned: true,
        backgroundColor: cardColor,
        elevation: 0,
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor, Color(0xFF3B82F6)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_checkout,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Finalizar Compra',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }

    Widget _buildOrderSummary() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header responsive
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: accentColor,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Resumen del Pedido',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : isMediumScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${widget.cartItems.length} ${widget.cartItems.length == 1 ? 'producto' : 'productos'}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Lista de productos responsive
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * (isSmallScreen ? 0.25 : 0.3),
              ),
              child: widget.cartItems.isEmpty
                  ? SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'No hay productos en el carrito',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.cartItems.length,
                      separatorBuilder: (context, index) => SizedBox(
                        height: isSmallScreen ? 8 : 12,
                      ),
                      itemBuilder: (context, index) => _buildOrderItem(
                        widget.cartItems[index],
                      ),
                    ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Separador responsive
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 0 : 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey[300]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Resumen de precios responsive
           _buildSummaryRow('Subtotal:', '\$${formatPrice(_subtotal)}', false),
SizedBox(height: isSmallScreen ? 8 : 12),
_buildSummaryRow('Total:', '\$${formatPrice(_total)}', true),

          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Imagen responsive
          Container(
            width: isSmallScreen ? 45 : isMediumScreen ? 50 : 60,
            height: isSmallScreen ? 45 : isMediumScreen ? 50 : 60,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              child: Image.asset(
                item.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.shopping_bag,
                    color: Colors.grey[400],
                    size: isSmallScreen ? 20 : 28,
                  );
                },
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          
          // Información del producto responsive
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: isSmallScreen ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                
                // Badges responsive
                Wrap(
                  spacing: isSmallScreen ? 4 : 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Cant: ${item.quantity}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    if (screenWidth > 320) // Solo mostrar código en pantallas más grandes
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * (isSmallScreen ? 0.25 : 0.3),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Cód: ${item.codigoSap}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w500,
                            color: secondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          
          // Precio responsive
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.price,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : isMediumScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isTotal) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTotal ? (isSmallScreen ? 12 : 16) : (isSmallScreen ? 6 : 8),
        horizontal: isTotal ? (isSmallScreen ? 12 : 16) : 0,
      ),
      decoration: isTotal
          ? BoxDecoration(
              color: secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              border: Border.all(color: secondaryColor.withOpacity(0.3)),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal 
                    ? (isSmallScreen ? 16 : 18)
                    : (isSmallScreen ? 14 : 16),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? secondaryColor : textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal 
                    ? (isSmallScreen ? 18 : 20)
                    : (isSmallScreen ? 16 : 18),
                fontWeight: FontWeight.bold,
                color: isTotal ? secondaryColor : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildCustomerInfo() {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _clientFoundInSAP ? _pulseAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _clientFoundInSAP ? secondaryColor : Colors.grey[300]!,
                  width: _clientFoundInSAP ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _clientFoundInSAP
                        ? secondaryColor.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _clientFoundInSAP
                                ? secondaryColor.withOpacity(0.1)
                                : primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _clientFoundInSAP ? Icons.verified_user : Icons.person,
                            color: _clientFoundInSAP ? secondaryColor : primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información del Cliente',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _clientFoundInSAP ? secondaryColor : textPrimary,
                                ),
                              ),
                              Text(
                                _clientFoundInSAP
                                    ? 'Cliente verificado en el sistema'
                                    : 'Ingresa tu cédula para verificar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _clientFoundInSAP ? secondaryColor : textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_clientFoundInSAP)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Verificado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildCedulaField(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre Completo',
                      hint: 'Se completará automáticamente',
                      icon: Icons.person_outline,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Correo Electrónico',
                      hint: 'Se completará automáticamente',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El correo es requerido';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _telefonoController,
                      label: 'Teléfono',
                      hint: 'Se completará automáticamente',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _direccionController,
                      label: 'Dirección',
                      hint: 'Se completará automáticamente',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    Widget _buildCedulaField() {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: _cedulaController,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Número de Cédula *',
            hintText: 'Ej: C39536277',
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _clientFoundInSAP ? secondaryColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _clientFoundInSAP ? Icons.verified_user : Icons.credit_card,
                color: _clientFoundInSAP ? secondaryColor : primaryColor,
                size: 20,
              ),
            ),
            suffixIcon: _isSearchingUser
                ? Container(
                    margin: const EdgeInsets.all(12),
                    width: 20,
                    height: 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_clientFoundInSAP)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 14, color: secondaryColor),
                              const SizedBox(width: 4),
                              Text(
                                'Verificado',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.search, color: primaryColor),
                        onPressed: () => _searchUserByCedula(_cedulaController.text.trim()),
                        tooltip: 'Buscar cliente',
                      ),
                    ],
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _clientFoundInSAP ? secondaryColor.withOpacity(0.3) : Colors.grey[300]!,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _clientFoundInSAP ? secondaryColor : primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: errorColor, width: 2),
            ),
            filled: true,
            fillColor: _clientFoundInSAP ? secondaryColor.withOpacity(0.05) : backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            helperText: _clientFoundInSAP
                ? '✅ Cliente verificado exitosamente'
                : 'Ingresa tu cédula para buscar tus datos',
            helperStyle: TextStyle(
              color: _clientFoundInSAP ? secondaryColor : primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La cédula es requerida';
            }
            if (value.trim().length < 6) {
              return 'Ingresa una cédula válida';
            }
            return null;
          },
          onChanged: (value) {
            if (value.trim() != _sapClientData?['cardCode']) {
              setState(() {
                _clientFoundInSAP = false;
                _sapClientData = null;
              });
              if (value.trim() != _userSession.currentUser?.documento) {
                _nombreController.text = '';
                _emailController.text = '';
                _telefonoController.text = '';
              }
            }
          },
          onFieldSubmitted: (value) {
            _searchUserByCedula(value.trim());
          },
        ),
      );
    }

    Widget _buildTextField({
      required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      TextInputType? keyboardType,
      int maxLines = 1,
      String? Function(String?)? validator,
      bool readOnly = false,
    }) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          readOnly: readOnly,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: errorColor, width: 2),
            ),
            filled: true,
            fillColor: backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
        ),
      );
    }

    Widget _buildTermsAndConditions() {
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                  activeColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Términos y Condiciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Acepto los términos y condiciones de la compra. Confirmo que la información proporcionada es correcta y autorizo el procesamiento de mi pedido.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: primaryColor, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Tus datos están protegidos y se procesan de forma segura',
                              style: TextStyle(
                                fontSize: 13,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
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
        ),
      );
    }

    Widget _buildProcessButton() {
      return Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _clientFoundInSAP
                ? [secondaryColor, const Color(0xFF047857)]
                : [Colors.grey[400]!, Colors.grey[300]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (_clientFoundInSAP ? secondaryColor : Colors.grey).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: (_isProcessingOrder || !_clientFoundInSAP) ? null : _processOrder,
            child: Center(
              child: _isProcessingOrder
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Procesando compra...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _clientFoundInSAP ? Icons.shopping_cart_checkout : Icons.warning,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _clientFoundInSAP
                                  ? 'Procesar Compra - \$${_total.toStringAsFixed(0)}'
                                  : 'Cliente debe estar verificado',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (!_clientFoundInSAP)
                              const Text(
                                'Busca tu cédula primero',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
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

    void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 16,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width < 360 ? 16 : 32,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [secondaryColor.withOpacity(0.05), Colors.white],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono responsive
                  Container(
                    width: MediaQuery.of(context).size.width < 360 ? 60 : 80,
                    height: MediaQuery.of(context).size.width < 360 ? 60 : 80,
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: secondaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width < 360 ? 30 : 40,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width < 360 ? 16 : 24),
                  
                  // Título responsive
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '¡Compra Exitosa!',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width < 360 ? 12 : 16),
                  
                  // Mensaje responsive
                  Flexible(
                    child: Text(
                      result['message'] ?? 'Tu compra ha sido procesada exitosamente',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 360 ? 14 : 16,
                        color: textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width < 360 ? 16 : 24),
                  
                  // Container de información responsive
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 360 ? 12 : 20,
                    ),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: secondaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        if (result['docNum'] != null) ...[
                          _buildTransactionInfo(
                            '📄 Número de Documento', 
                            '${result['docNum']}',
                            context,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.width < 360 ? 8 : 12),
                        ],
                        if (result['docEntry'] != null) ...[
                          _buildTransactionInfo(
                            '🔢 ID de Transacción', 
                            '${result['docEntry']}',
                            context,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.width < 360 ? 8 : 12),
                        ],
                        _buildTransactionInfo(
                          '💰 Total Pagado', 
                          '\$${_total.toStringAsFixed(0)}',
                          context,
                        ),
                        SizedBox(height: MediaQuery.of(context).size.width < 360 ? 8 : 12),
                        _buildTransactionInfo(
                          '📧 Confirmación por Email',
                          result['emailSent'] == true ? 'Enviado ✅' : 'No enviado ❌',
                          context,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width < 360 ? 20 : 32),
                  
                  // Botón responsive
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width < 360 ? 48 : 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Continuar Comprando',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width < 360 ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Método helper actualizado para ser responsive
  Widget _buildTransactionInfo(String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: MediaQuery.of(context).size.width < 360 ? 2 : 3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: MediaQuery.of(context).size.width < 360 ? 3 : 2,
          child: Text(
            value,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  

    void _showErrorSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    void _showSuccessSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    void _showWarningSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
