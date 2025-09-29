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
  final double? calificacion;
  final String? comentario;

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
    this.calificacion,
    this.comentario,
  });

  factory ViajeModel.fromJson(Map<String, dynamic> json) {
    return ViajeModel(
      id: json['id'] ?? '',
      pasajeroId: json['pasajero_id'] ?? 0,
      taxistaId: json['taxista_id'],
      latitudOrigen: json['latitud_origen']?.toDouble() ?? 0.0,
      longitudOrigen: json['longitud_origen']?.toDouble() ?? 0.0,
      direccionOrigen: json['direccion_origen'] ?? '',
      latitudDestino: json['latitud_destino']?.toDouble() ?? 0.0,
      longitudDestino: json['longitud_destino']?.toDouble() ?? 0.0,
      direccionDestino: json['direccion_destino'] ?? '',
      estado: json['estado'] ?? 'solicitado',
      fechaCreacion: DateTime.parse(
          json['fecha_creacion'] ?? DateTime.now().toIso8601String()),
      fechaAceptacion: json['fecha_aceptacion'] != null
          ? DateTime.parse(json['fecha_aceptacion'])
          : null,
      fechaCompletado: json['fecha_completado'] != null
          ? DateTime.parse(json['fecha_completado'])
          : null,
      calificacion: json['calificacion']?.toDouble(),
      comentario: json['comentario'],
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
      'calificacion': calificacion,
      'comentario': comentario,
    };
  }
}
