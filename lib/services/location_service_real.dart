import 'dart:math' as math;
import 'package:location/location.dart' as location_pkg;
import 'package:permission_handler/permission_handler.dart';

class LocationServiceReal {
  static final location_pkg.Location _location = location_pkg.Location();

  // Verificar si los permisos de ubicación están concedidos
  static Future<bool> hasLocationPermission() async {
    try {
      location_pkg.PermissionStatus permissionGranted =
          await _location.hasPermission();
      return permissionGranted == location_pkg.PermissionStatus.granted ||
          permissionGranted == location_pkg.PermissionStatus.grantedLimited;
    } catch (e) {
      print('Error verificando permisos: $e');
      return false;
    }
  }

  // Solicitar permisos de ubicación
  static Future<bool> requestLocationPermission() async {
    try {
      // Solicitar permisos usando permission_handler
      PermissionStatus status = await Permission.location.request();

      if (status.isGranted || status.isLimited) {
        // Verificar si los servicios de ubicación están habilitados
        bool serviceEnabled = await _location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await _location.requestService();
          if (!serviceEnabled) {
            return false;
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error solicitando permisos: $e');
      return false;
    }
  }

  // Verificar si los servicios de ubicación están habilitados
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await _location.serviceEnabled();
    } catch (e) {
      print('Error verificando servicios: $e');
      return false;
    }
  }

  // Obtener ubicación actual
  static Future<Map<String, double>> getCurrentLocation() async {
    try {
      // Verificar permisos
      bool hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await requestLocationPermission();
        if (!hasPermission) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      // Verificar si los servicios están habilitados
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Servicios de ubicación deshabilitados');
      }

      // Habilitar servicio de ubicación en modo background si es necesario
      await _location.enableBackgroundMode(enable: false);

      // Obtener ubicación actual
      location_pkg.LocationData locationData = await _location.getLocation();

      return {
        'latitude': locationData.latitude ?? 16.867,
        'longitude': locationData.longitude ?? -92.094,
      };
    } catch (e) {
      // En caso de error, devolver ubicación por defecto (Ocosingo)
      print('Error obteniendo ubicación: $e');
      return {
        'latitude': 16.867,
        'longitude': -92.094,
      };
    }
  }

  // Obtener ubicación con precisión específica
  // Nota: El paquete location usa una API diferente, así que simulamos con alta precisión
  static Future<Map<String, double>> getCurrentLocationWithAccuracy(
    dynamic accuracy, // Mantenemos el parámetro para compatibilidad
  ) async {
    try {
      bool hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await requestLocationPermission();
        if (!hasPermission) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      // El paquete location no tiene control directo de precisión,
      // pero intentamos obtener la mejor ubicación disponible
      _location.changeSettings(
        accuracy: location_pkg.LocationAccuracy.high,
        interval: 1000,
        distanceFilter: 0,
      );

      location_pkg.LocationData locationData = await _location.getLocation();

      return {
        'latitude': locationData.latitude ?? 16.867,
        'longitude': locationData.longitude ?? -92.094,
      };
    } catch (e) {
      print('Error obteniendo ubicación con precisión: $e');
      return {
        'latitude': 16.867,
        'longitude': -92.094,
      };
    }
  }

  // Calcular distancia entre dos puntos usando la fórmula de Haversine
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

  // Obtener distancia en metros
  static double calculateDistanceInMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return calculateDistance(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) *
        1000; // Convertir kilómetros a metros
  }

  // Escuchar cambios de ubicación
  static Stream<Map<String, double>> getLocationStream() {
    return _location.onLocationChanged
        .map((location_pkg.LocationData locationData) {
      return {
        'latitude': locationData.latitude ?? 16.867,
        'longitude': locationData.longitude ?? -92.094,
      };
    });
  }

  // Obtener dirección desde coordenadas (requiere API de geocodificación)
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Por ahora devolvemos coordenadas como dirección
      // En el futuro se puede integrar con una API de geocodificación
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      print('Error obteniendo dirección: $e');
      return 'Ubicación desconocida';
    }
  }

  // Verificar si la ubicación está dentro de un radio específico
  static bool isWithinRadius(
    double userLatitude,
    double userLongitude,
    double targetLatitude,
    double targetLongitude,
    double radiusInKm,
  ) {
    double distance = calculateDistance(
      userLatitude,
      userLongitude,
      targetLatitude,
      targetLongitude,
    );
    return distance <= radiusInKm;
  }

  // Método auxiliar para convertir grados a radianes
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
