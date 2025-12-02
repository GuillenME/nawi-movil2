import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nawii/services/location_service_simple.dart';
import 'package:nawii/services/taxista_service.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/services/session_service.dart';
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/widgets/persistent_message.dart';

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
  _TaxistaViajeEnCursoPageState createState() =>
      _TaxistaViajeEnCursoPageState();
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
  double? _tarifa; // Tarifa del viaje
  String? _mensajePersistente; // Mensaje persistente a mostrar

  @override
  void initState() {
    super.initState();
    _detectarMiUbicacion();
    _cargarInformacionViaje();
    _inicializarMapa();
    _escucharEstadoViaje();
    _escucharUbicacionPasajero();
    _actualizarMiUbicacionPeriodicamente();
  }

  Future<void> _cargarInformacionViaje() async {
    try {
      // Obtener información del viaje desde el backend para obtener la tarifa
      final viajes = await _taxistaService.obtenerMisViajes();
      if (viajes['success'] == true) {
        final listaViajes = viajes['viajes'] as List<ViajeModel>;
        try {
          final viajeActual = listaViajes.firstWhere(
            (v) => v.id == widget.viajeId,
          );
          setState(() {
            _tarifa = viajeActual.tarifa;
          });
        } catch (e) {
          // No se encontró el viaje en la lista, intentar obtener desde Firebase
          print('Viaje no encontrado en la lista, intentando desde Firebase');
        }
      }
    } catch (e) {
      print('Error al cargar información del viaje: $e');
    }
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
        position:
            LatLng(_miUbicacion!['latitude']!, _miUbicacion!['longitude']!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: 'Mi ubicación'),
      ));

      // Polilíneas según el estado del viaje
      if (_estadoViaje == 'aceptado' || _estadoViaje == 'en_progreso') {
        if (_estadoViaje == 'aceptado') {
          // Ruta 1: Del taxista al origen (donde está el pasajero)
          polylines.add(Polyline(
            polylineId: PolylineId('ruta_taxista_origen'),
            points: [
              LatLng(_miUbicacion!['latitude']!, _miUbicacion!['longitude']!),
              LatLng(widget.origenLat, widget.origenLon),
            ],
            color: Colors.blue,
            width: 4,
          ));

          // Ruta 2: Del origen al destino (ruta completa del viaje)
          polylines.add(Polyline(
            polylineId: PolylineId('ruta_origen_destino'),
            points: [
              LatLng(widget.origenLat, widget.origenLon),
              LatLng(widget.destinoLat, widget.destinoLon),
            ],
            color: Colors.orange,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ));
        } else {
          // Cuando el viaje está en progreso: solo del taxista al destino
          polylines.add(Polyline(
            polylineId: PolylineId('ruta'),
            points: [
              LatLng(_miUbicacion!['latitude']!, _miUbicacion!['longitude']!),
              LatLng(widget.destinoLat, widget.destinoLon),
            ],
            color: Colors.blue,
            width: 4,
          ));
        }
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

    // Ajustar cámara para incluir todos los puntos relevantes
    if (_miUbicacion != null) {
      // Calcular los límites incluyendo: taxista, origen y destino
      final latMin = [
        _miUbicacion!['latitude']!,
        widget.origenLat,
        widget.destinoLat,
      ].reduce((a, b) => a < b ? a : b);

      final latMax = [
        _miUbicacion!['latitude']!,
        widget.origenLat,
        widget.destinoLat,
      ].reduce((a, b) => a > b ? a : b);

      final lonMin = [
        _miUbicacion!['longitude']!,
        widget.origenLon,
        widget.destinoLon,
      ].reduce((a, b) => a < b ? a : b);

      final lonMax = [
        _miUbicacion!['longitude']!,
        widget.origenLon,
        widget.destinoLon,
      ].reduce((a, b) => a > b ? a : b);

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(latMin, lonMin),
            northeast: LatLng(latMax, lonMax),
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
    _viajeSubscription =
        viajesRef.child(widget.viajeId).onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final estado = data['estado'] as String?;
        final tarifa = data['tarifa']?.toDouble();

        setState(() {
          _estadoViaje = estado ?? 'aceptado';
          if (tarifa != null) {
            _tarifa = tarifa;
          }
        });
        _actualizarMapa();

        // Recargar información del viaje desde el backend para obtener la tarifa actualizada
        _cargarInformacionViaje();

        if (estado == 'completado' && !_isCompletado) {
          _isCompletado = true;
          _mostrarDialogoCompletado();
        } else if (estado == 'cancelado') {
          setState(() {
            _mensajePersistente = 'El viaje fue cancelado';
          });
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
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

        // Verificar si la sesión expiró
        final sessionHandled =
            await SessionService.handleServiceResult(context, result);
        if (sessionHandled) {
          return;
        }

        if (result['success']) {
          setState(() {
            _mensajePersistente = 'Viaje completado exitosamente';
          });
        } else {
          setState(() {
            _mensajePersistente =
                result['message'] ?? 'Error al completar viaje';
          });
        }
      } catch (e) {
        setState(() {
          _mensajePersistente = 'Error: $e';
        });
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
      setState(() {
        _mensajePersistente = 'Viaje iniciado';
      });
    } catch (e) {
      setState(() {
        _mensajePersistente = 'Error al iniciar viaje: $e';
      });
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                        Icon(Icons.flag, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Destino',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Mostrar tarifa si está establecida
                    if (_tarifa != null) ...[
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.attach_money,
                                color: Colors.green[700], size: 24),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tarifa del viaje',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'MX\$${_tarifa!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
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
              // Mensajes persistentes
              if (_mensajePersistente != null)
                PersistentMessage(
                  message: _mensajePersistente!,
                  backgroundColor: _mensajePersistente!.contains('Error') ||
                          _mensajePersistente!.contains('cancelado')
                      ? Colors.red[800]!
                      : _mensajePersistente!.contains('completado') ||
                              _mensajePersistente!.contains('iniciado')
                          ? Colors.green[800]!
                          : Colors.grey[800]!,
                  textColor: Colors.white,
                ),
              // Mensaje persistente sobre permisos de ubicación
              PersistentMessage.info(
                'Se solicitarán permisos de ubicación para funcionar como taxista',
              ),
            ],
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
