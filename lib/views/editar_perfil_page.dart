import 'package:flutter/material.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/models/user_model.dart';
import 'package:nawii/utils/app_colors.dart';
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

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

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

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('https://nawi.click/api/usuario/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'telefono': _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
          // No enviar email ya que generalmente no se puede cambiar
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Actualizar datos del usuario en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final userData = Map<String, dynamic>.from(
              jsonDecode(prefs.getString('user_data') ?? '{}'));
          userData['nombre'] = _nombreController.text.trim();
          userData['apellido'] = _apellidoController.text.trim();
          userData['telefono'] = _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim();
          await prefs.setString('user_data', jsonEncode(userData));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Perfil actualizado exitosamente'),
              backgroundColor: AppColors.successColor,
            ),
          );

          Navigator.pop(context, true); // Retornar true para indicar que se actualizó
        } else {
          throw Exception(data['message'] ?? 'Error al actualizar perfil');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorColor,
        ),
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

              // Campo Email (solo lectura)
              TextFormField(
                controller: _emailController,
                enabled: false,
                style: TextStyle(color: AppColors.mediumGrey),
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: TextStyle(color: AppColors.mediumGrey),
                  prefixIcon: Icon(Icons.email, color: AppColors.mediumGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mediumGrey),
                  ),
                  filled: true,
                  fillColor: AppColors.primaryDark.withOpacity(0.3),
                ),
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

