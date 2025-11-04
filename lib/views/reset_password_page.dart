import 'package:flutter/material.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/utils/validators.dart';
import 'package:nawii/views/login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  ResetPasswordPage({required this.email});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Método para extraer el token de un enlace o código
  String _extractToken(String input) {
    final trimmedInput = input.trim();
    
    // Si el input parece ser una URL, intentar extraer el token
    if (trimmedInput.startsWith('http://') || 
        trimmedInput.startsWith('https://') ||
        trimmedInput.contains('token=') ||
        trimmedInput.contains('password/reset') ||
        trimmedInput.contains('reset-password')) {
      try {
        final uri = Uri.parse(trimmedInput);
        
        // Formato Laravel típico: /password/reset/TOKEN
        // Ejemplo: https://nawi.click/password/reset/jWJg45mPSPqE6CNSUGMCf8gvF1aCDzwBsqoCZ2qDpExzsdDR83T1X8zYxCEgKbyc
        if (uri.path.contains('/password/reset/')) {
          final pathParts = uri.path.split('/');
          // Buscar la parte después de 'reset'
          final resetIndex = pathParts.indexOf('reset');
          if (resetIndex != -1 && resetIndex < pathParts.length - 1) {
            final token = pathParts[resetIndex + 1];
            if (token.isNotEmpty && token.length > 10) {
              // Limpiar cualquier query string que pueda estar pegado
              final cleanToken = token.split('?').first;
              return cleanToken;
            }
          }
        }
        
        // Intentar obtener el token de los query parameters
        final tokenFromQuery = uri.queryParameters['token'];
        if (tokenFromQuery != null && tokenFromQuery.isNotEmpty) {
          return tokenFromQuery;
        }
        
        // Si no está en el path específico, buscar en el último segmento del path
        final pathParts = uri.path.split('/');
        if (pathParts.isNotEmpty) {
          final lastPart = pathParts.last;
          // Si el último segmento es largo (probablemente un token)
          if (lastPart.length > 10 && !lastPart.contains('.')) {
            // Limpiar cualquier query string
            final cleanToken = lastPart.split('?').first;
            return cleanToken;
          }
        }
      } catch (e) {
        print('Error al parsear URL: $e');
        // Si no es una URL válida, usar el input tal cual
      }
    }
    
    // Si no es una URL o no se pudo extraer, usar el input directamente
    return trimmedInput;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Extraer el token (puede ser código directo o de un enlace)
    final token = _extractToken(_tokenController.text);

    final result = await AuthService.resetPassword(
      email: widget.email,
      token: token,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Contraseña restablecida'),
          content: Text(result['message']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Ir al inicio de sesión'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Restablecer Contraseña'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
                
                // Icono
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.blue[700],
                ),
                SizedBox(height: 20),
                
                // Título
                Text(
                  'Nueva Contraseña',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                
                // Descripción
                Text(
                  'Pega el enlace completo del correo o el código que recibiste.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Puedes copiar y pegar todo el enlace del correo que empieza con "https://nawi.click/password/reset/..."',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                
                // Email (solo lectura)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: Colors.blue[700]),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Campo de código/token
                TextFormField(
                  controller: _tokenController,
                  enabled: !_isLoading,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Enlace o código de recuperación',
                    hintText: 'Pega aquí el enlace completo del correo',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    helperText: 'Ejemplo: https://nawi.click/password/reset/... (pega todo el enlace)',
                    helperMaxLines: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el código o enlace';
                    }
                    // Validar que tenga al menos algunos caracteres
                    if (value.trim().length < 6) {
                      return 'El código o enlace parece muy corto';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Campo de nueva contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: Validators.validatePassword,
                ),
                SizedBox(height: 16),

                // Campo de confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                SizedBox(height: 24),

                // Botón de restablecer
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Restablecer Contraseña',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                SizedBox(height: 16),

                // Enlace para volver al login
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text(
                    'Volver al inicio de sesión',
                    style: TextStyle(
                      color: Colors.blue[700],
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

