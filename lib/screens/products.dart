import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:ui';

// Colores elegantes estilo Apple con más variaciones
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

// Modelo para items del carrito
class CartItem {
  final String id;
  final String title;
  final String price;
  final String originalPrice;
  final String image;
  final String description;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.image,
    required this.description,
    this.quantity = 1,
  });

  double get numericPrice {
    return double.tryParse(price.replaceAll('\$', '').replaceAll(',', '')) ?? 0.0;
  }

  double get totalPrice {
    return numericPrice * quantity;
  }
}

// Gestor del carrito
class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addItem(Map<String, dynamic> product) {
    final existingIndex = _items.indexWhere((item) => item.id == product['title']);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(
        id: product['title']!,
        title: product['title']!,
        price: product['price']!,
        originalPrice: product['originalPrice']!,
        image: product['image']!,
        description: product['description']!,
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
  const ProductsTab({Key? key}) : super(key: key);

  @override
  _ProductsTabState createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _heroController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heroAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _waveAnimation;

  final CartManager _cartManager = CartManager();

  // Helper method to clamp opacity values
  double _clampOpacity(double opacity) {
    return opacity.clamp(0.0, 1.0);
  }

  // Helper method to clamp scale values
  double _clampScale(double scale) {
    return scale.clamp(0.1, 2.0);
  }

  // Helper method to safely clamp animation values
  double _safeAnimationValue(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return value.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    
    // Controlador para pestañas
    _tabController = TabController(length: 6, vsync: this);
    
    // Inicializar controladores de animación
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Configurar animaciones con valores seguros
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutExpo,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _heroAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeInOutBack,
    ));

    _floatingAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOutSine,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    // Lanzar animaciones
    _startEnhancedAnimations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _heroController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _startEnhancedAnimations() async {
    // Animaciones continuas
    _floatingController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _waveController.repeat();

    // Animaciones de entrada secuenciales
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) _heroController.forward();
  }

  // Función para abrir el enlace de compra
  Future<void> _launchPurchaseUrl() async {
    const url = 'https://oral-plus.com/comprar.html';
    try {
      if (await canLaunch(url)) {
        await launch(url, forceSafariVC: false, forceWebView: false);
      } else {
        throw 'No se pudo abrir $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir el enlace de compra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Función para agregar al carrito
  void _addToCart(Map<String, dynamic> product) {
    _cartManager.addItem(product);
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
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Agregado al Carrito',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        product['title']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(milliseconds: 2000),
          elevation: 10,
        ),
      );
    }
  }

  // Función para mostrar el carrito
  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CartBottomSheet(),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    const animationDuration = Duration(milliseconds: 800);
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Detalles del producto",
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutExpo,
        );
        
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
            child: _buildProductDetailModal(product, animationDuration),
          ),
        );
      },
    );
  }

  Widget _buildProductDetailModal(Map<String, dynamic> product, Duration animationDuration) {
    return StatefulBuilder(
      builder: (context, setState) {
        final scrollController = ScrollController();
        bool isScrolled = false;
        
        scrollController.addListener(() {
          if (scrollController.offset > 20 && !isScrolled) {
            setState(() => isScrolled = true);
          } else if (scrollController.offset <= 20 && isScrolled) {
            setState(() => isScrolled = false);
          }
        });
        
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.transparent,
                ),
                clipBehavior: Clip.antiAlias,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: -5,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header con animación de glassmorphism
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 70,
                          decoration: BoxDecoration(
                            color: isScrolled
                                ? Colors.white.withOpacity(0.9)
                                : Colors.transparent,
                            boxShadow: isScrolled
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : [],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Detalles del Producto',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    _buildCloseButton(context),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Contenido scrollable
                        Expanded(
                          child: CustomScrollView(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              // Imagen del producto con animación
                              SliverToBoxAdapter(
                                child: _buildProductImageHero(product, animationDuration),
                              ),
                              
                              // Información del producto
                              SliverToBoxAdapter(
                                child: _buildProductInfo(product, animationDuration),
                              ),
                              
                              // Características del producto
                              SliverToBoxAdapter(
                                child: _buildProductFeatures(animationDuration),
                              ),
                              
                              // Espacio para el botón flotante
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 100),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Botón flotante de agregar al carrito
              FloatingAddToCartButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addToCart(product);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.05),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.close,
            size: 16,
            color: textPrimary.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImageHero(Map<String, dynamic> product, Duration animationDuration) {
    return Container(
      height: 350,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Fondo con gradiente
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryBlue.withOpacity(0.05),
                    Colors.white.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          
          // Círculos decorativos animados
          Positioned(
            top: 30,
            left: 30,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 2000),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: _clampScale(_safeAnimationValue(value)),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryBlue.withOpacity(0.05),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            bottom: 20,
            right: 40,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 2500),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: _clampScale(_safeAnimationValue(value)),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: secondaryBlue.withOpacity(0.05),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Imagen del producto con animación
          Center(
            child: TweenAnimationBuilder<double>(
              duration: animationDuration,
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: _clampScale(_safeAnimationValue(value)),
                  child: Hero(
                    tag: 'product_${product['title']}',
                    child: Image.asset(
                      product['image']!,
                      height: 280,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 280,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryBlue.withOpacity(0.1),
                                primaryBlue.withOpacity(0.05)
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_rounded,
                            color: primaryBlue,
                            size: 60,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Etiqueta de descuento
          Positioned(
            top: 20,
            right: 20,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: _clampScale(_safeAnimationValue(value)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      'OFERTA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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

  Widget _buildProductInfo(Map<String, dynamic> product, Duration animationDuration) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con animación
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              final safeValue = _safeAnimationValue(value);
              return Opacity(
                opacity: _clampOpacity(safeValue),
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - safeValue)),
                  child: Text(
                    product['title']!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          // Rating
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              final safeValue = _safeAnimationValue(value);
              return Opacity(
                opacity: _clampOpacity(safeValue),
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - safeValue)),
                  child: Row(
                    children: [
                      ...List.generate(5, (index) {
                        double rating = double.tryParse(product['rating']!) ?? 0.0;
                        return Icon(
                          index < rating.floor()
                              ? Icons.star
                              : (index < rating)
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        product['rating']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '(124 reseñas)',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Descripción
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              final safeValue = _safeAnimationValue(value);
              return Opacity(
                opacity: _clampOpacity(safeValue),
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - safeValue)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product['description']!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Precios
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1400),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              final safeValue = _safeAnimationValue(value);
              return Opacity(
                opacity: _clampOpacity(safeValue),
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - safeValue)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.05),
                          secondaryBlue.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Precio especial',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  product['price']!,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: primaryBlue,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Text(
                                    product['originalPrice']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red[400],
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: greenColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: greenColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: greenColor,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'En stock',
                                style: TextStyle(
                                  color: greenColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductFeatures(Duration animationDuration) {
    final features = [
      {'icon': Icons.verified_outlined, 'title': 'Calidad Premium', 'desc': 'Materiales de primera calidad'},
      {'icon': Icons.security_outlined, 'title': 'Garantía', 'desc': '30 días de garantía de satisfacción'},
      {'icon': Icons.support_agent_outlined, 'title': 'Soporte', 'desc': 'Asistencia técnica especializada'},
    ];
    
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          final safeValue = _safeAnimationValue(value);
          return Opacity(
            opacity: _clampOpacity(safeValue),
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - safeValue)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Características',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...features.asMap().entries.map((entry) {
                    final index = entry.key;
                    final feature = entry.value;
                    
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 800 + (index * 200)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, child) {
                        final safeValue = _safeAnimationValue(value);
                        return Opacity(
                          opacity: _clampOpacity(safeValue),
                          child: Transform.translate(
                            offset: Offset(20 * (1 - safeValue), 0),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      feature['icon'] as IconData,
                                      color: primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          feature['title'] as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          feature['desc'] as String,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassmorphicAppBar(),
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
                  Colors.white,
                ],
              ),
            ),
            child: Opacity(
              opacity: _clampOpacity(_safeAnimationValue(_fadeAnimation.value)),
              child: Column(
                children: [
                  const SizedBox(height: kToolbarHeight + 40),
                  // Tabs con glassmorphism mejorados
                  _buildGlassmorphicTabs(),
                  // Contenido con animaciones mejoradas
                  Expanded(
                    child: TabBarView(
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
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // HEADER MEJORADO CON DISEÑO MÁS ELEGANTE
  PreferredSizeWidget _buildGlassmorphicAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 10),
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.85),
                    Colors.white.withOpacity(0.75),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      centerTitle: false,
                      leading: _buildEnhancedBackButton(),
                      title: _buildEnhancedTitle(),
                      actions: [
                        _buildCartButton(),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedBackButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _clampScale(_safeAnimationValue(_scaleAnimation.value)),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 8,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                splashColor: primaryBlue.withOpacity(0.1),
                highlightColor: primaryBlue.withOpacity(0.05),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: textPrimary.withOpacity(0.8),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return ListenableBuilder(
          listenable: _cartManager,
          builder: (context, child) {
            return Transform.scale(
              scale: _clampScale(_safeAnimationValue(_pulseAnimation.value)),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      blurRadius: 8,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showCart();
                    },
                    splashColor: primaryBlue.withOpacity(0.1),
                    highlightColor: primaryBlue.withOpacity(0.05),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Stack(
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: textPrimary.withOpacity(0.8),
                            size: 18,
                          ),
                          if (_cartManager.itemCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryBlue, primaryBlue.withOpacity(0.8)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '${_cartManager.itemCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
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
          },
        );
      },
    );
  }

  // TÍTULO MEJORADO CON DISEÑO MÁS ELEGANTE
  Widget _buildEnhancedTitle() {
    return AnimatedBuilder(
      animation: _heroAnimation,
      builder: (context, child) {
        final safeValue = _safeAnimationValue(_heroAnimation.value);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - safeValue)),
          child: Opacity(
            opacity: _clampOpacity(safeValue),
            child: Row(
              children: [
                // Logo mejorado con efectos premium
                Hero(
                  tag: 'logo',
                  child: AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatingAnimation.value * 0.3),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryBlue,
                                secondaryBlue,
                                primaryBlue.withOpacity(0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.0, 0.5, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.4),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: secondaryBlue.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.9),
                                blurRadius: 10,
                                offset: const Offset(-3, -3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 18),
                // Texto mejorado con tipografía premium
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ORAL-PLUS',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black12,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'SALUD Y BELLEZA EN TU SONRISA',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TABS MEJORADOS CON DISEÑO MÁS ELEGANTE
  Widget _buildGlassmorphicTabs() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _clampScale(_safeAnimationValue(_scaleAnimation.value)),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 35,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: primaryBlue.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 15,
                  offset: const Offset(-8, -8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(8, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryBlue,
                        secondaryBlue,
                        primaryBlue.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: secondaryBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: textSecondary.withOpacity(0.8),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  onTap: (index) {
                    HapticFeedback.selectionClick();
                  },
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
      },
    );
  }

  // CEPILLOS TAB
  Widget _buildCepillosTab() {
    final cepillosProducts = [
      {
        'title': 'Cepillo Dental Original Ristro',
        'price': '\$14,109',
        'originalPrice': '\$18,500',
        'image': 'assets/CEPILLOS/RISTRACEPILLO.png',
        'rating': '5.0',
        'description': 'Cerdas suaves con tecnología avanzada para una limpieza profunda y cuidado de las encías'
      },
      {
        'title': 'Calipso kit',
        'price': '\$25,000',
        'originalPrice': '\$35,000',
        'image': 'assets/CEPILLOS/CALIPSOKIT.png',
        'rating': '5.0',
        'description': 'Kit completo con tecnología sónica de última generación para higiene bucal profesional'
      },
      {
        'title': 'Cepillo Calipso',
        'price': '\$5,072',
        'originalPrice': '\$7,200',
        'image': 'assets/CEPILLOS/CEPILLOCALIPSO.png',
        'rating': '5.0',
        'description': 'Diseño ergonómico profesional con cerdas de alta calidad'
      },
      {
        'title': 'Cepillo Interdental Premium',
        'price': '\$3,200',
        'originalPrice': '\$4,500',
        'image': 'assets/CEPILLOS/CEPILLOWAVINESS.png',
        'rating': '5.0',
        'description': 'Limpieza especializada entre dientes para una higiene completa'
      },
      {
        'title': 'Ristra Cepillo',
        'price': '\$2,800',
        'originalPrice': '\$3,800',
        'image': 'assets/CEPILLOS/RISTRACEPILLO.png',
        'rating': '5.0',
        'description': 'Cepillo portátil y eficiente para uso diario'
      },
      {
        'title': 'Cepillo Model',
        'price': '\$1,900',
        'originalPrice': '\$2,500',
        'image': 'assets/CEPILLOS/CEPMODEL400.png',
        'rating': '5.0',
        'description': 'Opción sustentable y biodegradable para el cuidado del medio ambiente'
      },
      {
        'title': 'Cepillo Teen',
        'price': '\$1,900',
        'originalPrice': '\$2,500',
        'image': 'assets/CEPILLOS/CEPILLOTEEN.png',
        'rating': '5.0',
        'description': 'Diseñado especialmente para adolescentes con cerdas suaves'
      },
      {
        'title': 'Cepillo Model x5',
        'price': '\$1,900',
        'originalPrice': '\$2,500',
        'image': 'assets/CEPILLOS/CEPMODELX5.png',
        'rating': '5.0',
        'description': 'Pack de 5 cepillos sustentables para toda la familia'
      },
      {
        'title': 'Kit Dacopta',
        'price': '\$1,900',
        'originalPrice': '\$2,500',
        'image': 'assets/CEPILLOS/KITDAKOPTA.png',
        'rating': '5.0',
        'description': 'Kit completo con accesorios para higiene bucal integral'
      },
    ];

    return _buildCategoryPage(
      'Cepillos Dentales',
      'Tecnología avanzada para tu higiene bucal diaria',
      cepillosProducts,
      Transform.scale(
        scale: 2.2,
        child: Image.asset(
          'assets/ENCABEZADOS/CEPILLOEN.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.cleaning_services,
              color: Colors.white,
              size: 38,
            );
          },
        ),
      ),
      primaryBlue,
    );
  }

  // CREMAS TAB
  Widget _buildCremasTab() {
    final cremasProducts = [
      {
        'title': 'Carbon Activado 30g',
        'price': '\$4,800',
        'originalPrice': '\$6,800',
        'image': 'assets/CREMAS/CARBONACTIVADO30.png',
        'rating': '5.0',
        'description': 'Blanqueamiento profesional en casa con carbón activado natural'
      },
      {
        'title': 'Carbon Activado 70g',
        'price': '\$3,500',
        'originalPrice': '\$4,800',
        'image': 'assets/CREMAS/CARBONACTIVADO70.png',
        'rating': '5.0',
        'description': 'Protección especial para dientes sensibles con fórmula suave'
      },
      {
        'title': 'Crema Dental Herbal Natural',
        'price': '\$2,900',
        'originalPrice': '\$3,900',
        'image': 'assets/CREMAS/CARBONACTIVADO90.png',
        'rating': '5.0',
        'description': 'Ingredientes 100% naturales para cuidado integral'
      },
      {
        'title': 'Coolmint 30g',
        'price': '\$5,200',
        'originalPrice': '\$7,000',
        'image': 'assets/CREMAS/COOLMINT30.png',
        'rating': '5.0',
        'description': 'Detox y blanqueamiento natural con frescura mentolada'
      },
      {
        'title': 'Coolmint 70g',
        'price': '\$2,200',
        'originalPrice': '\$3,000',
        'image': 'assets/CREMAS/COOLMINT70.png',
        'rating': '5.0',
        'description': 'Sabor refrescante sin flúor para uso diario'
      },
      {
        'title': 'Cuatri acción 30g',
        'price': '\$4,100',
        'originalPrice': '\$5,500',
        'image': 'assets/CREMAS/CUATRI30.png',
        'rating': '5.0',
        'description': 'Cuidado especializado para encías con 4 acciones en 1'
      },
    ];

    return _buildCategoryPage(
      'Cremas Dentales',
      'Fórmulas especializadas para cada necesidad bucal',
      cremasProducts,
      Transform.scale(
        scale: 2.2,
        child: Image.asset(
          'assets/ENCABEZADOS/CREMA.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.colorize,
              color: Colors.white,
              size: 38,
            );
          },
        ),
      ),
      const Color.fromARGB(255, 52, 123, 199),
    );
  }

  // ENJUAGUES TAB
  Widget _buildEnjuaguesTab() {
    final enjuaguesProducts = [
      {
        'title': 'Amarre Cuidado Total',
        'price': '\$6,500',
        'originalPrice': '\$8,800',
        'image': 'assets/ENJUAGES/AMARRECUIDADOTOTAL.png',
        'rating': '5.0',
        'description': 'Protección antibacterial de 12 horas para aliento fresco'
      },
      {
        'title': 'Cuidado Total 180ml',
        'price': '\$5,800',
        'originalPrice': '\$7,500',
        'image': 'assets/ENJUAGES/CUIDADOTOTAL180.png',
        'rating': '5.0',
        'description': 'Blanqueamiento gradual y seguro con protección completa'
      },
      {
        'title': 'Cuidado Total 300ml',
        'price': '\$4,200',
        'originalPrice': '\$5,600',
        'image': 'assets/ENJUAGES/CUIDADOTOTAL300.png',
        'rating': '5.0',
        'description': 'Fórmula suave y natural para uso diario familiar'
      },
      {
        'title': 'Cuidado Total 500ml',
        'price': '\$5,500',
        'originalPrice': '\$7,200',
        'image': 'assets/ENJUAGES/CUIDADOTOTAL500.png',
        'rating': '5.0',
        'description': 'Efecto calmante y reparador para encías sensibles'
      },
      {
        'title': 'Cuidado Total 1000ml',
        'price': '\$3,800',
        'originalPrice': '\$5,000',
        'image': 'assets/ENJUAGES/CUIDADOTOTAL1000.png',
        'rating': '5.0',
        'description': 'Presentación familiar económica para uso prolongado'
      },
      {
        'title': 'Fluor 30ml',
        'price': '\$7,200',
        'originalPrice': '\$9,500',
        'image': 'assets/ENJUAGES/FLUOR30.png',
        'rating': '5.0',
        'description': 'Reparación nocturna con flúor para fortalecimiento dental'
      },
    ];

    return _buildCategoryPage(
      'Enjuagues Bucales',
      'Protección completa y frescura duradera todo el día',
      enjuaguesProducts,
      Transform.scale(
        scale: 2.2,
        child: Image.asset(
          'assets/ENCABEZADOS/ENJUAGE.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.water_drop,
              color: Colors.white,
              size: 38,
            );
          },
        ),
      ),
      const Color.fromARGB(255, 4, 58, 195),
    );
  }

  // SEDAS TAB
  Widget _buildSedasTab() {
    final sedasProducts = [
      {
        'title': 'Seda Dental Clásica',
        'price': '\$2,500',
        'originalPrice': '\$3,200',
        'image': 'assets/SEDAS/1.png',
        'rating': '5.0',
        'description': 'Deslizamiento suave entre dientes para limpieza profunda'
      },
      {
        'title': 'Seda Cuidado Total 230m',
        'price': '\$3,100',
        'originalPrice': '\$4,000',
        'image': 'assets/SEDAS/CUIDADOTOTAL230.png',
        'rating': '5.0',
        'description': 'Se expande para mejor limpieza interdental'
      },
      {
        'title': 'Seda Yerbabuena Fluor 230m',
        'price': '\$2,200',
        'originalPrice': '\$2,900',
        'image': 'assets/SEDAS/TOTALYERBABUENAFLUOR230M.png',
        'rating': '5.0',
        'description': 'Frescura mentolada duradera con protección anticaries'
      },
      {
        'title': 'Cuidado Total Yerbabuena 50m',
        'price': '\$3,800',
        'originalPrice': '\$4,800',
        'image': 'assets/SEDAS/CUIDADOTOTALYERBABUENAFLUOR50M.png',
        'rating': '5.0',
        'description': 'Detox y limpieza profunda con sabor refrescante'
      },
      {
        'title': 'Seda Dental Biodegradable',
        'price': '\$2,800',
        'originalPrice': '\$3,500',
        'image': 'assets/SEDAS/SEDACONCERA10.png',
        'rating': '5.0',
        'description': 'Opción ecológica y sustentable con cera natural'
      },
      {
        'title': 'Hilo Dental con Flúor',
        'price': '\$2,600',
        'originalPrice': '\$3,300',
        'image': 'assets/SEDAS/SEDA12.png',
        'rating': '5.0',
        'description': 'Protección anticaries adicional durante la limpieza'
      },
    ];

    return _buildCategoryPage(
      'Sedas Dentales',
      'Limpieza interdental perfecta para sonrisa saludable',
      sedasProducts,
      Transform.scale(
        scale: 2.2,
        child: Image.asset(
          'assets/ENCABEZADOS/Seda.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.linear_scale,
              color: Colors.white,
              size: 38,
            );
          },
        ),
      ),
      const Color.fromARGB(255, 4, 58, 195),
    );
  }

  // UNIVERSO DE LOS NIÑOS TAB
  Widget _buildUniversoNinosTab() {
    final ninosProducts = [
      {
        'title': 'Kit Dental Niños Superhéroes',
        'price': '\$8,500',
        'originalPrice': '\$11,000',
        'image': 'assets/NIÑOS/NIÑOS300.png',
        'rating': '5.0',
        'description': 'Kit completo con cepillo, pasta y vaso temático de superhéroes'
      },
      {
        'title': 'Cepillo Eléctrico Musical',
        'price': '\$12,000',
        'originalPrice': '\$15,500',
        'image': 'assets/NIÑOS/TUTTI300.png',
        'rating': '5.0',
        'description': 'Cepillo eléctrico con música y luces LED para hacer divertido el cepillado'
      },
      {
        'title': 'Pasta Dental Sin Flúor',
        'price': '\$2,800',
        'originalPrice': '\$3,600',
        'image': 'assets/NIÑOS/NIÑOSVARIOS.png',
        'rating': '5.0',
        'description': 'Sabores frutales naturales seguros para niños pequeños'
      },
      {
        'title': 'Enjuague Niños Princesas',
        'price': '\$4,200',
        'originalPrice': '\$5,400',
        'image': 'assets/NIÑOS/CEPILLOJUNIOR.png',
        'rating': '5.0',
        'description': 'Enjuague suave sin alcohol con diseño de princesas'
      },
      {
        'title': 'Cepillo Cerdas Extra Suaves',
        'price': '\$3,500',
        'originalPrice': '\$4,500',
        'image': 'assets/NIÑOS/SINFLUOR70G.png',
        'rating': '5.0',
        'description': 'Diseño ergonómico infantil con cerdas ultra suaves'
      },
      {
        'title': 'Kit Educativo Higiene Bucal',
        'price': '\$6,800',
        'originalPrice': '\$8,800',
        'image': 'assets/NIÑOS/OFERTAJUNIOR.png',
        'rating': '5.0',
        'description': 'Kit completo con libro educativo para enseñar higiene bucal'
      },
    ];

    return _buildCategoryPage(
      'Universo de los Niños',
      'Higiene bucal divertida y educativa para los más pequeños',
      ninosProducts,
      Transform.scale(
        scale: 2.2,
        child: Image.asset(
          'assets/ENCABEZADOS/NIÑOS.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.child_care,
              color: Colors.white,
              size: 38,
            );
          },
        ),
      ),
      const Color.fromARGB(255, 5, 138, 187),
    );
  }

  // KITS TAB
  Widget _buildKitsTab() {
    final kitsProducts = [
      {
        'title': 'Kit Dental Completo Premium',
        'price': '\$18,500',
        'originalPrice': '\$24,000',
        'image': 'assets/KITS/VIAJERO.png',
        'rating': '5.0',
        'description': 'Todo lo necesario para higiene bucal completa y profesional'
      },
      {
        'title': 'Kit de Viaje Ejecutivo',
        'price': '\$8,200',
        'originalPrice': '\$10,500',
        'image': 'assets/KITS/KITIGIENEORAL.png',
        'rating': '5.0',
        'description': 'Kit compacto y elegante perfecto para viajes de negocios'
      },
      {
        'title': 'Kit Blanqueamiento Profesional',
        'price': '\$15,800',
        'originalPrice': '\$20,000',
        'image': 'assets/KITS/TOTALCERRADO.png',
        'rating': '5.0',
        'description': 'Resultados profesionales de blanqueamiento en la comodidad del hogar'
      },
      {
        'title': 'Kit Familiar Completo',
        'price': '\$22,500',
        'originalPrice': '\$28,000',
        'image': 'assets/KITS/VIAJERO.png',
        'rating': '5.0',
        'description': 'Solución completa para toda la familia con productos especializados'
      },
    ];

    return _buildCategoryPage(
      'Kits Especializados',
      'Soluciones completas para cada necesidad específica',
      kitsProducts,
      Transform.scale(
        scale: 2.2,
        child: Image.asset(
          'assets/ENCABEZADOS/KIT.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.inventory,
              color: Colors.white,
              size: 38,
            );
          },
        ),
      ),
      darkBlue,
    );
  }

  Widget _buildCategoryPage(
    String title,
    String subtitle,
    List<Map<String, dynamic>> products,
    Widget iconWidget,
    Color themeColor,
  ) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryHeader(title, subtitle, iconWidget, themeColor),
                const SizedBox(height: 30),
                _buildFeaturedProduct(products.first, themeColor),
                const SizedBox(height: 40),
                _buildProductsGrid(products, themeColor),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader(
      String title, String subtitle, Widget iconWidget, Color themeColor) {
    return AnimatedBuilder(
      animation: _heroAnimation,
      builder: (context, child) {
        final safeValue = _safeAnimationValue(_heroAnimation.value);
        return Transform.translate(
          offset: Offset(0, 50 * (1 - safeValue)),
          child: Opacity(
            opacity: _clampOpacity(safeValue),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(30),
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
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColor,
                          themeColor.withOpacity(0.8)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: iconWidget,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 14,
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
        );
      },
    );
  }

  Widget _buildFeaturedProduct(Map<String, dynamic> product, Color themeColor) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _clampScale(_safeAnimationValue(_scaleAnimation.value)),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                // Imagen destacada
                Hero(
                  tag: 'featured_${product['title']}',
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(30)),
                      gradient: LinearGradient(
                        colors: [
                          themeColor.withOpacity(0.05),
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(30)),
                            child: Image.asset(
                              product['image']!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        themeColor.withOpacity(0.1),
                                        themeColor.withOpacity(0.05)
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag_rounded,
                                    color: themeColor,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  themeColor,
                                  themeColor.withOpacity(0.8)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Text(
                              'DESTACADO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  product['rating']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
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
                // Información del producto
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title']!,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product['description']!,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['price']!,
                                style: TextStyle(
                                  color: themeColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                product['originalPrice']!,
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      themeColor.withOpacity(0.1),
                                      themeColor.withOpacity(0.05)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: themeColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _showProductDetails(product),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      child: Text(
                                        'Ver Detalles',
                                        style: TextStyle(
                                          color: themeColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      themeColor,
                                      themeColor.withOpacity(0.8)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: themeColor.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _addToCart(product),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.shopping_cart_outlined,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Agregar',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid(
    List<Map<String, dynamic>> products,
    Color themeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length - 1, // Exclude first item (featured)
        itemBuilder: (context, index) {
          final productIndex = index + 1; // Skip first item
          return AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 800 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: _clampScale(_safeAnimationValue(value)),
                    child: _buildProductCard(products[productIndex], themeColor),
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
    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: [
                      themeColor.withOpacity(0.05),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      product['image']!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeColor.withOpacity(0.1),
                                themeColor.withOpacity(0.05)
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.medical_services,
                            color: themeColor,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Información del producto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['title']!,
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          product['description']!,
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              product['price']!,
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                product['originalPrice']!,
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeColor,
                                themeColor.withOpacity(0.8)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _addToCart(product),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_shopping_cart,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Agregar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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
}

// Botón flotante para agregar al carrito
class FloatingAddToCartButton extends StatefulWidget {
  final VoidCallback onPressed;

  const FloatingAddToCartButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  _FloatingAddToCartButtonState createState() => _FloatingAddToCartButtonState();
}

class _FloatingAddToCartButtonState extends State<FloatingAddToCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          bottom: 30,
          left: 24,
          right: 24,
          child: Transform.scale(
            scale: _scaleAnimation.value.clamp(0.1, 2.0),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3 * _shadowAnimation.value),
                    blurRadius: 20 * _shadowAnimation.value,
                    offset: Offset(0, 10 * _shadowAnimation.value),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onPressed();
                  },
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Agregar al Carrito',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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
          ),
        );
      },
    );
  }
}

// Widget del carrito de compras
class CartBottomSheet extends StatefulWidget {
  @override
  _CartBottomSheetState createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final CartManager _cartManager = CartManager();

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.9),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: -10,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mi Carrito',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        ListenableBuilder(
                          listenable: _cartManager,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryBlue.withOpacity(0.1),
                                    secondaryBlue.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primaryBlue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${_cartManager.itemCount} productos',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de productos
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _cartManager,
                      builder: (context, child) {
                        if (_cartManager.items.isEmpty) {
                          return _buildEmptyCart();
                        }
                        
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _cartManager.items.length,
                          itemBuilder: (context, index) {
                            final item = _cartManager.items[index];
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildCartItem(item, index),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  
                  // Footer con total y botón de compra
                  ListenableBuilder(
                    listenable: _cartManager,
                    builder: (context, child) {
                      if (_cartManager.items.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return _buildCartFooter();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.1),
                  secondaryBlue.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Agrega productos para comenzar tu compra',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, secondaryBlue],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Text(
                    'Explorar Productos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

  Widget _buildCartItem(CartItem item, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Imagen del producto
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.05),
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        item.image,
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
                            child: const Icon(
                              Icons.shopping_bag_rounded,
                              color: primaryBlue,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Información del producto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.price,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: primaryBlue,
                                  ),
                                ),
                                Text(
                                  item.originalPrice,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[400],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Controles de cantidad
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildQuantityButton(
                                    icon: Icons.remove,
                                    onTap: () {
                                      if (item.quantity > 1) {
                                        _cartManager.updateQuantity(item.id, item.quantity - 1);
                                      } else {
                                        _cartManager.removeItem(item.id);
                                      }
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  _buildQuantityButton(
                                    icon: Icons.add,
                                    onTap: () {
                                      _cartManager.updateQuantity(item.id, item.quantity + 1);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Botón eliminar
                  GestureDetector(
                    onTap: () => _cartManager.removeItem(item.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red[400],
                        size: 20,
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
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 16,
          color: primaryBlue,
        ),
      ),
    );
  }

  Widget _buildCartFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Resumen de precios
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.05),
                  secondaryBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryBlue.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                    ),
                    Text(
                      '\$${_cartManager.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Envío:',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                    ),
                    Text(
                      'GRATIS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: greenColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '\$${_cartManager.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Botón de compra
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
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
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showCheckoutDialog();
                },
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Proceder al Pago',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
    );
  }

  void _showCheckoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: greenColor, size: 28),
            SizedBox(width: 12),
            Text('¡Pedido Confirmado!'),
          ],
        ),
        content: const Text(
          'Tu pedido ha sido procesado exitosamente. Recibirás un email de confirmación en breve.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Cerrar carrito
              _cartManager.clearCart(); // Limpiar carrito
            },
            child: const Text(
              'Continuar Comprando',
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}