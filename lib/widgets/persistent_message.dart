import 'package:flutter/material.dart';

/// Widget para mostrar mensajes persistentes en la parte inferior de la pantalla
class PersistentMessage extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const PersistentMessage({
    Key? key,
    required this.message,
    this.backgroundColor = const Color(0xFF424242), // Colors.grey[800]
    this.textColor = Colors.white70,
    this.icon,
  }) : super(key: key);

  /// Constructor para mensaje de éxito
  factory PersistentMessage.success(String message) {
    return PersistentMessage(
      message: message,
      backgroundColor: Colors.green[800]!,
      textColor: Colors.white,
      icon: Icons.check_circle,
    );
  }

  /// Constructor para mensaje de error
  factory PersistentMessage.error(String message) {
    return PersistentMessage(
      message: message,
      backgroundColor: Colors.red[800]!,
      textColor: Colors.white,
      icon: Icons.error,
    );
  }

  /// Constructor para mensaje de advertencia
  factory PersistentMessage.warning(String message) {
    return PersistentMessage(
      message: message,
      backgroundColor: Colors.orange[800]!,
      textColor: Colors.white,
      icon: Icons.warning,
    );
  }

  /// Constructor para mensaje informativo
  factory PersistentMessage.info(String message) {
    return PersistentMessage(
      message: message,
      backgroundColor: Colors.blue[800]!,
      textColor: Colors.white,
      icon: Icons.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 18),
            SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

