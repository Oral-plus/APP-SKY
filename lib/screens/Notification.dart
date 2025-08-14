import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> noticias = const [
    {
      'titulo': 'Revolución en el Cuidado Dental: Nuevo Enjuague Sin Alcohol',
      'fecha': '8 Agosto 2025',
      'categoria': 'INNOVACIÓN',
      'tiempoLectura': '3 min',
      'descripcion':
          'Nuestra nueva fórmula suave para encías sensibles proporciona limpieza profunda sin irritación. Ideal para adultos y niños mayores de 6 años.',
      'contenidoCompleto':
          'La industria del cuidado dental ha dado un paso revolucionario con el lanzamiento de nuestro nuevo enjuague bucal sin alcohol. Esta innovadora fórmula combina la efectividad de los enjuagues tradicionales con la suavidad que requieren las encías sensibles.\n\nDesarrollado tras años de investigación, este producto contiene aloe vera natural y xylitol, ingredientes que no solo proporcionan una limpieza profunda, sino que también fortalecen el esmalte dental y previenen la formación de caries.\n\nLos estudios clínicos han demostrado una reducción del 95% en la irritación de encías comparado con fórmulas tradicionales con alcohol, manteniendo la misma efectividad antibacteriana.',
      'imagen':
          'https://images.unsplash.com/photo-1588776814546-4443c5f3a0f1?auto=format&fit=crop&w=1200&q=80',
      'destacada': true,
    },
    {
      'titulo': 'Promoción Especial: 2x1 en Cremas Dentales Premium',
      'fecha': '15 Agosto 2025',
      'categoria': 'PROMOCIONES',
      'tiempoLectura': '2 min',
      'descripcion':
          'Durante todo agosto, aprovecha nuestra oferta especial en pastas dentales profesionales. Tres variedades disponibles hasta agotar existencias.',
      'contenidoCompleto':
          'Este mes de agosto trae consigo una oportunidad única para renovar tu rutina de cuidado dental. Nuestra promoción 2x1 incluye tres variedades de pastas dentales profesionales: blanqueadora avanzada, anti-sarro con flúor activo y fórmula especial para dientes sensibles.\n\nCada una de estas fórmulas ha sido desarrollada con tecnología de vanguardia y ingredientes de la más alta calidad. La pasta blanqueadora utiliza micropartículas que remueven manchas sin dañar el esmalte, mientras que la fórmula anti-sarro previene la acumulación de placa bacteriana.\n\nLa oferta es válida en todas nuestras sucursales y tienda en línea hasta agotar existencias.',
      'imagen':
          'https://images.unsplash.com/photo-1606813902916-9b35e5b93210?auto=format&fit=crop&w=1200&q=80',
      'destacada': false,
    },
    {
      'titulo': 'Campaña Educativa Llegará a 5,000 Estudiantes',
      'fecha': '20 Agosto 2025',
      'categoria': 'SALUD PÚBLICA',
      'tiempoLectura': '4 min',
      'descripcion':
          'Iniciativa de salud bucal escolar incluye charlas educativas, demostraciones prácticas y kits gratuitos para estudiantes de primaria.',
      'contenidoCompleto':
          'Nuestra campaña de salud bucal escolar representa el compromiso más ambicioso hasta la fecha en educación dental infantil. Durante los próximos tres meses, visitaremos 50 instituciones educativas para llegar a más de 5,000 estudiantes de primaria.\n\nEl programa incluye charlas interactivas dirigidas por odontólogos certificados, demostraciones prácticas de técnicas de cepillado y el uso correcto del hilo dental. Cada estudiante recibirá un kit gratuito que incluye cepillo dental, pasta dental infantil y material educativo.\n\nLos estudios demuestran que la educación temprana en higiene dental reduce en un 60% la incidencia de caries en la edad adulta. Esta iniciativa busca crear hábitos saludables que perduren toda la vida.',
      'imagen':
          'https://images.unsplash.com/photo-1526256262350-7da7584cf5eb?auto=format&fit=crop&w=1200&q=80',
      'destacada': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildFeaturedNews(),
            _buildNewsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      pinned: true,
      elevation: 0,
      expandedHeight: 140,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.newspaper,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Dental News",
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.withOpacity(0.1),
                Colors.grey.withOpacity(0.3),
                Colors.grey.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedNews() {
    final featuredNews = noticias.firstWhere((noticia) => noticia['destacada']);
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () => _showNoticiaDetail(context, featuredNews),
          child: Container(
            height: 280, // Altura fija para evitar desbordamiento
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand, // Asegura que el Stack use todo el espacio disponible
                children: [
                  Image.network(
                    featuredNews['imagen'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        featuredNews['categoria'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Evita que se expanda más de lo necesario
                      children: [
                        Text(
                          featuredNews['titulo'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Playfair Display',
                            height: 1.3,
                          ),
                          maxLines: 3, // Limita las líneas del título
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white.withOpacity(0.8),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                featuredNews['fecha'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.schedule,
                              color: Colors.white.withOpacity(0.8),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              featuredNews['tiempoLectura'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
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
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    final regularNews = noticias.where((noticia) => !noticia['destacada']).toList();
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildNewsCard(context, regularNews[index], index);
          },
          childCount: regularNews.length,
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, Map<String, dynamic> noticia, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () => _showNoticiaDetail(context, noticia),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        noticia['imagen'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 40),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(noticia['categoria']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            noticia['categoria'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.grey[500],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            noticia['fecha'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            noticia['tiempoLectura'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      noticia['titulo'],
                      style: const TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      noticia['descripcion'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          "Leer más",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(noticia['categoria']),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: _getCategoryColor(noticia['categoria']),
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
    );
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria) {
      case 'INNOVACIÓN':
        return const Color(0xFF667EEA);
      case 'PROMOCIONES':
        return const Color(0xFFFF6B6B);
      case 'SALUD PÚBLICA':
        return const Color(0xFF4ECDC4);
      default:
        return const Color(0xFF667EEA);
    }
  }

  void _showNoticiaDetail(BuildContext context, Map<String, dynamic> noticia) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                height: 5,
                width: 50,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                          child: Image.network(
                            noticia['imagen'],
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(25),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(noticia['categoria']),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              noticia['categoria'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.grey[500],
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                noticia['fecha'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Icon(
                                Icons.schedule,
                                color: Colors.grey[500],
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                noticia['tiempoLectura'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            noticia['titulo'],
                            style: const TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(noticia['categoria']),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            noticia['contenidoCompleto'] ?? noticia['descripcion'],
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.7,
                              color: Color(0xFF2D3748),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getCategoryColor(noticia['categoria']),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        onPressed: () {
                          // Compartir funcionalidad
                          Navigator.pop(context);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Compartir",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
