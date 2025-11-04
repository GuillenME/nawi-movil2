import 'package:flutter/material.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/utils/validators.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/views/reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.forgotPassword(_emailController.text.trim());

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      setState(() {
        _emailSent = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.successColor,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Recuperar Contraseña'),
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
                SizedBox(height: 40),
                
                // Icono
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: AppColors.primaryYellow,
                ),
                SizedBox(height: 20),
                
                // Título
                Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                
                // Descripción
                Text(
                  _emailSent
                      ? 'Revisa tu correo electrónico. Hemos enviado un enlace para restablecer tu contraseña.'
                      : 'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.mediumGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),

                if (!_emailSent) ...[
                  // Campo de email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
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
                    validator: Validators.validateEmail,
                  ),
                  SizedBox(height: 24),

                  // Botón de enviar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetEmail,
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
                            'Enviar enlace de recuperación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ] else ...[
                  // Mensaje de éxito
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.successColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.successColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.successColor,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Correo enviado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.successColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mediumGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Botón para ir a restablecer contraseña
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResetPasswordPage(
                            email: _emailController.text.trim(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.primaryDark,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ya tengo el código',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: 24),
                
                // Enlace para volver al login
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Volver al inicio de sesión',
                    style: TextStyle(
                      color: AppColors.primaryYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

