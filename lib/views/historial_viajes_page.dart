import 'package:flutter/material.dart';
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/models/user_model.dart';
import 'package:nawii/services/pasajero_service.dart';
import 'package:nawii/services/taxista_service.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/services/session_service.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/utils/date_formatter.dart';
import 'package:nawii/views/calificar_viaje_page.dart';

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
  Map<String, UserModel> _usuariosCache = {}; // Cache para datos de usuarios

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
      Map<String, dynamic> result;
      if (_isTaxista) {
        result = await _taxistaService.obtenerMisViajes();
      } else {
        result = await _pasajeroService.obtenerMisViajes();
      }

      // Verificar si la sesión expiró
      final sessionHandled = await SessionService.handleServiceResult(context, result);
      if (sessionHandled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<ViajeModel> viajes = [];
      if (result['success'] == true && result['viajes'] != null) {
        viajes = List<ViajeModel>.from(result['viajes']);
      }

      // Ordenar por fecha (más recientes primero)
      viajes.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

      // Cargar datos de usuarios que no vienen anidados
      for (var viaje in viajes) {
        if (_isTaxista && viaje.pasajero == null && viaje.pasajeroId != 0) {
          _cargarDatosUsuario(viaje.pasajeroId.toString());
        } else if (!_isTaxista && viaje.taxista == null && viaje.taxistaId != null) {
          _cargarDatosUsuario(viaje.taxistaId.toString());
        }
      }

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
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return AppColors.successColor;
      case 'cancelado':
        return AppColors.errorColor;
      case 'en_progreso':
        return AppColors.primaryYellow;
      case 'aceptado':
        return AppColors.primaryDark;
      case 'solicitado':
        return AppColors.mediumGrey;
      default:
        return AppColors.mediumGrey;
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

  Future<void> _cargarDatosUsuario(String userId) async {
    if (_usuariosCache.containsKey(userId)) {
      return; // Ya está en caché
    }

    try {
      final usuario = await _pasajeroService.obtenerUsuarioPorId(userId);
      if (usuario != null) {
        setState(() {
          _usuariosCache[userId] = usuario;
        });
      }
    } catch (e) {
      print('Error al cargar datos del usuario $userId: $e');
    }
  }

  UserModel? _obtenerDatosUsuario(ViajeModel viaje) {
    if (_isTaxista) {
      // Si es taxista, mostrar datos del pasajero
      if (viaje.pasajero != null) {
        return viaje.pasajero;
      }
      return _usuariosCache[viaje.pasajeroId.toString()];
    } else {
      // Si es pasajero, mostrar datos del taxista
      if (viaje.taxista != null) {
        return viaje.taxista;
      }
      if (viaje.taxistaId != null) {
        return _usuariosCache[viaje.taxistaId.toString()];
      }
    }
    return null;
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormatter.formatearFechaConHora(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Historial de Viajes'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
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
                        color: AppColors.mediumGrey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay viajes registrados',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.mediumGrey,
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
                      final usuarioData = _obtenerDatosUsuario(viaje);
                      
                      return Card(
                        color: AppColors.primaryDark.withOpacity(0.3),
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
                                              size: 16, color: AppColors.primaryYellow),
                                          SizedBox(width: 4),
                                          Text(
                                            viaje.calificacion!
                                                .toStringAsFixed(1),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryYellow,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                // Información del pasajero/taxista si está disponible
                                if (usuarioData != null) ...[
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: _isTaxista 
                                            ? AppColors.primaryDark 
                                            : AppColors.primaryYellow,
                                        radius: 16,
                                        child: Icon(
                                          Icons.person,
                                          size: 16,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              usuarioData.nombreCompleto,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (usuarioData.telefono != null) ...[
                                              SizedBox(height: 2),
                                              Text(
                                                usuarioData.telefono!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.mediumGrey,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                ],
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: AppColors.successColor, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        viaje.direccionOrigen,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.flag,
                                        color: AppColors.errorColor, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        viaje.direccionDestino,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white,
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
                                            color: AppColors.mediumGrey),
                                        SizedBox(width: 4),
                                        Text(
                                          _formatearFecha(viaje.fechaCreacion),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.mediumGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (viaje.comentario != null)
                                      Icon(Icons.message,
                                          size: 16, color: AppColors.mediumGrey),
                                  ],
                                ),
                                // Botón para calificar si el viaje está completado y no tiene calificación
                                if (viaje.estado == 'completado' && 
                                    viaje.calificacion == null && 
                                    !_isTaxista) ...[
                                  SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        final taxistaNombre = usuarioData?.nombreCompleto ?? 
                                            (_isTaxista 
                                                ? 'Pasajero ${viaje.pasajeroId}' 
                                                : 'Taxista ${viaje.taxistaId ?? "N/A"}');
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CalificarViajePage(
                                              viajeId: viaje.id,
                                              taxistaNombre: taxistaNombre,
                                            ),
                                          ),
                                        ).then((calificado) {
                                          if (calificado == true) {
                                            // Recargar viajes para mostrar la nueva calificación
                                            _cargarViajes();
                                          }
                                        });
                                      },
                                      icon: Icon(Icons.star, size: 18),
                                      label: Text('Calificar Viaje'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryYellow,
                                        foregroundColor: AppColors.primaryDark,
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
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

