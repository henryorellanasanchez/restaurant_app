import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/cocina/presentation/providers/cocina_provider.dart';
import 'package:restaurant_app/features/cocina/presentation/widgets/cocina_ticket_card.dart';
import 'package:restaurant_app/features/pedidos/domain/entities/pedido.dart';

/// Pantalla de Cocina — Fase 4.
///
/// Diseño oscuro optimizado para tablets y pantallas de cocina.
/// Muestra los pedidos agrupados en tres columnas:
/// - NUEVOS    (estado: creado)
/// - PREPARANDO (estado: aceptado / enPreparacion)
/// - LISTOS    (estado: finalizado)
///
/// Auto-refresh cada 30 segundos. Permite cambiar estados
/// del pedido completo o de items individuales con un toque.
class CocinaPage extends ConsumerStatefulWidget {
  const CocinaPage({super.key});

  @override
  ConsumerState<CocinaPage> createState() => _CocinaPageState();
}

class _CocinaPageState extends ConsumerState<CocinaPage> {
  late CocinaNotifier _notifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier = ref.read(cocinaProvider.notifier);
      _notifier.start();
    });
  }

  @override
  void dispose() {
    _notifier.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cocinaProvider);

    return Scaffold(appBar: _buildAppBar(state), body: _buildBody(state));
  }

  // ── AppBar ────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(CocinaState state) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      elevation: 0,
      title: Row(
        children: [
          Icon(Icons.soup_kitchen_rounded, color: cs.onPrimary, size: 24),
          const SizedBox(width: 10),
          const Text(
            'PANTALLA DE COCINA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          // Contador total
          if (!state.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${state.totalPedidos} pedidos activos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      actions: [
        // Última actualización
        if (state.lastRefresh != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                'Actualizado: ${_formatTime(state.lastRefresh!)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        // Botón actualizar manual
        IconButton(
          icon: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Actualizar',
          onPressed: state.isLoading
              ? null
              : () => ref.read(cocinaProvider.notifier).refresh(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────

  Widget _buildBody(CocinaState state) {
    if (state.errorMessage != null) {
      return _buildError(state.errorMessage!);
    }

    if (state.isLoading && state.totalPedidos == 0) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.totalPedidos == 0) {
      return _buildEmpty();
    }

    // ── Layout 3 columnas ────────────────────────────────────────
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna 1: Nuevos
        Expanded(
          child: _buildColumna(
            titulo: 'NUEVOS',
            icono: Icons.fiber_new_rounded,
            color: AppColors.pedidoCreado,
            pedidos: state.nuevos,
            emptyMsg: 'No hay pedidos nuevos',
          ),
        ),
        _buildDivider(),

        // Columna 2: Preparando
        Expanded(
          child: _buildColumna(
            titulo: 'PREPARANDO',
            icono: Icons.restaurant_rounded,
            color: AppColors.pedidoEnPreparacion,
            pedidos: state.preparando,
            emptyMsg: 'No hay pedidos en preparación',
          ),
        ),
        _buildDivider(),

        // Columna 3: Listos
        Expanded(
          child: _buildColumna(
            titulo: 'LISTOS',
            icono: Icons.done_all_rounded,
            color: AppColors.pedidoFinalizado,
            pedidos: state.listos,
            emptyMsg: 'No hay pedidos listos',
          ),
        ),
      ],
    );
  }

  Widget _buildColumna({
    required String titulo,
    required IconData icono,
    required Color color,
    required List<Pedido> pedidos,
    required String emptyMsg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header de columna ──────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: color.withValues(alpha: 0.12),
          child: Row(
            children: [
              Icon(icono, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (pedidos.isNotEmpty)
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${pedidos.length}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Lista de tickets ───────────────────────────────────
        Expanded(
          child: pedidos.isEmpty
              ? _buildEmptyColumna(emptyMsg, color)
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CocinaTicketCard(
                        pedido: pedido,
                        onAvanzar: () => ref
                            .read(cocinaProvider.notifier)
                            .avanzarEstadoPedido(pedido),
                        onToggleItem: (itemId, estadoActual) => ref
                            .read(cocinaProvider.notifier)
                            .toggleEstadoItem(
                              itemId,
                              estadoActual,
                              pedido.restaurantId,
                            ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  Widget _buildEmptyColumna(String mensaje, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 48,
            color: color.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.soup_kitchen_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'La cocina está tranquila',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay pedidos activos en este momento',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(cocinaProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
