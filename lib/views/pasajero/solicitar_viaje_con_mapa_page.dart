import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nawii/services/pasajero_service.dart';
import 'package:nawii/services/session_service.dart';
import 'package:nawii/services/location_service_simple.dart';
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/models/user_model.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/utils/message_dialog.dart';
import 'package:nawii/views/pasajero/viaje_en_curso_page.dart';
import 'package:nawii/widgets/places_autocomplete_field.dart';

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
  Map<String, UserModel> _taxistasCache = {};

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
          MessageDialog.showError(
            context,
            'Se necesitan permisos de ubicación para usar esta función',
            title: 'Permisos Requeridos',
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
      MessageDialog.showError(
        context,
        'Error al obtener ubicación: $e',
        title: 'Error de Ubicación',
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
      final taxistaNombre = _taxistasCache.containsKey(taxista['id'])
          ? _taxistasCache[taxista['id']]!.nombreCompleto
          : 'Taxista ${taxista['id'].substring(0, 8)}...';
      markers.add(Marker(
        markerId: MarkerId('taxista_${taxista['id']}'),
        position: LatLng(taxista['latitude'], taxista['longitude']),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueYellow,
        ),
        infoWindow: InfoWindow(
          title: taxistaNombre,
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
    taxisRef.onValue.listen((event) async {
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
      
      // Cargar datos completos de los taxistas
      for (var taxista in taxisList) {
        if (!_taxistasCache.containsKey(taxista['id'])) {
          _cargarDatosTaxista(taxista['id']);
        }
      }
      
      _actualizarMapa();
    });
  }

  Future<void> _cargarDatosTaxista(String taxistaId) async {
    try {
      final taxistaData = await _pasajeroService.obtenerUsuarioPorId(taxistaId);
      if (taxistaData != null) {
        setState(() {
          _taxistasCache[taxistaId] = taxistaData;
        });
        _actualizarMapa(); // Actualizar mapa para mostrar el nombre
      }
    } catch (e) {
      print('Error al cargar datos del taxista $taxistaId: $e');
    }
  }

  void _seleccionarTaxista(Map<String, dynamic> taxista) {
    setState(() {
      _taxistaSeleccionado = taxista;
    });
    _actualizarMapa();
    
    // Mostrar bottom sheet con información del taxista
    _mostrarInfoTaxista(taxista);
  }

  void _mostrarInfoTaxista(Map<String, dynamic> taxista) async {
    final distancia = LocationServiceSimple.calculateDistance(
      _userLocation['latitude']!,
      _userLocation['longitude']!,
      taxista['latitude'],
      taxista['longitude'],
    );

    // Obtener datos completos del taxista (usar caché si está disponible)
    UserModel? taxistaData = _taxistasCache[taxista['id']];
    if (taxistaData == null) {
      try {
        taxistaData = await _pasajeroService.obtenerUsuarioPorId(taxista['id']);
        if (taxistaData != null) {
          setState(() {
            _taxistasCache[taxista['id']] = taxistaData!;
          });
        }
      } catch (e) {
        print('Error al obtener datos del taxista: $e');
      }
    }

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
                        taxistaData != null 
                            ? taxistaData.nombreCompleto
                            : 'Taxista ${taxista['id'].substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (taxistaData != null && taxistaData.telefono != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, color: AppColors.mediumGrey, size: 16),
                            SizedBox(width: 4),
                            Text(
                              taxistaData.telefono!,
                              style: TextStyle(color: AppColors.mediumGrey, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                      if (taxistaData != null && taxistaData.email.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email, color: AppColors.mediumGrey, size: 16),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                taxistaData.email,
                                style: TextStyle(color: AppColors.mediumGrey, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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
      MessageDialog.showWarning(
        context,
        'Por favor ingresa un destino',
        title: 'Destino Requerido',
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

      // Mensaje de éxito con diálogo modal
      MessageDialog.showSuccess(
        context,
        'Destino confirmado: ${_destinoController.text}',
        title: 'Destino Confirmado',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      MessageDialog.showError(
        context,
        'No se pudo encontrar la ubicación. Intenta con una dirección más específica.',
        title: 'Error de Ubicación',
      );
    }
  }

  Future<void> _solicitarViaje() async {
    if (_destino == null) {
      MessageDialog.showWarning(
        context,
        'Por favor confirma el destino primero',
        title: 'Destino Requerido',
      );
      return;
    }

    if (_taxistaSeleccionado == null) {
      MessageDialog.showWarning(
        context,
        'Por favor selecciona un taxista del mapa',
        title: 'Taxista Requerido',
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

      // Verificar si la sesión expiró
      final sessionHandled = await SessionService.handleServiceResult(context, result);
      if (sessionHandled) {
        setState(() => _isSolicitandoViaje = false);
        return;
      }

      if (result['success']) {
        final viaje = result['viaje'] as ViajeModel?;
        
        MessageDialog.showInfo(
          context,
          'Solicitud enviada. Esperando respuesta del taxista...',
          title: 'Solicitud Enviada',
        );

        // Escuchar cambios en el estado del viaje
        _escucharEstadoViaje(viaje?.id ?? '');
      } else {
        MessageDialog.showError(
          context,
          result['message'] ?? 'Error al solicitar viaje',
          title: 'Error',
        );
        setState(() => _isSolicitandoViaje = false);
      }
    } catch (e) {
      MessageDialog.showError(
        context,
        'Error al solicitar viaje: $e',
        title: 'Error',
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
          MessageDialog.showWarning(
            context,
            'El taxista rechazó el viaje. Selecciona otro taxista.',
            title: 'Viaje Rechazado',
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
                        child: PlacesAutocompleteField(
                          controller: _destinoController,
                          hintText: 'Ingresa tu destino',
                          prefixIcon: Icons.flag,
                          prefixIconColor: AppColors.errorColor,
                          apiKey: 'AIzaSyCaZFeEmON_iOVCBO24V1FmQu0pQ2QrxhU',
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
                          onPlaceSelected: (placeId, description, lat, lng) {
                            // ⭐ NUEVO: Usar coordenadas directamente del lugar seleccionado
                            print('Lugar seleccionado: $description');
                            if (lat != null && lng != null) {
                              setState(() {
                                _destino = {
                                  'latitude': lat,
                                  'longitude': lng,
                                };
                              });
                              // Actualizar marcadores en el mapa
                              _actualizarMapa();
                              // Mover la cámara al destino
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(lat, lng),
                                  15.0,
                                ),
                              );
                            } else {
                              // Si no hay coordenadas, usar geocoding como fallback
                              _confirmarDestino();
                            }
                          },
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
                                      _taxistasCache.containsKey(_taxistaSeleccionado!['id'])
                                          ? _taxistasCache[_taxistaSeleccionado!['id']]!.nombreCompleto
                                          : 'ID: ${_taxistaSeleccionado!['id'].substring(0, 8)}...',
                                      style: TextStyle(fontSize: 12, color: AppColors.mediumGrey),
                                    ),
                                    if (_taxistasCache.containsKey(_taxistaSeleccionado!['id'])) ...[
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone, size: 12, color: AppColors.mediumGrey),
                                          SizedBox(width: 4),
                                          Text(
                                            _taxistasCache[_taxistaSeleccionado!['id']]!.telefono ?? 'Sin teléfono',
                                            style: TextStyle(fontSize: 11, color: AppColors.mediumGrey),
                                          ),
                                        ],
                                      ),
                                    ],
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

