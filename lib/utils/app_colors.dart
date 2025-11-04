import 'package:flutter/material.dart';

/// Paleta de colores de NAWI
class AppColors {
  // Colores principales de la paleta
  static const Color primaryYellow = Color(0xFFF1C40F); // Amarillo dorado
  static const Color primaryDark = Color(0xFF2B3D4F); // Azul oscuro/gris carbón
  static const Color white = Color(0xFFFFFFFF); // Blanco
  static const Color mediumGrey = Color(0xFF7F8C8D); // Gris medio
  static const Color vibrantGreen = Color(0xFF27AE60); // Verde vibrante
  static const Color oliveGreen = Color(0xFF807E26); // Verde oliva

  // Colores semánticos derivados
  static const Color backgroundColor = white;
  static const Color surfaceColor = white;
  static const Color primaryColor = primaryDark;
  static const Color accentColor = primaryYellow;

  // Colores para estados
  static const Color successColor = vibrantGreen;
  static const Color errorColor =
      Color(0xFFE74C3C); // Rojo para errores (no en paleta pero necesario)
  static const Color warningColor = primaryYellow;
  static const Color infoColor = primaryDark;

  // Colores de texto
  static const Color textPrimary = primaryDark;
  static const Color textSecondary = mediumGrey;
  static const Color textOnPrimary = white;
  static const Color textOnAccent = primaryDark;

  // Colores de fondo suaves
  static const Color backgroundLight =
      Color(0xFFF8F9FA); // Blanco con un toque gris
  static const Color backgroundYellowTint =
      Color(0xFFFFF9E6); // Amarillo muy claro
}
