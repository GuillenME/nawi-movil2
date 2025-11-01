import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/models/user_model.dart';
import 'package:nawii/views/login_page.dart';
import 'package:nawii/views/pasajero/solicitar_viaje_simple_page.dart';
import 'package:nawii/views/taxista/taxista_home_page.dart';
import 'package:nawii/views/perfil_page.dart';
import 'package:nawii/views/mapa_page.dart';
import 'package:nawii/banner_ad.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      return const LoginPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nawi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PerfilPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentUser!.isTaxista
                ? const TaxistaHomePage()
                : const PasajeroHomePage(),
          ),
          // Banner de anuncios en la parte inferior
          const BannerAdWidget(
            adSize: AdSize.banner,
            adUnitId: 'ca-app-pub-1838002939487298/5731553456',
          ),
        ],
      ),
    );
  }
}

class PasajeroHomePage extends StatelessWidget {
  const PasajeroHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bienvenida
          Container(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 16),
                Text(
                  '¡Bienvenido Pasajero!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
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
          const SizedBox(height: 30),

          // Botón principal para solicitar viaje
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SolicitarViajeSimplePage()),
              );
            },
            icon: const Icon(Icons.local_taxi, size: 28),
            label: const Text(
              'Solicitar Viaje',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Botón del Mapa
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapaPage()),
              );
            },
            icon: const Icon(Icons.map, size: 24),
            label: const Text(
              'Ver Mapa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Opciones adicionales
          Row(
            children: [
              Expanded(
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.history, color: Colors.blue[700]),
                    title: const Text('Historial'),
                    subtitle: const Text('Ver viajes anteriores'),
                    onTap: () {
                      // TODO: Implementar historial
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Próximamente: Historial de viajes')),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.star, color: Colors.orange[700]),
                    title: const Text('Calificaciones'),
                    subtitle: const Text('Ver mis calificaciones'),
                    onTap: () {
                      // TODO: Implementar calificaciones
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Próximamente: Calificaciones')),
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
