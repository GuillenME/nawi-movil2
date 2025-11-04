import 'package:flutter/material.dart';
import 'package:nawii/utils/app_colors.dart';

/// Widget que representa el logo de NAWI
class NawiLogo extends StatelessWidget {
  final double? size;
  final bool showText;
  final bool showTagline;

  const NawiLogo({
    Key? key,
    this.size = 80,
    this.showText = true,
    this.showTagline = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo circular con icono de taxi
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryYellow,
                Color(0xFFFF8C00), // Naranja más oscuro para el gradiente
              ],
            ),
          ),
          child: Icon(
            Icons.local_taxi,
            size: size! * 0.6,
            color: Colors.black,
          ),
        ),
        if (showText) ...[
          SizedBox(height: (size! * 0.25)),
          Text(
            'NAWI',
            style: TextStyle(
              fontSize: size! * 0.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryYellow,
              letterSpacing: 2,
            ),
          ),
        ],
        if (showTagline && showText) ...[
          SizedBox(height: 8),
          Text(
            '"Raíces que se mueven contigo."',
            style: TextStyle(
              fontSize: size! * 0.2,
              color: AppColors.primaryYellow,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Widget compacto del logo solo con el icono
class NawiLogoIcon extends StatelessWidget {
  final double? size;

  const NawiLogoIcon({
    Key? key,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryYellow,
            Color(0xFFFF8C00),
          ],
        ),
      ),
      child: Icon(
        Icons.local_taxi,
        size: size! * 0.6,
        color: Colors.black,
      ),
    );
  }
}

