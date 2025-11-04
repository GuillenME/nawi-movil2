import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nawii/services/location_service_simple.dart';
import 'package:nawii/services/taxista_service.dart';
import 'package:nawii/services/auth_service.dart';

class TaxistaViajeEnCursoPage extends StatefulWidget {
  final String viajeId;
  final double origenLat;
  final double origenLon;
  final double destinoLat;
  final double destinoLon;
  final String pasajeroId;

  const TaxistaViajeEnCursoPage({
    Key? key,
    required this.viajeId,
    required this.origenLat,
    required this.origenLon,
    required this.destinoLat,
    required this.destinoLon,
    required this.pasajeroId,
  }) : super(key: key);

  @override
  _TaxistaViajeEnCursoPageState createState() => _TaxistaViajeEnCursoPageState();
}

class _TaxistaViajeEnCursoPageState extends State<TaxistaViajeEnCursoPage> {
  final DatabaseReference viajesRef = FirebaseDatabase.instance.ref('viajes');
  final TaxistaService _taxistaService = TaxistaService();
  
  GoogleMapController? _mapController;
  StreamSubscription? _viajeSubscription;
  StreamSubscription? _ubicacionSubscription;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  Map<String, double>? _miUbicacion;
  String _estadoViaje = 'aceptado';
  bool _isCompletado = false;

  @override
  void initState() {
    super.initState();
    _detectarMiUbicacion();
    _inicializarMapa();
    _escucharEstadoViaje();
    _escucharUbicacionPasajero();
    _actualizarMiUbicacionPeriodicamente();
  }

  @override
  void dispose() {
    _viajeSubscription?.cancel();
    _ubicacionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _detectarMiUbicacion() async {
    try {
      bool hasPermission = await LocationServiceSimple.hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await LocationServiceSimple.requestLocationPermission();
      }
      
      if (hasPermission) {
        final ubicacion = await LocationServiceSimple.getCurrentLocation();
        setState(() {
          _miUbicacion = ubicacion;
        });
        _actualizarMapa();
      }
    } catch (e) {
      print('Error obteniendo ubicación: $e');
    }
  }

  void _actualizarMiUbicacionPeriodicamente() {
    Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final ubicacion = await LocationServiceSimple.getCurrentLocation();
        setState(() {
          _miUbicacion = ubicacion;
        });
        _actualizarMapa();
        
        // Actualizar ubicación en Firebase
        final user = await AuthService.getCurrentUser();
        if (user != null) {
          await _taxistaService.actualizarUbicacion(user.id);
        }
      } catch (e) {
        print('Error actualizando ubicación: $e');
      }
    });
  }

  void _inicializarMapa() {
    _actualizarMapa();
  }

  void _actualizarMapa() {
    if (_mapController == null) return;

    Set<Marker> markers = {};
    Set<Polyline> polylines = {};

    // Marcador de origen (donde está el pasajero)
    markers.add(Marker(
      markerId: MarkerId('origen'),
      position: LatLng(widget.origenLat, widget.origenLon),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: 'Origen (Pasajero)'),
    ));

    // Marcador de destino
    markers.add(Marker(
      markerId: MarkerId('destino'),
      position: LatLng(widget.destinoLat, widget.destinoLon),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: 'Destino'),
    ));

    // Marcador de mi ubicación (taxista)
    if (_miUbicacion != null) {
      markers.add(Marker(
        markerId: MarkerId('mi_ubicacion'),
        position: LatLng(_miUbicacion!['latitude']!, _miUbicacion!['longitude']!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: 'Mi ubicación'),
      ));

      // Polilínea desde mi ubicación al origen (si aún no he recogido al pasajero)
      // o al destino (si ya lo recogí)
      if (_estadoViaje == 'aceptado' || _estadoViaje == 'en_progreso') {
        List<LatLng> puntos = [
          LatLng(_miUbicacion!['latitude']!, _miUbicacion!['longitude']!),
        ];
        
        if (_estadoViaje == 'aceptado') {
          puntos.add(LatLng(widget.origenLat, widget.origenLon)); // Al origen
        } else {
          puntos.add(LatLng(widget.destinoLat, widget.destinoLon)); // Al destino
        }
        
        polylines.add(Polyline(
          polylineId: PolylineId('ruta'),
          points: puntos,
          color: Colors.blue,
          width: 4,
        ));
      }
    } else {
      // Si no tengo mi ubicación, mostrar ruta de origen a destino
      polylines.add(Polyline(
        polylineId: PolylineId('ruta'),
        points: [
          LatLng(widget.origenLat, widget.origenLon),
          LatLng(widget.destinoLat, widget.destinoLon),
        ],
        color: Colors.blue,
        width: 4,
      ));
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // Ajustar cámara
    if (_miUbicacion != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _miUbicacion!['latitude']! < widget.destinoLat
                  ? _miUbicacion!['latitude']!
                  : widget.destinoLat,
              _miUbicacion!['longitude']! < widget.destinoLon
                  ? _miUbicacion!['longitude']!
                  : widget.destinoLon,
            ),
            northeast: LatLng(
              _miUbicacion!['latitude']! > widget.destinoLat
                  ? _miUbicacion!['latitude']!
                  : widget.destinoLat,
              _miUbicacion!['longitude']! > widget.destinoLon
                  ? _miUbicacion!['longitude']!
                  : widget.destinoLon,
            ),
          ),
          100.0,
        ),
      );
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(widget.origenLat, widget.origenLon),
            northeast: LatLng(widget.destinoLat, widget.destinoLon),
          ),
          100.0,
        ),
      );
    }
  }

  void _escucharEstadoViaje() {
    _viajeSubscription = viajesRef.child(widget.viajeId).onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final estado = data['estado'] as String?;

        setState(() {
          _estadoViaje = estado ?? 'aceptado';
        });
        _actualizarMapa();

        if (estado == 'completado' && !_isCompletado) {
          _isCompletado = true;
          _mostrarDialogoCompletado();
        } else if (estado == 'cancelado') {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El viaje fue cancelado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  void _escucharUbicacionPasajero() {
    // Escuchar ubicación del pasajero si está disponible en Firebase (opcional)
    // Por ahora no se usa, pero se puede implementar si el pasajero comparte su ubicación en tiempo real
  }

  void _mostrarDialogoCompletado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('¡Viaje Completado!'),
        content: Text('Has completado el viaje exitosamente.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver a home
            },
            child: Text('Aceptar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completarViaje() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Completar Viaje'),
        content: Text('¿Has completado el viaje y llegado al destino?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, completar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final result = await _taxistaService.completarViaje(widget.viajeId);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viaje completado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al completar viaje'),
              backgroundColor: Colors.red,
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
    }
  }

  Future<void> _iniciarViaje() async {
    // Cambiar estado a "en_progreso" cuando el taxista recoge al pasajero
    try {
      await viajesRef.child(widget.viajeId).update({
        'estado': 'en_progreso',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viaje iniciado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar viaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Viaje en Curso'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Información del estado
          Container(
            padding: EdgeInsets.all(16),
            color: _getColorEstado(),
            child: Row(
              children: [
                Icon(_getIconEstado(), color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTextoEstado(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_miUbicacion != null)
                        Text(
                          'Tu ubicación: ${_miUbicacion!['latitude']!.toStringAsFixed(4)}, ${_miUbicacion!['longitude']!.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mapa
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.origenLat, widget.origenLon),
                zoom: 14.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _actualizarMapa();
              },
            ),
          ),

          // Panel inferior con información y botones
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Origen',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    Icon(Icons.flag, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Destino',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Botones de acción
                if (_estadoViaje == 'aceptado')
                  ElevatedButton.icon(
                    onPressed: _iniciarViaje,
                    icon: Icon(Icons.directions_car),
                    label: Text('Iniciar Viaje (Recoger Pasajero)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  )
                else if (_estadoViaje == 'en_progreso')
                  ElevatedButton.icon(
                    onPressed: _completarViaje,
                    icon: Icon(Icons.check_circle),
                    label: Text('Completar Viaje'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorEstado() {
    switch (_estadoViaje) {
      case 'aceptado':
        return Colors.blue[700]!;
      case 'en_progreso':
        return Colors.orange[700]!;
      case 'completado':
        return Colors.green[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  IconData _getIconEstado() {
    switch (_estadoViaje) {
      case 'aceptado':
        return Icons.check_circle;
      case 'en_progreso':
        return Icons.directions_car;
      case 'completado':
        return Icons.check_circle_outline;
      default:
        return Icons.info;
    }
  }

  String _getTextoEstado() {
    switch (_estadoViaje) {
      case 'aceptado':
        return 'Viaje Aceptado - Dirígete al origen';
      case 'en_progreso':
        return 'Viaje en Progreso - Dirígete al destino';
      case 'completado':
        return 'Viaje Completado';
      default:
        return 'Estado: $_estadoViaje';
    }
  }
}

