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
    super.horaInicio,
    super.horaFin,
    super.numeroPersonas,
    super.estado,
    super.tipoEvento,
    required super.clienteNombre,
    required super.clienteTelefono,
    required super.clienteEmail,
    super.notas,
    super.requerimientos,
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
      horaInicio: (map['hora_inicio'] as String?) ?? '19:00',
      horaFin: (map['hora_fin'] as String?) ?? '20:30',
      numeroPersonas: (map['numero_personas'] as num?)?.toInt() ?? 2,
      estado: EstadoReserva.fromString(
        (map['estado'] as String?) ?? 'pendiente',
      ),
      tipoEvento: map['tipo_evento'] as String?,
      clienteNombre: map['cliente_nombre'] as String,
      clienteTelefono: map['cliente_telefono'] as String,
      clienteEmail: (map['cliente_email'] as String?) ?? '',
      notas: map['notas'] as String?,
      requerimientos: map['requerimientos'] as String?,
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
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'numero_personas': numeroPersonas,
      'estado': estado.value,
      'tipo_evento': tipoEvento,
      'cliente_nombre': clienteNombre,
      'cliente_telefono': clienteTelefono,
      'cliente_email': clienteEmail,
      'notas': notas,
      'requerimientos': requerimientos,
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
      horaInicio: entity.horaInicio,
      horaFin: entity.horaFin,
      numeroPersonas: entity.numeroPersonas,
      estado: entity.estado,
      tipoEvento: entity.tipoEvento,
      clienteNombre: entity.clienteNombre,
      clienteTelefono: entity.clienteTelefono,
      clienteEmail: entity.clienteEmail,
      notas: entity.notas,
      requerimientos: entity.requerimientos,
      createdAt: entity.createdAt,
    );
  }
}
