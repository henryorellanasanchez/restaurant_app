import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/features/reportes/domain/entities/reporte_mesero.dart';
import 'package:restaurant_app/features/reportes/domain/entities/reporte_metodo_pago.dart';
import 'package:restaurant_app/features/reportes/domain/entities/reporte_producto_vendido.dart';
import 'package:restaurant_app/features/reportes/domain/entities/reporte_resumen.dart';
import 'package:restaurant_app/features/reportes/domain/entities/reporte_venta_dia.dart';
import 'package:restaurant_app/features/reportes/domain/usecases/reportes_usecases.dart';

// ── Filtro de período ──────────────────────────────────────────────────────────

enum FiltroFecha {
  hoy,
  semana,
  mes,
  trimestre;

  String get label {
    switch (this) {
      case FiltroFecha.hoy:
        return 'Hoy';
      case FiltroFecha.semana:
        return '7 días';
      case FiltroFecha.mes:
        return '30 días';
      case FiltroFecha.trimestre:
        return '3 meses';
    }
  }

  /// Calcula [fechaInicio] relativo a [ahora].
  DateTime fechaInicio(DateTime ahora) {
    switch (this) {
      case FiltroFecha.hoy:
        return DateTime(ahora.year, ahora.month, ahora.day);
      case FiltroFecha.semana:
        return DateTime(
          ahora.year,
          ahora.month,
          ahora.day,
        ).subtract(const Duration(days: 6));
      case FiltroFecha.mes:
        return DateTime(
          ahora.year,
          ahora.month,
          ahora.day,
        ).subtract(const Duration(days: 29));
      case FiltroFecha.trimestre:
        return DateTime(
          ahora.year,
          ahora.month,
          ahora.day,
        ).subtract(const Duration(days: 89));
    }
  }

  DateTime fechaFin(DateTime ahora) =>
      DateTime(ahora.year, ahora.month, ahora.day);
}

// ── Estado ─────────────────────────────────────────────────────────────────────

class ReportesState {
  final FiltroFecha filtro;
  final ResumenVentas? resumen;
  final List<VentaPorDia> ventasPorDia;
  final List<ProductoVendido> topProductos;
  final List<VentaPorMetodo> ventasPorMetodo;
  final List<VentaPorMesero> ventasPorMesero;
  final bool isLoading;
  final String? error;

  const ReportesState({
    this.filtro = FiltroFecha.semana,
    this.resumen,
    this.ventasPorDia = const [],
    this.topProductos = const [],
    this.ventasPorMetodo = const [],
    this.ventasPorMesero = const [],
    this.isLoading = false,
    this.error,
  });

  ReportesState copyWith({
    FiltroFecha? filtro,
    ResumenVentas? resumen,
    List<VentaPorDia>? ventasPorDia,
    List<ProductoVendido>? topProductos,
    List<VentaPorMetodo>? ventasPorMetodo,
    List<VentaPorMesero>? ventasPorMesero,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ReportesState(
      filtro: filtro ?? this.filtro,
      resumen: resumen ?? this.resumen,
      ventasPorDia: ventasPorDia ?? this.ventasPorDia,
      topProductos: topProductos ?? this.topProductos,
      ventasPorMetodo: ventasPorMetodo ?? this.ventasPorMetodo,
      ventasPorMesero: ventasPorMesero ?? this.ventasPorMesero,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class ReportesNotifier extends StateNotifier<ReportesState> {
  ReportesNotifier({
    required GetResumenVentas getResumenVentas,
    required GetVentasPorDia getVentasPorDia,
    required GetTopProductos getTopProductos,
    required GetVentasPorMetodo getVentasPorMetodo,
    required GetVentasPorMesero getVentasPorMesero,
  }) : _getResumenVentas = getResumenVentas,
       _getVentasPorDia = getVentasPorDia,
       _getTopProductos = getTopProductos,
       _getVentasPorMetodo = getVentasPorMetodo,
       _getVentasPorMesero = getVentasPorMesero,
       super(const ReportesState()) {
    cargarReportes();
  }

  final GetResumenVentas _getResumenVentas;
  final GetVentasPorDia _getVentasPorDia;
  final GetTopProductos _getTopProductos;
  final GetVentasPorMetodo _getVentasPorMetodo;
  final GetVentasPorMesero _getVentasPorMesero;

  /// Cambia el filtro de período y recarga automáticamente.
  Future<void> cambiarFiltro(FiltroFecha filtro) async {
    state = state.copyWith(filtro: filtro);
    await cargarReportes();
  }

  /// Carga todos los datos del reporte en paralelo.
  Future<void> cargarReportes() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final ahora = DateTime.now();
    final inicio = state.filtro.fechaInicio(ahora);
    final fin = state.filtro.fechaFin(ahora);
    final restaurantId = AppConstants.defaultRestaurantId;

    final params = FiltroReporteParams(
      restaurantId: restaurantId,
      fechaInicio: inicio,
      fechaFin: fin,
    );

    final results = await Future.wait([
      _getResumenVentas(params),
      _getVentasPorDia(params),
      _getTopProductos(
        FiltroTopProductosParams(
          restaurantId: restaurantId,
          fechaInicio: inicio,
          fechaFin: fin,
          limit: 10,
        ),
      ),
      _getVentasPorMetodo(params),
      _getVentasPorMesero(params),
    ]);

    final resumenResult = results[0];
    final diasResult = results[1];
    final productosResult = results[2];
    final metodosResult = results[3];
    final mserosResult = results[4];

    String? errorMsg;

    resumenResult.fold((f) => errorMsg = f.toString(), (_) {});

    state = state.copyWith(
      isLoading: false,
      error: errorMsg,
      resumen: resumenResult.fold((_) => null, (r) => r as ResumenVentas),
      ventasPorDia: diasResult.fold((_) => [], (r) => r as List<VentaPorDia>),
      topProductos: productosResult.fold(
        (_) => [],
        (r) => r as List<ProductoVendido>,
      ),
      ventasPorMetodo: metodosResult.fold(
        (_) => [],
        (r) => r as List<VentaPorMetodo>,
      ),
      ventasPorMesero: mserosResult.fold(
        (_) => [],
        (r) => r as List<VentaPorMesero>,
      ),
    );
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final reportesProvider = StateNotifierProvider<ReportesNotifier, ReportesState>(
  (ref) {
    return ReportesNotifier(
      getResumenVentas: sl(),
      getVentasPorDia: sl(),
      getTopProductos: sl(),
      getVentasPorMetodo: sl(),
      getVentasPorMesero: sl(),
    );
  },
);
