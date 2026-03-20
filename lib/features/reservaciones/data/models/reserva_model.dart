import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/reservaciones/domain/entities/reserva.dart';

/// Modelo de datos: Reserva.
class ReservaModel extends Reserva {
  const ReservaModel({
    required super.id,
    required super.restaurantId,
    required super.tipo,
    super.mesaId,
    super.mesaNombre,
    required super.fecha,
    required super.clienteNombre,
    required super.clienteTelefono,
    required super.clienteEmail,
    super.notas,
    required super.createdAt,
  });

  factory ReservaModel.fromMap(Map<String, dynamic> map) {
    return ReservaModel(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String,
      tipo: TipoReserva.fromString(map['tipo'] as String),
      mesaId: map['mesa_id'] as String?,
      mesaNombre: map['mesa_nombre'] as String?,
      fecha: map['fecha'] as String,
      clienteNombre: map['cliente_nombre'] as String,
      clienteTelefono: map['cliente_telefono'] as String,
      clienteEmail: map['cliente_email'] as String,
      notas: map['notas'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'tipo': tipo.value,
      'mesa_id': mesaId,
      'fecha': fecha,
      'cliente_nombre': clienteNombre,
      'cliente_telefono': clienteTelefono,
      'cliente_email': clienteEmail,
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReservaModel.fromEntity(Reserva entity) {
    return ReservaModel(
      id: entity.id,
      restaurantId: entity.restaurantId,
      tipo: entity.tipo,
      mesaId: entity.mesaId,
      mesaNombre: entity.mesaNombre,
      fecha: entity.fecha,
      clienteNombre: entity.clienteNombre,
      clienteTelefono: entity.clienteTelefono,
      clienteEmail: entity.clienteEmail,
      notas: entity.notas,
      createdAt: entity.createdAt,
    );
  }
}
