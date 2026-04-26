import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/pedidos/domain/entities/pedido.dart';
import 'package:restaurant_app/features/pedidos/domain/usecases/pedido_usecases.dart';

/// Estado de la pantalla de Cocina.
///
/// Agrupa los pedidos en tres columnas visuales:
/// - [nuevos]      → estado: creado
/// - [preparando]  → estado: aceptado / enPreparacion
/// - [listos]      → estado: finalizado
class CocinaState {
  final List<Pedido> nuevos;
  final List<Pedido> preparando;
  final List<Pedido> listos;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastRefresh;

  const CocinaState({
    this.nuevos = const [],
    this.preparando = const [],
    this.listos = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastRefresh,
  });

  CocinaState copyWith({
    List<Pedido>? nuevos,
    List<Pedido>? preparando,
    List<Pedido>? listos,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastRefresh,
  }) {
    return CocinaState(
      nuevos: nuevos ?? this.nuevos,
      preparando: preparando ?? this.preparando,
      listos: listos ?? this.listos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }

  /// Total de pedidos visibles.
  int get totalPedidos => nuevos.length + preparando.length + listos.length;
}

/// Notifier para la pantalla de Cocina.
///
/// Tiene auto-refresh cada [_refreshInterval] segundos y
/// permite cambiar estados de pedidos e items desde la cocina.
class CocinaNotifier extends StateNotifier<CocinaState> {
  final GetPedidosActivos _getPedidosActivos;
  final UpdateEstadoPedido _updateEstadoPedido;
  final UpdateEstadoItem _updateEstadoItem;

  static const _refreshInterval = Duration(seconds: 30);
  Timer? _timer;

  CocinaNotifier({
    required GetPedidosActivos getPedidosActivos,
    required UpdateEstadoPedido updateEstadoPedido,
    required UpdateEstadoItem updateEstadoItem,
  }) : _getPedidosActivos = getPedidosActivos,
       _updateEstadoPedido = updateEstadoPedido,
       _updateEstadoItem = updateEstadoItem,
       super(const CocinaState());

  /// Inicia la pantalla de cocina y el auto-refresh.
  void start([String? restaurantId]) {
    refresh(restaurantId);
    _timer?.cancel();
    _timer = Timer.periodic(_refreshInterval, (_) => refresh(restaurantId));
  }

  /// Detiene el auto-refresh.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Recarga manualmente los pedidos.
  Future<void> refresh([String? restaurantId]) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getPedidosActivos(
      restaurantId ?? AppConstants.defaultRestaurantId,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (pedidos) {
        // Clasificar en columnas (excluyendo los entregados).
        // Para cocina rápida agrupamos creado + aceptado en la misma cola.
        final activos = pedidos
            .where((p) => p.estado != EstadoPedido.entregado)
            .toList();

        state = state.copyWith(
          isLoading: false,
          nuevos: activos
              .where(
                (p) =>
                    p.estado == EstadoPedido.creado ||
                    p.estado == EstadoPedido.aceptado,
              )
              .toList(),
          preparando: activos
              .where((p) => p.estado == EstadoPedido.enPreparacion)
              .toList(),
          listos: activos
              .where((p) => p.estado == EstadoPedido.finalizado)
              .toList(),
          lastRefresh: DateTime.now(),
        );
      },
    );
  }

  /// Avanza el estado de un pedido al siguiente paso.
  ///
  /// Flujo: creado → aceptado → enPreparacion → finalizado
  Future<void> avanzarEstadoPedido(Pedido pedido) async {
    final siguiente = _nextEstado(pedido.estado);
    if (siguiente == null) return;

    final result = await _updateEstadoPedido(
      UpdateEstadoPedidoParams(id: pedido.id, estado: siguiente.value),
    );

    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) => refresh(pedido.restaurantId),
    );
  }

  /// Alterna el estado de un item entre en preparación ↔ listo.
  ///
  /// Un toque lo marca listo; un segundo toque permite corregirlo.
  Future<void> toggleEstadoItem(
    String itemId,
    EstadoPedido estadoActual,
    String restaurantId,
  ) async {
    final nuevoEstado = estadoActual == EstadoPedido.finalizado
        ? EstadoPedido.enPreparacion
        : EstadoPedido.finalizado;

    final result = await _updateEstadoItem(
      UpdateEstadoItemParams(itemId: itemId, estado: nuevoEstado.value),
    );

    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) => refresh(restaurantId),
    );
  }

  /// Limpia el mensaje de error.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Retorna el siguiente estado lógico para la cocina rápida.
  ///
  /// Flujo simplificado: creado/aceptado → en preparación → finalizado.
  EstadoPedido? _nextEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendienteAprobacion:
      case EstadoPedido.creado:
      case EstadoPedido.aceptado:
        return EstadoPedido.enPreparacion;
      case EstadoPedido.enPreparacion:
        return EstadoPedido.finalizado;
      case EstadoPedido.finalizado:
      case EstadoPedido.entregado:
        return null;
    }
  }
}

/// Provider principal de la pantalla de Cocina.
final cocinaProvider = StateNotifierProvider<CocinaNotifier, CocinaState>((
  ref,
) {
  return CocinaNotifier(
    getPedidosActivos: sl<GetPedidosActivos>(),
    updateEstadoPedido: sl<UpdateEstadoPedido>(),
    updateEstadoItem: sl<UpdateEstadoItem>(),
  );
});
