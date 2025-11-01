import 'dart:math' as math;
import 'package:location/location.dart';

// Servicio de ubicación simplificado con plugin location
class LocationServiceSimple {
  // Simular ubicación actual (Ocosingo, Chiapas)
  static Map<String, double> getCurrentLocation() {
    return {
      'latitude': 16.867,
      'longitude': -92.094,
    };
  }

  // Solicitar permisos de ubicación
  static Future<bool> requestLocationPermission() async {
    try {
      Location location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return false;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Verificar permisos de ubicación
  static Future<bool> hasLocationPermission() async {
    try {
      Location location = Location();
      PermissionStatus permissionGranted = await location.hasPermission();
      return permissionGranted == PermissionStatus.granted;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  // Verificar si los servicios de ubicación están habilitados
  static Future<bool> isLocationServiceEnabled() async {
    try {
      Location location = Location();
      return await location.serviceEnabled();
    } catch (e) {
      print('Error checking location service: $e');
      return false;
    }
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
