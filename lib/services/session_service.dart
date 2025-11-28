import 'package:flutter/material.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/views/login_page.dart';
import 'package:nawii/utils/app_colors.dart';

class SessionService {
  /// Verifica si un resultado de servicio indica sesión expirada
  static bool isSessionExpiredResult(Map<String, dynamic> result) {
    return result['session_expired'] == true || 
           (result['message'] != null && 
            result['message'].toString().toLowerCase().contains('sesión expirada'));
  }

  /// Maneja el resultado de un servicio verificando si hay expiración de sesión
  /// y mostrando el diálogo correspondiente
  static Future<bool> handleServiceResult(
    BuildContext context,
    Map<String, dynamic> result, {
    bool showConfirmDialog = true,
  }) async {
    if (isSessionExpiredResult(result)) {
      return await handleSessionExpired(context, showConfirmDialog: showConfirmDialog);
    }
    return false;
  }

  /// Maneja el error 401 (sesión expirada) mostrando un diálogo al usuario
  /// y redirigiendo al login si confirma o si es automático
  static Future<bool> handleSessionExpired(BuildContext context, {bool showConfirmDialog = true}) async {
    if (showConfirmDialog) {
      // Mostrar diálogo de confirmación
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.primaryDark,
            title: Text(
              'Sesión Expirada',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Tu sesión ha expirado. ¿Deseas cerrar sesión e iniciar sesión nuevamente?',
              style: TextStyle(color: AppColors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.mediumGrey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.primaryDark,
                ),
                child: Text('Cerrar Sesión'),
              ),
            ],
          );
        },
      );

      // Si el usuario confirma, cerrar sesión y redirigir
      if (result == true) {
        await AuthService.logout();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
        }
        return true;
      }
      return false;
    } else {
      // Cerrar sesión automáticamente sin diálogo
      await AuthService.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
      return true;
    }
  }

  /// Verifica si una respuesta HTTP indica sesión expirada
  static bool isSessionExpired(int statusCode) {
    return statusCode == 401;
  }
}

