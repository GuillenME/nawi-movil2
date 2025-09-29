import 'package:flutter/material.dart';
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/services/taxista_service.dart';

class ViajesPendientesPage extends StatefulWidget {
  @override
  _ViajesPendientesPageState createState() => _ViajesPendientesPageState();
}

class _ViajesPendientesPageState extends State<ViajesPendientesPage> {
  final TaxistaService _taxistaService = TaxistaService();
  List<ViajeModel> _viajesPendientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarViajesPendientes();
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
