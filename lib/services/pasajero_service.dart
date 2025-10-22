import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/services/auth_service.dart';

class PasajeroService {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  static const String baseUrl = 'https://nawi.click/api';

  // Crear nuevo viaje
  Future<Map<String, dynamic>> crearViaje({
    required double salidaLat,
    required double salidaLon,
    required double destinoLat,
    required double destinoLon,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/pasajero/crear-viaje'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({
          'id_pasajero': user.id,
          'salida': {
            'lat': salidaLat,
            'lon': salidaLon,
          },
          'destino': {
            'lat': destinoLat,
            'lon': destinoLon,
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Guardar en Firebase para tiempo real
          await _guardarViajeEnFirebase(data['data']);
          return {
            'success': true,
            'viaje': ViajeModel.fromJson(data['data']),
            'message': data['message'] ?? 'Viaje creado exitosamente',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error al crear viaje',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error de conexión: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Ver mis viajes
  Future<List<ViajeModel>> obtenerMisViajes() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/pasajero/mis-viajes'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          List<ViajeModel> viajes = [];
          for (var viajeData in data['data']) {
            viajes.add(ViajeModel.fromJson(viajeData));
          }
          return viajes;
        }
      }
      return [];
    } catch (e) {
      print('Error obteniendo viajes: $e');
      return [];
    }
  }

  // Cancelar viaje
  Future<Map<String, dynamic>> cancelarViaje(String viajeId) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/pasajero/cancelar-viaje/$viajeId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Actualizar en Firebase
          await database.child('viajes/$viajeId').update({
            'estado': 'cancelado',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          return {
            'success': true,
            'message': data['message'] ?? 'Viaje cancelado exitosamente',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error al cancelar viaje',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error de conexión: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Calificar viaje
  Future<Map<String, dynamic>> calificarViaje({
    required String viajeId,
    required int calificacion,
    String? comentario,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/pasajero/calificar-viaje/$viajeId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({
          'calificacion': calificacion,
          'comentario': comentario,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Viaje calificado exitosamente',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error al calificar viaje',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error de conexión: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Guardar viaje en Firebase para tiempo real
  Future<void> _guardarViajeEnFirebase(Map<String, dynamic> viajeData) async {
    try {
      await database.child('viajes/${viajeData['id']}').set({
        'id_pasajero': viajeData['id_pasajero'],
        'id_taxista': viajeData['id_taxista'],
        'salida': viajeData['salida'],
        'destino': viajeData['destino'],
        'estado': 'solicitado',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'activo': true,
      });
    } catch (e) {
      print('Error guardando en Firebase: $e');
    }
  }

  // Obtener estado del viaje en tiempo real
  Stream<Map<String, dynamic>?> obtenerEstadoViaje(String viajeId) {
    return database.child('viajes/$viajeId').onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  // Obtener dirección desde coordenadas (usando Google Geocoding API)
  Future<String> obtenerDireccionDesdeCoordenadas(
      double lat, double lng) async {
    try {
      // Nota: Necesitarás una API key de Google para usar el Geocoding API
      // Por ahora retornamos una dirección genérica
      return 'Ubicación actual (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
    } catch (e) {
      return 'Ubicación no disponible';
    }
  }

  // Obtener coordenadas desde dirección (usando Google Geocoding API)
  Future<Map<String, double>> obtenerCoordenadasDesdeDireccion(
      String direccion) async {
    try {
      // Nota: Necesitarás una API key de Google para usar el Geocoding API
      // Por ahora retornamos coordenadas de ejemplo
      return {
        'lat': 16.867, // Ocosingo
        'lng': -92.094,
      };
    } catch (e) {
      throw Exception('Error al obtener coordenadas: $e');
    }
  }
}
