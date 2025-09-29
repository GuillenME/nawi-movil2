class UserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String rolId;
  final String? telefono;
  final String? foto;
  final String? token;
  final String? tipo;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.rolId,
    this.telefono,
    this.foto,
    this.token,
    this.tipo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      email: json['email'] ?? '',
      rolId: json['id_rol'] ?? json['rol_id'] ?? '',
      telefono: json['telefono'],
      foto: json['foto'],
      token: json['access_token'] ?? json['token'],
      tipo: json['tipo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'id_rol': rolId,
      'telefono': telefono,
      'foto': foto,
      'access_token': token,
      'tipo': tipo,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
  bool get isTaxista => tipo == 'taxista' || rolId == '3';
  bool get isPasajero => tipo == 'pasajero' || rolId == '2';
}
