import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:nawii/models/viaje_model.dart';
import 'package:nawii/models/user_model.dart';
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
    String? idTaxista, // ID del taxista específico si se seleccionó uno
    int? tiempoLimiteMinutos, // ⭐ NUEVO: Tiempo límite en minutos (1-30), por defecto 5
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener el token directamente desde SharedPreferences
      final tokenRaw = await AuthService.getToken();
      if (tokenRaw == null || tokenRaw.isEmpty || tokenRaw.trim().isEmpty) {
        print('❌ ERROR: Token no encontrado en SharedPreferences');
        final isLoggedIn = await AuthService.isLoggedIn();
        print('   is_logged_in: $isLoggedIn');
        throw Exception(
            'Token de autenticación no encontrado. Por favor inicia sesión nuevamente.');
      }

      // Limpiar el token (quitar espacios)
      final token = tokenRaw.trim();
      print('🔐 Token obtenido: ${token.length} caracteres');
      print('👤 Usuario ID: ${user.id}');
      print('👤 Usuario tipo: ${user.tipo}');
      print('👤 Usuario rolId: ${user.rolId}');

      // Verificar que el ID del usuario no esté vacío y no sea un placeholder
      if (user.id.isEmpty ||
          user.id == '' ||
          user.id == '00000000-0000-0000-0000-000000000002' ||
          user.id == '00000000-0000-0000-0000-000000000003') {
        throw Exception(
            'ID de usuario inválido. El ID parece ser un placeholder. Verifica que el backend retorne el ID real del usuario en el login.');
      }

      // Verificar que el ID del usuario sea válido (no placeholder)
      if (user.id.startsWith('00000000-0000-0000-0000-00000000')) {
        print(
            '⚠️  ADVERTENCIA: El ID del usuario parece ser un placeholder UUID');
        print('   El backend debe retornar el ID real del usuario en el login');
        print('   ID recibido: ${user.id}');
      }

      // Verificar que el ID del taxista sea válido si se proporciona
      if (idTaxista != null && idTaxista.isNotEmpty) {
        print('🚕 Taxista ID: $idTaxista');
        // Limpiar el ID del taxista (quitar espacios, caracteres especiales)
        idTaxista = idTaxista.trim();

        // Verificar que no sea un placeholder
        if (idTaxista == '00000000-0000-0000-0000-000000000002' ||
            idTaxista == '00000000-0000-0000-0000-000000000003') {
          print('❌ ERROR: El ID del taxista es un placeholder UUID');
          print(
              '   El ID del taxista debe ser el ID real del usuario en MySQL');
          print('   ID recibido: $idTaxista');
          throw Exception(
              'ID del taxista inválido. El ID debe corresponder con el ID real del usuario en MySQL, no un placeholder.');
        }
      }

      // Preparar el body del request
      // IMPORTANTE: El backend obtiene id_pasajero del token JWT (más seguro)
      final requestBody = <String, dynamic>{
        // NO enviar id_pasajero - el backend lo obtiene del token JWT

        'salida': {
          'lat': salidaLat,
          'lon': salidaLon,
        },
        'destino': {
          'lat': destinoLat,
          'lon': destinoLon,
        },
      };

      print('📝 Configuración del request:');
      print('   id_pasajero en body: NO (backend lo obtiene del token JWT)');
      print('   👤 Usuario ID desde Flutter: ${user.id}');
      print('   👤 Usuario Rol ID: ${user.rolId}');
      print('   👤 Usuario Tipo: ${user.tipo}');

      // Agregar id_taxista solo si existe y es válido
      // IMPORTANTE: El ID del taxista debe corresponder con el ID en la base de datos MySQL
      // Si el ID viene de Firebase, puede que necesites buscar el ID real en MySQL
      if (idTaxista != null && idTaxista.isNotEmpty) {
        // Limpiar el ID del taxista
        String taxistaIdLimpio = idTaxista.trim();

        // Si el ID parece ser solo una key de Firebase, puede que necesites el ID real
        // Por ahora lo enviamos tal cual, pero el backend debe validarlo
        requestBody['id_taxista'] = taxistaIdLimpio;

        print('🚕 Taxista ID (desde Firebase): $taxistaIdLimpio');
        print(
            '⚠️  VERIFICAR: Este ID debe existir en la tabla "users" de MySQL');
        print(
            '   Si el error persiste, verifica que el taxista se guardó en Firebase usando su ID real de MySQL');
      }

      // ⭐ NUEVO: Agregar tiempo_limite_minutos si se proporciona (1-30 minutos)
      if (tiempoLimiteMinutos != null && tiempoLimiteMinutos >= 1 && tiempoLimiteMinutos <= 30) {
        requestBody['tiempo_limite_minutos'] = tiempoLimiteMinutos;
        print('⏱️  Tiempo límite de aceptación: $tiempoLimiteMinutos minutos');
      }

      print('📤 Enviando datos:');
      print('   id_pasajero: [obtenido del token JWT por el backend]');
      print('   salida: lat=$salidaLat, lon=$salidaLon');
      print('   destino: lat=$destinoLat, lon=$destinoLon');
      if (idTaxista != null) {
        print('   id_taxista: $idTaxista');
        print(
            '   ⚠️  VERIFICAR: Este ID debe existir en la tabla "users" de MySQL');
        print(
            '   ID esperado para Froilan: 208e049f-8ea7-47da-903e-a55917287af5');
      }

      final bodyJson = jsonEncode(requestBody);
      print('📦 Body JSON: $bodyJson');

      // Preparar headers con el token limpio
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('🔐 Enviando request con token (${token.length} chars)');

      final response = await http.post(
        Uri.parse('$baseUrl/pasajero/crear-viaje'),
        headers: headers,
        body: bodyJson,
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Headers: ${response.headers}');
      print('📦 Response Body: ${response.body}');

      // Si es 401, verificar el token
      if (response.statusCode == 401) {
        print('❌ ERROR 401 - Token puede ser inválido o expirado');
        print('   Verificando token guardado...');
        final tokenRevisado = await AuthService.getToken();
        print(
            '   Token en SharedPreferences: ${tokenRevisado != null && tokenRevisado.isNotEmpty ? 'EXISTE (${tokenRevisado.length} chars)' : 'NO EXISTE'}');
        if (tokenRevisado != null && tokenRevisado.isNotEmpty) {
          print(
              '   Token (primeros 30): ${tokenRevisado.substring(0, tokenRevisado.length > 30 ? 30 : tokenRevisado.length)}...');
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Guardar en Firebase para tiempo real
          await _guardarViajeEnFirebase(data['data'], idTaxista);
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
      } else if (response.statusCode == 401) {
        // Error 401 - No autorizado
        try {
          final errorData = jsonDecode(response.body);
          print('❌ Error 401: ${errorData['message'] ?? 'No autorizado'}');
          return {
            'success': false,
            'session_expired': true,
            'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
          };
        } catch (e) {
          return {
            'success': false,
            'session_expired': true,
            'message': 'No autorizado. Por favor inicia sesión nuevamente.',
          };
        }
      } else if (response.statusCode == 422) {
        // Error 422 - Validación fallida (Datos de entrada inválidos)
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
          print('📦 Error completo: ${response.body}');

          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          print('❌ Error parseando respuesta 422: ${response.body}');
          return {
            'success': false,
            'message':
                'Datos de entrada inválidos. Verifica los datos enviados.',
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = errorData['message'] ?? 'Error desconocido';

          // Si hay mensaje de error más específico
          if (errorData['error'] != null) {
            errorMessage = errorData['error'] as String;
          }

          print('❌ Error ${response.statusCode}: $errorMessage');
          print('📦 Response completo: ${response.body}');

          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          print('❌ Error parseando respuesta: ${response.body}');
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
        Uri.parse('$baseUrl/pasajero/mis-viajes'),
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
      print('Error obteniendo viajes: $e');
      return {
        'success': false,
        'viajes': <ViajeModel>[],
      };
    }
  }

  // Cancelar viaje
  Future<Map<String, dynamic>> cancelarViaje(String viajeId) async {
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
      print('🔐 Cancelando viaje con token: ${token.length} caracteres');

      final response = await http.post(
        Uri.parse('$baseUrl/pasajero/cancelar-viaje/$viajeId'),
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
  Future<void> _guardarViajeEnFirebase(
      Map<String, dynamic> viajeData, String? idTaxista) async {
    try {
      // ✅ IMPORTANTE: En Firebase guardamos el ID del usuario del taxista (no el ID de la tabla taxistas)
      // porque es lo que se usa para comparar en viajes_pendientes_page.dart
      // El idTaxista que viene de Flutter es el ID del usuario (208e049f-8ea7-47da-903e-a55917287af5)
      // El viajeData['id_taxista'] del backend es el ID de la tabla taxistas (41a005cc-3f5e-45e8-b73e-a9532acb2f0a)
      await database.child('viajes/${viajeData['id']}').set({
        'id_pasajero': viajeData['id_pasajero'],
        'id_taxista': idTaxista ?? viajeData['id_taxista'], // ✅ Priorizar ID del usuario (para Firebase)
        'salida': viajeData['salida'] ?? {
          'lat': viajeData['latitud_origen'],
          'lon': viajeData['longitud_origen'],
        },
        'destino': viajeData['destino'] ?? {
          'lat': viajeData['latitud_destino'],
          'lon': viajeData['longitud_destino'],
        },
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

  // Obtener dirección desde coordenadas (usando Google Geocoding API - Reverse Geocoding)
  Future<String> obtenerDireccionDesdeCoordenadas(
      double lat, double lng) async {
    try {
      // API Key de Google Maps (debe ser la misma que usas en AndroidManifest.xml)
      const String apiKey = 'AIzaSyCaZFeEmON_iOVCBO24V1FmQu0pQ2QrxhU';

      // URL de Reverse Geocoding API
      final String url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Retornar la dirección formateada
          return data['results'][0]['formatted_address'] as String;
        } else {
          // Si no se encuentra, retornar coordenadas
          return 'Ubicación (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
        }
      } else {
        return 'Ubicación (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
      }
    } catch (e) {
      print('Error al obtener dirección: $e');
      return 'Ubicación (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
    }
  }

  // Obtener coordenadas desde dirección (usando Google Geocoding API)
  Future<Map<String, double>> obtenerCoordenadasDesdeDireccion(
      String direccion) async {
    try {
      // API Key de Google Maps (debe ser la misma que usas en AndroidManifest.xml)
      const String apiKey = 'AIzaSyCaZFeEmON_iOVCBO24V1FmQu0pQ2QrxhU';

      // ⭐ ACTUALIZADO: Siempre agregar Ocosingo, Chiapas para restringir búsqueda
      String direccionConContexto = direccion;
      if (!direccion.toLowerCase().contains('ocosingo')) {
        direccionConContexto = '$direccion, Ocosingo, Chiapas, México';
      }

      // ⭐ NUEVO: Coordenadas del centro de Ocosingo para location bias
      // Esto ayuda a que Google priorice resultados cercanos a Ocosingo
      const double ocosingoLat = 16.9064;
      const double ocosingoLng = -92.0937;
      const int radius = 10000; // 10 km de radio desde el centro de Ocosingo

      // URL de Geocoding API con restricción a Ocosingo
      final String url = Uri.encodeFull(
          'https://maps.googleapis.com/maps/api/geocode/json?address=$direccionConContexto&region=mx&components=locality:Ocosingo|administrative_area:Chiapas|country:MX&location=$ocosingoLat,$ocosingoLng&radius=$radius&key=$apiKey');

      print('🔍 Buscando dirección: $direccionConContexto');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('📦 Respuesta Geocoding: ${data['status']}');
        if (data['results'] != null && data['results'].isNotEmpty) {
          print('📍 Resultados encontrados: ${data['results'].length}');

          // Mostrar todos los resultados para debugging
          for (var i = 0; i < data['results'].length; i++) {
            final result = data['results'][i];
            final types = List<String>.from(result['types'] ?? []);
            print('  ${i + 1}. ${result['formatted_address']}');
            print('     Tipos: ${types.join(", ")}');
          }
        }

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Sistema de puntuación para seleccionar el mejor resultado
          // Evita resultados genéricos (centros de ciudades) y prioriza lugares específicos
          Map<String, dynamic>? mejorResultado;
          int mejorPuntuacion = -1;
          final direccionLower = direccion.toLowerCase();

          for (var resultado in data['results']) {
            int puntuacion = 0;
            final types = List<String>.from(resultado['types'] ?? []);
            final address =
                (resultado['formatted_address'] as String).toLowerCase();

            // ❌ EVITAR resultados genéricos (centros de ciudades, áreas administrativas)
            if (types.contains('locality') ||
                types.contains('political') ||
                types.contains('administrative_area_level_1') ||
                types.contains('administrative_area_level_2') ||
                types.contains('country')) {
              print(
                  '   ⚠️  Saltando resultado genérico: ${resultado['formatted_address']}');
              continue; // Saltar este resultado
            }

            // ✅ PRIORIZAR establecimientos y puntos de interés específicos
            if (types.contains('establishment')) puntuacion += 50;
            if (types.contains('point_of_interest')) puntuacion += 40;
            if (types.contains('university')) puntuacion += 60;
            if (types.contains('school')) puntuacion += 45;
            if (types.contains('library')) puntuacion += 35;
            if (types.contains('hospital')) puntuacion += 40;
            if (types.contains('restaurant')) puntuacion += 30;
            if (types.contains('store')) puntuacion += 30;
            if (types.contains('gas_station')) puntuacion += 25;
            if (types.contains('bank')) puntuacion += 30;

            // ✅ BONUS: Si el nombre del lugar coincide con palabras clave de la búsqueda
            final palabrasBusqueda =
                direccionLower.split(' ').where((p) => p.length > 3).toList();
            int coincidencias = 0;
            for (var palabra in palabrasBusqueda) {
              if (address.contains(palabra)) {
                coincidencias++;
                puntuacion += 10; // 10 puntos por cada palabra que coincida
              }
            }

            // ✅ BONUS EXTRA: Si contiene palabras muy específicas
            if (direccionLower.contains('universidad') &&
                address.contains('universidad')) {
              puntuacion += 30;
            }
            
            // ✅ BONUS: Priorizar resultados que mencionen Ocosingo
            if (address.contains('ocosingo')) {
              puntuacion += 40;
            }

            // ❌ PENALIZAR: Si es solo una calle o ruta sin establecimiento
            if (types.contains('route') &&
                !types.contains('establishment') &&
                !types.contains('point_of_interest')) {
              puntuacion -= 30;
            }

            // ✅ BONUS: Si tiene nombre específico en el resultado
            if (resultado['name'] != null) {
              final name = (resultado['name'] as String).toLowerCase();
              for (var palabra in palabrasBusqueda) {
                if (name.contains(palabra)) {
                  puntuacion += 15; // Bonus extra por coincidencia en el nombre
                }
              }
            }

            print(
                '   📊 Puntuación: $puntuacion (${coincidencias} coincidencias) - ${resultado['formatted_address']}');

            if (puntuacion > mejorPuntuacion) {
              mejorPuntuacion = puntuacion;
              mejorResultado = resultado;
            }
          }

          // Si no encontramos un resultado específico (todos fueron genéricos)
          if (mejorResultado == null) {
            print(
                '⚠️  Todos los resultados fueron genéricos, usando el primero');
            mejorResultado = data['results'][0];
          }

          final location = mejorResultado!['geometry']['location'];
          final direccionEncontrada =
              mejorResultado['formatted_address'] as String;
          print('✅ Ubicación seleccionada: $direccionEncontrada');
          print('   Coordenadas: ${location['lat']}, ${location['lng']}');

          return {
            'lat': location['lat'].toDouble(),
            'lng': location['lng'].toDouble(),
          };
        } else if (data['status'] == 'ZERO_RESULTS') {
          throw Exception('No se encontró la dirección: $direccion');
        } else {
          throw Exception('Error en Geocoding: ${data['status']}');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener coordenadas: $e');
      throw Exception('Error al obtener coordenadas: $e');
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
          print('⚠️  Respuesta exitosa pero sin datos: ${data['message'] ?? 'Sin mensaje'}');
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
