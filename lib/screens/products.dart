import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../models/cart_item.dart';
import '../screens/checkout_screen.dart';
import '../services/Sap_service.dart' as sap;
import '../services/api_service.dart'; // ✅ Para validar usuario logueado
import '../models/user_model.dart'; // ✅ Para obtener datos del usuario

// Helper extension for responsive sizing
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double responsive(double value) {
    double baseWidth = 390.0;
    return (screenWidth / baseWidth) * value;
  }

  double responsiveHeight(double value) {
    double baseHeight = 844.0;
    return (screenHeight / baseHeight) * value;
  }

  double clampFont(double min, double max, double scale) {
    double size = responsive(scale);
    return size.clamp(min, max);
  }

  bool get isTablet => screenWidth >= 600;
  bool get isDesktop => screenWidth >= 900;
  bool get isLandscape => screenWidth > screenHeight;

  EdgeInsets get responsivePadding {
    if (isDesktop) return const EdgeInsets.all(32);
    if (isTablet) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  double get responsiveRadius {
    if (isDesktop) return 32;
    if (isTablet) return 28;
    return 24;
  }
}

// Colores elegantes estilo Apple con mejoras para profesionalismo
const Color primaryBlue = Color(0xFF007AFF);
const Color secondaryBlue = Color(0xFF5AC8FA);
const Color lightBlue = Color(0xFFADD8E6);
const Color darkBlue = Color(0xFF0051D5);
const Color accentColor = Color(0xFFFF9500);
const Color greenColor = Color(0xFF34C759);
const Color backgroundColor = Color(0xFFF2F2F7);
const Color cardBackground = Color(0xFFFFFFFF);
const Color textPrimary = Color(0xFF000000);
const Color textSecondary = Color(0xFF8E8E93);
const Color elegantGray = Color(0xFFF2F2F7);
const Color glassColor = Color(0xFFFFFFFF);

// Global utility function for price formatting

String formatPrice(dynamic price) {
  final formatter = NumberFormat("#,##0");
  final number =
      double.tryParse(price.toString().replaceAll(RegExp(r'[^\d.]'), '')) ??
          0.0;
  final precioConIva = number * 1.19; // Incluye el IVA (19%)
  return formatter.format(precioConIva.round());
}

// Gestor del carrito optimizado con integración SAP
class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addItem(Map<String, dynamic> product) {
    final String itemId =
        '${product['title']}_${product['textura'] ?? 'default'}';
    final existingIndex = _items.indexWhere((item) => item.id == itemId);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(
        id: itemId,
        title: product['title']!,
        price: product['price']!,
        originalPrice: product['originalPrice'] ?? '',
        image: product['image']!,
        description: product['description']!,
        codigoSap: product['codigoSap'] ?? product['title']!,
        textura: product['textura'],
      ));
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _searchController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _searchAnimation;

  final CartManager _cartManager = CartManager();
  final TextEditingController _searchTextController = TextEditingController();
  final ScrollController _searchScrollController = ScrollController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  // Variables SAP y usuario
  UserModel? _currentUser;
  String _codigoClienteActual = '';
  Map<String, Map<String, dynamic>> _preciosSAP = {};
  Map<String, Map<String, dynamic>> _estadosSAP = {};
  bool _cargandoPrecios = false;
  bool _cargandoEstados = false;
  bool _isLoadingUser = true;
  bool _errorCargandoPrecios = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _scaleController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _searchController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutBack));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _searchController, curve: Curves.easeOut));

    _searchTextController.addListener(() {
      setState(() {
        _searchQuery = _searchTextController.text.toLowerCase();
        _isSearching = _searchQuery.isNotEmpty;
        if (_isSearching) {
          _searchController.forward();
          _filterAllProducts();
        } else {
          _searchController.reverse();
        }
      });
    });

    _initializeAllProducts();
    _startAnimations();

    // ✅ Cargar usuario y datos SAP automáticamente
    _loadUserAndSapData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _searchController.dispose();
    _searchTextController.dispose();
    _searchScrollController.dispose();
    super.dispose();
  }

  void _initializeAllProducts() {
    _allProducts = [
      ..._getCepillosProducts(),
      ..._getCremasProducts(),
      ..._getEnjuaguesProducts(),
      ..._getSedasProducts(),
      ..._getUniversoNinosProducts(),
      ..._getKitsProducts(),
    ];
  }

  // ✅ NUEVA FUNCIÓN: Cargar usuario y datos SAP automáticamente
  Future<void> _loadUserAndSapData() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      // Verificar si hay sesión activa
      final hasSession = await ApiService.hasActiveSession();
      if (!hasSession) {
        _redirectToLogin();
        return;
      }

      // Obtener datos del usuario
      final user = await ApiService.getUserProfile();
      if (user == null) {
        _redirectToLogin();
        return;
      }

      setState(() {
        _currentUser = user;
        _codigoClienteActual =
            user.documento; // Usar documento como código de cliente
        _isLoadingUser = false;
      });

      print('✅ Usuario cargado: ${user.nombre} - Documento: ${user.documento}');

      // Cargar datos SAP automáticamente
      await _cargarDatosSAP();
    } catch (e) {
      print('❌ Error cargando usuario: $e');
      setState(() {
        _isLoadingUser = false;
      });
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  // ✅ FUNCIÓN SIMPLIFICADA: Cargar datos SAP
  Future<void> _cargarDatosSAP() async {
    if (_codigoClienteActual.isEmpty) {
      print('⚠️ No hay código de cliente configurado');
      return;
    }

    // Obtener todos los códigos SAP de los productos
    final codigosSAP = <String>{};
    for (final product in _allProducts) {
      codigosSAP.add(product['codigoSap'] ?? '');
      if (product['codigoSapSuave'] != null) {
        codigosSAP.add(product['codigoSapSuave']!);
      }
      if (product['codigoSapAlternativo'] != null) {
        codigosSAP.add(product['codigoSapAlternativo']!);
      }
    }

    final codigosLista =
        codigosSAP.where((codigo) => codigo.isNotEmpty).toList();

    if (codigosLista.isEmpty) return;

    // Cargar precios y estados en paralelo
    await Future.wait([
      _cargarPreciosSAP(codigosLista),
      _cargarEstadosSAP(codigosLista),
    ]);
  }

  // ✅ FUNCIÓN ACTUALIZADA: Cargar precios SAP usando la nueva API - CON ACTUALIZACIÓN EN TIEMPO REAL
  Future<void> _cargarPreciosSAP(List<String> codigos) async {
    if (_codigoClienteActual.isEmpty) return;

    setState(() {
      _cargandoPrecios = true;
      _errorCargandoPrecios = false;
    });

    try {
      final resultado = await sap.InvoiceService1.obtenerPreciosSAP(
          codigos, _codigoClienteActual);

      if (resultado['success'] == true && resultado['precios'] != null) {
        setState(() {
          _preciosSAP =
              Map<String, Map<String, dynamic>>.from(resultado['precios']);
        });

        print('✅ Precios SAP cargados: ${_preciosSAP.length} productos');

        // ✅ ACTUALIZACIÓN EN TIEMPO REAL: Actualizar todos los productos con precios SAP
        _actualizarPreciosEnTiempoReal();

        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Precios Actualizados',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(
                            'Lista de precios: ${resultado['lista_precios_usada']} - ${_preciosSAP.length} productos',
                            style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              backgroundColor: greenColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.all(20),
              duration: const Duration(milliseconds: 3000),
            ),
          );
        }
      } else {
        print('⚠️ Error al cargar precios SAP: ${resultado['error']}');
        setState(() {
          _errorCargandoPrecios = true;
        });

        // ✅ NO BLOQUEAR - Solo mostrar mensaje informativo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.info_outline,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Precios por Defecto',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(
                            'Se mostrarán precios estándar. Los productos están disponibles.',
                            style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.all(20),
              duration: const Duration(milliseconds: 4000),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error al cargar precios SAP: $e');
      setState(() {
        _errorCargandoPrecios = true;
      });
    } finally {
      setState(() {
        _cargandoPrecios = false;
      });
    }
  }

  // ✅ NUEVA FUNCIÓN: Actualizar precios en tiempo real en todos los productos
  void _actualizarPreciosEnTiempoReal() {
    setState(() {
      // Actualizar precios en _allProducts
      for (int i = 0; i < _allProducts.length; i++) {
        final codigoSap = _allProducts[i]['codigoSap'] ?? '';
        if (codigoSap.isNotEmpty && _preciosSAP.containsKey(codigoSap)) {
          final precioSAP = _obtenerPrecioSAP(codigoSap);
          if (precioSAP != 'Precio no disponible') {
            _allProducts[i]['price'] = '\$${formatPrice(precioSAP)}';
            _allProducts[i]['precioSAPActualizado'] = true;
          }
        }

        // También actualizar precios alternativos si existen
        if (_allProducts[i]['codigoSapSuave'] != null) {
          final codigoSapSuave = _allProducts[i]['codigoSapSuave']!;
          if (_preciosSAP.containsKey(codigoSapSuave)) {
            final precioSAPSuave = _obtenerPrecioSAP(codigoSapSuave);
            if (precioSAPSuave != 'Precio no disponible') {
              _allProducts[i]['priceSuave'] =
                  '\$${formatPrice(precioSAPSuave)}';
            }
          }
        }

        if (_allProducts[i]['codigoSapAlternativo'] != null) {
          final codigoSapAlt = _allProducts[i]['codigoSapAlternativo']!;
          if (_preciosSAP.containsKey(codigoSapAlt)) {
            final precioSAPAlt = _obtenerPrecioSAP(codigoSapAlt);
            if (precioSAPAlt != 'Precio no disponible') {
              _allProducts[i]['priceAlternativo'] =
                  '\$${formatPrice(precioSAPAlt)}';
            }
          }
        }
      }

      // Actualizar productos filtrados si hay búsqueda activa
      if (_isSearching) {
        _filterAllProducts();
      }
    });

    print(
        '✅ Precios actualizados en tiempo real para ${_allProducts.length} productos');
  }

  // ✅ FUNCIÓN ACTUALIZADA: Cargar estados SAP con verificación de disponibilidad
  Future<void> _cargarEstadosSAP(List<String> codigos) async {
    setState(() {
      _cargandoEstados = true;
    });

    try {
      final resultado = await sap.InvoiceService1.obtenerEstadosProductosSAP(
          codigos,
          _codigoClienteActual.isNotEmpty ? _codigoClienteActual : 'DEFAULT');

      if (resultado['success'] == true && resultado['productos'] != null) {
        setState(() {
          _estadosSAP =
              Map<String, Map<String, dynamic>>.from(resultado['productos']);
        });

        // ✅ ACTUALIZACIÓN EN TIEMPO REAL: Actualizar estados de disponibilidad
        _actualizarEstadosEnTiempoReal();

        print('✅ Estados SAP cargados: ${_estadosSAP.length} productos');
      }
    } catch (e) {
      print('❌ Error al cargar estados SAP: $e');
    } finally {
      setState(() {
        _cargandoEstados = false;
      });
    }
  }

  // ✅ NUEVA FUNCIÓN: Actualizar estados en tiempo real
  void _actualizarEstadosEnTiempoReal() {
    setState(() {
      for (int i = 0; i < _allProducts.length; i++) {
        final codigoSap = _allProducts[i]['codigoSap'] ?? '';
        if (codigoSap.isNotEmpty) {
          _allProducts[i]['disponible'] = _productoDisponible(codigoSap);
          _allProducts[i]['mensajeEstado'] = _obtenerMensajeEstado(codigoSap);
        }
      }
    });

    print(
        '✅ Estados actualizados en tiempo real para ${_allProducts.length} productos');
  }

  // ✅ FUNCIÓN ACTUALIZADA: Obtener precio SAP del producto - CON FALLBACK
  String _obtenerPrecioSAP(String codigoSap) {
    if (_preciosSAP.containsKey(codigoSap)) {
      final precio = _preciosSAP[codigoSap]!['precio'];
      return sap.InvoiceService1.formatearPrecioSAP(precio);
    }
    return 'Precio no disponible';
  }

  // ✅ FUNCIÓN ACTUALIZADA: Verificar disponibilidad del producto basado en estados SAP
  bool _productoDisponible(String codigoSap) {
    if (_estadosSAP.containsKey(codigoSap)) {
      final estado = _estadosSAP[codigoSap]!;
      // Verificar si el producto está disponible según los datos de SAP
      final disponible = estado['disponible'] ?? true;
      final stock = estado['stock'] ?? 0;

      // Producto disponible si tiene stock > 0 y está marcado como disponible
      return disponible == true && (stock is num ? stock > 0 : true);
    }
    // Si no hay información de estado, asumir que está disponible
    return true;
  }

  // ✅ FUNCIÓN ACTUALIZADA: Obtener mensaje de estado del producto
  String _obtenerMensajeEstado(String codigoSap) {
    if (_estadosSAP.containsKey(codigoSap)) {
      final estado = _estadosSAP[codigoSap]!;
      final disponible = _productoDisponible(codigoSap);

      if (!disponible) {
        return estado['mensaje']?.toString() ?? 'Producto no disponible';
      }

      return sap.InvoiceService1.obtenerMensajeEstado(_estadosSAP[codigoSap]!);
    }
    return 'Producto disponible';
  }

  void _filterAllProducts() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = [];
      return;
    }

    _filteredProducts = _allProducts.where((product) {
      final title = product['title']?.toString().toLowerCase() ?? '';
      final description =
          product['description']?.toString().toLowerCase() ?? '';
      final codigoSap = product['codigoSap']?.toString().toLowerCase() ?? '';
      final category = product['category']?.toString().toLowerCase() ?? '';

      return title.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          codigoSap.contains(_searchQuery) ||
          category.contains(_searchQuery);
    }).toList();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    // ✅ VERIFICAR DISPONIBILIDAD ANTES DE AGREGAR AL CARRITO
    final codigoSap = product['codigoSap'] ?? '';
    final disponible =
        codigoSap.isNotEmpty ? _productoDisponible(codigoSap) : true;

    if (!disponible) {
      // Mostrar mensaje de producto no disponible
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.block, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Producto No Disponible',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(
                          _obtenerMensajeEstado(codigoSap),
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.all(20),
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
      return;
    }

    // ✅ INTEGRACIÓN SAP: Actualizar precio con datos SAP si están disponibles
    final productWithSapPrice = Map<String, dynamic>.from(product);

    if (codigoSap.isNotEmpty && _preciosSAP.containsKey(codigoSap)) {
      final precioSAP = _obtenerPrecioSAP(codigoSap);
      if (precioSAP != 'Precio no disponible') {
        productWithSapPrice['price'] = '\$${formatPrice(precioSAP)}';
      }
    }

    _cartManager.addItem(productWithSapPrice);
    HapticFeedback.mediumImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Agregado al Carrito',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        '${product['title']!} ${product['textura'] != null ? '(${product['textura']})' : ''}',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(milliseconds: 2000),
        ),
      );
    }
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CartBottomSheet(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive(16),
        vertical: context.responsive(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.responsive(25)),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15), width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Tu Carrito',
            style: TextStyle(
              color: textPrimary,
              fontSize: context.clampFont(16, 22, 18),
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: textSecondary),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListenableBuilder(
      listenable: _cartManager,
      builder: (context, _) {
        final items = _cartManager.items;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    color: textSecondary, size: context.responsive(40)),
                SizedBox(height: context.responsive(8)),
                Text('Tu carrito está vacío',
                    style: TextStyle(
                        color: textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(context.responsive(16)),
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: context.responsive(8)),
          itemBuilder: (context, index) {
            final it = items[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.responsive(12)),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.responsive(12),
                  vertical: context.responsive(8),
                ),
                title: Text(it.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('\$${it.totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: primaryBlue, fontWeight: FontWeight.w800)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _cartManager.updateQuantity(
                            it.id, it.quantity - 1)),
                    Text('${it.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _cartManager.updateQuantity(
                            it.id, it.quantity + 1)),
                    IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _cartManager.removeItem(it.id)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProductPreview(Map<String, dynamic> product) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => ProductPreviewDialog(
        product: product,
        onAddToCart: _addToCart,
        preciosSAP: _preciosSAP,
        estadosSAP: _estadosSAP,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar pantalla de carga mientras se obtienen los datos del usuario
    if (_isLoadingUser) {
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
                  gradient:
                      LinearGradient(colors: [primaryBlue, secondaryBlue]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cargando perfil...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Obteniendo precios personalizados',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  backgroundColor,
                  backgroundColor.withOpacity(0.8),
                  Colors.white
                ],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  SizedBox(
                      height: kToolbarHeight + context.responsiveHeight(40)),
                  _buildEnhancedSearchBar(),
                  if (!_isSearching) _buildTabs(),
                  Expanded(
                    child: _isSearching
                        ? _buildSearchResults()
                        : _buildTabContent(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: context.responsive(16), vertical: context.responsive(8)),
      child: Stack(
        children: [
          // Main search container with glassmorphism effect
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.98),
                  Colors.white.withOpacity(0.88),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(context.responsive(28)),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: _isSearching
                      ? primaryBlue.withOpacity(0.1)
                      : Colors.transparent,
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.responsive(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: TextField(
                  controller: _searchTextController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _isSearching = value.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar en todos los productos...',
                    hintStyle: TextStyle(
                      color: textSecondary.withOpacity(0.65),
                      fontSize: context.clampFont(14, 18, 16),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    prefixIcon: _buildAnimatedSearchIcon(),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? _buildAnimatedClearButton()
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.responsive(22),
                      vertical: context.responsive(20),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: context.clampFont(14, 18, 16),
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ),

          // Animated bottom accent line
          if (_isSearching) _buildSearchAccentLine(),
        ],
      ),
    );
  }

  // Separated animated search icon for cleaner code
  Widget _buildAnimatedSearchIcon() {
    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.all(context.responsive(14)),
          padding: EdgeInsets.all(context.responsive(10)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isSearching
                  ? [primaryBlue, secondaryBlue]
                  : [
                      primaryBlue.withOpacity(0.25),
                      primaryBlue.withOpacity(0.08)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(context.responsive(14)),
            boxShadow: _isSearching
                ? [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isSearching ? Icons.search_rounded : Icons.search_outlined,
              key: ValueKey(_isSearching),
              color: _isSearching ? Colors.white : primaryBlue,
              size: context.responsive(22),
            ),
          ),
        );
      },
    );
  }

  // Separated animated clear button for cleaner code
  Widget _buildAnimatedClearButton() {
    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _searchAnimation.value,
          child: Container(
            margin: EdgeInsets.all(context.responsive(10)),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(context.responsive(14)),
            ),
            child: IconButton(
              onPressed: () {
                _searchTextController.clear();
                setState(() {
                  _searchQuery = '';
                  _isSearching = false;
                });
              },
              icon: Icon(
                Icons.close_rounded,
                color: textSecondary.withOpacity(0.8),
                size: context.responsive(20),
              ),
              splashRadius: 20,
            ),
          ),
        );
      },
    );
  }

  // Separated bottom accent line for cleaner code
  Widget _buildSearchAccentLine() {
    return Positioned(
      bottom: -1,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _searchAnimation,
        builder: (context, child) {
          return Container(
            height: 3.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.8),
                  secondaryBlue,
                  primaryBlue.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            margin: EdgeInsets.symmetric(
              horizontal: context.responsive(25) * (1 - _searchAnimation.value),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return FadeTransition(
      opacity: _searchAnimation,
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: context.responsive(20)),
            padding: EdgeInsets.all(context.responsive(16)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.1),
                  primaryBlue.withOpacity(0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(context.responsive(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: primaryBlue, size: context.responsive(20)),
                SizedBox(width: context.responsive(12)),
                Expanded(
                  child: Text(
                    'Resultados para "$_searchQuery" (${_filteredProducts.length})',
                    style: TextStyle(
                      fontSize: context.clampFont(14, 18, 16),
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.responsive(16)),
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildNoResults()
                : _buildScrollableProductsGrid(_filteredProducts, primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableProductsGrid(
      List<Map<String, dynamic>> products, Color themeColor) {
    return SingleChildScrollView(
      controller: _searchScrollController,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.responsive(16)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 1;
            double childAspectRatio = 0.75;

            if (constraints.maxWidth < 400) {
              crossAxisCount = 1;
              childAspectRatio = 0.85;
            } else if (constraints.maxWidth < 600) {
              crossAxisCount = 2;
              childAspectRatio = 0.75;
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 3;
              childAspectRatio = 0.8;
            } else {
              crossAxisCount = 4;
              childAspectRatio = 0.85;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: context.responsive(12),
                mainAxisSpacing: context.responsive(12),
                childAspectRatio: childAspectRatio,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    // ✅ FIX: Asegurar que value esté entre 0.0 y 1.0
                    final clampedValue = value.clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 0.8 + (0.2 * clampedValue),
                      child: Opacity(
                        opacity: clampedValue,
                        child: _buildProductCard(products[index], themeColor),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.responsive(40)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.1),
                  Colors.grey.withOpacity(0.05)
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: context.responsive(60),
              color: Colors.grey,
            ),
          ),
          SizedBox(height: context.responsive(24)),
          Text(
            'No se encontraron productos',
            style: TextStyle(
              fontSize: context.clampFont(18, 24, 20),
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          SizedBox(height: context.responsive(8)),
          Text(
            'Intenta con otros términos de búsqueda',
            style: TextStyle(
              fontSize: context.clampFont(14, 18, 16),
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      physics: const BouncingScrollPhysics(),
      children: [
        _buildCepillosTab(),
        _buildCremasTab(),
        _buildEnjuaguesTab(),
        _buildSedasTab(),
        _buildUniversoNinosTab(),
        _buildKitsTab(),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize:
          Size.fromHeight(kToolbarHeight + context.responsiveHeight(10)),
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.98),
                Colors.white.withOpacity(0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding:
                    EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: false,
                  leading: _buildBackButton(),
                  title: _buildTitle(),
                  actions: [
                    _buildSuperCuteCartButton(),
                    SizedBox(width: 15),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: context.responsive(16),
            vertical: context.responsive(12)),
        padding: EdgeInsets.all(context.responsive(8)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(context.responsive(25)),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 35,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.responsive(25)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(context.responsive(20)),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: textSecondary.withOpacity(0.8),
              labelStyle: TextStyle(
                fontSize: context.clampFont(11, 15, 13),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: context.clampFont(11, 15, 13),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              onTap: (index) => HapticFeedback.selectionClick(),
              tabs: const [
                Tab(text: 'Cepillos'),
                Tab(text: 'Cremas'),
                Tab(text: 'Enjuagues'),
                Tab(text: 'Sedas'),
                Tab(text: 'Universo Niños'),
                Tab(text: 'Kits'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ CEPILLOS CON CÓDIGOS SAP CORREGIDOS Y SELECCIÓN DE TEXTURA
  List<Map<String, dynamic>> _getCepillosProducts() {
    return [
      {
        'title': 'Cepillo Dental Original Ristro',
        'price': formatPrice('14109'),
        'image': 'assets/CEPILLOS/RISTRACEPILLO.png',
        'rating': '5.0',
        'description':
            'Mango ergonómico que se adapta perfectamente a tu mano con inclinación en forma de espejo odontológico para llegar fácil a todas las dentaduras.',
        'codigoSap': '50360251', // Media por defecto
        'codigoSapSuave': '50360256', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true, // Se actualizará con datos SAP
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Cerdas ultra suaves',
          'Mango ergonómico',
          'Tecnología avanzada',
          'Cuidado de encías'
        ],
        'specifications': {
          'Material': 'Nylon de alta calidad',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cep Original Flex Ristra x12',
        'price': formatPrice('16983'),
        'image': 'assets/CEPILLOS/RISTRACEPILLORIGINAL12.png',
        'rating': '5.0',
        'description':
            'Cepillo premium con cerdas extra suaves y cabezal compacto',
        'codigoSap': '50360249', // Media por defecto
        'codigoSapSuave': '50360250', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Cerdas premium',
          'Cabezal compacto',
          'Mango antideslizante',
          'Limpieza profunda'
        ],
        'specifications': {
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Original',
        'price': formatPrice('1280'),
        'image': 'assets/CEPILLOS/ORIGINAL.png',
        'rating': '5.0',
        'description': 'Cerdas de dureza media para limpieza efectiva diaria',
        'codigoSap': '50360264', // Media por defecto
        'codigoSapSuave': '50360267', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Cerdas medias',
          'Limpieza efectiva',
          'Diseño ergonómico',
          'Uso diario'
        ],
        'specifications': {
          'Dureza': 'Media',
          'Tamaño': 'Estándar',
        }
      },
      {
        'title': 'Cepillo Ultra Duo Individual',
        'price': formatPrice('5072'),
        'image': 'assets/CEPILLOS/CEPILLOULTRAINDIVIDUAL.png',
        'rating': '5.0',
        'description':
            'Cepillo compacto ideal para viajes con estuche protector',
        'codigoSap': '50280060', // Media por defecto
        'codigoSapSuave': '50280095', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Tamaño compacto',
          'Estuche incluido',
          'Portátil',
          'Cerdas suaves'
        ],
        'specifications': {
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Ultra Individual',
        'price': formatPrice('2930'),
        'image': 'assets/CEPILLOS/CEPILLOULTRADUOSUAVE.png',
        'rating': '5.0',
        'description':
            'Cepillo ecológico con mango de bambú y cerdas naturales',
        'codigoSap': '50360084', // Media por defecto
        'codigoSapSuave': '50290044', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Mango de bambú',
          'Cerdas naturales',
          'Biodegradable',
          'Eco-friendly'
        ],
        'specifications': {
          'Material': 'Bambú natural',
          'Dureza': 'Suave',
          'Tamaño': 'Estándar',
        }
      },
      {
        'title': 'Cepillo Waviness',
        'price': formatPrice('1685'),
        'image': 'assets/CEPILLOS/CEPILLOWAVINES.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50360167', // Media por defecto
        'textura': 'Media',
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Ristra Cepillo Waviness X12',
        'price': formatPrice('19674'),
        'image': 'assets/CEPILLOS/RISTRAWAVINESS12.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50360243', // Media por defecto
        'textura': 'Media',
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Media',
        }
      },
      {
        'title': 'Cepillo Calipso Ind',
        'price': formatPrice('3220'),
        'image': 'assets/CEPILLOS/CEPILLOWAVINES.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50280124', // Media por defecto
        'codigoSapSuave': '50290044', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Kit Calipso',
        'price': formatPrice('5487'),
        'image': 'assets/CEPILLOS/CALIPSO3.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50280128', // Media por defecto
        'textura': 'Media',
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Calipso X3',
        'price': formatPrice('3220'),
        'image': 'assets/CEPILLOS/CALIPSO3.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50280126', // Media por defecto
        'codigoSapSuave': '50280127', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Calipso x5',
        'price': formatPrice('3220'),
        'image': 'assets/CEPILLOS/CALIPSO5.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50360072', // Media por defecto
        'textura': 'Media',
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Dakota',
        'price': formatPrice('3220'),
        'image': 'assets/CEPILLOS/CEPILLODACOTA.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50280118', // Media por defecto
        'textura': 'Media',
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Kit Dakota',
        'price': formatPrice('8106'),
        'image': 'assets/KITS/KITDACOTA.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50280122', // Media por defecto
        'textura': 'Media',
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Duo Dakota',
        'price': formatPrice('6107'),
        'image': 'assets/CEPILLOS/CEPILLODUODACOTA.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50280116', // Media por defecto
        'textura': 'Media',
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Model 400 Ind',
        'price': formatPrice('3789'),
        'image': 'assets/CEPILLOS/CEPILLOMODEL400.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50360465', // Media por defecto
        'codigoSapSuave': '50360464', // Código para textura suave
        'textura': 'Media', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Model 400 X3',
        'price': formatPrice('9661'),
        'image': 'assets/CEPILLOS/CEPILLOMODEL4003.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50360467', // Media por defecto
        'codigoSapSuave': '50360466', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Model 400 X5',
        'price': formatPrice('15154'),
        'image': 'assets/CEPILLOS/CEPILLOMODEL4005.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50360469', // Media por defecto
        'codigoSapSuave': '50360468', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Cuidado Total',
        'price': formatPrice('6401'),
        'image': 'assets/CEPILLOS/CEPILLOCUIDADOTOTAL.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50280022', // Media por defecto
        'codigoSapSuave': '50360468', // Código para textura suave
        'textura': 'Media',
        'hasTextureOptions': true,
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Cuidado Total X2',
        'price': formatPrice('10111'),
        'image': 'assets/CEPILLOS/CEPILLOCUIDADOTOTAL2.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50280026', // Media por defecto
        'textura': 'Media',
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
      {
        'title': 'Cepillo Cuidado Total X3',
        'price': formatPrice('13913'),
        'image': 'assets/CEPILLOS/CEPILLOCUIDADOTOTAL3.png',
        'rating': '5.0',
        'description':
            'Diseño especial para limpieza con brackets y aparatos ortodónticos',
        'codigoSap': '50360238', // Media por defecto
        'textura': 'Media',
        'category': 'Cepillos',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Diseño ortodóntico',
          'Limpieza brackets',
          'Cerdas especiales',
          'Acceso fácil'
        ],
        'specifications': {
          'Material': 'Nylon especializado',
          'Dureza': 'Suave',
        }
      },
    ];
  }

  Widget _buildCepillosTab() {
    final products = _getCepillosProducts();
    return _buildCategoryPage(
      'Cepillos Dentales',
      'Tecnología avanzada para tu higiene bucal diaria',
      products,
      primaryBlue,
    );
  }

  // ✅ CREMAS CON OPCIONES DE TEXTURA PERSONALIZADAS
  List<Map<String, dynamic>> _getCremasProducts() {
    return [
      {
        'title': 'Cremas Dental Cool Mint 30g',
        'price': formatPrice('2554'),
        'image': 'assets/CREMAS/COOLMINT30.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50340010', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Sin químicos dañinos', 'Sabor neutro'],
        'specifications': {
          'Contenido': '30g',
        }
      },
      {
        'title': 'Cremas Dental Cool Mint 70g',
        'price': formatPrice('2743'),
        'image': 'assets/CREMAS/COOLMINT70.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50340012', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Sin químicos dañinos', 'Sabor neutro'],
        'specifications': {
          'Contenido': '70g',
        }
      },
      {
        'title': 'Cremas Dental Cool Mint 120g',
        'price': formatPrice('5160'),
        'image': 'assets/CREMAS/COLMINT90.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50340025', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Alivio sensibilidad', 'Fórmula suave', 'Sin abrasivos'],
        'specifications': {
          'Contenido': '120g',
        }
      },
      {
        'title': 'Cremas Dental Cool Mint 7g + cepillo + protector',
        'price': formatPrice('4248'),
        'image': 'assets/CREMAS/COOLMINTCREMA.png',
        'rating': '4.7',
        'description':
            'Fórmula natural con extractos herbales para cuidado integral',
        'codigoSap': '50360371', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Extractos naturales',
          'Sin químicos',
          'Cuidado integral',
          'Sabor herbal'
        ],
        'specifications': {
          'Contenido': 'Cremas Dental Cool Mint 7g + cepillo + protector',
        }
      },
      {
        'title': 'Cremas Dental En Gel Cuidado Total 30g',
        'price': formatPrice('3053'),
        'image': 'assets/CREMAS/TOTAL30.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360074', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Protección anticaries',
          'Fortalece esmalte',
          'Sabor fresco'
        ],
        'specifications': {
          'Contenido': '30g',
        }
      },
      {
        'title': 'Cremas Dental En Gel Cuidado Total 70g',
        'price': formatPrice('4593'),
        'image': 'assets/CREMAS/TOTAL70.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360076', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Cuidado 5 en 1',
          'Blanquea y protege',
          'Fortalece encías',
          'Aliento fresco'
        ],
        'specifications': {
          'Contenido': '70g',
        }
      },
      {
        'title': 'Cremas Dental En Gel Cuidado Total 90g',
        'price': formatPrice('6150'),
        'image': 'assets/CREMAS/TOTAL90.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360137', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Cuidado 5 en 1',
          'Blanquea y protege',
          'Fortalece encías',
          'Aliento fresco'
        ],
        'specifications': {
          'Contenido': '90g',
        }
      },
      {
        'title': 'Cremas Dental En Gel Carbon Activado 30g',
        'price': formatPrice('5095'),
        'image': 'assets/CREMAS/CARBONACTIVADO30.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360150', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Blanquea y protege', 'Aliento fresco'],
        'specifications': {
          'Contenido': '30g',
        }
      },
      {
        'title': 'Cremas Dental En Gel Carbon Activado 70g',
        'price': formatPrice('8731'),
        'image': 'assets/CREMAS/CARBONACTIVADO70.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360152', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Blanquea y protege', 'Aliento fresco'],
        'specifications': {
          'Contenido': '70g',
        }
      },
      {
        'title': 'Cremas Dental En Gel Carbon Activado 90g',
        'price': formatPrice('10302'),
        'image': 'assets/CREMAS/CARBONACTIVADO90.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360154', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Cuidado 5 en 1',
          'Blanquea y protege',
          'Fortalece encías',
          'Aliento fresco'
        ],
        'specifications': {
          'Contenido': '90g',
        }
      },
      {
        'title': 'Cremas Dental Cuatriaccion Plus 30g',
        'price': formatPrice('1416'),
        'image': 'assets/CREMAS/CUATRI30.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360473', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Cuidado 5 en 1',
          'Blanquea y protege',
          'Fortalece encías',
          'Aliento fresco'
        ],
        'specifications': {
          'Contenido': '30g',
        }
      },
      {
        'title': 'Cremas Dental Cuatriaccion Plus 151.2g',
        'price': formatPrice('4375'),
        'image': 'assets/CREMAS/CUATRI151.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360471', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Cuidado 4 en 1',
          'Blanquea y protege',
          'Fortalece encías',
          'Aliento fresco'
        ],
        'specifications': {
          'Contenido': '151.2g',
        }
      },
      {
        'title': 'Cremas Dental Cuatriaccion Plus x3',
        'price': formatPrice('13816'),
        'image': 'assets/CREMAS/CREMA23.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360475', // Estándar por defecto
        'category': 'Cremas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Cuidado 4 en 1',
          'Blanquea y protege',
          'Fortalece encías',
          'Aliento fresco'
        ],
        'specifications': {
          'Contenido': 'x3',
        }
      },
    ];
  }

  Widget _buildCremasTab() {
    final products = _getCremasProducts();
    return _buildCategoryPage(
      'Cremas Dentales',
      'Fórmulas especializadas para cada necesidad bucal',
      products,
      const Color.fromARGB(255, 52, 123, 199),
    );
  }

  // ✅ ENJUAGUES CON OPCIONES DE CONCENTRACIÓN
  List<Map<String, dynamic>> _getEnjuaguesProducts() {
    return [
      {
        'title': 'Enjuague Bucal Caja x24',
        'price': formatPrice('75327'),
        'image': 'assets/ENJUAGES/TOTALMULTIPLE.png',
        'rating': '5.0',
        'description':
            'Protección antibacterial de 12 horas para aliento fresco',
        'codigoSap': '50360120', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Protección 12 horas',
          'Antibacterial',
          'Aliento fresco',
          'Sin alcohol'
        ],
        'specifications': {
          'Contenido': 'Caja x24',
        }
      },
      {
        'title': 'Enjuague Bucal Cuidado Total 180ml',
        'price': formatPrice('5160'),
        'image': 'assets/ENJUAGES/CUIDADOTOTAL180.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50340048', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Antibacterial', 'Aliento fresco'],
        'specifications': {
          'Contenido': '180ml',
        }
      },
      {
        'title': 'Enjuague Bucal Cuidado Total 300ml',
        'price': formatPrice('7224'),
        'image': 'assets/ENJUAGES/CUIDADOTOTAL300.png',
        'rating': '5.0',
        'description':
            'Cuidado especial para dientes sensibles con alivio prolongado',
        'codigoSap': '50360085', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Para sensibilidad',
          'Alivio prolongado',
          'Fórmula suave',
          'Sin ardor'
        ],
        'specifications': {
          'Contenido': '300ml',
        }
      },
      {
        'title': 'Enjuague Bucal Cuidado Total 500ml',
        'price': formatPrice('10114'),
        'image': 'assets/ENJUAGES/CUIDADOTOTAL500.png',
        'rating': '5.0',
        'description':
            'Blanqueamiento gradual con uso diario, resultados visibles',
        'codigoSap': '50340046', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Blanqueamiento gradual',
          'Resultados visibles',
          'Protege esmalte',
          'Uso diario'
        ],
        'specifications': {
          'Contenido': '500ml',
        }
      },
      {
        'title': 'Enjuague Bucal Cuidado Total 1000ml',
        'price': formatPrice('15171'),
        'image': 'assets/ENJUAGES/AMARRECUIDADOTOTAL.png',
        'rating': '5.0',
        'description': 'Fórmula natural con extractos de plantas medicinales',
        'codigoSap': '50340050', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Ingredientes naturales',
          'Extractos herbales',
          'Sin químicos',
          'Sabor natural'
        ],
        'specifications': {
          'Contenido': '1000ml',
        }
      },
      {
        'title': 'Oferta Enj 500 + Crema Cuidado Total 90g',
        'price': formatPrice('12175'),
        'image': 'assets/ENJUAGES/AMARRECUIDADOTOTAL.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360462', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': 'Oferta Enj 500 + Crema Cuidado Total 90g',
        }
      },
      {
        'title': 'Enjuague Bucal Zero 180ml',
        'price': formatPrice('4311'),
        'image': 'assets/ENJUAGES/ZERO180.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360369', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '180ml',
        }
      },
      {
        'title': 'Enjuague Bucal Zero 300ml',
        'price': formatPrice('6035'),
        'image': 'assets/ENJUAGES/ZERO300.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360087', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '300ml',
        }
      },
      {
        'title': 'Enjuague Bucal Zero 500ml',
        'price': formatPrice('8450'),
        'image': 'assets/ENJUAGES/ZERO500.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360089', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '500ml',
        }
      },
      {
        'title': 'Enjuague Bucal Zero 1000ml',
        'price': formatPrice('12675'),
        'image': 'assets/ENJUAGES/ZERO1000.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360430', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '1000ml',
        }
      },
      {
        'title': 'Enjuague Bucal 50ml',
        'price': formatPrice('2855'),
        'image': 'assets/ENJUAGES/FLUOR30.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50330019', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '50ml',
        }
      },
      {
        'title': 'Enjuague Bucal Caja x24',
        'price': formatPrice('57085'),
        'image': 'assets/ENJUAGES/FLUORMULTIPLE.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360119', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': 'Caja x24',
        }
      },
      {
        'title': 'Enjuague Bucal Fluor 180ml',
        'price': formatPrice('4775'),
        'image': 'assets/ENJUAGES/FLUOR180.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50340052', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '180ml',
        }
      },
      {
        'title': 'Enjuague Bucal Fluor 300ml',
        'price': formatPrice('6685'),
        'image': 'assets/ENJUAGES/FLUOR300.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360097', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '300ml',
        }
      },
      {
        'title': 'Enjuague Bucal Fluor 500ml',
        'price': formatPrice('9358'),
        'image': 'assets/ENJUAGES/FLUOR500.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360096', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '500ml',
        }
      },
      {
        'title': 'Enjuague Bucal Fluor 1000ml',
        'price': formatPrice('14044'),
        'image': 'assets/ENJUAGES/FLUOR1000.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50340056', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '1000ml',
        }
      },
      {
        'title': 'Enjuague Bucal Carbon Activado 180ml',
        'price': formatPrice('5760'),
        'image': 'assets/ENJUAGES/CARBON1.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360371', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '180ml',
        }
      },
      {
        'title': 'Enjuague Bucal Carbon Activado 500ml',
        'price': formatPrice('11627'),
        'image': 'assets/ENJUAGES/CARBONACTIVADO.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360246', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '500ml',
        }
      },
      {
        'title': 'Oferta Enj 500 + Crema Carbon 90g',
        'price': formatPrice('16999'),
        'image': 'assets/ENJUAGES/AMARRECARBON.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360464', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': 'Oferta Enj 500 + Crema Carbon 90g',
        }
      },
      {
        'title': 'Enjuague Bucal Cuidado Odontologico 300ML',
        'price': formatPrice('20825'),
        'image': 'assets/ENJUAGES/ODONTO.png',
        'rating': '5.0',
        'description': 'Cuida tu salud bucal con un sabor fresco y natural',
        'codigoSap': '50360456', // Regular por defecto
        'category': 'Enjuagues',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Especial niños',
          'Sabor agradable',
          'Sin alcohol',
          'Fórmula suave'
        ],
        'specifications': {
          'Contenido': '300ml',
        }
      },
    ];
  }

  Widget _buildEnjuaguesTab() {
    final products = _getEnjuaguesProducts();
    return _buildCategoryPage(
      'Enjuagues Bucales',
      'Protección completa y frescura duradera todo el día',
      products,
      const Color.fromARGB(255, 4, 58, 195),
    );
  }

  // ✅ SEDAS CON OPCIONES DE GROSOR
  List<Map<String, dynamic>> _getSedasProducts() {
    return [
      {
        'title': 'Seda Dental Cuidado Total Yerbabuena + Flúor 50m',
        'price': formatPrice('5160'),
        'image': 'assets/SEDAS/CUIDADOTOTAL50.png',
        'rating': '5.0',
        'description':
            'Deslizamiento suave entre dientes para limpieza profunda',
        'codigoSap': '50270013', // Estándar por defecto
        'category': 'Sedas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Deslizamiento suave',
          'Limpieza profunda',
          'Resistente',
          'Sabor menta'
        ],
        'specifications': {
          'Contenido': '50m',
          'Sabor': 'Yerbabuena',
          'Grosor': 'Estándar'
        }
      },
      {
        'title': 'Seda Dental Cuidado Total Menta + Flúor 30m',
        'price': formatPrice('4738'),
        'image': 'assets/SEDAS/1.png',
        'rating': '5.0',
        'description': 'Seda ultra fina para espacios interdentales reducidos',
        'codigoSap': '50270011', // Estándar por defecto
        'category': 'Sedas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Ultra fina',
          'Espacios pequeños',
          'Suave deslizamiento',
          'Sin sabor'
        ],
        'specifications': {
          'Contenido': '30m',
          'Sabor': 'Menta',
        }
      },
      {
        'title': 'Seda Dental Cuidado Total Yerbabuena + Flúor 30m',
        'price': formatPrice('4738'),
        'image': 'assets/SEDAS/CUIDADOTOTAL30.png',
        'rating': '5.0',
        'description': 'Se expande al contacto con saliva para mejor limpieza',
        'codigoSap': '50360206', // Estándar por defecto
        'category': 'Sedas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Expandible',
          'Mejor limpieza',
          'Adaptable',
          'Sabor fresco'
        ],
        'specifications': {
          'Contenido': '30m',
          'Sabor': 'Yerbabuena',
        }
      },
      {
        'title': 'Seda Dental Dis Individual Cera 100m',
        'price': formatPrice('4900'),
        'image': 'assets/SEDAS/SEDACONCERA100.png',
        'rating': '5.0',
        'description': 'Seda impregnada con flúor para protección adicional',
        'codigoSap': '50360475', // Estándar por defecto
        'category': 'Sedas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Con flúor',
          'Protección extra',
          'Fortalece esmalte',
          'Sabor menta'
        ],
        'specifications': {
          'Contenido': '100m',
          'Sabor': 'Sin sabor',
        }
      },
      {
        'title': 'Seda Dental Dis Individual Cera 200m',
        'price': formatPrice('7708'),
        'image': 'assets/SEDAS/SEDACONCERA200.png',
        'rating': '5.0',
        'description':
            'Formato cinta ancha para espacios interdentales amplios',
        'codigoSap': '50360360', // Estándar por defecto
        'category': 'Sedas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Formato cinta',
          'Espacios amplios',
          'Cobertura mayor',
          'Resistente'
        ],
        'specifications': {
          'Contenido': '200m',
          'Sabor': 'Sin sabor',
        }
      },
      {
        'title': 'Seda Dental Cuidado Total Yerbabuena + Flúor 230m',
        'price': formatPrice('11627'),
        'image': 'assets/SEDAS/FLUOR230.png',
        'rating': '5.0',
        'description':
            'Dispensador compacto ideal para llevar a cualquier lugar',
        'codigoSap': '50360204', // Estándar por defecto
        'category': 'Sedas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Portátil',
          'Dispensador compacto',
          'Fácil uso',
          'Higiénico'
        ],
        'specifications': {
          'Longitud': '30m',
          'Material': 'Nylon encerado',
          'Sabor': 'Menta suave',
          'Grosor': 'Estándar'
        }
      },
      {
        'title': 'Seda Dental Cuidado Total Menta + Flúor 230m',
        'price': formatPrice('11627'),
        'image': 'assets/SEDAS/FLUOR230.png',
        'rating': '5.0',
        'description':
            'Dispensador compacto ideal para llevar a cualquier lugar',
        'codigoSap': '50360208', // Estándar por defecto
        'category': 'Sedas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Portátil',
          'Dispensador compacto',
          'Fácil uso',
          'Higiénico'
        ],
        'specifications': {
          'Contenido': '230m',
          'Sabor': 'Menta',
        }
      },
      {
        'title': 'Seda Dental Con Cera Caja x12',
        'price': formatPrice('11757'),
        'image': 'assets/SEDAS/CAJAX12.png',
        'rating': '5.0',
        'description':
            'Dispensador compacto ideal para llevar a cualquier lugar',
        'codigoSap': '50360242', // Estándar por defecto
        'category': 'Sedas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Portátil',
          'Dispensador compacto',
          'Fácil uso',
          'Higiénico'
        ],
        'specifications': {
          'Contenido': 'Caja x12',
          'Sabor': 'Sin sabor',
        }
      },
      {
        'title': 'Ristra Seda Dental Con Cera X12',
        'price': formatPrice('18812'),
        'image': 'assets/SEDAS/FLUOR230.png',
        'rating': '5.0',
        'description':
            'Dispensador compacto ideal para llevar a cualquier lugar',
        'codigoSap': '50360363', // Estándar por defecto
        'category': 'Sedas',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Portátil',
          'Dispensador compacto',
          'Fácil uso',
          'Higiénico'
        ],
        'specifications': {
          'Contenido': 'Ristra Seda Dental Con Cera X12',
          'Sabor': 'Sin sabor',
        }
      },
    ];
  }

  Widget _buildSedasTab() {
    final products = _getSedasProducts();
    return _buildCategoryPage(
      'Sedas Dentales',
      'Limpieza interdental perfecta para sonrisa saludable',
      products,
      const Color.fromARGB(255, 4, 58, 195),
    );
  }

  // ✅ UNIVERSO NIÑOS CON OPCIONES DE EDAD
  List<Map<String, dynamic>> _getUniversoNinosProducts() {
    return [
      {
        'title': 'Cepillo Original Flex',
        'price': formatPrice('1280'),
        'image': 'assets/NIÑOS/ORIGINALFLEXNINOS.png',
        'rating': '5.0',
        'description': 'Cepillo con forma flexible para un mejor ajuste',
        'codigoSap': '50360407', // 3-6 años por defecto
        'codigoSapAlternativo': '50360408', // Código para 6-12 años
        'textura': 'Niño',
        'texturaAlternativa': 'Niña',
        'hasTextureOptions': true,
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Cepillo Original Flex'],
        'specifications': {
          'Contenido': 'Cepillo Original Flex',
          'Edad': '3-8 años',
        }
      },
      {
        'title': 'Cepillo Children',
        'price': formatPrice('1790'),
        'image': 'assets/NIÑOS/CHILDREN.png',
        'rating': '5.0',
        'description': 'cerdas ultra suaves',
        'codigoSap': '50360090', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Cepillo Children'],
        'specifications': {
          'Incluye': 'Solo cepillo',
        }
      },
      {
        'title': 'Cepillo Junior',
        'price': formatPrice('3114'),
        'image': 'assets/NIÑOS/CEPILLOJUNIOR.png',
        'rating': '5.0',
        'description': 'Pasta dental con delicioso sabor a fresa, sin flúor',
        'codigoSap': '50360108', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'specifications': {
          'Contenido': 'Cepillo Junior',
        }
      },
      {
        'title': 'Cepillo kids Bonite',
        'price': formatPrice('3527'),
        'image': 'assets/NIÑOS/CEPILLOBONITE.png',
        'rating': '5.0',
        'description': 'Cepillo kids Bonite',
        'codigoSap': '51370004', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {
          'Edad': '4-10 años',
        }
      },
      {
        'title': 'Kit Gold Niño',
        'price': formatPrice('5879'),
        'image': 'assets/NIÑOS/GOLNIÑO.png',
        'rating': '5.0',
        'description': 'Kit Gold Niño',
        'codigoSap': '50280130', // 3-6 años por defecto
        'codigoSapAlternativo': '50360200', // Código para 6-12 años
        'textura': 'Niño',
        'texturaAlternativa': 'Niña',
        'hasTextureOptions': true,
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Kit Gold Niño'],
        'specifications': {
          'Edad': '6+ años',
        }
      },
      {
        'title': 'Cepillo Baby Panda',
        'price': formatPrice('6401'),
        'image': 'assets/NIÑOS/BABYPANDA.png',
        'rating': '5.0',
        'description': 'Cepillo Baby Panda',
        'codigoSap': '50360203', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {
          'Edad': '0-3 años',
        }
      },
      {
        'title': 'Kit Junior',
        'price': formatPrice('6467'),
        'image': 'assets/NIÑOS/KITJUNIOR.png',
        'rating': '5.0',
        'description': 'Cepillo Baby Panda',
        'codigoSap': '50360089', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {}
      },
      {
        'title': 'Cepillo Space Duo Niño + Cremas 30gr',
        'price': formatPrice('10425'),
        'image': 'assets/NIÑOS/SPACEDUO.png',
        'rating': '5.0',
        'description': 'Cepillo Baby Panda',
        'codigoSap': '50280010', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {}
      },
      {
        'title': 'Kit viajero',
        'price': formatPrice('11627'),
        'image': 'assets/NIÑOS/KITNIÑOS.png',
        'rating': '5.0',
        'description': 'Kit viajero',
        'codigoSap': '50280053', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {
          'Contenido': 'Kit viajero',
        }
      },
      {
        'title': 'Crema dental tutti-frutti sin fluor 70g',
        'price': formatPrice('6205'),
        'image': 'assets/NIÑOS/CREMANINOS.png',
        'rating': '5.0',
        'description': 'Kit viajero',
        'codigoSap': '50340012', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {
          'Contenido': 'Crema dental tutti-frutti sin fluor 70g',
        }
      },
      {
        'title': 'Crema dental chicle sin fluor 70g',
        'price': formatPrice('6205'),
        'image': 'assets/NIÑOS/SINFLUOR.png',
        'rating': '5.0',
        'description': 'Kit viajero',
        'codigoSap': '50340014', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {
          'Contenido': 'Kit viajero',
        }
      },
      {
        'title': 'Enjuague bucal tutti frutti 300ml',
        'price': formatPrice('6467'),
        'image': 'assets/NIÑOS/TUTTI300.png',
        'rating': '5.0',
        'description': 'Kit viajero',
        'codigoSap': '50360107', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {
          'Contenido': 'Enjuague bucal tutti frutti 300ml',
        }
      },
      {
        'title': 'Enjuague bucal chicle 300ml',
        'price': formatPrice('6467'),
        'image': 'assets/NIÑOS/NIÑOS300.png',
        'rating': '5.0',
        'description': 'Kit viajero',
        'codigoSap': '50360106', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {
          'Contenido': 'Enjuague bucal chicle 300ml',
        }
      },
      {
        'title': 'Crema dental chicle sin fluor + Cep 30g',
        'price': formatPrice('4507'),
        'image': 'assets/NIÑOS/CREMADENTALCHICLE.png',
        'rating': '5.0',
        'description': 'Kit viajero',
        'codigoSap': '50360368', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {
          'Contenido': 'Crema dental chicle sin fluor + Cep 30g',
        }
      },
      {
        'title': 'Crema dental tutti-frutti sin fluor + Cep 30g',
        'price': formatPrice('4507'),
        'image': 'assets/NIÑOS/CREMASINFLUORNINA.png',
        'rating': '5.0',
        'description': 'Kit viajero',
        'codigoSap': '50360367', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {
          'Contenido': 'Crema dental tutti-frutti sin fluor + Cep 30g',
        }
      },
      {
        'title': 'Crema dental con fluor 30g + Cep junior',
        'price': formatPrice('4507'),
        'image': 'assets/NIÑOS/OFERTAJUNIOR.png',
        'rating': '5.0',
        'description': 'Kit viajero',
        'codigoSap': '50360474', // 3-6 años por defecto
        'category': 'Universo Niños',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': ['Tema universo'],
        'specifications': {
          'Contenido': 'Crema dental con fluor 30g + Cep junior',
        }
      }
    ];
  }

  Widget _buildUniversoNinosTab() {
    final products = _getUniversoNinosProducts();
    return _buildCategoryPage(
      'Universo de los Niños',
      'Higiene bucal divertida y educativa para los más pequeños',
      products,
      const Color.fromARGB(255, 5, 138, 187),
    );
  }

  // ✅ KITS CON OPCIONES DE TAMAÑO
  List<Map<String, dynamic>> _getKitsProducts() {
    return [
      {
        'title': 'Kit Economico',
        'price': formatPrice('11836'),
        'image': 'assets/KITS/VIAJERO.png',
        'rating': '5.0',
        'description':
            'Todo lo necesario para higiene bucal completa y profesional',
        'codigoSap': '50360209', // Básico por defecto
        'codigoSapAlternativo': '50360210', // Código para completo
        'textura': 'Media',
        'texturaAlternativa': 'Suave',
        'hasTextureOptions': true,
        'category': 'Kits',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Kit completo',
          'Calidad premium',
          'Estuche de viaje',
          'Productos profesionales'
        ],
        'specifications': {
          'Contenido': 'Kit Economico',
        }
      },
      {
        'title': 'Kit Higiene Viajero',
        'price': formatPrice('14174'),
        'image': 'assets/KITS/KITIGIENEORAL.png',
        'rating': '5.0',
        'description': 'Sistema completo de blanqueamiento para uso en casa',
        'codigoSap': '50340039', // Básico por defecto
        'codigoSapAlternativo': '50360376', // Código para completo
        'textura': 'Media',
        'texturaAlternativa': 'Suave',
        'hasTextureOptions': true,
        'category': 'Kits',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Blanqueamiento profesional',
          'Resultados visibles',
          'Uso en casa',
          'Seguro y efectivo'
        ],
        'specifications': {
          'Incluye': 'Gel blanqueador, cubetas, pasta',
        }
      },
      {
        'title': 'Kit Higiene Viajero Cuidado Total',
        'price': formatPrice('19465'),
        'image': 'assets/KITS/TOTALCERRADO.png',
        'rating': '5.0',
        'description':
            'Solución completa para dientes sensibles con alivio inmediato',
        'codigoSap': '50290010', // Básico por defecto
        'codigoSapAlternativo': '50290011', // Código para completo
        'textura': 'Media',
        'texturaAlternativa': 'Suave',
        'hasTextureOptions': true,
        'category': 'Kits',
        'disponible': true,
        'mensajeEstado': 'Producto disponible',
        'features': [
          'Para sensibilidad',
          'Alivio inmediato',
          'Protección 24h',
          'Fórmulas suaves'
        ],
        'specifications': {
          'Incluye': 'Pasta, enjuague, cepillo suave',
        }
      },
    ];
  }

  Widget _buildKitsTab() {
    final products = _getKitsProducts();
    return _buildCategoryPage(
      'Kits Especializados',
      'Soluciones completas para cada necesidad específica',
      products,
      darkBlue,
    );
  }

  Widget _buildCategoryPage(
    String title,
    String subtitle,
    List<Map<String, dynamic>> products,
    Color themeColor,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryHeader(title, subtitle, themeColor),
            SizedBox(height: context.responsiveHeight(30)),
            if (products.isNotEmpty)
              _buildFeaturedProduct(products.first, themeColor),
            SizedBox(height: context.responsiveHeight(40)),
            _buildProductsGrid(products, themeColor),
            SizedBox(height: context.responsiveHeight(40)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, String subtitle, Color themeColor) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: context.responsive(20)),
        padding: EdgeInsets.all(context.responsive(30)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeColor.withOpacity(0.1),
              themeColor.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(context.responsiveRadius),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: context.clampFont(20, 28, 24),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: context.responsive(8)),
            Text(
              subtitle,
              style: TextStyle(
                color: textSecondary,
                fontSize: context.clampFont(12, 16, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProduct(Map<String, dynamic> product, Color themeColor) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () => _showProductPreview(product),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: context.responsive(20)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.responsiveRadius),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildProductImage(product, themeColor, true),
              _buildProductInfo(product, themeColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(
      Map<String, dynamic> product, Color themeColor, bool isFeatured) {
    // ✅ VERIFICAR DISPONIBILIDAD PARA APLICAR EFECTO VISUAL
    final codigoSap = product['codigoSap'] ?? '';
    final disponible = product['disponible'] ?? true;

    return Hero(
      tag: 'product_${product['title']}',
      child: Container(
        height: isFeatured
            ? context.responsiveHeight(220)
            : context.responsiveHeight(150),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.responsiveRadius)),
          gradient: LinearGradient(
            colors: [themeColor.withOpacity(0.03), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(context.responsiveRadius)),
                child: ColorFiltered(
                  // ✅ APLICAR FILTRO GRIS SI NO ESTÁ DISPONIBLE
                  colorFilter: disponible
                      ? const ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.matrix([
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          0.5,
                          0,
                        ]),
                  child: Opacity(
                    opacity: disponible ? 1.0 : 0.4,
                    child: Image.asset(
                      product['image']!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeColor.withOpacity(0.1),
                                themeColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              color: themeColor,
                              size: context.responsive(50),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // ✅ OVERLAY DE NO DISPONIBLE
            if (!disponible)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(context.responsiveRadius)),
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive(16),
                        vertical: context.responsive(8),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius:
                            BorderRadius.circular(context.responsive(20)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block,
                            color: Colors.white,
                            size: context.responsive(16),
                          ),
                          SizedBox(width: context.responsive(8)),
                          Text(
                            'No Disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.clampFont(12, 16, 14),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (isFeatured)
              Positioned(
                top: context.responsive(16),
                left: context.responsive(16),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(12),
                    vertical: context.responsive(6),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [themeColor, themeColor.withOpacity(0.8)]),
                    borderRadius: BorderRadius.circular(context.responsive(15)),
                  ),
                  child: Text(
                    'DESTACADO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.clampFont(9, 12, 10),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: context.responsive(16),
              right: context.responsive(16),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(8),
                  vertical: context.responsive(6),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(context.responsive(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        color: Colors.amber, size: context.responsive(14)),
                    SizedBox(width: context.responsive(3)),
                    Text(
                      product['rating']!,
                      style: TextStyle(
                        fontSize: context.clampFont(10, 12, 11),
                        fontWeight: FontWeight.w700,
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

  Widget _buildProductInfo(Map<String, dynamic> product, Color themeColor) {
    // ✅ INTEGRACIÓN SAP: Obtener precio actualizado y estado de disponibilidad
    final codigoSap = product['codigoSap'] ?? '';
    final precioSAP =
        codigoSap.isNotEmpty ? _obtenerPrecioSAP(codigoSap) : null;
    final precioMostrar =
        (precioSAP != null && precioSAP != 'Precio no disponible')
            ? '\$${formatPrice(precioSAP)}'
            : product['price']!;
    final disponible = product['disponible'] ?? true;
    final mensajeEstado = product['mensajeEstado'] ?? 'Producto disponible';

    return Padding(
      padding: EdgeInsets.all(context.responsive(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product['title']!,
            style: TextStyle(
              color: disponible ? textPrimary : textSecondary,
              fontSize: context.clampFont(16, 22, 19),
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: context.responsive(8)),
          Text(
            product['description']!,
            style: TextStyle(
              color:
                  disponible ? textSecondary : textSecondary.withOpacity(0.6),
              fontSize: context.clampFont(12, 15, 13),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // ✅ MOSTRAR MENSAJE DE ESTADO SI NO ESTÁ DISPONIBLE
          if (!disponible) ...[
            SizedBox(height: context.responsive(8)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(12),
                vertical: context.responsive(6),
              ),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.responsive(12)),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red,
                    size: context.responsive(14),
                  ),
                  SizedBox(width: context.responsive(6)),
                  Flexible(
                    child: Text(
                      mensajeEstado,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: context.clampFont(10, 14, 12),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: context.responsive(16)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          precioMostrar,
                          style: TextStyle(
                            color: disponible ? themeColor : textSecondary,
                            fontSize: context.clampFont(18, 28, 24),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        // ✅ INTEGRACIÓN SAP: Mostrar indicador de carga de precios
                        if (_cargandoPrecios && codigoSap.isNotEmpty)
                          Padding(
                            padding:
                                EdgeInsets.only(left: context.responsive(8)),
                            child: SizedBox(
                              width: context.responsive(12),
                              height: context.responsive(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(themeColor),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (product['originalPrice'] != null &&
                        product['originalPrice']!.isNotEmpty)
                      Text(
                        product['originalPrice']!,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: context.clampFont(11, 16, 14),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildActionButton(
                    'Ver Detalles',
                    Icons.visibility_outlined,
                    themeColor.withOpacity(0.1),
                    themeColor,
                    () => _showProductPreview(product),
                  ),
                  SizedBox(width: context.responsive(8)),
                  _buildActionButton(
                    'Agregar',
                    disponible ? Icons.shopping_cart_outlined : Icons.block,
                    disponible ? themeColor : Colors.grey,
                    Colors.white,
                    disponible
                        ? () => _showTextureSelectionDialog(product)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color backgroundColor,
      Color textColor, VoidCallback? onTap) {
    final isEnabled = onTap != null;

    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? backgroundColor : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(context.responsive(12)),
        boxShadow: isEnabled && backgroundColor == primaryBlue
            ? [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.responsive(12)),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(16),
              vertical: context.responsive(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    color: isEnabled ? textColor : Colors.grey,
                    size: context.responsive(16)),
                SizedBox(width: context.responsive(4)),
                Text(
                  text,
                  style: TextStyle(
                    color: isEnabled ? textColor : Colors.grey,
                    fontSize: context.clampFont(11, 15, 13),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTextureSelectionDialog(Map<String, dynamic> product) {
    // ✅ VERIFICAR DISPONIBILIDAD ANTES DE MOSTRAR OPCIONES
    final codigoSap = product['codigoSap'] ?? '';
    final disponible = product['disponible'] ?? true;

    if (!disponible) {
      _addToCart(product); // Esto mostrará el mensaje de no disponible
      return;
    }

    // Si el producto no tiene opciones de textura, agregar directamente
    if (product['hasTextureOptions'] != true) {
      _addToCart(product);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(context.responsive(25)),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.responsive(25)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(context.responsive(24)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.responsive(16)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryBlue.withOpacity(0.1),
                                primaryBlue.withOpacity(0.05)
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(context.responsive(16)),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                color: primaryBlue,
                                size: context.responsive(32),
                              ),
                              SizedBox(height: context.responsive(12)),
                              Text(
                                'Seleccionar Opción',
                                style: TextStyle(
                                  fontSize: context.clampFont(18, 24, 20),
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              SizedBox(height: context.responsive(8)),
                              Text(
                                product['title']!,
                                style: TextStyle(
                                  fontSize: context.clampFont(14, 18, 16),
                                  color: textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: context.responsive(24)),
                        _buildEnhancedTextureOption(
                          product['category'] == 'Cepillos'
                              ? 'Media'
                              : product['textura']!,
                          _getTextureDescription(
                              product['category'] == 'Cepillos'
                                  ? 'Media'
                                  : product['textura']!,
                              product['category']),
                          product['codigoSap']!,
                          primaryBlue,
                          () {
                            final productWithTexture =
                                Map<String, dynamic>.from(product);
                            productWithTexture['textura'] =
                                product['category'] == 'Cepillos'
                                    ? 'Media'
                                    : product['textura'];
                            productWithTexture['codigoSap'] =
                                product['codigoSap'];
                            Navigator.pop(context);
                            _addToCart(productWithTexture);
                          },
                        ),
                        SizedBox(height: context.responsive(16)),
                        _buildEnhancedTextureOption(
                          product['category'] == 'Cepillos'
                              ? 'Suave'
                              : product['texturaAlternativa']!,
                          _getTextureDescription(
                              product['category'] == 'Cepillos'
                                  ? 'Suave'
                                  : product['texturaAlternativa']!,
                              product['category']),
                          product['category'] == 'Cepillos'
                              ? product['codigoSapSuave']!
                              : product['codigoSapAlternativo']!,
                          secondaryBlue,
                          () {
                            final productWithTexture =
                                Map<String, dynamic>.from(product);
                            productWithTexture['textura'] =
                                product['category'] == 'Cepillos'
                                    ? 'Suave'
                                    : product['texturaAlternativa'];
                            productWithTexture['codigoSap'] =
                                product['category'] == 'Cepillos'
                                    ? product['codigoSapSuave']
                                    : product['codigoSapAlternativo'];
                            Navigator.pop(context);
                            _addToCart(productWithTexture);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTextureDescription(String texture, String? category) {
    switch (category?.toLowerCase()) {
      case 'cepillos':
        return texture == 'Media'
            ? 'Limpieza efectiva para uso diario'
            : 'Cuidado delicado para encías sensibles';
      case 'cremas':
        return texture == 'Estándar'
            ? 'Fórmula balanceada para uso diario'
            : texture == 'Concentrado'
                ? 'Fórmula concentrada de acción intensiva'
                : 'Fórmula premium con ingredientes selectos';
      case 'enjuagues':
        return texture == 'Regular'
            ? 'Protección estándar para uso diario'
            : 'Fórmula de acción intensiva';
      case 'sedas':
        return texture == 'Estándar'
            ? 'Grosor ideal para la mayoría de espacios'
            : 'Diseño ultra delgado para espacios reducidos';
      case 'universo niños':
        return texture.contains('3-6')
            ? 'Diseñado especialmente para niños pequeños'
            : 'Ideal para niños en edad escolar';
      case 'kits':
        return texture == 'Básico'
            ? 'Productos esenciales para higiene completa'
            : 'Kit completo con productos premium';
      default:
        return 'Opción especializada para tus necesidades';
    }
  }

  Widget _buildEnhancedTextureOption(String texture, String description,
      String codigoSap, Color accentColor, VoidCallback onTap) {
    final precioSAP = _obtenerPrecioSAP(codigoSap);
    final disponible = _productoDisponible(codigoSap);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(context.responsive(16)),
        border: Border.all(
            color: disponible
                ? accentColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: disponible
                ? accentColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.responsive(16)),
          onTap: disponible ? onTap : null,
          child: Opacity(
            opacity: disponible ? 1.0 : 0.5,
            child: Padding(
              padding: EdgeInsets.all(context.responsive(20)),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.responsive(12)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: disponible
                            ? [
                                accentColor.withOpacity(0.2),
                                accentColor.withOpacity(0.1)
                              ]
                            : [
                                Colors.grey.withOpacity(0.2),
                                Colors.grey.withOpacity(0.1)
                              ],
                      ),
                      borderRadius:
                          BorderRadius.circular(context.responsive(12)),
                    ),
                    child: Icon(
                      disponible ? Icons.check_circle_outline : Icons.block,
                      color: disponible ? accentColor : Colors.grey,
                      size: context.responsive(24),
                    ),
                  ),
                  SizedBox(width: context.responsive(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                texture,
                                style: TextStyle(
                                  fontSize: context.clampFont(16, 20, 18),
                                  fontWeight: FontWeight.w800,
                                  color: disponible ? accentColor : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive(10),
                                vertical: context.responsive(4),
                              ),
                              decoration: BoxDecoration(
                                color: disponible
                                    ? accentColor.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                    context.responsive(8)),
                              ),
                              child: Text(
                                codigoSap,
                                style: TextStyle(
                                  fontSize: context.clampFont(10, 14, 12),
                                  fontWeight: FontWeight.w700,
                                  color: disponible ? accentColor : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.responsive(6)),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: context.clampFont(12, 16, 14),
                            color: disponible
                                ? textSecondary
                                : textSecondary.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // ✅ INTEGRACIÓN SAP: Mostrar precio SAP si está disponible
                        if (precioSAP != 'Precio no disponible')
                          Padding(
                            padding:
                                EdgeInsets.only(top: context.responsive(4)),
                            child: Text(
                              'Precio SAP: \$${formatPrice(precioSAP)}',
                              style: TextStyle(
                                fontSize: context.clampFont(10, 14, 12),
                                color: disponible ? primaryBlue : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        // ✅ MOSTRAR ESTADO SI NO ESTÁ DISPONIBLE
                        if (!disponible)
                          Padding(
                            padding:
                                EdgeInsets.only(top: context.responsive(4)),
                            child: Text(
                              _obtenerMensajeEstado(codigoSap),
                              style: TextStyle(
                                fontSize: context.clampFont(10, 14, 12),
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    disponible ? Icons.arrow_forward_ios_rounded : Icons.block,
                    color: disponible
                        ? accentColor.withOpacity(0.7)
                        : Colors.grey.withOpacity(0.7),
                    size: context.responsive(16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(
      List<Map<String, dynamic>> products, Color themeColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          double childAspectRatio = 0.75;

          if (constraints.maxWidth < 400) {
            crossAxisCount = 1;
            childAspectRatio = 0.85;
          } else if (constraints.maxWidth < 600) {
            crossAxisCount = 2;
            childAspectRatio = 0.75;
          } else if (constraints.maxWidth < 900) {
            crossAxisCount = 3;
            childAspectRatio = 0.8;
          } else {
            crossAxisCount = 4;
            childAspectRatio = 0.85;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: context.responsive(12),
              mainAxisSpacing: context.responsive(12),
              childAspectRatio: childAspectRatio,
            ),
            itemCount: products.length > 1 ? products.length - 1 : 0,
            itemBuilder: (context, index) {
              final productIndex = index + 1;
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  // ✅ FIX: Asegurar que value esté entre 0.0 y 1.0
                  final clampedValue = value.clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: 0.8 + (0.2 * clampedValue),
                    child: Opacity(
                      opacity: clampedValue,
                      child:
                          _buildProductCard(products[productIndex], themeColor),
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

  Widget _buildProductCard(Map<String, dynamic> product, Color themeColor) {
    // ✅ INTEGRACIÓN SAP: Obtener datos actualizados
    final codigoSap = product['codigoSap'] ?? '';
    final precioSAP =
        codigoSap.isNotEmpty ? _obtenerPrecioSAP(codigoSap) : null;
    final precioMostrar =
        (precioSAP != null && precioSAP != 'Precio no disponible')
            ? '\$${formatPrice(precioSAP)}'
            : product['price']!;
    final disponible = product['disponible'] ?? true;

    return GestureDetector(
      onTap: () => _showProductPreview(product),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.responsive(16)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildProductImage(product, themeColor, false),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(context.responsive(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['title']!,
                            style: TextStyle(
                              color: disponible ? textPrimary : textSecondary,
                              fontSize: context.clampFont(10, 15, 12),
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: context.responsive(4)),
                          Text(
                            product['description']!,
                            style: TextStyle(
                              color: disponible
                                  ? textSecondary
                                  : textSecondary.withOpacity(0.6),
                              fontSize: context.clampFont(8, 12, 10),
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                precioMostrar,
                                style: TextStyle(
                                  color:
                                      disponible ? themeColor : textSecondary,
                                  fontSize: context.clampFont(12, 18, 14),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (product['originalPrice'] != null &&
                                product['originalPrice']!.isNotEmpty)
                              Text(
                                product['originalPrice']!,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: context.clampFont(8, 12, 10),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: context.responsive(8)),
                        Container(
                          width: double.infinity,
                          height: context.responsive(32),
                          decoration: BoxDecoration(
                            gradient: disponible
                                ? LinearGradient(colors: [
                                    themeColor,
                                    themeColor.withOpacity(0.8)
                                  ])
                                : LinearGradient(colors: [
                                    Colors.grey,
                                    Colors.grey.withOpacity(0.8)
                                  ]),
                            borderRadius:
                                BorderRadius.circular(context.responsive(8)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(context.responsive(8)),
                              onTap: disponible
                                  ? () => _showTextureSelectionDialog(product)
                                  : null,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      disponible
                                          ? Icons.add_shopping_cart
                                          : Icons.block,
                                      color: Colors.white,
                                      size: context.responsive(14),
                                    ),
                                    SizedBox(width: context.responsive(4)),
                                    Text(
                                      disponible ? 'Agregar' : 'No Disponible',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: context.clampFont(10, 14, 12),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildBackButton() {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded,
          color: primaryBlue.withOpacity(0.8)),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Volver',
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, primaryBlue.withOpacity(0.9)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ORAL-PLUS',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // ✅ Mostrar información del usuario logueado
            if (_currentUser != null)
              Text(
                '${_currentUser!.nombre} - ${_currentUser!.documento}',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuperCuteCartButton() {
    return ListenableBuilder(
      listenable: _cartManager,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryBlue.withOpacity(0.1),
                primaryBlue.withOpacity(0.05),
                Colors.white.withOpacity(0.8)
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primaryBlue.withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 8,
                offset: const Offset(-2, -2),
                spreadRadius: -3,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              splashColor: primaryBlue.withOpacity(0.1),
              highlightColor: primaryBlue.withOpacity(0.05),
              onTap: () {
                HapticFeedback.lightImpact();
                _showCart();
              },
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: primaryBlue.withOpacity(0.85),
                        size: 22,
                      ),
                    ),
                    if (_cartManager.itemCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          constraints:
                              BoxConstraints(minWidth: 18, minHeight: 18),
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.orange[400]!,
                                Colors.orange[500]!
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${_cartManager.itemCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ✅ DIÁLOGO DE PREVISUALIZACIÓN CON SELECCIÓN DE TEXTURA
class ProductPreviewDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onAddToCart;
  final Map<String, Map<String, dynamic>> preciosSAP;
  final Map<String, Map<String, dynamic>> estadosSAP;

  const ProductPreviewDialog({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.preciosSAP,
    required this.estadosSAP,
  });

  @override
  State<ProductPreviewDialog> createState() => _ProductPreviewDialogState();
}

class _ProductPreviewDialogState extends State<ProductPreviewDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ✅ INTEGRACIÓN SAP: Obtener precio SAP
  String _obtenerPrecioSAP(String codigoSap) {
    if (widget.preciosSAP.containsKey(codigoSap)) {
      final precio = widget.preciosSAP[codigoSap]!['precio'];
      return sap.InvoiceService1.formatearPrecioSAP(precio);
    }
    return 'Precio no disponible';
  }

  // ✅ VERIFICAR DISPONIBILIDAD
  bool _productoDisponible(String codigoSap) {
    if (widget.estadosSAP.containsKey(codigoSap)) {
      final estado = widget.estadosSAP[codigoSap]!;
      final disponible = estado['disponible'] ?? true;
      final stock = estado['stock'] ?? 0;
      return disponible == true && (stock is num ? stock > 0 : true);
    }
    return true;
  }

  // ✅ FUNCIÓN PARA OBTENER MENSAJE DE ESTADO
  String _obtenerMensajeEstado(String codigoSap) {
    if (widget.estadosSAP.containsKey(codigoSap)) {
      final estado = widget.estadosSAP[codigoSap]!;
      final disponible = _productoDisponible(codigoSap);

      if (!disponible) {
        return estado['mensaje']?.toString() ?? 'Producto no disponible';
      }

      return sap.InvoiceService1.obtenerMensajeEstado(
          widget.estadosSAP[codigoSap]!);
    }
    return 'Producto disponible';
  }

  void _showTextureSelectionDialog(Map<String, dynamic> product) {
    // ✅ VERIFICAR DISPONIBILIDAD ANTES DE MOSTRAR OPCIONES
    final codigoSap = product['codigoSap'] ?? '';
    final disponible = _productoDisponible(codigoSap);

    if (!disponible) {
      widget.onAddToCart(product); // Mostrará mensaje
      return;
    }

    // Si no tiene opciones, agregar directamente
    if (product['hasTextureOptions'] != true) {
      widget.onAddToCart(product);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(context.responsive(25)),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.responsive(25)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(context.responsive(24)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.responsive(16)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryBlue.withOpacity(0.1),
                                primaryBlue.withOpacity(0.05)
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(context.responsive(16)),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                color: primaryBlue,
                                size: context.responsive(32),
                              ),
                              SizedBox(height: context.responsive(12)),
                              Text(
                                'Seleccionar Opción',
                                style: TextStyle(
                                  fontSize: context.clampFont(18, 24, 20),
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              SizedBox(height: context.responsive(8)),
                              Text(
                                product['title']!,
                                style: TextStyle(
                                  fontSize: context.clampFont(14, 18, 16),
                                  color: textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: context.responsive(24)),
                        _buildEnhancedTextureOption(
                          product['category'] == 'Cepillos'
                              ? 'Media'
                              : product['textura']!,
                          _getTextureDescription(
                              product['category'] == 'Cepillos'
                                  ? 'Media'
                                  : product['textura']!,
                              product['category']),
                          product['codigoSap']!,
                          primaryBlue,
                          () {
                            final productWithTexture =
                                Map<String, dynamic>.from(product);
                            productWithTexture['textura'] =
                                product['category'] == 'Cepillos'
                                    ? 'Media'
                                    : product['textura'];
                            productWithTexture['codigoSap'] =
                                product['codigoSap'];
                            Navigator.pop(context);
                            widget.onAddToCart(productWithTexture);
                          },
                        ),
                        SizedBox(height: context.responsive(16)),
                        _buildEnhancedTextureOption(
                          product['category'] == 'Cepillos'
                              ? 'Suave'
                              : product['texturaAlternativa']!,
                          _getTextureDescription(
                              product['category'] == 'Cepillos'
                                  ? 'Suave'
                                  : product['texturaAlternativa']!,
                              product['category']),
                          product['category'] == 'Cepillos'
                              ? product['codigoSapSuave']!
                              : product['codigoSapAlternativo']!,
                          secondaryBlue,
                          () {
                            final productWithTexture =
                                Map<String, dynamic>.from(product);
                            productWithTexture['textura'] =
                                product['category'] == 'Cepillos'
                                    ? 'Suave'
                                    : product['texturaAlternativa'];
                            productWithTexture['codigoSap'] =
                                product['category'] == 'Cepillos'
                                    ? product['codigoSapSuave']
                                    : product['codigoSapAlternativo'];
                            Navigator.pop(context);
                            widget.onAddToCart(productWithTexture);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTextureDescription(String texture, String? category) {
    switch (category?.toLowerCase()) {
      case 'cepillos':
        return texture == 'Media'
            ? 'Limpieza efectiva para uso diario'
            : 'Cuidado delicado para encías sensibles';
      case 'cremas':
        return texture == 'Estándar'
            ? 'Fórmula balanceada para uso diario'
            : texture == 'Concentrado'
                ? 'Fórmula concentrada de acción intensiva'
                : 'Fórmula premium con ingredientes selectos';
      case 'enjuagues':
        return texture == 'Regular'
            ? 'Protección estándar para uso diario'
            : 'Fórmula de acción intensiva';
      case 'sedas':
        return texture == 'Estándar'
            ? 'Grosor ideal para la mayoría de espacios'
            : 'Diseño ultra delgado para espacios reducidos';
      case 'universo niños':
        return texture.contains('3-6')
            ? 'Diseñado especialmente para niños pequeños'
            : 'Ideal para niños en edad escolar';
      case 'kits':
        return texture == 'Básico'
            ? 'Productos esenciales para higiene completa'
            : 'Kit completo con productos premium';
      default:
        return 'Opción especializada para tus necesidades';
    }
  }

  Widget _buildEnhancedTextureOption(String texture, String description,
      String codigoSap, Color accentColor, VoidCallback onTap) {
    final precioSAP = _obtenerPrecioSAP(codigoSap);
    final disponible = _productoDisponible(codigoSap);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(context.responsive(16)),
        border: Border.all(
            color: disponible
                ? accentColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: disponible
                ? accentColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.responsive(16)),
          onTap: disponible ? onTap : null,
          child: Opacity(
            opacity: disponible ? 1.0 : 0.5,
            child: Padding(
              padding: EdgeInsets.all(context.responsive(20)),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.responsive(12)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: disponible
                            ? [
                                accentColor.withOpacity(0.2),
                                accentColor.withOpacity(0.1)
                              ]
                            : [
                                Colors.grey.withOpacity(0.2),
                                Colors.grey.withOpacity(0.1)
                              ],
                      ),
                      borderRadius:
                          BorderRadius.circular(context.responsive(12)),
                    ),
                    child: Icon(
                      disponible ? Icons.check_circle_outline : Icons.block,
                      color: disponible ? accentColor : Colors.grey,
                      size: context.responsive(24),
                    ),
                  ),
                  SizedBox(width: context.responsive(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                texture,
                                style: TextStyle(
                                  fontSize: context.clampFont(16, 20, 18),
                                  fontWeight: FontWeight.w800,
                                  color: disponible ? accentColor : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive(10),
                                vertical: context.responsive(4),
                              ),
                              decoration: BoxDecoration(
                                color: disponible
                                    ? accentColor.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                    context.responsive(8)),
                              ),
                              child: Text(
                                codigoSap,
                                style: TextStyle(
                                  fontSize: context.clampFont(10, 14, 12),
                                  fontWeight: FontWeight.w700,
                                  color: disponible ? accentColor : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.responsive(6)),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: context.clampFont(12, 16, 14),
                            color: disponible
                                ? textSecondary
                                : textSecondary.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // ✅ INTEGRACIÓN SAP: Mostrar precio SAP si está disponible
                        if (precioSAP != 'Precio no disponible')
                          Padding(
                            padding:
                                EdgeInsets.only(top: context.responsive(4)),
                            child: Text(
                              'Precio SAP: \$${formatPrice(precioSAP)}',
                              style: TextStyle(
                                fontSize: context.clampFont(10, 14, 12),
                                color: disponible ? primaryBlue : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        // ✅ MOSTRAR ESTADO SI NO ESTÁ DISPONIBLE
                        if (!disponible)
                          Padding(
                            padding:
                                EdgeInsets.only(top: context.responsive(4)),
                            child: Text(
                              _obtenerMensajeEstado(codigoSap),
                              style: TextStyle(
                                fontSize: context.clampFont(10, 14, 12),
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    disponible ? Icons.arrow_forward_ios_rounded : Icons.block,
                    color: disponible
                        ? accentColor.withOpacity(0.7)
                        : Colors.grey.withOpacity(0.7),
                    size: context.responsive(16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ INTEGRACIÓN SAP: Obtener datos actualizados del producto
    final codigoSap = widget.product['codigoSap'] ?? '';
    final precioSAP =
        codigoSap.isNotEmpty ? _obtenerPrecioSAP(codigoSap) : null;
    final precioMostrar =
        (precioSAP != null && precioSAP != 'Precio no disponible')
            ? '\$${formatPrice(precioSAP)}'
            : widget.product['price']!;
    final disponible = widget.product['disponible'] ?? true;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(context.responsive(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.responsiveRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.responsiveRadius),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(child: _buildContent(precioMostrar, disponible)),
                    _buildFooter(disponible),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(context.responsive(20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue.withOpacity(0.1), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Vista Previa del Producto',
              style: TextStyle(
                fontSize: context.clampFont(18, 24, 20),
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: EdgeInsets.all(context.responsive(8)),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.responsive(12)),
              ),
              child: Icon(
                Icons.close,
                color: textSecondary,
                size: context.responsive(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String precioMostrar, bool disponible) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.responsive(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(),
          SizedBox(height: context.responsive(24)),
          _buildProductDetails(precioMostrar, disponible),
          SizedBox(height: context.responsive(20)),
          _buildFeatures(),
          SizedBox(height: context.responsive(20)),
          _buildSpecifications(),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    final disponible = widget.product['disponible'] ?? true;

    return Hero(
      tag: 'product_${widget.product['title']}',
      child: Container(
        height: context.responsiveHeight(250),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue.withOpacity(0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(context.responsive(16)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.responsive(16)),
          child: Stack(
            children: [
              ColorFiltered(
                colorFilter: disponible
                    ? const ColorFilter.mode(
                        Colors.transparent, BlendMode.multiply)
                    : const ColorFilter.matrix([
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0.5,
                        0,
                      ]),
                child: Opacity(
                  opacity: disponible ? 1.0 : 0.4,
                  child: Image.asset(
                    widget.product['image']!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryBlue.withOpacity(0.1),
                              primaryBlue.withOpacity(0.05)
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            color: primaryBlue,
                            size: context.responsive(80),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (!disponible)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(context.responsive(16)),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(20),
                          vertical: context.responsive(12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius:
                              BorderRadius.circular(context.responsive(25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block,
                              color: Colors.white,
                              size: context.responsive(20),
                            ),
                            SizedBox(width: context.responsive(12)),
                            Text(
                              'Producto No Disponible',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.clampFont(14, 18, 16),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildProductDetails(String precioMostrar, bool disponible) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(8),
                vertical: context.responsive(4),
              ),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.responsive(8)),
              ),
              child: Text(
                widget.product['codigoSap'] ?? 'N/A',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: context.clampFont(10, 14, 12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.star_rounded,
                    color: Colors.amber, size: context.responsive(16)),
                SizedBox(width: context.responsive(4)),
                Text(
                  widget.product['rating'] ?? '5.0',
                  style: TextStyle(
                    fontSize: context.clampFont(12, 16, 14),
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: context.responsive(16)),
        Text(
          widget.product['title']!,
          style: TextStyle(
            fontSize: context.clampFont(20, 28, 24),
            fontWeight: FontWeight.w900,
            color: disponible ? textPrimary : textSecondary,
            height: 1.2,
          ),
        ),
        SizedBox(height: context.responsive(12)),
        Text(
          widget.product['description']!,
          style: TextStyle(
            fontSize: context.clampFont(14, 18, 16),
            color: disponible ? textSecondary : textSecondary.withOpacity(0.6),
            height: 1.5,
          ),
        ),
        SizedBox(height: context.responsive(20)),
        Text(
          precioMostrar,
          style: TextStyle(
            fontSize: context.clampFont(24, 32, 28),
            fontWeight: FontWeight.w900,
            color: disponible ? primaryBlue : textSecondary,
          ),
        ),
        // ✅ Add message to clarify IVA has been removed
        SizedBox(height: context.responsive(8)),
        Text(
          'Precio Con IVA (19%)',
          style: TextStyle(
            fontSize: context.clampFont(12, 16, 14),
            color: textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        // ✅ Existing unavailable message
        if (!disponible) ...[
          SizedBox(height: context.responsive(16)),
          Container(
            padding: EdgeInsets.all(context.responsive(16)),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.responsive(12)),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.red,
                  size: context.responsive(20),
                ),
                SizedBox(width: context.responsive(12)),
                Expanded(
                  child: Text(
                    widget.product['mensajeEstado'] ?? 'Producto no disponible',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: context.clampFont(14, 18, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeatures() {
    final features = widget.product['features'] as List<String>? ?? [];
    if (features.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Características Principales',
          style: TextStyle(
            fontSize: context.clampFont(16, 20, 18),
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        SizedBox(height: context.responsive(12)),
        ...features.map((feature) => Padding(
              padding: EdgeInsets.only(bottom: context.responsive(8)),
              child: Row(
                children: [
                  Container(
                    width: context.responsive(6),
                    height: context.responsive(6),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius:
                          BorderRadius.circular(context.responsive(3)),
                    ),
                  ),
                  SizedBox(width: context.responsive(12)),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: context.clampFont(12, 16, 14),
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildSpecifications() {
    final specs =
        widget.product['specifications'] as Map<String, String>? ?? {};
    if (specs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Especificaciones Técnicas',
          style: TextStyle(
            fontSize: context.clampFont(16, 20, 18),
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        SizedBox(height: context.responsive(12)),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(context.responsive(12)),
          ),
          child: Column(
            children: specs.entries
                .map((entry) => Container(
                      padding: EdgeInsets.all(context.responsive(16)),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: context.clampFont(12, 16, 14),
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: context.clampFont(12, 16, 14),
                                color: textSecondary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool disponible) {
    return Container(
      padding: EdgeInsets.all(context.responsive(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: context.responsive(50),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.responsive(25)),
                border:
                    Border.all(color: primaryBlue.withOpacity(0.3), width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(context.responsive(25)),
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: Text(
                      'Cerrar',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: context.clampFont(14, 18, 16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: context.responsive(16)),
          Expanded(
            flex: 2,
            child: Container(
              height: context.responsive(50),
              decoration: BoxDecoration(
                gradient: disponible
                    ? LinearGradient(
                        colors: [primaryBlue, primaryBlue.withOpacity(0.8)])
                    : LinearGradient(
                        colors: [Colors.grey, Colors.grey.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(context.responsive(25)),
                boxShadow: disponible
                    ? [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(context.responsive(25)),
                  onTap: disponible
                      ? () {
                          if (widget.product['hasTextureOptions'] == true) {
                            _showTextureSelectionDialog(widget.product);
                          } else {
                            widget.onAddToCart(widget.product);
                            Navigator.of(context).pop();
                          }
                        }
                      : null,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          disponible ? Icons.add_shopping_cart : Icons.block,
                          color: Colors.white,
                          size: context.responsive(20),
                        ),
                        SizedBox(width: context.responsive(8)),
                        Text(
                          disponible ? 'Agregar al Carrito' : 'No Disponible',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.clampFont(14, 18, 16),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ CARRITO SIMPLIFICADO
class CartBottomSheet extends StatefulWidget {
  const CartBottomSheet({super.key});

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final CartManager _cartManager = CartManager();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.responsive(25)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCartItems()),
            _buildCartFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(context.responsive(20)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.responsive(12)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.1),
                  primaryBlue.withOpacity(0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(context.responsive(12)),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              color: primaryBlue,
              size: context.responsive(24),
            ),
          ),
          SizedBox(width: context.responsive(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Carrito',
                  style: TextStyle(
                    fontSize: context.clampFont(18, 24, 20),
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                ListenableBuilder(
                  listenable: _cartManager,
                  builder: (context, child) {
                    return Text(
                      '${_cartManager.itemCount} productos',
                      style: TextStyle(
                        fontSize: context.clampFont(12, 16, 14),
                        color: textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: EdgeInsets.all(context.responsive(8)),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.responsive(12)),
              ),
              child: Icon(
                Icons.close,
                color: textSecondary,
                size: context.responsive(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListenableBuilder(
      listenable: _cartManager,
      builder: (context, child) {
        if (_cartManager.items.isEmpty) {
          return _buildEmptyCart();
        }
        return ListView.builder(
          padding: EdgeInsets.all(context.responsive(20)),
          itemCount: _cartManager.items.length,
          itemBuilder: (context, index) {
            final item = _cartManager.items[index];
            return _buildCartItem(item);
          },
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.responsive(40)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.1),
                  Colors.grey.withOpacity(0.05)
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: context.responsive(60),
              color: Colors.grey,
            ),
          ),
          SizedBox(height: context.responsive(24)),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: context.clampFont(18, 24, 20),
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          SizedBox(height: context.responsive(8)),
          Text(
            'Agrega productos para continuar',
            style: TextStyle(
              fontSize: context.clampFont(14, 18, 16),
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    double precioNumerico =
        double.tryParse(item.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    double subtotalReal = precioNumerico * item.quantity;
    double ivaItem = subtotalReal * 0.19;
    double subtotalItem = subtotalReal - ivaItem;
    double totalItem = subtotalReal;

    return Container(
      margin: EdgeInsets.only(bottom: context.responsive(16)),
      padding: EdgeInsets.all(context.responsive(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.responsive(16)),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.responsive(60),
            height: context.responsive(60),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.1),
                  primaryBlue.withOpacity(0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(context.responsive(12)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.responsive(12)),
              child: Image.asset(
                item.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.shopping_bag_rounded,
                    color: primaryBlue,
                    size: context.responsive(30),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: context.responsive(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: context.clampFont(14, 18, 16),
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.textura != null) ...[
                  SizedBox(height: context.responsive(4)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(8),
                      vertical: context.responsive(2),
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(context.responsive(8)),
                    ),
                    child: Text(
                      item.textura!,
                      style: TextStyle(
                        fontSize: context.clampFont(10, 14, 12),
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: context.responsive(8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal:',
                            style: TextStyle(
                              fontSize: context.clampFont(12, 16, 14),
                              color: textSecondary,
                            )),
                        Text('\$${subtotalItem.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: context.clampFont(12, 16, 14),
                              color: textSecondary,
                            )),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('IVA (19%):',
                            style: TextStyle(
                              fontSize: context.clampFont(12, 16, 14),
                              color: textSecondary,
                            )),
                        Text('\$${ivaItem.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: context.clampFont(12, 16, 14),
                              color: textSecondary,
                            )),
                      ],
                    ),
                    Divider(height: context.responsive(8), thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:',
                            style: TextStyle(
                              fontSize: context.clampFont(14, 18, 16),
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                            )),
                        Text('\$${totalItem.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: context.clampFont(14, 18, 16),
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                            )),
                      ],
                    ),
                    SizedBox(height: context.responsive(8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [_buildQuantityControls(item)],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(CartItem item) {
    return Row(
      children: [
        _buildQuantityButton(
          Icons.remove,
          () => _cartManager.updateQuantity(item.id, item.quantity - 1),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: context.responsive(12)),
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(16),
            vertical: context.responsive(8),
          ),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.responsive(8)),
          ),
          child: Text(
            '${item.quantity}',
            style: TextStyle(
              fontSize: context.clampFont(14, 18, 16),
              fontWeight: FontWeight.w700,
              color: primaryBlue,
            ),
          ),
        ),
        _buildQuantityButton(
          Icons.add,
          () => _cartManager.updateQuantity(item.id, item.quantity + 1),
        ),
      ],
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: context.responsive(32),
      height: context.responsive(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, primaryBlue.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(context.responsive(8)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.responsive(8)),
          onTap: onTap,
          child: Icon(
            icon,
            color: Colors.white,
            size: context.responsive(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCartFooter() {
  return ListenableBuilder(
    listenable: _cartManager,
    builder: (context, child) {
      return Container(
        padding: EdgeInsets.all(context.responsive(16)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(context.responsive(16)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.05),
                      secondaryBlue.withOpacity(0.05)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(context.responsive(16)),
                  border: Border.all(
                      color: primaryBlue.withOpacity(0.1), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal:',
                            style: TextStyle(
                              fontSize: context.clampFont(12, 16, 14),
                              color: textSecondary,
                            )),
                        Text(
                          '\$${_cartManager.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: context.clampFont(12, 16, 14),
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.responsive(8)),
                    Divider(height: context.responsive(16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:',
                            style: TextStyle(
                              fontSize: context.clampFont(16, 20, 18),
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            )),
                        Text(
                          '\$${_cartManager.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: context.clampFont(18, 24, 20),
                            fontWeight: FontWeight.w900,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.responsive(16)),
              Container(
                width: double.infinity,
                height: context.responsive(50),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: (_cartManager.totalAmount >= 120000)
                        ? [primaryBlue, secondaryBlue]
                        : [Colors.grey, Colors.grey.shade400], // 🔹 Cambia color si no alcanza
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(context.responsive(25)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(context.responsive(25)),
                    onTap: () {
                      HapticFeedback.mediumImpact();

                      if (_cartManager.totalAmount >= 120000) {
                        _processCheckout();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "El monto mínimo para proceder al pago es \$120.000",
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: context.responsive(20),
                          ),
                          SizedBox(width: context.responsive(8)),
                          Text(
                            'Proceder al Pago',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.clampFont(14, 18, 16),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _processCheckout() {
  Navigator.of(context).pop();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => CheckoutScreen(cartItems: _cartManager.items),
    ),
  );
}

}
