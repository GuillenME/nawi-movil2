import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nawii/services/pasajero_service.dart';
import 'package:nawii/services/session_service.dart';
import 'package:nawii/models/user_model.dart';

class SeleccionarTaxistaPage extends StatefulWidget {
  final Map<String, double> origen;
  final Map<String, double> destino;
  final String direccionOrigen;
  final String direccionDestino;

  const SeleccionarTaxistaPage({
    Key? key,
    required this.origen,
    required this.destino,
    required this.direccionOrigen,
    required this.direccionDestino,
  }) : super(key: key);

  @override
  _SeleccionarTaxistaPageState createState() => _SeleccionarTaxistaPageState();
}

class _SeleccionarTaxistaPageState extends State<SeleccionarTaxistaPage> {
  final DatabaseReference taxisRef = FirebaseDatabase.instance.ref('taxis');
  final PasajeroService _pasajeroService = PasajeroService();

  List<Map<String, dynamic>> _taxisDisponibles = [];
  Map<String, dynamic>? _taxistaSeleccionado;
  bool _isSolicitandoViaje = false;
  Map<String, UserModel> _taxistasCache = {};

  @override
  void initState() {
    super.initState();
    _escucharTaxis();
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
    });
  }

  Future<void> _cargarDatosTaxista(String taxistaId) async {
    try {
      final taxistaData = await _pasajeroService.obtenerUsuarioPorId(taxistaId);
      if (taxistaData != null) {
        setState(() {
          _taxistasCache[taxistaId] = taxistaData;
        });
      }
    } catch (e) {
      print('Error al cargar datos del taxista $taxistaId: $e');
    }
  }

  void _seleccionarTaxista(Map<String, dynamic> taxista) {
    // Mostrar perfil del taxista antes de seleccionar
    _mostrarPerfilTaxista(taxista);
  }

  void _mostrarPerfilTaxista(Map<String, dynamic> taxista) async {
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

    // Verificar si este taxista ya está seleccionado
    final yaSeleccionado = _taxistaSeleccionado?['id'] == taxista['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información del taxista
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[700],
                  radius: 30,
                  child: Icon(Icons.local_taxi, color: Colors.white, size: 30),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              taxistaData != null
                                  ? taxistaData.nombreCompleto
                                  : 'Taxista ${taxista['id'].substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (yaSeleccionado)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 14, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'Seleccionado',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (taxistaData != null &&
                          taxistaData.telefono != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                color: Colors.grey[600], size: 16),
                            SizedBox(width: 4),
                            Text(
                              taxistaData.telefono!,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                      if (taxistaData != null &&
                          taxistaData.email.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email,
                                color: Colors.grey[600], size: 16),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                taxistaData.email,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text('4.5 ⭐'),
                          SizedBox(width: 16),
                          Icon(Icons.access_time,
                              color: Colors.grey[600], size: 16),
                          SizedBox(width: 4),
                          Text('Disponible ahora'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close),
                    label: Text('Cancelar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Seleccionar el taxista
                      setState(() {
                        _taxistaSeleccionado = taxista;
                      });
                      Navigator.pop(context);

                      // Mostrar mensaje de confirmación
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Taxista seleccionado: ${taxistaData?.nombreCompleto ?? "Taxista"}',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(Icons.check),
                    label: Text(
                        yaSeleccionado ? 'Ya seleccionado' : 'Seleccionar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yaSeleccionado
                          ? Colors.green.withOpacity(0.5)
                          : Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
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

  Future<void> _solicitarViaje() async {
    if (_taxistaSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona un taxista'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSolicitandoViaje = true;
    });

    try {
      final result = await _pasajeroService.crearViaje(
        salidaLat: widget.origen['latitude']!,
        salidaLon: widget.origen['longitude']!,
        destinoLat: widget.destino['latitude']!,
        destinoLon: widget.destino['longitude']!,
      );

      // Verificar si la sesión expiró
      final sessionHandled =
          await SessionService.handleServiceResult(context, result);
      if (sessionHandled) {
        setState(() {
          _isSolicitandoViaje = false;
        });
        return;
      }

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
          content: Text('Error al solicitar viaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isSolicitandoViaje = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Taxista'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Información del viaje
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalles del Viaje',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.direccionOrigen,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.direccionDestino,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de taxistas disponibles
          Expanded(
            child: _taxisDisponibles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_taxi,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay taxistas disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Intenta de nuevo en unos momentos',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _taxisDisponibles.length,
                    itemBuilder: (context, index) {
                      final taxista = _taxisDisponibles[index];
                      final isSelected =
                          _taxistaSeleccionado?['id'] == taxista['id'];

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.blue[50] : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Colors.blue[700]
                                : Colors.grey[300],
                            child: Icon(
                              Icons.local_taxi,
                              color:
                                  isSelected ? Colors.white : Colors.grey[600],
                            ),
                          ),
                          title: Text(
                            _taxistasCache.containsKey(taxista['id'])
                                ? _taxistasCache[taxista['id']]!.nombreCompleto
                                : 'Taxista ${taxista['id'].substring(0, 8)}...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected ? Colors.blue[700] : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Disponible ahora'),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.orange, size: 16),
                                  SizedBox(width: 4),
                                  Text('4.5 ⭐'),
                                  SizedBox(width: 16),
                                  Icon(Icons.access_time,
                                      color: Colors.grey[600], size: 16),
                                  SizedBox(width: 4),
                                  Text('2 min'),
                                ],
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: Colors.blue[700])
                              : Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey[400]),
                          onTap: () => _seleccionarTaxista(taxista),
                        ),
                      );
                    },
                  ),
          ),

          // Información del taxista seleccionado
          if (_taxistaSeleccionado != null)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Taxista Seleccionado',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red[700]),
                        tooltip: 'Cancelar selección de taxista',
                        onPressed: () {
                          setState(() {
                            _taxistaSeleccionado = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selección de taxista cancelada'),
                              backgroundColor: Colors.grey[600],
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _taxistasCache
                                  .containsKey(_taxistaSeleccionado!['id'])
                              ? _taxistasCache[_taxistaSeleccionado!['id']]!
                                  .nombreCompleto
                              : 'ID: ${_taxistaSeleccionado!['id'].substring(0, 8)}...',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  if (_taxistasCache
                      .containsKey(_taxistaSeleccionado!['id'])) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, color: Colors.blue[700], size: 16),
                        SizedBox(width: 8),
                        Text(
                          _taxistasCache[_taxistaSeleccionado!['id']]!
                                  .telefono ??
                              'Sin teléfono',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    if (_taxistasCache[_taxistaSeleccionado!['id']]!
                        .email
                        .isNotEmpty) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.blue[700], size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _taxistasCache[_taxistaSeleccionado!['id']]!
                                  .email,
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Calificación: 4.5 ⭐'),
                    ],
                  ),
                ],
              ),
            ),

          // Botones de acción
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSolicitandoViaje ? null : _solicitarViaje,
                    icon: _isSolicitandoViaje
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.check),
                    label: Text(
                        _isSolicitandoViaje ? 'Solicitando...' : 'Solicitar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _taxistaSeleccionado = null;
                      });
                    },
                    icon: Icon(Icons.close),
                    label: Text('Cancelar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
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
