import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await ApiService.getUserProfile();
      if (mounted) {
        setState(() {
          _user = user;
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
            content: Text('Error cargando perfil: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar y nombre
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Text(
                            _user?.iniciales ?? 'U',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _user?.nombreCompleto ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user?.telefonoFormateado ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Información del perfil
                  _ProfileInfoCard(
                    title: 'Información Personal',
                    children: [
                      _InfoRow(
                        icon: Icons.person,
                        label: 'Nombre Completo',
                        value: _user?.nombreCompleto ?? '',
                      ),
                      _InfoRow(
                        icon: Icons.phone,
                        label: 'Teléfono',
                        value: _user?.telefonoFormateado ?? '',
                      ),
                      if (_user?.email != null && _user!.email!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.email,
                          label: 'Correo Electrónico',
                          value: _user!.email!,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Información financiera
                  _ProfileInfoCard(
                    title: 'Información Financiera',
                    children: [
                      _InfoRow(
                        icon: Icons.account_balance_wallet,
                        label: 'Saldo Actual',
                        value: _user?.saldoFormateado ?? 'Bs. 0.00',
                        valueColor: AppTheme.accentColor,
                      ),
                      _InfoRow(
                        icon: Icons.trending_up,
                        label: 'Límite Diario',
                        value: _user?.limiteDiarioFormateado ?? 'Bs. 0.00',
                      ),
                      _InfoRow(
                        icon: Icons.calendar_month,
                        label: 'Límite Mensual',
                        value: _user?.limiteMensualFormateado ?? 'Bs. 0.00',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Opciones
                  _ProfileOptionCard(
                    icon: Icons.security,
                    title: 'Cambiar PIN',
                    subtitle: 'Actualiza tu PIN de seguridad',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad en desarrollo'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _ProfileOptionCard(
                    icon: Icons.notifications,
                    title: 'Notificaciones',
                    subtitle: 'Configura tus notificaciones',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad en desarrollo'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _ProfileOptionCard(
                    icon: Icons.help,
                    title: 'Ayuda y Soporte',
                    subtitle: 'Obtén ayuda con tu cuenta',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad en desarrollo'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Botón de cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileInfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppTheme.textPrimaryColor,
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

class _ProfileOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
