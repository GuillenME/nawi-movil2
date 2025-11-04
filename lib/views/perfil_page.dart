import 'package:flutter/material.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/models/user_model.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/views/login_page.dart';
import 'package:nawii/views/historial_viajes_page.dart';
import 'package:nawii/views/editar_perfil_page.dart';

class PerfilPage extends StatefulWidget {
  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return LoginPage();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Mi Perfil'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        actions: [
          // Solo mostrar botón de editar para pasajeros
          if (!_currentUser!.isTaxista)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditarPerfilPage(),
                  ),
                );
                // Si se actualizó el perfil, recargar los datos
                if (result == true) {
                  _loadUser();
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información del usuario
            Card(
              color: AppColors.primaryDark.withOpacity(0.3),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryDark.withOpacity(0.5),
                      child: Icon(
                        _currentUser!.isTaxista
                            ? Icons.directions_car
                            : Icons.person,
                        size: 50,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _currentUser!.nombreCompleto,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _currentUser!.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.mediumGrey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentUser!.isTaxista
                            ? AppColors.primaryYellow.withOpacity(0.2)
                            : AppColors.successColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _currentUser!.isTaxista
                              ? AppColors.primaryYellow
                              : AppColors.successColor,
                        ),
                      ),
                      child: Text(
                        _currentUser!.isTaxista ? 'Taxista' : 'Pasajero',
                        style: TextStyle(
                          color: _currentUser!.isTaxista
                              ? AppColors.primaryYellow
                              : AppColors.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Información de contacto
            Card(
              color: AppColors.primaryDark.withOpacity(0.3),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de Contacto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_currentUser!.telefono != null) ...[
                      ListTile(
                        leading: Icon(Icons.phone, color: AppColors.primaryYellow),
                        title: Text('Teléfono', style: TextStyle(color: AppColors.white)),
                        subtitle: Text(_currentUser!.telefono!, style: TextStyle(color: AppColors.mediumGrey)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    ListTile(
                      leading: Icon(Icons.email, color: AppColors.primaryYellow),
                      title: Text('Correo', style: TextStyle(color: AppColors.white)),
                      subtitle: Text(_currentUser!.email, style: TextStyle(color: AppColors.mediumGrey)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Estadísticas (diferentes según el rol)
            if (_currentUser!.isTaxista) ...[
              _buildTaxistaStats(),
            ] else ...[
              _buildPasajeroStats(),
            ],

            SizedBox(height: 20),

            // Opciones adicionales
            Card(
              color: AppColors.primaryDark.withOpacity(0.3),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.history, color: AppColors.primaryYellow),
                    title: Text('Historial de Viajes', style: TextStyle(color: AppColors.white)),
                    subtitle: Text('Ver todos mis viajes', style: TextStyle(color: AppColors.mediumGrey)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGrey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistorialViajesPage(),
                        ),
                      );
                    },
                  ),
                  Divider(color: AppColors.mediumGrey.withOpacity(0.3)),
                  ListTile(
                    leading: Icon(Icons.star, color: AppColors.primaryYellow),
                    title: Text('Calificaciones', style: TextStyle(color: AppColors.white)),
                    subtitle: Text('Ver mis calificaciones', style: TextStyle(color: AppColors.mediumGrey)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGrey),
                    onTap: () {
                      // TODO: Implementar calificaciones
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Próximamente: Calificaciones')),
                      );
                    },
                  ),
                  Divider(color: AppColors.mediumGrey.withOpacity(0.3)),
                  ListTile(
                    leading: Icon(Icons.settings, color: AppColors.mediumGrey),
                    title: Text('Configuración', style: TextStyle(color: AppColors.white)),
                    subtitle: Text('Ajustes de la aplicación', style: TextStyle(color: AppColors.mediumGrey)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGrey),
                    onTap: () {
                      // TODO: Implementar configuración
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Próximamente: Configuración')),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Botón de cerrar sesión
            ElevatedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout),
              label: Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxistaStats() {
    return Card(
      color: AppColors.primaryDark.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas como Taxista',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryYellow,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Viajes Completados',
                    '0',
                    Icons.directions_car,
                    AppColors.successColor,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Calificación',
                    '4.5',
                    Icons.star,
                    AppColors.primaryYellow,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Ganancias',
                    '\$0',
                    Icons.attach_money,
                    AppColors.successColor,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Horas Online',
                    '0h',
                    Icons.access_time,
                    AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasajeroStats() {
    return Card(
      color: AppColors.primaryDark.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas como Pasajero',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryYellow,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Viajes Realizados',
                    '0',
                    Icons.directions_car,
                    AppColors.primaryDark,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Calificación Promedio',
                    '4.5',
                    Icons.star,
                    AppColors.primaryYellow,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Gastado',
                    '\$0',
                    Icons.attach_money,
                    AppColors.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mediumGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
