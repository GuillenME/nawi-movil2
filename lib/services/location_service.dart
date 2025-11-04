import 'package:location/location.dart';
import 'dart:math' as math;

// Servicio de ubicación usando el plugin location (más ligero que geolocator)
class LocationService {
  static final Location _location = Location();

  // Verificar si los permisos de ubicación están concedidos
  static Future<bool> hasLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    PermissionStatus permissionStatus = await _location.hasPermission();
    return permissionStatus == PermissionStatus.granted;
  }

  // Solicitar permisos de ubicación
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    PermissionStatus permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  // Verificar si los servicios de ubicación están habilitados
  static Future<bool> isLocationServiceEnabled() async {
    return await _location.serviceEnabled();
  }

  // Obtener ubicación actual
  static Future<Map<String, double>> getCurrentLocation() async {
    try {
      LocationData locationData = await _location.getLocation();
      return {
        'latitude': locationData.latitude ?? 16.867,
        'longitude': locationData.longitude ?? -92.094,
      };
    } catch (e) {
      // Si hay error, retornar ubicación por defecto (Ocosingo)
      return {
        'latitude': 16.867,
        'longitude': -92.094,
      };
    }
  }

  // Obtener stream de ubicación en tiempo real
  static Stream<LocationData> getLocationStream() {
    return _location.onLocationChanged;
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
