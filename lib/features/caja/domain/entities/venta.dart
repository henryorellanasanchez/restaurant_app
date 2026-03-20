import 'package:equatable/equatable.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/caja/domain/entities/venta_detalle.dart';

/// Entidad de dominio: Venta.
///
/// Representa una transacción de cobro completada.
/// Cada venta está asociada a un [pedidoId] y registra
/// el método de pago y el cajero que la procesó.
class Venta extends Equatable {
  final String id;
  final String restaurantId;
  final String pedidoId;
  final String? cajeroId;
  final String? clienteNombre;
  final String? clienteEmail;
  final MetodoPago metodoPago;
  final double subtotal;
  final double impuestos;
  final double total;
  final String? descripcionPago;
  final DateTime createdAt;

  /// Detalles de los productos vendidos (cargados opcionalmente).
  final List<VentaDetalle> detalles;

  /// Nombre del cajero (para display).
  final String? cajeroNombre;

  const Venta({
    required this.id,
    required this.restaurantId,
    required this.pedidoId,
    this.cajeroId,
    this.clienteNombre,
    this.clienteEmail,
    required this.metodoPago,
    required this.subtotal,
    this.impuestos = 0,
    required this.total,
    this.descripcionPago,
    required this.createdAt,
    this.detalles = const [],
    this.cajeroNombre,
  });

  /// Cantidad de items vendidos.
  int get cantidadItems => detalles.fold(0, (sum, d) => sum + d.cantidad);

  Venta copyWith({
    String? id,
    String? restaurantId,
    String? pedidoId,
    String? cajeroId,
    String? clienteNombre,
    String? clienteEmail,
    MetodoPago? metodoPago,
    double? subtotal,
    double? impuestos,
    double? total,
    String? descripcionPago,
    DateTime? createdAt,
    List<VentaDetalle>? detalles,
    String? cajeroNombre,
  }) {
    return Venta(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      pedidoId: pedidoId ?? this.pedidoId,
      cajeroId: cajeroId ?? this.cajeroId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      metodoPago: metodoPago ?? this.metodoPago,
      subtotal: subtotal ?? this.subtotal,
      impuestos: impuestos ?? this.impuestos,
      total: total ?? this.total,
      descripcionPago: descripcionPago ?? this.descripcionPago,
      createdAt: createdAt ?? this.createdAt,
      detalles: detalles ?? this.detalles,
      cajeroNombre: cajeroNombre ?? this.cajeroNombre,
    );
  }

  @override
  List<Object?> get props => [
    id,
    restaurantId,
    pedidoId,
    cajeroId,
    clienteNombre,
    clienteEmail,
    metodoPago,
    subtotal,
    impuestos,
    total,
    descripcionPago,
    createdAt,
  ];
}
