import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class ShoppingLoadingScreen extends StatefulWidget {
  final Widget destination;
  
  const ShoppingLoadingScreen({Key? key, required this.destination}) : super(key: key);

  @override
  _ShoppingLoadingScreenState createState() => _ShoppingLoadingScreenState();
}

class _ShoppingLoadingScreenState extends State<ShoppingLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _itemsController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  
  late Animation<double> _bagScaleAnimation;
  late Animation<double> _bagSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _itemsFloatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<Color?> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    
    _primaryController = AnimationController(
      duration: Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _itemsController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: Duration(milliseconds: 2500),
      vsync: this,
    );

    // Animación principal del bolso con curva más suave
    _bagScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _bagSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    // Animación del texto más elegante
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Items flotantes más suaves
    _itemsFloatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _itemsController, curve: Curves.easeInOut),
    );
    
    // Efecto de pulso suave
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Progreso suave
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    // Animación de color del gradiente
    _gradientAnimation = ColorTween(
      begin: Color(0xFF1E88E5),
      end: Color(0xFF42A5F5),
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _startAnimations();
  }

  void _startAnimations() async {
    // Iniciar animaciones en secuencia
    _primaryController.forward();
    
    await Future.delayed(Duration(milliseconds: 800));
    _itemsController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _progressController.forward();
    
    await Future.delayed(Duration(milliseconds: 2800));
    
    // Transición suave al destino
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.destination,
        transitionDuration: Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: SlideTransition(
              position: Tween<Offset>(begin: Offset(0.0, 0.1), end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _itemsController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E88E5),
      body: AnimatedBuilder(
        animation: Listenable.merge([_gradientAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E88E5),
                  _gradientAnimation.value ?? Color(0xFF42A5F5),
                  Color(0xFF64B5F6),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Contenedor principal del bolso con sombra elegante
                  AnimatedBuilder(
                    animation: Listenable.merge([_bagScaleAnimation, _bagSlideAnimation, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _bagSlideAnimation.value),
                        child: Transform.scale(
                          scale: _bagScaleAnimation.value * _pulseAnimation.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: Offset(0, 15),
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 20,
                                  offset: Offset(0, -5),
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Icono principal del bolso
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 70,
                                  color: Color(0xFF1E88E5),
                                ),
                                
                                // Items flotantes mejorados
                                ...List.generate(4, (index) => 
                                  AnimatedBuilder(
                                    animation: _itemsFloatAnimation,
                                    builder: (context, child) {
                                      final angle = _itemsFloatAnimation.value * 2 * math.pi + (index * math.pi / 2);
                                      final radius = 25.0;
                                      final colors = [
                                        Color(0xFFFF6B35),
                                        Color(0xFF4CAF50),
                                        Color(0xFFF44336),
                                        Color(0xFF9C27B0),
                                      ];
                                      
                                      return Positioned(
                                        top: 70 + (radius * math.sin(angle)),
                                        left: 70 + (radius * math.cos(angle)),
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: colors[index],
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colors[index].withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
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
                    },
                  ),
                  
                  SizedBox(height: 50),
                  
                  // Texto con animación elegante
                  AnimatedBuilder(
                    animation: _textFadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textFadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _textFadeAnimation.value)),
                          child: Column(
                            children: [
                              Text(
                                'Cargando Productos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Preparando tu catálogo...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Indicador de progreso personalizado
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: 200 * _progressAnimation.value,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Indicador circular sutil
                  AnimatedBuilder(
                    animation: _itemsFloatAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}