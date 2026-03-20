import 'package:equatable/equatable.dart';
import 'package:restaurant_app/core/domain/enums.dart';

/// Entidad de dominio: Reserva.
class Reserva extends Equatable {
  final String id;
  final String restaurantId;
  final TipoReserva tipo;
  final String? mesaId;
  final String? mesaNombre;
  final String fecha; // YYYY-MM-DD
  final String clienteNombre;
  final String clienteTelefono;
  final String clienteEmail;
  final String? notas;
  final DateTime createdAt;

  const Reserva({
    required this.id,
    required this.restaurantId,
    required this.tipo,
    this.mesaId,
    this.mesaNombre,
    required this.fecha,
    required this.clienteNombre,
    required this.clienteTelefono,
    required this.clienteEmail,
    this.notas,
    required this.createdAt,
  });

  Reserva copyWith({
    String? id,
    String? restaurantId,
    TipoReserva? tipo,
    String? mesaId,
    String? mesaNombre,
    String? fecha,
    String? clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    String? notas,
    DateTime? createdAt,
  }) {
    return Reserva(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      tipo: tipo ?? this.tipo,
      mesaId: mesaId ?? this.mesaId,
      mesaNombre: mesaNombre ?? this.mesaNombre,
      fecha: fecha ?? this.fecha,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    restaurantId,
    tipo,
    mesaId,
    mesaNombre,
    fecha,
    clienteNombre,
    clienteTelefono,
    clienteEmail,
    notas,
    createdAt,
  ];
}
