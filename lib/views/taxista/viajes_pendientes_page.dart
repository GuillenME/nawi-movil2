import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/models/user_model.dart';
import 'package:nawii/services/taxista_service.dart';
import 'package:nawii/services/pasajero_service.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/services/session_service.dart';
import 'package:nawii/views/taxista/viaje_en_curso_page.dart';

class ViajesPendientesPage extends StatefulWidget {
  @override
  _ViajesPendientesPageState createState() => _ViajesPendientesPageState();
}

class _ViajesPendientesPageState extends State<ViajesPendientesPage> {
  final TaxistaService _taxistaService = TaxistaService();
  final PasajeroService _pasajeroService = PasajeroService();
  final DatabaseReference viajesRef = FirebaseDatabase.instance.ref('viajes');
  List<ViajeModel> _viajesPendientes = [];
  StreamSubscription? _viajesSubscription;
  bool _isLoading = true;
  String? _taxistaId;
  Map<String, UserModel> _usuariosCache = {};

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
      // ⭐ ACTUALIZADO: Firebase solo como complemento, el backend es la fuente principal
      // Esto es útil para actualizaciones en tiempo real de viajes ya asignados
      if (event.snapshot.exists && _taxistaId != null) {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          // Buscar viajes dirigidos a este taxista con estado 'solicitado'
          final nuevosViajes = <ViajeModel>[];

          print('🔍 Escuchando viajes en Firebase. Taxista ID: $_taxistaId');
          print('📦 Total de viajes en Firebase: ${data.length}');

          data.forEach((viajeId, viajeData) {
            if (viajeData is Map) {
              final estado = viajeData['estado'] as String?;
              final idTaxista = viajeData['id_taxista'] as String?;

              print('   Viaje $viajeId: estado=$estado, id_taxista=$idTaxista');

              // Si el viaje está dirigido a este taxista y está en estado 'solicitado'
              if (estado == 'solicitado' && idTaxista == _taxistaId) {
                print('   ✅ Viaje $viajeId coincide con este taxista');
                try {
                  // Convertir datos de Firebase a ViajeModel
                  final viaje =
                      _convertirFirebaseAViaje(viajeId.toString(), viajeData);
                  if (viaje != null) {
                    // ⭐ NUEVO: Validar que el viaje no haya expirado
                    if (viaje.tiempoLimiteAceptacion != null) {
                      final ahora = DateTime.now();
                      final limite = viaje.tiempoLimiteAceptacion!;
                      if (limite.isBefore(ahora)) {
                        print(
                            '   ⚠️  Viaje $viajeId ha expirado (limite: $limite, ahora: $ahora)');
                        return; // No agregar viajes expirados
                      }
                    }
                    nuevosViajes.add(viaje);
                    print('   ✅ Viaje agregado a la lista');
                  }
                } catch (e) {
                  print('   ❌ Error convirtiendo viaje: $e');
                }
              } else {
                print(
                    '   ⚠️  Viaje $viajeId no coincide: estado=$estado (esperado: solicitado), id_taxista=$idTaxista (esperado: $_taxistaId)');
              }
            }
          });

          print(
              '📊 Total de viajes pendientes desde Firebase: ${nuevosViajes.length}');
          // ⭐ ACTUALIZADO: Combinar con viajes del backend en lugar de reemplazar
          setState(() {
            // Mantener viajes del backend y agregar nuevos de Firebase que no estén duplicados
            final idsExistentes = _viajesPendientes.map((v) => v.id).toSet();
            final viajesNuevos = nuevosViajes
                .where((v) => !idsExistentes.contains(v.id))
                .toList();
            _viajesPendientes = [..._viajesPendientes, ...viajesNuevos];
            if (_isLoading) {
              _isLoading = false;
            }
          });
        } else {
          print('⚠️  No hay datos en Firebase');
          if (_isLoading) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        print('⚠️  No hay taxista ID o no hay datos en Firebase');
        if (_isLoading) {
          setState(() {
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

      final latOrigen = salida['lat']?.toDouble() ?? 0.0;
      final lonOrigen = salida['lon']?.toDouble() ?? 0.0;
      final latDestino = destino['lat']?.toDouble() ?? 0.0;
      final lonDestino = destino['lon']?.toDouble() ?? 0.0;

      // ⭐ ACTUALIZADO: Usar direcciones de Firebase si están disponibles, sino obtenerlas
      final direccionOrigen = viajeData['direccion_origen']?.toString() ??
          'Ubicación (${latOrigen.toStringAsFixed(4)}, ${lonOrigen.toStringAsFixed(4)})';
      final direccionDestino = viajeData['direccion_destino']?.toString() ??
          'Ubicación (${latDestino.toStringAsFixed(4)}, ${lonDestino.toStringAsFixed(4)})';

      // Solo obtener direcciones si no están disponibles y las coordenadas son válidas
      if ((direccionOrigen.contains('Ubicación') || direccionOrigen.isEmpty) &&
          latOrigen != 0.0 &&
          lonOrigen != 0.0) {
        _obtenerDireccionesParaViaje(
            viajeId, latOrigen, lonOrigen, latDestino, lonDestino);
      }

      return ViajeModel(
        id: viajeId,
        pasajeroId:
            int.tryParse(viajeData['id_pasajero']?.toString() ?? '0') ?? 0,
        taxistaId: viajeData['id_taxista'] != null
            ? int.tryParse(viajeData['id_taxista'].toString())
            : null,
        latitudOrigen: latOrigen,
        longitudOrigen: lonOrigen,
        direccionOrigen: direccionOrigen,
        latitudDestino: latDestino,
        longitudDestino: lonDestino,
        direccionDestino: direccionDestino,
        estado: viajeData['estado'] ?? 'solicitado',
        fechaCreacion: DateTime.fromMillisecondsSinceEpoch(
          viajeData['timestamp'] as int? ??
              DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      print('Error en _convertirFirebaseAViaje: $e');
      return null;
    }
  }

  Future<void> _obtenerDireccionesParaViaje(
    String viajeId,
    double latOrigen,
    double lonOrigen,
    double latDestino,
    double lonDestino,
  ) async {
    try {
      // Obtener direcciones en paralelo
      final direcciones = await Future.wait([
        _pasajeroService.obtenerDireccionDesdeCoordenadas(latOrigen, lonOrigen),
        _pasajeroService.obtenerDireccionDesdeCoordenadas(
            latDestino, lonDestino),
      ]);

      // Actualizar el viaje en la lista
      setState(() {
        final index = _viajesPendientes.indexWhere((v) => v.id == viajeId);
        if (index != -1) {
          final viaje = _viajesPendientes[index];
          _viajesPendientes[index] = ViajeModel(
            id: viaje.id,
            pasajeroId: viaje.pasajeroId,
            taxistaId: viaje.taxistaId,
            latitudOrigen: viaje.latitudOrigen,
            longitudOrigen: viaje.longitudOrigen,
            direccionOrigen: direcciones[0],
            latitudDestino: viaje.latitudDestino,
            longitudDestino: viaje.longitudDestino,
            direccionDestino: direcciones[1],
            estado: viaje.estado,
            fechaCreacion: viaje.fechaCreacion,
          );
        }
      });
    } catch (e) {
      print('Error al obtener direcciones: $e');
      // Si falla, usar coordenadas como fallback
      setState(() {
        final index = _viajesPendientes.indexWhere((v) => v.id == viajeId);
        if (index != -1) {
          final viaje = _viajesPendientes[index];
          _viajesPendientes[index] = ViajeModel(
            id: viaje.id,
            pasajeroId: viaje.pasajeroId,
            taxistaId: viaje.taxistaId,
            latitudOrigen: viaje.latitudOrigen,
            longitudOrigen: viaje.longitudOrigen,
            direccionOrigen:
                'Ubicación (${latOrigen.toStringAsFixed(4)}, ${lonOrigen.toStringAsFixed(4)})',
            latitudDestino: viaje.latitudDestino,
            longitudDestino: viaje.longitudDestino,
            direccionDestino:
                'Ubicación (${latDestino.toStringAsFixed(4)}, ${lonDestino.toStringAsFixed(4)})',
            estado: viaje.estado,
            fechaCreacion: viaje.fechaCreacion,
          );
        }
      });
    }
  }

  Future<void> _cargarViajesPendientes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ⭐ NUEVO: Cargar viajes disponibles desde el backend (filtra automáticamente expirados)
      final result = await _taxistaService.obtenerViajesDisponibles();

      // Verificar si la sesión expiró
      if (result['session_expired'] == true) {
        final sessionHandled =
            await SessionService.handleServiceResult(context, result);
        if (sessionHandled) {
          return;
        }
      }

      if (result['success'] == true) {
        final viajesBackend = result['viajes'] as List<ViajeModel>;

        // Filtrar viajes que están dirigidos a este taxista específico o sin taxista asignado
        final viajesFiltrados = viajesBackend.where((viaje) {
          // Si el viaje tiene un taxista asignado, debe ser este taxista
          if (viaje.taxistaId != null) {
            final taxistaIdViaje = viaje.taxistaId.toString();
            final coincide = taxistaIdViaje == _taxistaId;
            print('   🔍 Viaje ${viaje.id}: taxistaId=$taxistaIdViaje, esperado=$_taxistaId, coincide=$coincide');
            return coincide;
          }
          // Si no tiene taxista, está disponible para todos
          print('   ✅ Viaje ${viaje.id}: Sin taxista asignado, disponible para todos');
          return true;
        }).toList();

        // Validar que los viajes no hayan expirado (doble verificación)
        final viajesValidos = viajesFiltrados.where((viaje) {
          if (viaje.tiempoLimiteAceptacion != null) {
            final ahora = DateTime.now();
            final limite = viaje.tiempoLimiteAceptacion!;
            return limite.isAfter(ahora);
          }
          return true; // Si no tiene límite, está disponible
        }).toList();

        print('📊 Viajes disponibles desde backend: ${viajesValidos.length}');
        
        // ⭐ NUEVO: Filtrar viajes sin ID válido y mostrar advertencia
        final viajesConId = viajesValidos.where((v) => v.id.isNotEmpty && v.id != 'null').toList();
        final viajesSinId = viajesValidos.where((v) => v.id.isEmpty || v.id == 'null').toList();
        
        if (viajesSinId.isNotEmpty) {
          print('⚠️  ADVERTENCIA: ${viajesSinId.length} viajes sin ID válido del backend');
          print('   Estos viajes no se pueden aceptar/rechazar hasta que el backend envíe el ID');
          // Mostrar mensaje al usuario
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Algunos viajes no tienen ID válido. Verifica que el backend envíe el campo "id" en la respuesta.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }

        setState(() {
          // ⭐ ACTUALIZADO: Priorizar viajes del backend (tienen direcciones correctas)
          // Solo agregar viajes de Firebase que no estén en el backend
          final idsBackend = viajesConId.map((v) => v.id).toSet();
          final viajesFirebase = _viajesPendientes
              .where((v) => !idsBackend.contains(v.id))
              .toList();

          // Los viajes del backend ya tienen direcciones correctas del API
          // Los de Firebase necesitan obtener direcciones (se hará automáticamente)
          // ⭐ IMPORTANTE: Solo incluir viajes con ID válido
          _viajesPendientes = [...viajesConId, ...viajesFirebase];
          _isLoading = false;

          print('✅ Viajes cargados: ${viajesConId.length} del backend (con ID), ${viajesFirebase.length} de Firebase');
          // Verificar direcciones de los viajes del backend
          for (var viaje in viajesConId) {
            print('   Viaje ${viaje.id}: Origen="${viaje.direccionOrigen}", Destino="${viaje.direccionDestino}"');
          }
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error al cargar viajes: $e');
    }
  }

  Future<void> _aceptarViaje(ViajeModel viaje) async {
    try {
      // ⭐ NUEVO: Validar que el viaje tenga un ID válido antes de intentar aceptarlo
      if (viaje.id.isEmpty || viaje.id == 'null' || viaje.id == '') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Error')),
              ],
            ),
            content: Text(
              'Este viaje no tiene un ID válido. Por favor, recarga la lista de viajes.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cargarViajesPendientes();
                },
                child: Text('Recargar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
            ],
          ),
        );
        return;
      }
      
      print('🚕 Intentando aceptar viaje ID: ${viaje.id}');
      print('   Tipo de ID: ${viaje.id.runtimeType}');
      print('   Estado: ${viaje.estado}');
      print('   Taxista ID actual: $_taxistaId (tipo: ${_taxistaId.runtimeType})');
      print('   Taxista ID del viaje: ${viaje.taxistaId} (tipo: ${viaje.taxistaId.runtimeType})');
      print('   Tiempo límite: ${viaje.tiempoLimiteAceptacion}');
      if (viaje.tiempoLimiteAceptacion != null) {
        final ahora = DateTime.now();
        final limite = viaje.tiempoLimiteAceptacion!;
        final expirado = limite.isBefore(ahora);
        print('   ⏱️  Tiempo restante: ${limite.difference(ahora).inMinutes} minutos');
        print('   ⚠️  Expirado: $expirado');
      }
      
      final result = await _taxistaService.aceptarViaje(viaje.id);

      // Verificar si la sesión expiró
      final sessionHandled =
          await SessionService.handleServiceResult(context, result);
      if (sessionHandled) {
        return;
      }

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Viaje aceptado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Remover el viaje de la lista local
        setState(() {
          _viajesPendientes.removeWhere((v) => v.id == viaje.id);
        });

        // Navegar a la página de viaje en curso
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TaxistaViajeEnCursoPage(
              viajeId: viaje.id,
              origenLat: viaje.latitudOrigen,
              origenLon: viaje.longitudOrigen,
              destinoLat: viaje.latitudDestino,
              destinoLon: viaje.longitudDestino,
              pasajeroId: viaje.pasajeroId.toString(),
            ),
          ),
        );
      } else {
        // ⭐ MEJORADO: Mostrar diálogo con información detallada del error
        String mensaje = result['message'] ?? 'No se pudo aceptar el viaje';
        String mensajeDetallado = result['error_details'] ?? mensaje;
        
        bool esExpirado = mensaje.toLowerCase().contains('expirado') || 
                         mensaje.toLowerCase().contains('tiempo límite') ||
                         mensaje.toLowerCase().contains('tiempo limite');
        
        if (esExpirado) {
          mensaje = 'Este viaje ya no está disponible. El tiempo límite para aceptarlo ha expirado.';
          setState(() {
            _viajesPendientes.removeWhere((v) => v.id == viaje.id);
          });
          _cargarViajesPendientes();
        }
        
        // Mostrar diálogo con información detallada
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Error al Aceptar Viaje')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mensaje, style: TextStyle(fontSize: 16)),
                  if (mensajeDetallado != mensaje) ...[
                    SizedBox(height: 12),
                    Divider(),
                    Text(
                      'Detalles técnicos:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      mensajeDetallado,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ],
                  SizedBox(height: 12),
                  Divider(),
                  Text(
                    'Información del viaje:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text('ID: ${viaje.id}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  Text('Estado: ${viaje.estado}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  if (viaje.tiempoLimiteAceptacion != null) ...[
                    Text(
                      'Tiempo límite: ${viaje.tiempoLimiteAceptacion}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      'Expirado: ${viaje.tiempoLimiteAceptacion!.isBefore(DateTime.now()) ? "Sí" : "No"}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
            ],
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
      // ⭐ NUEVO: Validar que el viaje tenga un ID válido antes de intentar rechazarlo
      if (viaje.id.isEmpty || viaje.id == 'null' || viaje.id == '') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Error')),
              ],
            ),
            content: Text(
              'Este viaje no tiene un ID válido. Por favor, recarga la lista de viajes.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cargarViajesPendientes();
                },
                child: Text('Recargar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
            ],
          ),
        );
        return;
      }
      
      print('❌ Intentando rechazar viaje ID: ${viaje.id}');

      final result = await _taxistaService.rechazarViaje(viaje.id);

      // Verificar si la sesión expiró
      final sessionHandled =
          await SessionService.handleServiceResult(context, result);
      if (sessionHandled) {
        return;
      }

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Viaje rechazado'),
            backgroundColor: Colors.orange,
          ),
        );
        // Remover el viaje de la lista local
        setState(() {
          _viajesPendientes.removeWhere((v) => v.id == viaje.id);
        });
        // Recargar viajes disponibles
        _cargarViajesPendientes();
      } else {
        String mensaje = result['message'] ?? 'No se pudo rechazar el viaje';
        String mensajeDetallado = result['error_details'] ?? mensaje;
        
        bool esExpirado = mensaje.toLowerCase().contains('expirado') || 
                         mensaje.toLowerCase().contains('tiempo límite') ||
                         mensaje.toLowerCase().contains('tiempo limite');
        
        if (esExpirado) {
          mensaje = 'Este viaje ya no está disponible. El tiempo límite ha expirado.';
          setState(() {
            _viajesPendientes.removeWhere((v) => v.id == viaje.id);
          });
          _cargarViajesPendientes();
        }
        
        // Mostrar diálogo con información detallada
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Error al Rechazar Viaje')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mensaje, style: TextStyle(fontSize: 16)),
                  if (mensajeDetallado != mensaje) ...[
                    SizedBox(height: 12),
                    Divider(),
                    Text(
                      'Detalles técnicos:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      mensajeDetallado,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ],
                  SizedBox(height: 12),
                  Divider(),
                  Text(
                    'Información del viaje:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text('ID: ${viaje.id}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  Text('Estado: ${viaje.estado}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
            ],
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
                      // Usar datos anidados del viaje si están disponibles, sino obtenerlos
                      final usuario = viaje.pasajero;
                      final tieneDatosAnidados = usuario != null;

                      return FutureBuilder<UserModel?>(
                        future: tieneDatosAnidados
                            ? Future.value(usuario)
                            : _obtenerDatosUsuario(viaje.pasajeroId.toString()),
                        builder: (context, snapshot) {
                          final usuarioData = snapshot.data ?? usuario;
                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Información del pasajero
                                  if (usuarioData != null) ...[
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.blue[700],
                                          radius: 20,
                                          child: Icon(Icons.person,
                                              color: Colors.white, size: 20),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                usuarioData.nombreCompleto,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (usuarioData.telefono !=
                                                  null) ...[
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.phone,
                                                        size: 14,
                                                        color:
                                                            Colors.grey[600]),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      usuarioData.telefono!,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Divider(),
                                    SizedBox(height: 8),
                                  ],
                                  // Origen
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.red),
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
                                  // Destino
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
                                      // ⭐ NUEVO: Mostrar tiempo restante si hay límite
                                      if (viaje.tiempoLimiteAceptacion !=
                                          null) ...[
                                        SizedBox(width: 16),
                                        _buildTiempoRestante(
                                            viaje.tiempoLimiteAceptacion!),
                                      ],
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
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _rechazarViaje(viaje),
                                          icon: Icon(Icons.close, size: 18),
                                          label: Text('Rechazar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[700],
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
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

  // ⭐ NUEVO: Widget para mostrar tiempo restante antes de expirar
  Widget _buildTiempoRestante(DateTime limite) {
    final ahora = DateTime.now();
    final diferencia = limite.difference(ahora);

    if (diferencia.isNegative) {
      // Ya expiró
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 14, color: Colors.red[700]),
            SizedBox(width: 4),
            Text(
              'Expirado',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final minutosRestantes = diferencia.inMinutes;
    final segundosRestantes = diferencia.inSeconds % 60;

    Color color;
    if (minutosRestantes < 1) {
      color = Colors.red[700]!;
    } else if (minutosRestantes < 2) {
      color = Colors.orange[700]!;
    } else {
      color = Colors.green[700]!;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            minutosRestantes < 1
                ? '${segundosRestantes}s'
                : '${minutosRestantes}m',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<UserModel?> _obtenerDatosUsuario(String userId) async {
    if (_usuariosCache.containsKey(userId)) {
      return _usuariosCache[userId];
    }

    try {
      final usuario = await _pasajeroService.obtenerUsuarioPorId(userId);
      if (usuario != null) {
        _usuariosCache[userId] = usuario;
      }
      return usuario;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }
}
