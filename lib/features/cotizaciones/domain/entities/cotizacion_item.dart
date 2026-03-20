import 'package:equatable/equatable.dart';

/// Entidad de dominio: item de cotizacion.
class CotizacionItem extends Equatable {
  final String id;
  final String cotizacionId;
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const CotizacionItem({
    required this.id,
    required this.cotizacionId,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  CotizacionItem copyWith({
    String? id,
    String? cotizacionId,
    String? productoId,
    String? productoNombre,
    int? cantidad,
    double? precioUnitario,
    double? subtotal,
  }) {
    return CotizacionItem(
      id: id ?? this.id,
      cotizacionId: cotizacionId ?? this.cotizacionId,
      productoId: productoId ?? this.productoId,
      productoNombre: productoNombre ?? this.productoNombre,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  @override
  List<Object?> get props => [
    id,
    cotizacionId,
    productoId,
    productoNombre,
    cantidad,
    precioUnitario,
    subtotal,
  ];
}
