import 'package:restaurant_app/features/clientes/domain/entities/cliente.dart';

/// Modelo de datos: Cliente.
///
/// Serialización SQLite para la entidad [Cliente].
class ClienteModel extends Cliente {
  const ClienteModel({
    required super.cedula,
    required super.restaurantId,
    required super.nombre,
    super.apellido,
    super.telefono,
    super.email,
    super.direccion,
    super.fechaNacimiento,
    super.notas,
    super.activo,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      cedula: map['cedula'] as String,
      restaurantId: map['restaurant_id'] as String,
      nombre: map['nombre'] as String,
      apellido: map['apellido'] as String?,
      telefono: map['telefono'] as String?,
      email: map['email'] as String?,
      direccion: map['direccion'] as String?,
      fechaNacimiento: map['fecha_nacimiento'] != null
          ? DateTime.tryParse(map['fecha_nacimiento'] as String)
          : null,
      notas: map['notas'] as String?,
      activo: (map['activo'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cedula': cedula,
      'restaurant_id': restaurantId,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'notas': notas,
      'activo': activo ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClienteModel.fromEntity(Cliente cliente) {
    return ClienteModel(
      cedula: cliente.cedula,
      restaurantId: cliente.restaurantId,
      nombre: cliente.nombre,
      apellido: cliente.apellido,
      telefono: cliente.telefono,
      email: cliente.email,
      direccion: cliente.direccion,
      fechaNacimiento: cliente.fechaNacimiento,
      notas: cliente.notas,
      activo: cliente.activo,
      createdAt: cliente.createdAt,
      updatedAt: cliente.updatedAt,
    );
  }
}
