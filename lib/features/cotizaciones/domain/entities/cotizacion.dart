import 'package:equatable/equatable.dart';
import 'package:restaurant_app/features/cotizaciones/domain/entities/cotizacion_item.dart';

/// Entidad de dominio: Cotizacion.
class Cotizacion extends Equatable {
  final String id;
  final String restaurantId;
  final String? mesaId;
  final String clienteNombre;
  final String clienteTelefono;
  final String clienteEmail;
  final String estado;
  final bool reservaLocal;
  final int? personas;
  final String? fechaEvento;
  final String? comidaPreferida;
  final String? notas;
  final double subtotal;
  final double total;
  final DateTime createdAt;

  final List<CotizacionItem> items;

  const Cotizacion({
    required this.id,
    required this.restaurantId,
    this.mesaId,
    required this.clienteNombre,
    required this.clienteTelefono,
    required this.clienteEmail,
    this.estado = 'pendiente',
    this.reservaLocal = false,
    this.personas,
    this.fechaEvento,
    this.comidaPreferida,
    this.notas,
    required this.subtotal,
    required this.total,
    required this.createdAt,
    this.items = const [],
  });

  Cotizacion copyWith({
    String? id,
    String? restaurantId,
    String? mesaId,
    String? clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    String? estado,
    bool? reservaLocal,
    int? personas,
    String? fechaEvento,
    String? comidaPreferida,
    String? notas,
    double? subtotal,
    double? total,
    DateTime? createdAt,
    List<CotizacionItem>? items,
  }) {
    return Cotizacion(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      mesaId: mesaId ?? this.mesaId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      estado: estado ?? this.estado,
      reservaLocal: reservaLocal ?? this.reservaLocal,
      personas: personas ?? this.personas,
      fechaEvento: fechaEvento ?? this.fechaEvento,
      comidaPreferida: comidaPreferida ?? this.comidaPreferida,
      notas: notas ?? this.notas,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    id,
    restaurantId,
    mesaId,
    clienteNombre,
    clienteTelefono,
    clienteEmail,
    estado,
    reservaLocal,
    personas,
    fechaEvento,
    comidaPreferida,
    notas,
    subtotal,
    total,
    createdAt,
  ];
}
