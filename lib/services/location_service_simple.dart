import 'dart:math' as math;

// Servicio de ubicación simplificado sin dependencias externas
class LocationServiceSimple {
  // Simular ubicación actual (Ocosingo, Chiapas)
  static Map<String, double> getCurrentLocation() {
    return {
      'latitude': 16.867,
      'longitude': -92.094,
    };
  }

  // Simular solicitud de permisos
  static Future<bool> requestLocationPermission() async {
    // Simular que siempre se conceden los permisos
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  // Simular verificación de permisos
  static Future<bool> hasLocationPermission() async {
    return true;
  }

  // Simular servicios de ubicación habilitados
  static Future<bool> isLocationServiceEnabled() async {
    return true;
  }

  // Calcular distancia entre dos puntos (fórmula de Haversine)
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double earthRadius = 6371; // Radio de la Tierra en km

    double dLat = _degreesToRadians(endLatitude - startLatitude);
    double dLon = _degreesToRadians(endLongitude - startLongitude);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(startLatitude)) *
            math.cos(_degreesToRadians(endLatitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
