import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nawii/services/location_service_simple.dart';
import 'package:nawii/services/pasajero_service.dart';
import 'package:nawii/views/calificar_viaje_page.dart';

class ViajeEnCursoPage extends StatefulWidget {
  final String viajeId;
  final double origenLat;
  final double origenLon;
  final double destinoLat;
  final double destinoLon;
  final String taxistaId;

  const ViajeEnCursoPage({
    Key? key,
    required this.viajeId,
    required this.origenLat,
    required this.origenLon,
    required this.destinoLat,
    required this.destinoLon,
    required this.taxistaId,
  }) : super(key: key);

  @override
  _ViajeEnCursoPageState createState() => _ViajeEnCursoPageState();
}

class _ViajeEnCursoPageState extends State<ViajeEnCursoPage> {
  final DatabaseReference viajesRef = FirebaseDatabase.instance.ref('viajes');
  final PasajeroService _pasajeroService = PasajeroService();
  
  GoogleMapController? _mapController;
  StreamSubscription? _viajeSubscription;
  StreamSubscription? _taxistaSubscription;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  Map<String, double>? _ubicacionTaxista;
  String _estadoViaje = 'aceptado';
  bool _isCompletado = false;

  @override
  void initState() {
    super.initState();
    _inicializarMapa();
    _escucharEstadoViaje();
    _escucharUbicacionTaxista();
  }

  @override
  void dispose() {
    _viajeSubscription?.cancel();
    _taxistaSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _inicializarMapa() {
    _actualizarMapa();
  }

  void _actualizarMapa() {
    if (_mapController == null) return;

    Set<Marker> markers = {};
    Set<Polyline> polylines = {};

    // Marcador de origen
    markers.add(Marker(
      markerId: MarkerId('origen'),
      position: LatLng(widget.origenLat, widget.origenLon),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: 'Origen'),
    ));

    // Marcador de destino
    markers.add(Marker(
      markerId: MarkerId('destino'),
      position: LatLng(widget.destinoLat, widget.destinoLon),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: 'Destino'),
    ));

    // Marcador de taxista si está disponible
    if (_ubicacionTaxista != null) {
      markers.add(Marker(
        markerId: MarkerId('taxista'),
        position: LatLng(_ubicacionTaxista!['latitude']!, _ubicacionTaxista!['longitude']!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: 'Taxista en camino'),
        rotation: 45.0, // Simular dirección del vehículo
      ));

      // Polilínea del taxista al destino
      polylines.add(Polyline(
        polylineId: PolylineId('ruta'),
        points: [
          LatLng(_ubicacionTaxista!['latitude']!, _ubicacionTaxista!['longitude']!),
          LatLng(widget.destinoLat, widget.destinoLon),
        ],
        color: Colors.blue,
        width: 4,
      ));
    } else {
      // Polilínea de origen a destino si no hay ubicación del taxista
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
    if (_ubicacionTaxista != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _ubicacionTaxista!['latitude']! < widget.destinoLat
                  ? _ubicacionTaxista!['latitude']!
                  : widget.destinoLat,
              _ubicacionTaxista!['longitude']! < widget.destinoLon
                  ? _ubicacionTaxista!['longitude']!
                  : widget.destinoLon,
            ),
            northeast: LatLng(
              _ubicacionTaxista!['latitude']! > widget.destinoLat
                  ? _ubicacionTaxista!['latitude']!
                  : widget.destinoLat,
              _ubicacionTaxista!['longitude']! > widget.destinoLon
                  ? _ubicacionTaxista!['longitude']!
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

  void _escucharUbicacionTaxista() {
    _taxistaSubscription = viajesRef
        .child(widget.viajeId)
        .child('ubicacion_taxista')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _ubicacionTaxista = {
            'latitude': data['lat']?.toDouble() ?? 0.0,
            'longitude': data['lon']?.toDouble() ?? 0.0,
          };
        });
        _actualizarMapa();
      }
    });

    // También escuchar ubicación del taxista desde la tabla de taxis
    FirebaseDatabase.instance.ref('taxis/${widget.taxistaId}').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _ubicacionTaxista = {
            'latitude': data['latitude']?.toDouble() ?? 0.0,
            'longitude': data['longitude']?.toDouble() ?? 0.0,
          };
        });
        _actualizarMapa();
      }
    });
  }

  void _mostrarDialogoCompletado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('¡Viaje Completado!'),
        content: Text('El viaje ha sido completado. ¿Deseas calificar al taxista?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver a home
            },
            child: Text('Después'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CalificarViajePage(
                    viajeId: widget.viajeId,
                    taxistaNombre: 'Taxista ${widget.taxistaId.substring(0, 8)}...',
                  ),
                ),
              );
            },
            child: Text('Calificar Ahora'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelarViaje() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar Viaje'),
        content: Text('¿Estás seguro de que deseas cancelar este viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, cancelar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final result = await _pasajeroService.cancelarViaje(widget.viajeId);
        if (result['success']) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viaje cancelado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al cancelar viaje'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Viaje en Curso'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_estadoViaje != 'completado')
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _cancelarViaje,
              tooltip: 'Cancelar viaje',
            ),
        ],
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
                      if (_ubicacionTaxista != null)
                        Text(
                          'Taxista en camino',
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

          // Panel inferior con información
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
                SizedBox(height: 8),
                if (_ubicacionTaxista != null)
                  Text(
                    'Distancia estimada: ${_calcularDistancia().toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
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
        return 'Viaje Aceptado - El taxista está en camino';
      case 'en_progreso':
        return 'Viaje en Progreso';
      case 'completado':
        return 'Viaje Completado';
      default:
        return 'Estado: $_estadoViaje';
    }
  }

  double _calcularDistancia() {
    if (_ubicacionTaxista == null) {
      return LocationServiceSimple.calculateDistance(
        widget.origenLat,
        widget.origenLon,
        widget.destinoLat,
        widget.destinoLon,
      );
    } else {
      return LocationServiceSimple.calculateDistance(
        _ubicacionTaxista!['latitude']!,
        _ubicacionTaxista!['longitude']!,
        widget.destinoLat,
        widget.destinoLon,
      );
    }
  }
}

