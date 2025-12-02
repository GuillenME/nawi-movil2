import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/utils/validators.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/utils/message_dialog.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.registerPasajero(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      telefono: _telefonoController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      MessageDialog.showSuccess(
        context,
        result['message'],
        title: 'Registro Exitoso',
        onClose: () {
          Navigator.pop(context); // Volver al login
        },
      );
    } else {
      MessageDialog.showError(
        context,
        result['message'],
        title: 'Error de Registro',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Registro'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),

                // Información de tipo de usuario
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryYellow.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppColors.primaryYellow),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registro como Pasajero',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryYellow,
                              ),
                            ),
                            Text(
                              'Podrás solicitar viajes cuando lo necesites',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Campo de nombre
                TextFormField(
                  controller: _nombreController,
                  style: TextStyle(color: AppColors.white),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: TextStyle(color: AppColors.mediumGrey),
                    prefixIcon:
                        Icon(Icons.person, color: AppColors.primaryYellow),
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
                      borderSide:
                          BorderSide(color: AppColors.primaryYellow, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryDark.withOpacity(0.5),
                  ),
                  validator: (value) =>
                      Validators.validateName(value, 'tu nombre'),
                ),
                SizedBox(height: 16),

                // Campo de apellido
                TextFormField(
                  controller: _apellidoController,
                  style: TextStyle(color: AppColors.white),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    labelStyle: TextStyle(color: AppColors.mediumGrey),
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppColors.primaryYellow),
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
                      borderSide:
                          BorderSide(color: AppColors.primaryYellow, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryDark.withOpacity(0.5),
                  ),
                  validator: (value) =>
                      Validators.validateName(value, 'tu apellido'),
                ),
                SizedBox(height: 16),

                // Campo de email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: AppColors.white),
                  inputFormatters: [
                    // Bloquear caracteres peligrosos como <, >, /, \, &, ;, etc.
                    FilteringTextInputFormatter.deny(RegExp(r'[<>/\\&;`\$]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    labelStyle: TextStyle(color: AppColors.mediumGrey),
                    prefixIcon:
                        Icon(Icons.email, color: AppColors.primaryYellow),
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
                      borderSide:
                          BorderSide(color: AppColors.primaryYellow, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryDark.withOpacity(0.5),
                  ),
                  validator: Validators.validateEmail,
                ),
                SizedBox(height: 16),

                // Campo de teléfono
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.white),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Teléfono (10 dígitos)',
                    labelStyle: TextStyle(color: AppColors.mediumGrey),
                    prefixIcon:
                        Icon(Icons.phone, color: AppColors.primaryYellow),
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
                      borderSide:
                          BorderSide(color: AppColors.primaryYellow, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryDark.withOpacity(0.5),
                  ),
                  validator: Validators.validatePhone,
                ),
                SizedBox(height: 16),

                // Campo de contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: AppColors.white),
                  inputFormatters: [
                    // Bloquear caracteres peligrosos pero permitir caracteres especiales seguros
                    FilteringTextInputFormatter.deny(RegExp(r'[<>/\\&;`\$]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: AppColors.mediumGrey),
                    prefixIcon:
                        Icon(Icons.lock, color: AppColors.primaryYellow),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.mediumGrey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
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
                      borderSide:
                          BorderSide(color: AppColors.primaryYellow, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryDark.withOpacity(0.5),
                  ),
                  validator: Validators.validatePassword,
                ),
                SizedBox(height: 16),

                // Campo de confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(color: AppColors.white),
                  inputFormatters: [
                    // Bloquear caracteres peligrosos pero permitir caracteres especiales seguros
                    FilteringTextInputFormatter.deny(RegExp(r'[<>/\\&;`\$]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    labelStyle: TextStyle(color: AppColors.mediumGrey),
                    prefixIcon: Icon(Icons.lock_outline,
                        color: AppColors.primaryYellow),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.mediumGrey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
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
                      borderSide:
                          BorderSide(color: AppColors.primaryYellow, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryDark.withOpacity(0.5),
                  ),
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                SizedBox(height: 24),

                // Botón de registro
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: AppColors.primaryDark,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: AppColors.primaryDark)
                      : Text(
                          'Registrarse',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                SizedBox(height: 16),

                // Enlace a login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: TextStyle(color: AppColors.mediumGrey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Inicia sesión aquí',
                        style: TextStyle(
                          color: AppColors.primaryYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
