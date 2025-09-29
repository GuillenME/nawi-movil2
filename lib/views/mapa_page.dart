import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nawii/services/location_service_simple.dart';

class MapaPage extends StatefulWidget {
  @override
  _MapaPageState createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final DatabaseReference taxisRef = FirebaseDatabase.instance.ref('taxis');
  List<Map<String, dynamic>> _taxisDisponibles = [];
  Map<String, double> _userLocation = {
    'latitude': 16.867,
    'longitude': -92.094
  }; // Ocosingo
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _detectarUbicacion();
    _escucharTaxis();
  }

  Future<void> _detectarUbicacion() async {
    try {
      // Simular verificación de permisos
      bool hasPermission = await LocationServiceSimple.hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await LocationServiceSimple.requestLocationPermission();
        if (!hasPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Se necesitan permisos de ubicación'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Obtener ubicación simulada
      Map<String, double> position = LocationServiceSimple.getCurrentLocation();
      setState(() {
        _userLocation = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _escucharTaxis() {
    taxisRef.onValue.listen((event) {
      Map<dynamic, dynamic>? taxis = event.snapshot.value as Map?;
      List<Map<String, dynamic>> taxisList = [];

      if (taxis != null) {
        taxis.forEach((key, value) {
          if (value['disponible'] == true) {
            taxisList.add({
              'id': key,
              'latitude': value['latitude']?.toDouble() ?? 0.0,
              'longitude': value['longitude']?.toDouble() ?? 0.0,
              'timestamp': value['timestamp'] ?? 0,
            });
          }
        });
      }

      setState(() {
        _taxisDisponibles = taxisList;
      });
    });
  }

  double _calcularDistancia(Map<String, dynamic> taxista) {
    return LocationServiceSimple.calculateDistance(
      _userLocation['latitude']!,
      _userLocation['longitude']!,
      taxista['latitude'],
      taxista['longitude'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa Nawi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Información de ubicación
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      Icon(Icons.my_location, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu ubicación',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            Text(
                              '${_userLocation['latitude']!.toStringAsFixed(4)}, ${_userLocation['longitude']!.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de taxistas disponibles
                Expanded(
                  child: _taxisDisponibles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_taxi,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay taxistas disponibles',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Los taxistas aparecerán aquí cuando estén en línea',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _taxisDisponibles.length,
                          itemBuilder: (context, index) {
                            final taxista = _taxisDisponibles[index];
                            final distancia = _calcularDistancia(taxista);

                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[700],
                                  child: Icon(
                                    Icons.local_taxi,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  'Taxista ${taxista['id'].substring(0, 8)}...',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Disponible ahora'),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.orange, size: 16),
                                        SizedBox(width: 4),
                                        Text('4.5 ⭐'),
                                        SizedBox(width: 16),
                                        Icon(Icons.location_on,
                                            color: Colors.grey[600], size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                            '${distancia.toStringAsFixed(1)} km'),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.directions_car,
                                        color: Colors.green),
                                    Text(
                                      'En línea',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Taxista seleccionado: ${taxista['id'].substring(0, 8)}...'),
                                      backgroundColor: Colors.blue[700],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
