import 'package:flutter/material.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/models/user_model.dart';
import 'package:nawii/views/login_page.dart';
import 'package:nawii/views/pasajero/solicitar_viaje_con_mapa_page.dart';
import 'package:nawii/views/taxista/taxista_home_page.dart';
import 'package:nawii/views/perfil_page.dart';

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
      appBar: AppBar(
        title: Text('Nawi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bienvenida
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.blue[700],
                ),
                SizedBox(height: 16),
                Text(
                  '¡Bienvenido Pasajero!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Solicita un viaje cuando lo necesites',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
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
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
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
                  child: ListTile(
                    leading: Icon(Icons.history, color: Colors.blue[700]),
                    title: Text('Historial'),
                    subtitle: Text('Ver viajes anteriores'),
                    onTap: () {
                      // TODO: Implementar historial
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Próximamente: Historial de viajes')),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.star, color: Colors.orange[700]),
                    title: Text('Calificaciones'),
                    subtitle: Text('Ver mis calificaciones'),
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
