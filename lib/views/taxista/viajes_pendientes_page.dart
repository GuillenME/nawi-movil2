import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/services/taxista_service.dart';
import 'package:nawii/services/auth_service.dart';

class ViajesPendientesPage extends StatefulWidget {
  @override
  _ViajesPendientesPageState createState() => _ViajesPendientesPageState();
}

class _ViajesPendientesPageState extends State<ViajesPendientesPage> {
  final TaxistaService _taxistaService = TaxistaService();
  final DatabaseReference viajesRef = FirebaseDatabase.instance.ref('viajes');
  List<ViajeModel> _viajesPendientes = [];
  StreamSubscription? _viajesSubscription;
  bool _isLoading = true;
  String? _taxistaId;

  @override
  void initState() {
    super.initState();
    _obtenerTaxistaId();
    _cargarViajesPendientes();
    _escucharViajesEnTiempoReal();
  }

  @override
  void dispose() {
    _viajesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _obtenerTaxistaId() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      _taxistaId = user?.id;
    });
  }

  void _escucharViajesEnTiempoReal() {
    _viajesSubscription = viajesRef.onValue.listen((event) {
      if (event.snapshot.exists && _taxistaId != null) {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          // Buscar viajes dirigidos a este taxista con estado 'solicitado'
          final nuevosViajes = <ViajeModel>[];
          
          data.forEach((viajeId, viajeData) {
            if (viajeData is Map) {
              final estado = viajeData['estado'] as String?;
              final idTaxista = viajeData['id_taxista'] as String?;
              
              // Si el viaje está dirigido a este taxista y está en estado 'solicitado'
              if (estado == 'solicitado' && idTaxista == _taxistaId) {
                try {
                  // Convertir datos de Firebase a ViajeModel
                  final viaje = _convertirFirebaseAViaje(viajeId.toString(), viajeData);
                  if (viaje != null) {
                    nuevosViajes.add(viaje);
                  }
                } catch (e) {
                  print('Error convirtiendo viaje: $e');
                }
              }
            }
          });

          setState(() {
            _viajesPendientes = nuevosViajes;
            _isLoading = false;
          });
        }
      }
    });
  }

  ViajeModel? _convertirFirebaseAViaje(String viajeId, Map viajeData) {
    try {
      final salida = viajeData['salida'] as Map?;
      final destino = viajeData['destino'] as Map?;
      
      if (salida == null || destino == null) return null;

      return ViajeModel(
        id: viajeId,
        pasajeroId: int.tryParse(viajeData['id_pasajero']?.toString() ?? '0') ?? 0,
        taxistaId: viajeData['id_taxista'] != null 
            ? int.tryParse(viajeData['id_taxista'].toString()) 
            : null,
        latitudOrigen: salida['lat']?.toDouble() ?? 0.0,
        longitudOrigen: salida['lon']?.toDouble() ?? 0.0,
        direccionOrigen: 'Origen',
        latitudDestino: destino['lat']?.toDouble() ?? 0.0,
        longitudDestino: destino['lon']?.toDouble() ?? 0.0,
        direccionDestino: 'Destino',
        estado: viajeData['estado'] ?? 'solicitado',
        fechaCreacion: DateTime.fromMillisecondsSinceEpoch(
          viajeData['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      print('Error en _convertirFirebaseAViaje: $e');
      return null;
    }
  }

  Future<void> _cargarViajesPendientes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final viajes = await _taxistaService.obtenerViajesDisponibles();
      setState(() {
        _viajesPendientes = viajes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar viajes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _aceptarViaje(ViajeModel viaje) async {
    try {
      final result = await _taxistaService.aceptarViaje(viaje.id);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        _cargarViajesPendientes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aceptar viaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rechazarViaje(ViajeModel viaje) async {
    try {
      final result = await _taxistaService.rechazarViaje(viaje.id);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.orange,
          ),
        );
        _cargarViajesPendientes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al rechazar viaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Viajes Pendientes'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarViajesPendientes,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _viajesPendientes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay viajes pendientes',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Los viajes aparecerán aquí cuando estés en línea',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarViajesPendientes,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _viajesPendientes.length,
                    itemBuilder: (context, index) {
                      final viaje = _viajesPendientes[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.red),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      viaje.direccionOrigen,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.flag, color: Colors.green),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      viaje.direccionDestino,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    'Hace ${_calcularTiempo(viaje.fechaCreacion)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _aceptarViaje(viaje),
                                      icon: Icon(Icons.check, size: 18),
                                      label: Text('Aceptar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _rechazarViaje(viaje),
                                      icon: Icon(Icons.close, size: 18),
                                      label: Text('Rechazar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[700],
                                        foregroundColor: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _calcularTiempo(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.inMinutes < 1) {
      return 'ahora';
    } else if (diferencia.inMinutes < 60) {
      return '${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return '${diferencia.inHours} h';
    } else {
      return '${diferencia.inDays} días';
    }
  }
}
