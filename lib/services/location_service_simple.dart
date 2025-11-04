import 'package:nawii/services/location_service.dart';

// Wrapper para mantener compatibilidad con el código existente
// Ahora usa LocationService real en lugar de simulado
class LocationServiceSimple {
  // Obtener ubicación actual (ahora usa ubicación real)
  static Future<Map<String, double>> getCurrentLocation() async {
    return await LocationService.getCurrentLocation();
  }

  // Solicitar permisos de ubicación (ahora usa permisos reales)
  static Future<bool> requestLocationPermission() async {
    return await LocationService.requestLocationPermission();
  }

  // Verificar permisos de ubicación (ahora verifica permisos reales)
  static Future<bool> hasLocationPermission() async {
    return await LocationService.hasLocationPermission();
  }

  // Verificar servicios de ubicación habilitados
  static Future<bool> isLocationServiceEnabled() async {
    return await LocationService.isLocationServiceEnabled();
  }

  // Calcular distancia entre dos puntos
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return LocationService.calculateDistance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
