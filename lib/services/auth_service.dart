import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'https://nawi.click/api';

  // Método para login
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      print('🔐 Intentando login con email: $email');
      print('🌐 URL: $baseUrl/login');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            // Guardar datos del usuario en SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                'user_data', jsonEncode(data['data']['usuario']));

            // Verificar que el token existe en la respuesta
            final accessToken = data['data']['access_token'];
            if (accessToken == null || accessToken.isEmpty) {
              print(
                  '⚠️  ADVERTENCIA: access_token está vacío o no existe en la respuesta');
              print('   Respuesta completa: ${jsonEncode(data)}');
            } else {
              print('✅ Token recibido: ${accessToken.length} caracteres');
              print(
                  '✅ Token (primeros 30): ${accessToken.substring(0, accessToken.length > 30 ? 30 : accessToken.length)}...');
            }

            await prefs.setString('token', accessToken ?? '');
            await prefs.setString('tipo', data['data']['tipo'] ?? '');
            await prefs.setBool('is_logged_in', true);

            // Verificar que se guardó correctamente
            final tokenGuardado = prefs.getString('token');
            print(
                '✅ Token guardado en SharedPreferences: ${tokenGuardado != null && tokenGuardado.isNotEmpty ? 'SÍ' : 'NO'}');
            if (tokenGuardado != null) {
              print('   Longitud del token guardado: ${tokenGuardado.length}');
            }

            print('✅ Login exitoso');
            return {
              'success': true,
              'user': UserModel.fromJson(data['data']['usuario']),
              'token': data['data']['access_token'],
            };
          } else {
            print('❌ Login fallido: ${data['message']}');
            return {
              'success': false,
              'message': data['message'] ?? 'Error en el login',
            };
          }
        } catch (e) {
          print('❌ Error parseando respuesta: $e');
          print('📦 Respuesta recibida: ${response.body}');
          return {
            'success': false,
            'message': 'Error al procesar respuesta del servidor: $e',
          };
        }
      } else if (response.statusCode == 500) {
        // Error 500 - Error interno del servidor
        String errorMessage = 'Error interno del servidor (500)';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
          print('❌ Error 500: $errorMessage');
        } catch (e) {
          print('❌ No se pudo parsear el error 500: ${response.body}');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      } else {
        print('❌ Error HTTP ${response.statusCode}');
        String errorMessage = 'Error de conexión: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          // Si no se puede parsear, usar el mensaje por defecto
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('❌ Excepción en login: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Método para registro de pasajero
  static Future<Map<String, dynamic>> registerPasajero({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String telefono,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/pasajero'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
          'password': password,
          'telefono': telefono,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Registro exitoso',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error en el registro',
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

  // Método para obtener usuario actual
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (isLoggedIn && userData != null) {
        return UserModel.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Método para logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('token');
    await prefs.setBool('is_logged_in', false);
  }

  // Método para verificar si está logueado
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Método para obtener token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Método para solicitar recuperación de contraseña
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('🔐 Solicitando recuperación de contraseña para: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/password/forgot'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ??
                'Se ha enviado un correo con las instrucciones para restablecer tu contraseña',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ??
                'Error al solicitar recuperación de contraseña',
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ??
                'Error al solicitar recuperación de contraseña',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error de conexión: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('❌ Excepción en forgotPassword: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Método para restablecer contraseña
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      print('🔐 Restableciendo contraseña para: $email');

      // Validar que las contraseñas coincidan
      if (password != passwordConfirmation) {
        return {
          'success': false,
          'message': 'Las contraseñas no coinciden',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/password/reset'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'token': token.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message':
                data['message'] ?? 'Contraseña restablecida exitosamente',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error al restablecer contraseña',
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage =
              errorData['message'] ?? 'Error al restablecer contraseña';

          // Si hay errores de validación específicos
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
          }

          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error de conexión: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('❌ Excepción en resetPassword: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
