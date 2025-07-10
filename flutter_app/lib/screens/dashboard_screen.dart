import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import 'send_money_screen.dart';
import 'transaction_history_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _user;
  double? _saldo;
  bool _isLoading = true;
  bool _saldoVisible = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await ApiService.getUserProfile();
      final saldo = await ApiService.getUserBalance();
      
      if (mounted) {
        setState(() {
          _user = user;
          _saldo = saldo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                ApiService.clearToken();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CustomScrollView(
        slivers: [
          // App Bar personalizado
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    _user?.iniciales ?? 'U',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hola, ${_user?.nombre ?? 'Usuario'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _user?.telefonoFormateado ?? '',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: _logout,
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Saldo
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saldo disponible',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      _saldoVisible 
                                          ? 'Bs. ${_saldo?.toStringAsFixed(2) ?? '0.00'}'
                                          : '••••••',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _saldoVisible = !_saldoVisible;
                                        });
                                      },
                                      icon: Icon(
                                        _saldoVisible 
                                            ? Icons.visibility 
                                            : Icons.visibility_off,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Contenido principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Acciones rápidas
                  const Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.send,
                          title: 'Enviar\nDinero',
                          color: AppTheme.accentColor,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SendMoneyScreen(),
                              ),
                            ).then((_) => _refreshData());
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.add_circle,
                          title: 'Recargar\nSaldo',
                          color: AppTheme.secondaryColor,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Funcionalidad en desarrollo'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.receipt_long,
                          title: 'Pagar\nServicios',
                          color: AppTheme.warningColor,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Funcionalidad en desarrollo'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.phone_android,
                          title: 'Recarga\nCelular',
                          color: AppTheme.primaryColor,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Funcionalidad en desarrollo'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Historial reciente
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transacciones Recientes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                        child: const Text('Ver todo'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Lista de transacciones recientes
                  FutureBuilder(
                    future: ApiService.getTransactionHistory(limit: 5),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error cargando transacciones'),
                        );
                      }
                      
                      final transactions = snapshot.data ?? [];
                      
                      if (transactions.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(40),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: AppTheme.textSecondaryColor,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No tienes transacciones aún',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Column(
                        children: transactions.take(3).map((transaction) {
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: transaction.estado == 'COMPLETADA'
                                    ? AppTheme.accentColor
                                    : AppTheme.warningColor,
                                child: Icon(
                                  transaction.tipoTransaccionId == 1
                                      ? Icons.send
                                      : Icons.receipt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                transaction.nombreParaMostrar,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                transaction.fechaRelativa,
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              trailing: Text(
                                transaction.getMontoConSigno(_user?.id ?? 0),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: transaction.isOutgoing(_user?.id ?? 0)
                                      ? AppTheme.errorColor
                                      : AppTheme.accentColor,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = [
      _buildDashboardContent(),
      const TransactionHistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
