import 'package:restaurant_app/features/cotizaciones/domain/entities/cotizacion_item.dart';

/// Modelo de datos: item de cotizacion.
class CotizacionItemModel extends CotizacionItem {
  const CotizacionItemModel({
    required super.id,
    required super.cotizacionId,
    required super.productoId,
    required super.productoNombre,
    required super.cantidad,
    required super.precioUnitario,
    required super.subtotal,
  });

  factory CotizacionItemModel.fromMap(Map<String, dynamic> map) {
    return CotizacionItemModel(
      id: map['id'] as String,
      cotizacionId: map['cotizacion_id'] as String,
      productoId: map['producto_id'] as String,
      productoNombre: map['producto_nombre'] as String,
      cantidad: map['cantidad'] as int,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cotizacion_id': cotizacionId,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }

  factory CotizacionItemModel.fromEntity(CotizacionItem entity) {
    return CotizacionItemModel(
      id: entity.id,
      cotizacionId: entity.cotizacionId,
      productoId: entity.productoId,
      productoNombre: entity.productoNombre,
      cantidad: entity.cantidad,
      precioUnitario: entity.precioUnitario,
      subtotal: entity.subtotal,
    );
  }
}
