import 'package:flutter/material.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/models/user_model.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/views/login_page.dart';
import 'package:nawii/views/pasajero/solicitar_viaje_con_mapa_page.dart';
import 'package:nawii/views/taxista/taxista_home_page.dart';
import 'package:nawii/views/perfil_page.dart';
import 'package:nawii/views/historial_viajes_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      return LoginPage();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('NAWI'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PerfilPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _currentUser!.isTaxista ? TaxistaHomePage() : PasajeroHomePage(),
    );
  }
}

class PasajeroHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bienvenida
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryYellow.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.person,
                  size: 60,
                  color: AppColors.primaryYellow,
                ),
                SizedBox(height: 16),
                Text(
                  '¡Bienvenido Pasajero!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Solicita un viaje cuando lo necesites',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.mediumGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 30),

          // Botón principal para solicitar viaje
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SolicitarViajeConMapaPage()),
              );
            },
            icon: Icon(Icons.local_taxi, size: 28),
            label: Text(
              'Solicitar Viaje',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.primaryDark,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Opciones adicionales
          Row(
            children: [
              Expanded(
                child: Card(
                  color: AppColors.primaryDark.withOpacity(0.3),
                  child: ListTile(
                    leading: Icon(Icons.history, color: AppColors.primaryYellow),
                    title: Text('Historial', style: TextStyle(color: AppColors.white)),
                    subtitle: Text('Ver viajes anteriores', style: TextStyle(color: AppColors.mediumGrey)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistorialViajesPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Card(
                  color: AppColors.primaryDark.withOpacity(0.3),
                  child: ListTile(
                    leading: Icon(Icons.star, color: AppColors.primaryYellow),
                    title: Text('Calificaciones', style: TextStyle(color: AppColors.white)),
                    subtitle: Text('Ver mis calificaciones', style: TextStyle(color: AppColors.mediumGrey)),
                    onTap: () {
                      // TODO: Implementar calificaciones
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Próximamente: Calificaciones')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
