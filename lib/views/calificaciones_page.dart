import 'package:flutter/material.dart';
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/models/user_model.dart';
import 'package:nawii/services/pasajero_service.dart';
import 'package:nawii/services/taxista_service.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/services/session_service.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/utils/date_formatter.dart';

class CalificacionesPage extends StatefulWidget {
  @override
  _CalificacionesPageState createState() => _CalificacionesPageState();
}

class _CalificacionesPageState extends State<CalificacionesPage> {
  final PasajeroService _pasajeroService = PasajeroService();
  final TaxistaService _taxistaService = TaxistaService();

  List<ViajeModel> _viajes = [];
  bool _isLoading = true;
  bool _isTaxista = false;
  Map<String, UserModel> _usuariosCache = {};

  // Estadísticas
  double _promedioCalificacion = 0.0;
  int _totalCalificaciones = 0;
  Map<int, int> _distribucionCalificaciones = {};

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
      final sessionHandled =
          await SessionService.handleServiceResult(context, result);
      if (sessionHandled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<ViajeModel> viajes = [];
      if (result['success'] == true && result['viajes'] != null) {
        viajes = result['viajes'] as List<ViajeModel>;
      }

      // Filtrar solo viajes con calificaciones
      final viajesConCalificacion =
          viajes.where((v) => v.calificacion != null).toList();

      // Calcular estadísticas
      _calcularEstadisticas(viajesConCalificacion);

      setState(() {
        _viajes = viajesConCalificacion;
        _isLoading = false;
      });

      // Cargar datos de usuarios
      for (var viaje in viajesConCalificacion) {
        if (_isTaxista && viaje.pasajeroId != 0) {
          _cargarDatosUsuario(viaje.pasajeroId.toString());
        } else if (!_isTaxista && viaje.taxistaId != null) {
          _cargarDatosUsuario(viaje.taxistaId.toString());
        }
      }
    } catch (e) {
      print('Error al cargar calificaciones: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calcularEstadisticas(List<ViajeModel> viajes) {
    if (viajes.isEmpty) {
      _promedioCalificacion = 0.0;
      _totalCalificaciones = 0;
      _distribucionCalificaciones = {};
      return;
    }

    double suma = 0.0;
    _distribucionCalificaciones = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var viaje in viajes) {
      if (viaje.calificacion != null) {
        final calif = viaje.calificacion!.round();
        suma += viaje.calificacion!;
        _distribucionCalificaciones[calif] =
            (_distribucionCalificaciones[calif] ?? 0) + 1;
      }
    }

    _promedioCalificacion = suma / viajes.length;
    _totalCalificaciones = viajes.length;
  }

  Future<void> _cargarDatosUsuario(String userId) async {
    if (_usuariosCache.containsKey(userId)) return;

    try {
      UserModel? usuario;
      if (_isTaxista) {
        usuario = await _pasajeroService.obtenerUsuarioPorId(userId);
      } else {
        usuario = await _pasajeroService.obtenerUsuarioPorId(userId);
      }

      if (usuario != null) {
        setState(() {
          _usuariosCache[userId] = usuario!;
        });
      }
    } catch (e) {
      print('Error al cargar datos del usuario $userId: $e');
    }
  }

  UserModel? _obtenerDatosUsuario(ViajeModel viaje) {
    if (_isTaxista) {
      return viaje.pasajero ?? _usuariosCache[viaje.pasajeroId.toString()];
    } else {
      return viaje.taxista ?? _usuariosCache[viaje.taxistaId?.toString() ?? ''];
    }
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormatter.formatearFecha(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Mis Calificaciones'),
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
                        Icons.star_border,
                        size: 64,
                        color: AppColors.mediumGrey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tienes calificaciones aún',
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
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      // Estadísticas
                      Card(
                        color: AppColors.primaryDark.withOpacity(0.3),
                        margin: EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.star,
                                      color: AppColors.primaryYellow, size: 40),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _promedioCalificacion
                                            .toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryYellow,
                                        ),
                                      ),
                                      Text(
                                        'de 5.0 estrellas',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.mediumGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                '$_totalCalificaciones ${_totalCalificaciones == 1 ? 'calificación' : 'calificaciones'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.white,
                                ),
                              ),
                              SizedBox(height: 16),
                              // Distribución de calificaciones
                              ...List.generate(5, (index) {
                                final calif = 5 - index;
                                final cantidad =
                                    _distribucionCalificaciones[calif] ?? 0;
                                final porcentaje = _totalCalificaciones > 0
                                    ? (cantidad / _totalCalificaciones * 100)
                                    : 0.0;
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        child: Text(
                                          '$calif',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.star,
                                          size: 16,
                                          color: AppColors.primaryYellow),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: porcentaje / 100,
                                          backgroundColor: AppColors.primaryDark.withOpacity(0.5),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AppColors.primaryYellow),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      SizedBox(
                                        width: 30,
                                        child: Text(
                                          '$cantidad',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.mediumGrey,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      // Lista de calificaciones
                      ...List.generate(_viajes.length, (index) {
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
                                      // Calificación con estrellas
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
                                  if (viaje.comentario != null &&
                                      viaje.comentario!.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.message,
                                            size: 16, color: AppColors.mediumGrey),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            viaje.comentario!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.white,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
