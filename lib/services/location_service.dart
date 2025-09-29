// Importar math para las funciones trigonométricas
import 'dart:math' as math;

// Servicio de ubicación simplificado sin dependencias externas
// Este archivo está comentado porque las dependencias están deshabilitadas en pubspec.yaml

class LocationService {
  // Verificar si los permisos de ubicación están concedidos
  static Future<bool> hasLocationPermission() async {
    // Simular verificación de permisos
    return true;
  }

  // Solicitar permisos de ubicación
  static Future<bool> requestLocationPermission() async {
    // Simular solicitud de permisos
    return true;
  }

  // Verificar si los servicios de ubicación están habilitados
  static Future<bool> isLocationServiceEnabled() async {
    // Simular verificación de servicios
    return true;
  }

  // Obtener ubicación actual
  static Future<Map<String, double>> getCurrentLocation() async {
    // Simular ubicación (Ocosingo, Chiapas)
    return {
      'latitude': 16.867,
      'longitude': -92.094,
    };
  }

  // Calcular distancia entre dos puntos
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    // Fórmula de Haversine simplificada
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
