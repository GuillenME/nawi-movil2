class MapsConfig {
  // API Key de Google Maps
  // IMPORTANTE: En producción, esta clave debe estar en variables de entorno
  // y no hardcodeada en el código fuente
  static const String googleMapsApiKey = 'AIzaSyCaZFeEmON_iOVCBO24V1FmQu0pQ2QrxhU';
  
  // Configuración por defecto del mapa
  static const double defaultZoom = 15.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 20.0;
  
  // Ubicación por defecto (Ocosingo, Chiapas)
  static const double defaultLatitude = 16.867;
  static const double defaultLongitude = -92.094;
  
  // Configuración de marcadores
  static const double markerSize = 40.0;
  static const double userMarkerSize = 50.0;
  
  // Configuración de ubicación
  static const double locationAccuracy = 10.0; // metros
  static const int locationTimeout = 10; // segundos
}
