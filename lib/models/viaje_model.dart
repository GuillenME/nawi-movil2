import 'package:nawii/models/user_model.dart';

class ViajeModel {
  final String id;
  final int pasajeroId;
  final int? taxistaId;
  final double latitudOrigen;
  final double longitudOrigen;
  final String direccionOrigen;
  final double latitudDestino;
  final double longitudDestino;
  final String direccionDestino;
  final String
      estado; // 'solicitado', 'aceptado', 'en_progreso', 'completado', 'cancelado'
  final DateTime fechaCreacion;
  final DateTime? fechaAceptacion;
  final DateTime? fechaCompletado;
  final DateTime? tiempoLimiteAceptacion; // ⭐ NUEVO: Tiempo límite para aceptar el viaje
  final double? tarifa; // ⭐ NUEVO: Tarifa del viaje (establecida por el taxista)
  final double? calificacion;
  final String? comentario;
  final UserModel? pasajero; // Datos completos del pasajero (viene de la API)
  final UserModel? taxista; // Datos completos del taxista (viene de la API)

  ViajeModel({
    required this.id,
    required this.pasajeroId,
    this.taxistaId,
    required this.latitudOrigen,
    required this.longitudOrigen,
    required this.direccionOrigen,
    required this.latitudDestino,
    required this.longitudDestino,
    required this.direccionDestino,
    required this.estado,
    required this.fechaCreacion,
    this.fechaAceptacion,
    this.fechaCompletado,
    this.tiempoLimiteAceptacion,
    this.tarifa,
    this.calificacion,
    this.comentario,
    this.pasajero,
    this.taxista,
  });

  // Helper para parsear fechas y convertirlas a hora local
  static DateTime _parsearFecha(dynamic fechaValue) {
    if (fechaValue == null) return DateTime.now();
    
    DateTime fecha;
    if (fechaValue is String) {
      fecha = DateTime.parse(fechaValue);
    } else {
      return DateTime.now();
    }
    
    // Si la fecha está en UTC, convertirla a hora local
    if (fecha.isUtc) {
      return fecha.toLocal();
    }
    return fecha;
  }

  factory ViajeModel.fromJson(Map<String, dynamic> json) {
    // Parsear datos anidados de pasajero y taxista si existen
    UserModel? pasajeroData;
    UserModel? taxistaData;
    
    if (json['pasajero'] != null && json['pasajero'] is Map) {
      try {
        pasajeroData = UserModel.fromJson(json['pasajero'] as Map<String, dynamic>);
      } catch (e) {
        print('Error parseando datos del pasajero: $e');
      }
    }
    
    if (json['taxista'] != null && json['taxista'] is Map) {
      try {
        taxistaData = UserModel.fromJson(json['taxista'] as Map<String, dynamic>);
      } catch (e) {
        print('Error parseando datos del taxista: $e');
      }
    }
    
    // ⭐ ACTUALIZADO según documentación: El backend SIEMPRE envía "id" como UUID (string) y nunca es null
    // Según BACKEND_API_STRUCTURE.md: "✅ El campo `id` SIEMPRE está presente y nunca es null"
    dynamic idValue = json['id'];
    
    // Convertir a string (el backend envía UUIDs como strings)
    String id = '';
    if (idValue != null) {
      id = idValue.toString().trim();
      // Si el string es "null" o está vacío después del trim, es un error del backend
      if (id.isEmpty || id.toLowerCase() == 'null') {
        id = '';
      }
    }
    
    // ⭐ CRÍTICO: Si el ID está vacío, el backend no está cumpliendo con la documentación
    if (id.isEmpty) {
      print('❌ ERROR CRÍTICO: Viaje sin ID válido. El backend debe enviar siempre el campo "id".');
      print('   Keys disponibles en JSON: ${json.keys.toList()}');
      print('   Valor de json["id"]: ${json['id']} (tipo: ${json['id']?.runtimeType})');
      print('   JSON completo: $json');
      // Intentar campos alternativos como fallback (aunque no deberían ser necesarios)
      idValue = json['id_viaje'] ?? json['viaje_id'] ?? json['uuid'];
      if (idValue != null) {
        id = idValue.toString().trim();
        print('   ⚠️  Usando campo alternativo: $id');
      }
    }
    
    // ⭐ ACTUALIZADO: Parsear pasajero_id y taxista_id (pueden venir como UUID string o int)
    // Según documentación, vienen como UUID strings, pero mantenemos compatibilidad con int
    final pasajeroIdValue = json['pasajero_id'];
    final pasajeroId = pasajeroIdValue != null
        ? (pasajeroIdValue is String
            ? int.tryParse(pasajeroIdValue) ?? 0
            : pasajeroIdValue is int
                ? pasajeroIdValue
                : 0)
        : 0;
    
    final taxistaIdValue = json['taxista_id'];
    final taxistaId = taxistaIdValue != null
        ? (taxistaIdValue is String
            ? int.tryParse(taxistaIdValue)
            : taxistaIdValue is int
                ? taxistaIdValue
                : null)
        : null;
    
    return ViajeModel(
      id: id,
      pasajeroId: pasajeroId,
      taxistaId: taxistaId,
      latitudOrigen: json['latitud_origen']?.toDouble() ?? 0.0,
      longitudOrigen: json['longitud_origen']?.toDouble() ?? 0.0,
      direccionOrigen: json['direccion_origen'] ?? '',
      latitudDestino: json['latitud_destino']?.toDouble() ?? 0.0,
      longitudDestino: json['longitud_destino']?.toDouble() ?? 0.0,
      direccionDestino: json['direccion_destino'] ?? '',
      estado: json['estado'] ?? 'solicitado',
      fechaCreacion: json['fecha_creacion'] != null
          ? _parsearFecha(json['fecha_creacion'])
          : (json['created_at'] != null
              ? _parsearFecha(json['created_at'])
              : DateTime.now()),
      fechaAceptacion: json['fecha_aceptacion'] != null
          ? _parsearFecha(json['fecha_aceptacion'])
          : null,
      fechaCompletado: json['fecha_completado'] != null
          ? _parsearFecha(json['fecha_completado'])
          : null,
      tiempoLimiteAceptacion: json['tiempo_limite_aceptacion'] != null
          ? _parsearFecha(json['tiempo_limite_aceptacion'])
          : null,
      tarifa: json['tarifa']?.toDouble(),
      calificacion: json['calificacion']?.toDouble(),
      comentario: json['comentario'],
      pasajero: pasajeroData,
      taxista: taxistaData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pasajero_id': pasajeroId,
      'taxista_id': taxistaId,
      'latitud_origen': latitudOrigen,
      'longitud_origen': longitudOrigen,
      'direccion_origen': direccionOrigen,
      'latitud_destino': latitudDestino,
      'longitud_destino': longitudDestino,
      'direccion_destino': direccionDestino,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_aceptacion': fechaAceptacion?.toIso8601String(),
      'fecha_completado': fechaCompletado?.toIso8601String(),
      'tiempo_limite_aceptacion': tiempoLimiteAceptacion?.toIso8601String(),
      'tarifa': tarifa,
      'calificacion': calificacion,
      'comentario': comentario,
    };
  }
}
