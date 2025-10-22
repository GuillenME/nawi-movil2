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
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Guardar datos del usuario en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'user_data', jsonEncode(data['data']['usuario']));
          await prefs.setString('token', data['data']['access_token']);
          await prefs.setString('tipo', data['data']['tipo']);
          await prefs.setBool('is_logged_in', true);

          return {
            'success': true,
            'user': UserModel.fromJson(data['data']['usuario']),
            'token': data['data']['access_token'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error en el login',
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
}
