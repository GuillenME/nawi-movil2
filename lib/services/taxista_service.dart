import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/models/user_model.dart';
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
  Future<Map<String, dynamic>> obtenerViajesDisponibles() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return {
          'success': false,
          'session_expired': true,
          'message': 'Usuario no autenticado',
          'viajes': <ViajeModel>[],
        };
      }

      final tokenRaw = await AuthService.getToken();
      if (tokenRaw == null || tokenRaw.isEmpty || tokenRaw.trim().isEmpty) {
        return {
          'success': false,
          'session_expired': true,
          'message': 'Token no encontrado',
          'viajes': <ViajeModel>[],
        };
      }

      final token = tokenRaw.trim();
      final response = await http.get(
        Uri.parse('$baseUrl/taxista/viajes-disponibles'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          List<ViajeModel> viajes = [];
          for (var viajeData in data['data']) {
            // ⭐ MEJORADO: Log detallado según documentación del backend
            print('📦 Viaje recibido del backend:');
            print('   Keys: ${viajeData.keys.toList()}');
            print('   ID: ${viajeData['id']} (tipo: ${viajeData['id']?.runtimeType})');
            print('   Estado: ${viajeData['estado']}');
            print('   Pasajero ID: ${viajeData['pasajero_id']} (tipo: ${viajeData['pasajero_id']?.runtimeType})');
            
            // Validar que el ID esté presente (según documentación, SIEMPRE debe estar)
            if (viajeData['id'] == null) {
              print('❌ ERROR: El backend no está enviando el campo "id" (requerido según documentación)');
              print('   JSON completo: $viajeData');
              continue; // Saltar este viaje si no tiene ID
            }
            
            final viaje = ViajeModel.fromJson(viajeData);
            if (viaje.id.isEmpty || viaje.id == 'null') {
              print('❌ ERROR: Viaje parseado sin ID válido después del parseo');
              print('   Datos originales: $viajeData');
              continue; // No agregar viajes sin ID válido
            } else {
              print('✅ Viaje parseado correctamente: ID=${viaje.id}, Estado=${viaje.estado}');
            }
            viajes.add(viaje);
          }
          return {
            'success': true,
            'viajes': viajes,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'session_expired': true,
          'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
          'viajes': <ViajeModel>[],
        };
      }
      return {
        'success': false,
        'viajes': <ViajeModel>[],
      };
    } catch (e) {
      print('Error obteniendo viajes disponibles: $e');
      return {
        'success': false,
        'viajes': <ViajeModel>[],
      };
    }
  }

  // Ver mis viajes
  Future<Map<String, dynamic>> obtenerMisViajes() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return {
          'success': false,
          'session_expired': true,
          'message': 'Usuario no autenticado',
          'viajes': <ViajeModel>[],
        };
      }

      final tokenRaw = await AuthService.getToken();
      if (tokenRaw == null || tokenRaw.isEmpty || tokenRaw.trim().isEmpty) {
        return {
          'success': false,
          'session_expired': true,
          'message': 'Token no encontrado',
          'viajes': <ViajeModel>[],
        };
      }

      final token = tokenRaw.trim();
      final response = await http.get(
        Uri.parse('$baseUrl/taxista/mis-viajes'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          List<ViajeModel> viajes = [];
          for (var viajeData in data['data']) {
            viajes.add(ViajeModel.fromJson(viajeData));
          }
          return {
            'success': true,
            'viajes': viajes,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'session_expired': true,
          'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
          'viajes': <ViajeModel>[],
        };
      }
      return {
        'success': false,
        'viajes': <ViajeModel>[],
      };
    } catch (e) {
      print('Error obteniendo mis viajes: $e');
      return {
        'success': false,
        'viajes': <ViajeModel>[],
      };
    }
  }

  // Aceptar viaje
  Future<Map<String, dynamic>> aceptarViaje(
    String viajeId, {
    double? tarifa, // ⭐ NUEVO: Tarifa opcional (0-9999.99)
  }) async {
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

      // ⭐ NUEVO: Preparar body con tarifa opcional
      final requestBody = <String, dynamic>{};
      if (tarifa != null) {
        requestBody['tarifa'] = tarifa;
        print('💰 Tarifa establecida: \$${tarifa.toStringAsFixed(2)}');
      }

      // ⭐ NUEVO: Limpiar el ID del viaje (puede tener espacios o caracteres especiales)
      final viajeIdLimpio = viajeId.trim();
      // ⭐ NUEVO: Codificar el ID del viaje en la URL para evitar problemas con caracteres especiales
      final viajeIdEncoded = Uri.encodeComponent(viajeIdLimpio);
      final url = '$baseUrl/taxista/aceptar-viaje/$viajeIdEncoded';

      print('🌐 URL completa: $url');
      print('📤 Body: ${requestBody.isNotEmpty ? jsonEncode(requestBody) : "vacío"}');
      print('🔑 Token (primeros 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody.isNotEmpty ? jsonEncode(requestBody) : null,
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');
      
      // ⭐ NUEVO: Log detallado del error si no es exitoso
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ ERROR al aceptar viaje: Status Code ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          print('   Error message: ${errorData['message'] ?? 'Sin mensaje'}');
          if (errorData['errors'] != null) {
            print('   Errores de validación: ${errorData['errors']}');
          }
        } catch (e) {
          print('   No se pudo parsear el error: $e');
        }
      }

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
          'session_expired': true,
          'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
        };
      } else if (response.statusCode == 422) {
        // ⭐ NUEVO: Manejar error 422 (Validación fallida - viaje expirado o tarifa inválida)
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Datos de entrada inválidos';

          // Si hay mensajes de validación específicos, mostrarlos
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorMessages = <String>[];
            errors.forEach((key, value) {
              if (value is List) {
                errorMessages.addAll(value.map((e) => e.toString()));
              }
            });
            if (errorMessages.isNotEmpty) {
              errorMessage = errorMessages.join(', ');
            }
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'] as String;
          }

          print('❌ Error 422 (Validación): $errorMessage');
          return {
            'success': false,
            'message': errorMessage,
            'error_details': 'Error de validación del backend. ${errorData.toString()}',
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Datos de entrada inválidos. Verifica los datos enviados.',
            'error_details': 'Error parseando respuesta 422: ${e.toString()}. Body: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ??
                'Error de conexión: ${response.statusCode}',
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

      // ⭐ NUEVO: Limpiar el ID del viaje (puede tener espacios o caracteres especiales)
      final viajeIdLimpio = viajeId.trim();
      // ⭐ NUEVO: Codificar el ID del viaje en la URL para evitar problemas con caracteres especiales
      final viajeIdEncoded = Uri.encodeComponent(viajeIdLimpio);
      final url = '$baseUrl/taxista/rechazar-viaje/$viajeIdEncoded';
      
      print('🌐 URL completa: $url');
      print('🔑 Token (primeros 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

      final response = await http.post(
        Uri.parse(url),
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
          'session_expired': true,
          'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ??
                'Error de conexión: ${response.statusCode}',
            'error_details': 'Status Code: ${response.statusCode}. Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error de conexión: ${response.statusCode}',
            'error_details': 'No se pudo parsear la respuesta. Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'error_details': 'Excepción: ${e.toString()}',
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
          'session_expired': true,
          'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ??
                'Error de conexión: ${response.statusCode}',
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

  // Obtener datos de usuario por ID
  Future<UserModel?> obtenerUsuarioPorId(String userId) async {
    try {
      if (userId.isEmpty || userId.trim().isEmpty) {
        print('❌ Error: userId está vacío');
        return null;
      }

      final tokenRaw = await AuthService.getToken();
      if (tokenRaw == null || tokenRaw.isEmpty) {
        print('❌ Error: Token no encontrado');
        throw Exception('Token no encontrado');
      }

      final token = tokenRaw.trim();
      final userIdLimpio = userId.trim();

      print('🔍 Obteniendo datos del usuario ID: $userIdLimpio');
      print('🌐 URL: $baseUrl/usuario/$userIdLimpio');

      final response = await http.get(
        Uri.parse('$baseUrl/usuario/$userIdLimpio'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final usuario = UserModel.fromJson(data['data']);
          print('✅ Usuario obtenido: ${usuario.nombreCompleto}');
          return usuario;
        } else {
          print(
              '⚠️  Respuesta exitosa pero sin datos: ${data['message'] ?? 'Sin mensaje'}');
        }
      } else if (response.statusCode == 404) {
        print('❌ Usuario no encontrado (404)');
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener usuario $userId: $e');
      return null;
    }
  }
}
