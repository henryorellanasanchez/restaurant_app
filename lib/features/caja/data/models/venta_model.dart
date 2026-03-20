import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/caja/domain/entities/venta.dart';
import 'package:restaurant_app/features/caja/domain/entities/venta_detalle.dart';

/// Modelo de datos: Venta.
///
/// Serialización SQLite para la entidad [Venta].
/// Los [detalles] se cargan opcionalmente con una query separada.
class VentaModel extends Venta {
  const VentaModel({
    required super.id,
    required super.restaurantId,
    required super.pedidoId,
    super.cajeroId,
    super.clienteNombre,
    super.clienteEmail,
    required super.metodoPago,
    required super.subtotal,
    super.impuestos,
    required super.total,
    super.descripcionPago,
    required super.createdAt,
    super.detalles,
    super.cajeroNombre,
  });

  factory VentaModel.fromMap(
    Map<String, dynamic> map, {
    List<VentaDetalle>? detalles,
  }) {
    return VentaModel(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String,
      pedidoId: map['pedido_id'] as String,
      cajeroId: map['cajero_id'] as String?,
      clienteNombre: map['cliente_nombre'] as String?,
      clienteEmail: map['cliente_email'] as String?,
      metodoPago: MetodoPago.fromString(map['metodo_pago'] as String),
      subtotal: (map['subtotal'] as num).toDouble(),
      impuestos: (map['impuestos'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num).toDouble(),
      descripcionPago: map['descripcion_pago'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      detalles: detalles ?? const [],
      cajeroNombre: map['cajero_nombre'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'pedido_id': pedidoId,
      'cajero_id': cajeroId,
      'cliente_nombre': clienteNombre,
      'cliente_email': clienteEmail,
      'metodo_pago': metodoPago.value,
      'subtotal': subtotal,
      'impuestos': impuestos,
      'total': total,
      'descripcion_pago': descripcionPago,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VentaModel.fromEntity(Venta entity) {
    return VentaModel(
      id: entity.id,
      restaurantId: entity.restaurantId,
      pedidoId: entity.pedidoId,
      cajeroId: entity.cajeroId,
      clienteNombre: entity.clienteNombre,
      clienteEmail: entity.clienteEmail,
      metodoPago: entity.metodoPago,
      subtotal: entity.subtotal,
      impuestos: entity.impuestos,
      total: entity.total,
      descripcionPago: entity.descripcionPago,
      createdAt: entity.createdAt,
      detalles: entity.detalles,
      cajeroNombre: entity.cajeroNombre,
    );
  }
}
