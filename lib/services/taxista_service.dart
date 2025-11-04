import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/services/location_service_simple.dart';

class TaxistaService {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  static const String baseUrl = 'https://nawi.click/api';

  // Conectar taxista (poner en línea)
  Future<void> conectar() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('Usuario no autenticado');

    // Verificar permisos de ubicación (simulado)
    if (!await LocationServiceSimple.hasLocationPermission()) {
      final granted = await LocationServiceSimple.requestLocationPermission();
      if (!granted) {
        throw Exception(
            'Se necesitan permisos de ubicación para funcionar como taxista');
      }
    }

    await actualizarUbicacion(user.id.toString());
    await database.child('taxis/${user.id}/disponible').set(true);
  }

  // Desconectar taxista (poner fuera de línea)
  Future<void> desconectar() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('Usuario no autenticado');

    await database.child('taxis/${user.id}/disponible').set(false);
  }

  // Actualizar ubicación del taxista
  Future<void> actualizarUbicacion(String userId) async {
    Map<String, double> pos = await LocationServiceSimple.getCurrentLocation();

    await database.child('taxis/$userId').set({
      'latitude': pos['latitude']!,
      'longitude': pos['longitude']!,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'disponible': true,
    });
  }

  // Obtener viajes disponibles
  Future<List<ViajeModel>> obtenerViajesDisponibles() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/taxista/viajes-disponibles'),
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
      print('Error obteniendo viajes disponibles: $e');
      return [];
    }
  }

  // Ver mis viajes
  Future<List<ViajeModel>> obtenerMisViajes() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/taxista/mis-viajes'),
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
      print('Error obteniendo mis viajes: $e');
      return [];
    }
  }

  // Aceptar viaje
  Future<Map<String, dynamic>> aceptarViaje(String viajeId) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener el token directamente desde SharedPreferences
      final tokenRaw = await AuthService.getToken();
      if (tokenRaw == null || tokenRaw.isEmpty) {
        return {
          'success': false,
          'message': 'Token no encontrado. Por favor inicia sesión nuevamente.',
        };
      }

      final token = tokenRaw.trim();
      print('🔐 Aceptando viaje con token: ${token.length} caracteres');

      final response = await http.post(
        Uri.parse('$baseUrl/taxista/aceptar-viaje/$viajeId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Actualizar en Firebase
          await database.child('viajes/$viajeId').update({
            'estado': 'aceptado',
            'id_taxista': user.id,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          return {
            'success': true,
            'message': data['message'] ?? 'Viaje aceptado exitosamente',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error al aceptar viaje',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Error de conexión: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error de conexión: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Rechazar viaje
  Future<Map<String, dynamic>> rechazarViaje(String viajeId) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener el token directamente desde SharedPreferences
      final tokenRaw = await AuthService.getToken();
      if (tokenRaw == null || tokenRaw.isEmpty) {
        return {
          'success': false,
          'message': 'Token no encontrado. Por favor inicia sesión nuevamente.',
        };
      }

      final token = tokenRaw.trim();
      print('🔐 Rechazando viaje con token: ${token.length} caracteres');

      final response = await http.post(
        Uri.parse('$baseUrl/taxista/rechazar-viaje/$viajeId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Actualizar en Firebase
          await database.child('viajes/$viajeId').update({
            'estado': 'rechazado',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          return {
            'success': true,
            'message': data['message'] ?? 'Viaje rechazado exitosamente',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error al rechazar viaje',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Error de conexión: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error de conexión: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Completar viaje
  Future<Map<String, dynamic>> completarViaje(String viajeId) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener el token directamente desde SharedPreferences
      final tokenRaw = await AuthService.getToken();
      if (tokenRaw == null || tokenRaw.isEmpty) {
        return {
          'success': false,
          'message': 'Token no encontrado. Por favor inicia sesión nuevamente.',
        };
      }

      final token = tokenRaw.trim();
      print('🔐 Completando viaje con token: ${token.length} caracteres');

      final response = await http.post(
        Uri.parse('$baseUrl/taxista/completar-viaje/$viajeId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Actualizar en Firebase
          await database.child('viajes/$viajeId').update({
            'estado': 'completado',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          return {
            'success': true,
            'message': data['message'] ?? 'Viaje completado exitosamente',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error al completar viaje',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Error de conexión: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error de conexión: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Actualizar ubicación en tiempo real
  Future<Map<String, dynamic>> actualizarUbicacionViaje({
    required String viajeId,
    required double lat,
    required double lon,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await http.post(
        Uri.parse('$baseUrl/viaje/actualizar-ubicacion/$viajeId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({
          'lat': lat,
          'lon': lon,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Actualizar en Firebase
          await database.child('viajes/$viajeId/ubicacion_taxista').set({
            'lat': lat,
            'lon': lon,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          return {
            'success': true,
            'message': data['message'] ?? 'Ubicación actualizada exitosamente',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error al actualizar ubicación',
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

  // Obtener estado del viaje
  Future<Map<String, dynamic>?> obtenerEstadoViaje(String viajeId) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/viaje/estado/$viajeId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error obteniendo estado del viaje: $e');
      return null;
    }
  }
}
