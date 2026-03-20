import 'package:restaurant_app/features/cotizaciones/domain/entities/cotizacion.dart';
import 'package:restaurant_app/features/cotizaciones/domain/entities/cotizacion_item.dart';

/// Modelo de datos: Cotizacion.
class CotizacionModel extends Cotizacion {
  const CotizacionModel({
    required super.id,
    required super.restaurantId,
    super.mesaId,
    required super.clienteNombre,
    required super.clienteTelefono,
    required super.clienteEmail,
    super.estado,
    super.reservaLocal,
    super.personas,
    super.fechaEvento,
    super.comidaPreferida,
    super.notas,
    required super.subtotal,
    required super.total,
    required super.createdAt,
    super.items,
  });

  factory CotizacionModel.fromMap(
    Map<String, dynamic> map, {
    List<CotizacionItem>? items,
  }) {
    return CotizacionModel(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String,
      mesaId: map['mesa_id'] as String?,
      clienteNombre: map['cliente_nombre'] as String,
      clienteTelefono: map['cliente_telefono'] as String,
      clienteEmail: map['cliente_email'] as String,
      estado: map['estado'] as String? ?? 'pendiente',
      reservaLocal: (map['reserva_local'] as int?) == 1,
      personas: map['personas'] as int?,
      fechaEvento: map['fecha_evento'] as String?,
      comidaPreferida: map['comida_preferida'] as String?,
      notas: map['notas'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'mesa_id': mesaId,
      'cliente_nombre': clienteNombre,
      'cliente_telefono': clienteTelefono,
      'cliente_email': clienteEmail,
      'estado': estado,
      'reserva_local': reservaLocal ? 1 : 0,
      'personas': personas,
      'fecha_evento': fechaEvento,
      'comida_preferida': comidaPreferida,
      'notas': notas,
      'subtotal': subtotal,
      'total': total,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CotizacionModel.fromEntity(Cotizacion entity) {
    return CotizacionModel(
      id: entity.id,
      restaurantId: entity.restaurantId,
      mesaId: entity.mesaId,
      clienteNombre: entity.clienteNombre,
      clienteTelefono: entity.clienteTelefono,
      clienteEmail: entity.clienteEmail,
      estado: entity.estado,
      reservaLocal: entity.reservaLocal,
      personas: entity.personas,
      fechaEvento: entity.fechaEvento,
      comidaPreferida: entity.comidaPreferida,
      notas: entity.notas,
      subtotal: entity.subtotal,
      total: entity.total,
      createdAt: entity.createdAt,
      items: entity.items,
    );
  }
}
