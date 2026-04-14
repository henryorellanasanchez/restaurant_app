import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/caja/domain/entities/venta.dart';
import 'package:restaurant_app/features/caja/domain/entities/venta_detalle.dart';
import 'package:restaurant_app/features/caja/domain/usecases/caja_usecases.dart';
import 'package:restaurant_app/features/pedidos/domain/entities/pedido.dart';
import 'package:restaurant_app/services/facturacion/sri_service.dart';
import 'package:uuid/uuid.dart';

/// Estado del módulo de Caja.
class CajaState {
  final List<Pedido> pedidosParaCobrar;
  final List<Venta> ventasHoy;
  final List<Venta> todasLasVentas;
  final bool isLoading;
  final bool isProcessing;
  final String? errorMessage;
  final Venta? ultimaVenta;

  const CajaState({
    this.pedidosParaCobrar = const [],
    this.ventasHoy = const [],
    this.todasLasVentas = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.errorMessage,
    this.ultimaVenta,
  });

  CajaState copyWith({
    List<Pedido>? pedidosParaCobrar,
    List<Venta>? ventasHoy,
    List<Venta>? todasLasVentas,
    bool? isLoading,
    bool? isProcessing,
    String? errorMessage,
    Venta? ultimaVenta,
    bool clearError = false,
    bool clearUltimaVenta = false,
  }) {
    return CajaState(
      pedidosParaCobrar: pedidosParaCobrar ?? this.pedidosParaCobrar,
      ventasHoy: ventasHoy ?? this.ventasHoy,
      todasLasVentas: todasLasVentas ?? this.todasLasVentas,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      ultimaVenta: clearUltimaVenta ? null : (ultimaVenta ?? this.ultimaVenta),
    );
  }

  // ── Computed ─────────────────────────────────────────────────

  int get totalPedidosPendientes => pedidosParaCobrar.length;

  double get totalVentasHoy => ventasHoy.fold(0.0, (sum, v) => sum + v.total);

  int get cantidadVentasHoy => ventasHoy.length;

  double get ticketPromedioHoy =>
      cantidadVentasHoy == 0 ? 0.0 : totalVentasHoy / cantidadVentasHoy;

  double get totalPendientePorCobrar =>
      pedidosParaCobrar.fold(0.0, (sum, pedido) {
        final totalPedido = pedido.totalCalculado > 0
            ? pedido.totalCalculado
            : pedido.total;
        return sum + totalPedido;
      });

  Map<MetodoPago, double> get ventasPorMetodo {
    final map = <MetodoPago, double>{};
    for (final v in ventasHoy) {
      map[v.metodoPago] = (map[v.metodoPago] ?? 0) + v.total;
    }
    return map;
  }
}

/// Notifier del módulo de Caja.
class CajaNotifier extends StateNotifier<CajaState> {
  final GetPedidosParaCobrar _getPedidosParaCobrar;
  final RegistrarVenta _registrarVenta;
  final GetVentas _getVentas;
  final GetVentasByFecha _getVentasByFecha;
  final SriService _sriService;

  CajaNotifier({
    required GetPedidosParaCobrar getPedidosParaCobrar,
    required RegistrarVenta registrarVenta,
    required GetVentas getVentas,
    required GetVentasByFecha getVentasByFecha,
    required SriService sriService,
  }) : _getPedidosParaCobrar = getPedidosParaCobrar,
       _registrarVenta = registrarVenta,
       _getVentas = getVentas,
       _getVentasByFecha = getVentasByFecha,
       _sriService = sriService,
       super(const CajaState());

  // ── Carga ──────────────────────────────────────────────────────

  Future<void> loadCaja([String? restaurantId]) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final rid = restaurantId ?? AppConstants.defaultRestaurantId;

    final pedidosResult = await _getPedidosParaCobrar(rid);
    pedidosResult.fold(
      (f) => state = state.copyWith(isLoading: false, errorMessage: f.message),
      (pedidos) async {
        final ventasResult = await _getVentasByFecha(rid, DateTime.now());
        ventasResult.fold(
          (f) => state = state.copyWith(
            isLoading: false,
            pedidosParaCobrar: pedidos,
            errorMessage: f.message,
          ),
          (ventas) => state = state.copyWith(
            isLoading: false,
            pedidosParaCobrar: pedidos,
            ventasHoy: ventas,
          ),
        );
      },
    );
  }

  Future<void> loadHistorial([String? restaurantId]) async {
    final rid = restaurantId ?? AppConstants.defaultRestaurantId;
    final result = await _getVentas(rid);
    result.fold(
      (f) => state = state.copyWith(errorMessage: f.message),
      (ventas) => state = state.copyWith(todasLasVentas: ventas),
    );
  }

  // ── Cobro ──────────────────────────────────────────────────────

  /// Procesa el cobro de un pedido.
  ///
  /// Retorna la [Venta] creada si fue exitoso, o null en caso de error.
  Future<Venta?> cobrarPedido({
    required Pedido pedido,
    required MetodoPago metodoPago,
    TipoComprobante tipoComprobante = TipoComprobante.ticket,
    double descuento = 0,
    String? descripcion,
    String? clienteNombre,
    String? clienteEmail,
    String? clienteIdentificacion,
    String? cajeroId,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    // Construir detalles desde los items del pedido
    final ventaId = const Uuid().v4();
    final detalles = pedido.items.map((item) {
      return VentaDetalle(
        id: const Uuid().v4(),
        ventaId: ventaId,
        productoId: item.productoId,
        varianteId: item.varianteId,
        cantidad: item.cantidad,
        precioUnitario: item.precioUnitario,
        subtotal: item.subtotal,
        productoNombre: item.productoNombre,
        varianteNombre: item.varianteNombre,
      );
    }).toList();

    final subtotal = pedido.totalCalculado;
    final totalConDescuento = (subtotal - descuento).clamp(0.0, subtotal);
    const double impuestos = 0; // configurable en fases posteriores

    final ventaBase = Venta(
      id: ventaId,
      restaurantId: pedido.restaurantId,
      pedidoId: pedido.id,
      cajeroId: cajeroId,
      clienteNombre: clienteNombre,
      clienteEmail: clienteEmail,
      clienteIdentificacion: clienteIdentificacion,
      metodoPago: metodoPago,
      tipoComprobante: tipoComprobante,
      subtotal: subtotal,
      impuestos: impuestos,
      total: totalConDescuento + impuestos,
      descripcionPago: descripcion,
      createdAt: DateTime.now(),
      detalles: detalles,
    );

    final sriDraft = tipoComprobante == TipoComprobante.factura
        ? await _sriService.buildInvoiceDraft(ventaBase)
        : null;

    final venta = ventaBase.copyWith(
      estadoSri: tipoComprobante == TipoComprobante.factura
          ? ((sriDraft?.status.canPrepareInvoice ?? false)
                ? EstadoComprobanteSri.preparado
                : EstadoComprobanteSri.noConfigurado)
          : EstadoComprobanteSri.noAplica,
      sriClaveAcceso: sriDraft?.accessKey,
      sriMensaje: tipoComprobante == TipoComprobante.factura
          ? '${sriDraft?.status.message ?? 'Factura preparada localmente.'} La transmisión real queda comentada.'
          : 'Comprobante interno generado sin envío fiscal.',
    );

    final result = await _registrarVenta(venta, mesaId: pedido.mesaId);

    return result.fold(
      (f) {
        state = state.copyWith(isProcessing: false, errorMessage: f.message);
        return null;
      },
      (_) {
        // Recargar datos
        loadCaja();
        state = state.copyWith(isProcessing: false, ultimaVenta: venta);
        return venta;
      },
    );
  }

  void clearUltimaVenta() {
    state = state.copyWith(clearUltimaVenta: true);
  }
}

/// Provider global del módulo de Caja.
final cajaProvider = StateNotifierProvider<CajaNotifier, CajaState>((ref) {
  return CajaNotifier(
    getPedidosParaCobrar: sl(),
    registrarVenta: sl(),
    getVentas: sl(),
    getVentasByFecha: sl(),
    sriService: sl(),
  );
});
