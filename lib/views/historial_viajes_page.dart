import 'package:flutter/material.dart';
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/services/pasajero_service.dart';
import 'package:nawii/services/taxista_service.dart';
import 'package:nawii/services/auth_service.dart';

class HistorialViajesPage extends StatefulWidget {
  @override
  _HistorialViajesPageState createState() => _HistorialViajesPageState();
}

class _HistorialViajesPageState extends State<HistorialViajesPage> {
  final PasajeroService _pasajeroService = PasajeroService();
  final TaxistaService _taxistaService = TaxistaService();
  
  List<ViajeModel> _viajes = [];
  bool _isLoading = true;
  bool _isTaxista = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndViajes();
  }

  Future<void> _loadUserAndViajes() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isTaxista = user.isTaxista;
    });

    await _cargarViajes();
  }

  Future<void> _cargarViajes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<ViajeModel> viajes = [];
      if (_isTaxista) {
        viajes = await _taxistaService.obtenerMisViajes();
      } else {
        viajes = await _pasajeroService.obtenerMisViajes();
      }

      // Ordenar por fecha (más recientes primero)
      viajes.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

      setState(() {
        _viajes = viajes;
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

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'en_progreso':
        return Colors.orange;
      case 'aceptado':
        return Colors.blue;
      case 'solicitado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getTextoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      case 'en_progreso':
        return 'En Progreso';
      case 'aceptado':
        return 'Aceptado';
      case 'solicitado':
        return 'Solicitado';
      default:
        return estado;
    }
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Viajes'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _viajes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay viajes registrados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarViajes,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _viajes.length,
                    itemBuilder: (context, index) {
                      final viaje = _viajes[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            // TODO: Mostrar detalles del viaje
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getColorEstado(viaje.estado)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getColorEstado(viaje.estado),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getTextoEstado(viaje.estado),
                                        style: TextStyle(
                                          color: _getColorEstado(viaje.estado),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (viaje.calificacion != null)
                                      Row(
                                        children: [
                                          Icon(Icons.star,
                                              size: 16, color: Colors.orange),
                                          SizedBox(width: 4),
                                          Text(
                                            viaje.calificacion!
                                                .toStringAsFixed(1),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.green, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        viaje.direccionOrigen,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.flag,
                                        color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        viaje.direccionDestino,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 16,
                                            color: Colors.grey[600]),
                                        SizedBox(width: 4),
                                        Text(
                                          _formatearFecha(viaje.fechaCreacion),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (viaje.comentario != null)
                                      Icon(Icons.message,
                                          size: 16, color: Colors.grey[600]),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

