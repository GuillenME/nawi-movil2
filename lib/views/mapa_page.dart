import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  
  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(16.867, -92.094), // Ocosingo
    zoom: 15.0,
  );

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
        _initialCameraPosition = CameraPosition(
          target: LatLng(position['latitude']!, position['longitude']!),
          zoom: 15.0,
        );
      });
      
      // Actualizar marcadores
      _actualizarMarcadores();
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
      
      // Actualizar marcadores cuando cambien los taxistas
      _actualizarMarcadores();
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

  // Actualizar marcadores en el mapa
  void _actualizarMarcadores() {
    Set<Marker> newMarkers = {};

    // Marcador del usuario
    newMarkers.add(
      Marker(
        markerId: MarkerId('user_location'),
        position: LatLng(_userLocation['latitude']!, _userLocation['longitude']!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Tu ubicación',
          snippet: '${_userLocation['latitude']!.toStringAsFixed(4)}, ${_userLocation['longitude']!.toStringAsFixed(4)}',
        ),
      ),
    );

    // Marcadores de taxistas
    for (int i = 0; i < _taxisDisponibles.length; i++) {
      final taxista = _taxisDisponibles[i];
      final distancia = _calcularDistancia(taxista);
      
      newMarkers.add(
        Marker(
          markerId: MarkerId('taxista_${taxista['id']}'),
          position: LatLng(taxista['latitude'], taxista['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Taxista ${taxista['id'].substring(0, 8)}...',
            snippet: '${distancia.toStringAsFixed(1)} km - Disponible',
          ),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  // Ir a la ubicación del usuario
  void _irAMiUbicacion() async {
    if (_mapController != null) {
      Map<String, double> position = LocationServiceSimple.getCurrentLocation();
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position['latitude']!, position['longitude']!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa Nawi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _irAMiUbicacion,
            tooltip: 'Ir a mi ubicación',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Obteniendo ubicación...'),
                ],
              ),
            )
          : Stack(
              children: [
                // Mapa de Google
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: _initialCameraPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  onTap: (LatLng position) {
                    // Opcional: manejar toques en el mapa
                  },
                ),
                
                // Panel de información en la parte superior
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
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
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_taxisDisponibles.length} taxistas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Lista de taxistas en la parte inferior (si hay taxistas)
                if (_taxisDisponibles.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Handle para arrastrar
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Taxistas disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _taxisDisponibles.length,
                              itemBuilder: (context, index) {
                                final taxista = _taxisDisponibles[index];
                                final distancia = _calcularDistancia(taxista);

                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green[700],
                                      child: Icon(
                                        Icons.local_taxi,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      'Taxista ${taxista['id'].substring(0, 8)}...',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                                        SizedBox(width: 4),
                                        Text('${distancia.toStringAsFixed(1)} km'),
                                        SizedBox(width: 16),
                                        Icon(Icons.star, color: Colors.orange, size: 16),
                                        SizedBox(width: 4),
                                        Text('4.5'),
                                      ],
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {
                                      // Centrar el mapa en el taxista seleccionado
                                      _mapController!.animateCamera(
                                        CameraUpdate.newLatLng(
                                          LatLng(taxista['latitude'], taxista['longitude']),
                                        ),
                                      );
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Taxista seleccionado: ${taxista['id'].substring(0, 8)}...'),
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
                    ),
                  ),
              ],
            ),
    );
  }
}
