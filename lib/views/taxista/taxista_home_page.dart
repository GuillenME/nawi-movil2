import 'package:flutter/material.dart';
import 'package:nawii/services/taxista_service.dart';
import 'package:nawii/views/taxista/viajes_pendientes_page.dart';
import 'package:nawii/views/perfil_page.dart';

class TaxistaHomePage extends StatefulWidget {
  const TaxistaHomePage({super.key});

  @override
  State<TaxistaHomePage> createState() => _TaxistaHomePageState();
}

class _TaxistaHomePageState extends State<TaxistaHomePage> {
  final TaxistaService _taxistaService = TaxistaService();
  bool _isOnline = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    // TODO: Implementar solicitud de permisos de ubicación
    // Por ahora solo mostramos un mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Se solicitarán permisos de ubicación para funcionar como taxista'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _toggleOnlineStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isOnline) {
        // Desconectar
        await _taxistaService.desconectar();
        setState(() {
          _isOnline = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has desconectado'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Conectar
        await _taxistaService.conectar();
        setState(() {
          _isOnline = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has conectado y estás disponible para viajes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Estado de conexión
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isOnline ? Colors.green[200]! : Colors.orange[200]!,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _isOnline ? Icons.check_circle : Icons.pause_circle,
                  size: 60,
                  color: _isOnline ? Colors.green[700] : Colors.orange[700],
                ),
                const SizedBox(height: 16),
                Text(
                  _isOnline ? 'En línea' : 'Desconectado',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isOnline ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isOnline
                      ? 'Recibiendo solicitudes de viaje'
                      : 'No estás disponible para viajes',
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

          // Botón principal para conectar/desconectar
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _toggleOnlineStatus,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(_isOnline ? Icons.pause : Icons.play_arrow, size: 28),
            label: Text(
              _isOnline ? 'Desconectar' : 'Conectar',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isOnline ? Colors.orange[700] : Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                    leading:
                        Icon(Icons.directions_car, color: Colors.blue[700]),
                    title: const Text('Viajes Pendientes'),
                    subtitle: const Text('Ver solicitudes'),
                    onTap: _isOnline
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ViajesPendientesPage()),
                            );
                          }
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.history, color: Colors.blue[700]),
                    title: const Text('Historial'),
                    subtitle: const Text('Viajes completados'),
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
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.star, color: Colors.orange[700]),
                    title: const Text('Calificaciones'),
                    subtitle: const Text('Ver mis calificaciones'),
                    onTap: () {
                      // TODO: Implementar calificaciones
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Próximamente: Calificaciones')),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  child: ListTile(
                    leading:
                        Icon(Icons.account_circle, color: Colors.purple[700]),
                    title: const Text('Perfil'),
                    subtitle: const Text('Mi información'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PerfilPage()),
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
