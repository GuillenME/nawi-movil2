import 'package:flutter/material.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/services/session_service.dart';
import 'package:nawii/models/user_model.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/utils/message_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditarPerfilPage extends StatefulWidget {
  @override
  _EditarPerfilPageState createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUser = user;
        _nombreController.text = user.nombre;
        _apellidoController.text = user.apellido;
        _emailController.text = user.email;
        _telefonoController.text = user.telefono ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final tokenRaw = await AuthService.getToken();
      if (tokenRaw == null || tokenRaw.isEmpty || tokenRaw.trim().isEmpty) {
        throw Exception('Token no encontrado');
      }

      final token = tokenRaw.trim();
      print('🔐 Actualizando perfil con token: ${token.length} caracteres');

      // ⭐ NUEVO: Construir body solo con campos que han cambiado o están presentes
      final requestBody = <String, dynamic>{};
      
      // Solo enviar campos que han cambiado o están presentes
      final nombreTrimmed = _nombreController.text.trim();
      if (nombreTrimmed.isNotEmpty && nombreTrimmed != _currentUser?.nombre) {
        requestBody['nombre'] = nombreTrimmed;
      }
      
      final apellidoTrimmed = _apellidoController.text.trim();
      if (apellidoTrimmed.isNotEmpty && apellidoTrimmed != _currentUser?.apellido) {
        requestBody['apellido'] = apellidoTrimmed;
      }
      
      final telefonoTrimmed = _telefonoController.text.trim();
      if (telefonoTrimmed != (_currentUser?.telefono ?? '')) {
        requestBody['telefono'] = telefonoTrimmed.isEmpty ? null : telefonoTrimmed;
      }
      
      // ⭐ NUEVO: Permitir cambiar email si es diferente
      final emailTrimmed = _emailController.text.trim();
      if (emailTrimmed.isNotEmpty && emailTrimmed != _currentUser?.email) {
        requestBody['email'] = emailTrimmed;
      }
      
      // ⭐ NUEVO: Permitir cambiar contraseña si se proporciona
      final passwordTrimmed = _passwordController.text.trim();
      if (passwordTrimmed.isNotEmpty) {
        requestBody['password'] = passwordTrimmed;
      }

      print('📤 Enviando datos de perfil: ${requestBody.keys.toList()}');

      final response = await http.put(
        Uri.parse('https://nawi.click/api/usuario/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      // Verificar si la sesión expiró
      if (response.statusCode == 401) {
        final sessionHandled = await SessionService.handleSessionExpired(context);
        if (sessionHandled) {
          return;
        }
        throw Exception('Sesión expirada. Por favor inicia sesión nuevamente.');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // ⭐ NUEVO: Actualizar datos del usuario en SharedPreferences con todos los campos
          final prefs = await SharedPreferences.getInstance();
          final userDataString = prefs.getString('user_data');
          if (userDataString != null) {
            final userData = Map<String, dynamic>.from(jsonDecode(userDataString));
            
            // Actualizar con los datos del response (más confiable)
            if (data['data'] != null) {
              final updatedData = data['data'] as Map<String, dynamic>;
              userData['nombre'] = updatedData['nombre'] ?? _nombreController.text.trim();
              userData['apellido'] = updatedData['apellido'] ?? _apellidoController.text.trim();
              userData['email'] = updatedData['email'] ?? _emailController.text.trim();
              userData['telefono'] = updatedData['telefono'];
            } else {
              // Fallback: usar valores de los controllers
              userData['nombre'] = _nombreController.text.trim();
              userData['apellido'] = _apellidoController.text.trim();
              userData['email'] = _emailController.text.trim();
              userData['telefono'] = _telefonoController.text.trim().isEmpty
                  ? null
                  : _telefonoController.text.trim();
            }
            
            await prefs.setString('user_data', jsonEncode(userData));
            print('✅ Perfil actualizado en SharedPreferences');
          }

          // Limpiar campos de contraseña después de actualizar exitosamente
          _passwordController.clear();
          _confirmPasswordController.clear();

          MessageDialog.showSuccess(
            context,
            data['message'] ?? 'Perfil actualizado exitosamente',
            title: 'Perfil Actualizado',
            onClose: () {
              Navigator.pop(context, true); // Retornar true para indicar que se actualizó
            },
          );
        } else {
          throw Exception(data['message'] ?? 'Error al actualizar perfil');
        }
      } else if (response.statusCode == 422) {
        // ⭐ NUEVO: Manejar error 422 (Validación fallida)
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
              errorMessage = errorMessages.join('\n');
            }
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'] as String;
          }

          print('❌ Error 422 (Validación): $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Datos de entrada inválidos. Verifica los datos enviados.');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
              errorData['message'] ?? 'Error al actualizar perfil');
        } catch (e) {
          throw Exception('Error al actualizar perfil: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Error al actualizar perfil: $e');
      MessageDialog.showError(
        context,
        'Error: $e',
        title: 'Error al Actualizar',
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Editar Perfil'),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Editar Perfil'),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.white,
        ),
        body: Center(child: Text('Usuario no encontrado', style: TextStyle(color: AppColors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Editar Perfil'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del usuario
              Card(
                color: AppColors.primaryDark.withOpacity(0.3),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primaryDark.withOpacity(0.5),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '${_nombreController.text} ${_apellidoController.text}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Campo Nombre
              TextFormField(
                controller: _nombreController,
                style: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: TextStyle(color: AppColors.mediumGrey),
                  prefixIcon: Icon(Icons.person, color: AppColors.primaryYellow),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.primaryDark.withOpacity(0.5),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Campo Apellido
              TextFormField(
                controller: _apellidoController,
                style: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  labelStyle: TextStyle(color: AppColors.mediumGrey),
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryYellow),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.primaryDark.withOpacity(0.5),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El apellido es requerido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // ⭐ NUEVO: Campo Email (ahora editable)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: TextStyle(color: AppColors.mediumGrey),
                  prefixIcon: Icon(Icons.email, color: AppColors.primaryYellow),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.primaryDark.withOpacity(0.5),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Ingresa un email válido';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Campo Teléfono
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  labelStyle: TextStyle(color: AppColors.mediumGrey),
                  prefixIcon: Icon(Icons.phone, color: AppColors.primaryYellow),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.primaryDark.withOpacity(0.5),
                  hintText: 'Ej: 1234567890',
                  hintStyle: TextStyle(color: AppColors.mediumGrey.withOpacity(0.7)),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty && value.trim().length > 15) {
                    return 'El teléfono no puede tener más de 15 caracteres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // ⭐ NUEVO: Sección de Cambio de Contraseña
              Divider(color: AppColors.mediumGrey.withOpacity(0.3), height: 32),
              Text(
                'Cambiar Contraseña (opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryYellow,
                ),
              ),
              SizedBox(height: 16),

              // Campo Nueva Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                style: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  labelStyle: TextStyle(color: AppColors.mediumGrey),
                  prefixIcon: Icon(Icons.lock, color: AppColors.primaryYellow),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.mediumGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.primaryDark.withOpacity(0.5),
                  hintText: 'Mínimo 6 caracteres',
                  hintStyle: TextStyle(color: AppColors.mediumGrey.withOpacity(0.7)),
                ),
                validator: (value) {
                  // Solo validar si se ingresó algo
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    // Si hay contraseña, debe haber confirmación
                    if (_confirmPasswordController.text.isEmpty) {
                      return 'Confirma tu nueva contraseña';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Campo Confirmar Contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                style: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  labelStyle: TextStyle(color: AppColors.mediumGrey),
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryYellow),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.mediumGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.primaryDark.withOpacity(0.5),
                ),
                validator: (value) {
                  // Solo validar si se ingresó contraseña nueva
                  if (_passwordController.text.isNotEmpty) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu nueva contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _guardarPerfil,
                icon: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                        ),
                      )
                    : Icon(Icons.save),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.primaryDark,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

