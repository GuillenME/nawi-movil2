import 'package:nawii/services/location_service_simple.dart';

class TarifaEstimada {
  // Coordenadas del centro de Ocosingo (aproximadas)
  static const double centroOcosingoLat = 16.9064;
  static const double centroOcosingoLon = -92.0931;
  
  // Radio en km para considerar que está en el centro
  static const double radioCentroKm = 3.0; // 3 km de radio desde el centro
  
  // Tarifas estimadas
  static const double tarifaMinCentro = 35.0;
  static const double tarifaMaxCentro = 40.0;
  static const double tarifaMinFuera = 40.0;
  static const double tarifaMaxFuera = 60.0;

  /// Calcula si un punto está dentro del centro de Ocosingo
  static bool _estaEnCentro(double lat, double lon) {
    final distancia = LocationServiceSimple.calculateDistance(
      centroOcosingoLat,
      centroOcosingoLon,
      lat,
      lon,
    );
    return distancia <= radioCentroKm;
  }

  /// Calcula la tarifa estimada basada en el origen y destino
  /// Retorna un mapa con 'min', 'max' y 'tipo' ('centro' o 'fuera')
  static Map<String, dynamic> calcularTarifaEstimada({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
  }) {
    // Verificar si origen y destino están en el centro
    final origenEnCentro = _estaEnCentro(origenLat, origenLon);
    final destinoEnCentro = _estaEnCentro(destinoLat, destinoLon);
    
    // Si ambos están en el centro, es viaje por el centro
    // Si alguno está fuera, es viaje fuera de Ocosingo
    final esCentro = origenEnCentro && destinoEnCentro;
    
    if (esCentro) {
      return {
        'min': tarifaMinCentro,
        'max': tarifaMaxCentro,
        'tipo': 'centro',
        'texto': 'MX\$${tarifaMinCentro.toStringAsFixed(0)} - MX\$${tarifaMaxCentro.toStringAsFixed(0)}',
      };
    } else {
      return {
        'min': tarifaMinFuera,
        'max': tarifaMaxFuera,
        'tipo': 'fuera',
        'texto': 'MX\$${tarifaMinFuera.toStringAsFixed(0)} - MX\$${tarifaMaxFuera.toStringAsFixed(0)}',
      };
    }
  }

  /// Obtiene el texto descriptivo de la tarifa estimada
  static String obtenerTextoEstimado({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
  }) {
    final tarifa = calcularTarifaEstimada(
      origenLat: origenLat,
      origenLon: origenLon,
      destinoLat: destinoLat,
      destinoLon: destinoLon,
    );
    return tarifa['texto'] as String;
  }
}

