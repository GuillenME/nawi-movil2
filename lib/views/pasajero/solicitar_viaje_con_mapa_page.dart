import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nawii/services/pasajero_service.dart';
import 'package:nawii/services/location_service_simple.dart';
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/views/pasajero/viaje_en_curso_page.dart';

class SolicitarViajeConMapaPage extends StatefulWidget {
  @override
  _SolicitarViajeConMapaPageState createState() => _SolicitarViajeConMapaPageState();
}

class _SolicitarViajeConMapaPageState extends State<SolicitarViajeConMapaPage> {
  final DatabaseReference taxisRef = FirebaseDatabase.instance.ref('taxis');
  final DatabaseReference viajesRef = FirebaseDatabase.instance.ref('viajes');
  final PasajeroService _pasajeroService = PasajeroService();
  final TextEditingController _destinoController = TextEditingController();
  
  GoogleMapController? _mapController;
  Map<String, double> _userLocation = {
    'latitude': 16.867,
    'longitude': -92.094
  };
  
  Map<String, double>? _destino;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _taxisDisponibles = [];
  Map<String, dynamic>? _taxistaSeleccionado;
  bool _isLoading = true;
  bool _isSolicitandoViaje = false;
  StreamSubscription? _viajeSubscription;

  @override
  void initState() {
    super.initState();
    _detectarUbicacion();
    _escucharTaxis();
  }

  @override
  void dispose() {
    _destinoController.dispose();
    _viajeSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _detectarUbicacion() async {
    try {
      bool hasPermission = await LocationServiceSimple.hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await LocationServiceSimple.requestLocationPermission();
        if (!hasPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Se necesitan permisos de ubicación'),
              backgroundColor: AppColors.errorColor,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      Map<String, double> position = await LocationServiceSimple.getCurrentLocation();
      setState(() {
        _userLocation = position;
        _isLoading = false;
      });
      
      _actualizarMapa();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _actualizarMapa() {
    if (_mapController == null) return;

    Set<Marker> markers = {};
    
    // Marcador de usuario
    markers.add(Marker(
      markerId: MarkerId('user'),
      position: LatLng(_userLocation['latitude']!, _userLocation['longitude']!),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(title: 'Tu ubicación'),
    ));

    // Marcador de destino si existe
    if (_destino != null) {
      markers.add(Marker(
        markerId: MarkerId('destino'),
        position: LatLng(_destino!['latitude']!, _destino!['longitude']!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destino'),
      ));
    }

    // Marcadores de taxistas
    for (var taxista in _taxisDisponibles) {
      final isSelected = _taxistaSeleccionado?['id'] == taxista['id'];
      markers.add(Marker(
        markerId: MarkerId('taxista_${taxista['id']}'),
        position: LatLng(taxista['latitude'], taxista['longitude']),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueYellow,
        ),
        infoWindow: InfoWindow(
          title: 'Taxista ${taxista['id'].substring(0, 8)}...',
          snippet: 'Toca para seleccionar',
        ),
        onTap: () => _seleccionarTaxista(taxista),
      ));
    }

    setState(() => _markers = markers);

    // Ajustar cámara para mostrar todos los marcadores
    if (_destino != null && _taxisDisponibles.isNotEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          _calcularBounds(),
          100.0,
        ),
      );
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userLocation['latitude']!, _userLocation['longitude']!),
          14.0,
        ),
      );
    }
  }

  LatLngBounds _calcularBounds() {
    double minLat = _userLocation['latitude']!;
    double maxLat = _userLocation['latitude']!;
    double minLng = _userLocation['longitude']!;
    double maxLng = _userLocation['longitude']!;

    if (_destino != null) {
      minLat = minLat < _destino!['latitude']! ? minLat : _destino!['latitude']!;
      maxLat = maxLat > _destino!['latitude']! ? maxLat : _destino!['latitude']!;
      minLng = minLng < _destino!['longitude']! ? minLng : _destino!['longitude']!;
      maxLng = maxLng > _destino!['longitude']! ? maxLng : _destino!['longitude']!;
    }

    for (var taxista in _taxisDisponibles) {
      minLat = minLat < taxista['latitude'] ? minLat : taxista['latitude'];
      maxLat = maxLat > taxista['latitude'] ? maxLat : taxista['latitude'];
      minLng = minLng < taxista['longitude'] ? minLng : taxista['longitude'];
      maxLng = maxLng > taxista['longitude'] ? maxLng : taxista['longitude'];
    }

    return LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );
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
      
      _actualizarMapa();
    });
  }

  void _seleccionarTaxista(Map<String, dynamic> taxista) {
    setState(() {
      _taxistaSeleccionado = taxista;
    });
    _actualizarMapa();
    
    // Mostrar bottom sheet con información del taxista
    _mostrarInfoTaxista(taxista);
  }

  void _mostrarInfoTaxista(Map<String, dynamic> taxista) {
    final distancia = LocationServiceSimple.calculateDistance(
      _userLocation['latitude']!,
      _userLocation['longitude']!,
      taxista['latitude'],
      taxista['longitude'],
    );

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryDark,
                  radius: 30,
                  child: Icon(Icons.local_taxi, color: AppColors.primaryYellow, size: 30),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taxista ${taxista['id'].substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: AppColors.primaryYellow, size: 16),
                          SizedBox(width: 4),
                          Text('4.5 ⭐', style: TextStyle(color: AppColors.white)),
                          SizedBox(width: 16),
                          Icon(Icons.location_on, color: AppColors.mediumGrey, size: 16),
                          SizedBox(width: 4),
                          Text('${distancia.toStringAsFixed(1)} km', style: TextStyle(color: AppColors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close),
                    label: Text('Cerrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mediumGrey,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarDestino() async {
    if (_destinoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor ingresa un destino'),
          backgroundColor: AppColors.primaryYellow,
        ),
      );
      return;
    }

    // Mostrar loading
    setState(() => _isLoading = true);

    try {
      // Usar Geocoding API para convertir la dirección a coordenadas
      final coordenadas = await _pasajeroService.obtenerCoordenadasDesdeDireccion(
        _destinoController.text.trim(),
      );

      setState(() {
        _destino = {
          'latitude': coordenadas['lat']!,
          'longitude': coordenadas['lng']!,
        };
        _isLoading = false;
      });

      _actualizarMapa();
      
      // Mover la cámara al destino
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(coordenadas['lat']!, coordenadas['lng']!),
          15.0,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Destino confirmado: ${_destinoController.text}'),
          backgroundColor: AppColors.successColor,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: No se pudo encontrar la ubicación. Intenta con una dirección más específica.'),
          backgroundColor: AppColors.errorColor,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _solicitarViaje() async {
    if (_destino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor confirma el destino primero'),
          backgroundColor: AppColors.primaryYellow,
        ),
      );
      return;
    }

    if (_taxistaSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona un taxista del mapa'),
          backgroundColor: AppColors.primaryYellow,
        ),
      );
      return;
    }

    setState(() => _isSolicitandoViaje = true);

    try {
      final result = await _pasajeroService.crearViaje(
        salidaLat: _userLocation['latitude']!,
        salidaLon: _userLocation['longitude']!,
        destinoLat: _destino!['latitude']!,
        destinoLon: _destino!['longitude']!,
        idTaxista: _taxistaSeleccionado!['id'],
      );

      if (result['success']) {
        final viaje = result['viaje'] as ViajeModel?;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitud enviada. Esperando respuesta del taxista...'),
            backgroundColor: AppColors.primaryDark,
            duration: Duration(seconds: 3),
          ),
        );

        // Escuchar cambios en el estado del viaje
        _escucharEstadoViaje(viaje?.id ?? '');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al solicitar viaje'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        setState(() => _isSolicitandoViaje = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al solicitar viaje: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      setState(() => _isSolicitandoViaje = false);
    }
  }

  void _escucharEstadoViaje(String viajeId) {
    _viajeSubscription?.cancel();
    _viajeSubscription = viajesRef.child(viajeId).onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final estado = data['estado'] as String?;

        if (estado == 'aceptado') {
          // El taxista aceptó, navegar a página de viaje en curso
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ViajeEnCursoPage(
                viajeId: viajeId,
                origenLat: _userLocation['latitude']!,
                origenLon: _userLocation['longitude']!,
                destinoLat: _destino!['latitude']!,
                destinoLon: _destino!['longitude']!,
                taxistaId: _taxistaSeleccionado!['id'],
              ),
            ),
          );
        } else if (estado == 'rechazado') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El taxista rechazó el viaje. Selecciona otro taxista.'),
              backgroundColor: AppColors.primaryYellow,
            ),
          );
          setState(() {
            _isSolicitandoViaje = false;
            _taxistaSeleccionado = null;
          });
          _viajeSubscription?.cancel();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Solicitar Viaje'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Campo de destino
                Container(
                  padding: EdgeInsets.all(16),
                  color: AppColors.primaryDark.withOpacity(0.5),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _destinoController,
                          style: TextStyle(color: AppColors.white),
                          decoration: InputDecoration(
                            hintText: 'Ingresa tu destino',
                            hintStyle: TextStyle(color: AppColors.mediumGrey),
                            prefixIcon: Icon(Icons.flag, color: AppColors.errorColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.mediumGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.mediumGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
                            ),
                            filled: true,
                            fillColor: AppColors.primaryDark.withOpacity(0.7),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _confirmarDestino,
                        icon: Icon(Icons.check),
                        label: Text('Confirmar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // Mapa
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _userLocation['latitude']!,
                            _userLocation['longitude']!,
                          ),
                          zoom: 14.0,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          _actualizarMapa();
                        },
                      ),
                      
                      // Información del viaje
                      if (_destino != null)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                            child: Card(
                            color: AppColors.primaryDark.withOpacity(0.9),
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, color: AppColors.successColor, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Origen confirmado',
                                          style: TextStyle(fontSize: 12, color: AppColors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.flag, color: AppColors.errorColor, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _destinoController.text.isNotEmpty
                                              ? _destinoController.text
                                              : 'Destino confirmado',
                                          style: TextStyle(fontSize: 12, color: AppColors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Panel inferior con información y botones
                Container(
                  padding: EdgeInsets.all(16),
                  color: AppColors.primaryDark.withOpacity(0.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_taxistaSeleccionado != null)
                        Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.successColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.successColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.successColor),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Taxista seleccionado',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.successColor,
                                      ),
                                    ),
                                    Text(
                                      'ID: ${_taxistaSeleccionado!['id'].substring(0, 8)}...',
                                      style: TextStyle(fontSize: 12, color: AppColors.mediumGrey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      if (_isSolicitandoViaje)
                        Container(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text(
                                'Esperando respuesta del taxista...',
                                style: TextStyle(color: AppColors.primaryYellow),
                              ),
                            ],
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _solicitarViaje,
                          icon: Icon(Icons.local_taxi, size: 24),
                          label: Text(
                            'Solicitar Viaje',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryYellow,
                            foregroundColor: AppColors.primaryDark,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

