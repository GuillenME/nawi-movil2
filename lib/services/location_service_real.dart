import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationServiceReal {
  // Verificar si los permisos de ubicación están concedidos
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Solicitar permisos de ubicación
  static Future<bool> requestLocationPermission() async {
    // Solicitar permisos usando permission_handler
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Solicitar al usuario que habilite los servicios de ubicación
        return false;
      }
      return true;
    }
    return false;
  }

  // Verificar si los servicios de ubicación están habilitados
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
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

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
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
  static Future<Map<String, double>> getCurrentLocationWithAccuracy(
    LocationAccuracy accuracy,
  ) async {
    try {
      bool hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await requestLocationPermission();
        if (!hasPermission) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: Duration(seconds: 15),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
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
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convertir metros a kilómetros
  }

  // Obtener distancia en metros
  static double calculateDistanceInMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Escuchar cambios de ubicación
  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
      ),
    );
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
}
