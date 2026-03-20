import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/caja/presentation/providers/caja_provider.dart';
import 'package:restaurant_app/features/caja/presentation/widgets/cobro_dialog.dart';
import 'package:restaurant_app/features/caja/presentation/widgets/ticket_dialog.dart';
import 'package:restaurant_app/features/caja/presentation/widgets/venta_card.dart';
import 'package:restaurant_app/features/pedidos/domain/entities/pedido.dart';

/// Página principal del módulo de Caja.
///
/// Dos pestañas:
/// - Cobrar: pedidos finalizados listos para pagar
/// - Historial: ventas del día / todas las ventas
class CajaPage extends ConsumerStatefulWidget {
  const CajaPage({super.key});

  @override
  ConsumerState<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends ConsumerState<CajaPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _verTodas = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cajaProvider.notifier).loadCaja();
      ref.read(cajaProvider.notifier).loadHistorial();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Cobro ──────────────────────────────────────────────────────

  Future<void> _cobrarPedido(Pedido pedido) async {
    final venta = await CobroDialog.show(context, pedido: pedido);
    if (venta == null || !mounted) return;

    // Mostrar ticket inmediatamente tras el cobro
    await TicketDialog.show(
      context,
      venta: venta,
      mesaNombre: pedido.mesaNombre,
    );

    // Limpiar referencia
    if (mounted) {
      ref.read(cajaProvider.notifier).clearUltimaVenta();
    }
  }

  void _verTicket(BuildContext context, String ventaId) async {
    final state = ref.read(cajaProvider);
    final todas = [...state.ventasHoy, ...state.todasLasVentas];
    final venta = todas.where((v) => v.id == ventaId).firstOrNull;
    if (venta == null || !mounted) return;
    await TicketDialog.show(context, venta: venta);
  }

  void _showError(String? msg) {
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cajaProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (state.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showError(state.errorMessage),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // ── Header con resumen ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            color: cs.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caja',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Tarjetas de resumen
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final perRow = width < 700 ? 2 : 3;
                    const spacing = 8.0;
                    final cardWidth = (width - (perRow - 1) * spacing) / perRow;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _ResumenCard(
                            icon: Icons.pending_actions_outlined,
                            label: 'Por cobrar',
                            value: '${state.totalPedidosPendientes}',
                            color: cs.tertiary,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _ResumenCard(
                            icon: Icons.receipt_outlined,
                            label: 'Ventas hoy',
                            value: '${state.cantidadVentasHoy}',
                            color: cs.primary,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _ResumenCard(
                            icon: Icons.attach_money,
                            label: 'Total hoy',
                            value:
                                '\$${state.totalVentasHoy.toStringAsFixed(2)}',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                // Desglose por método
                if (state.ventasPorMetodo.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: state.ventasPorMetodo.entries
                        .map(
                          (e) => Chip(
                            avatar: Icon(_iconForMetodo(e.key), size: 14),
                            label: Text(
                              '${e.key.label}: \$${e.value.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),

          // ── TabBar ─────────────────────────────────────────
          ColoredBox(
            color: cs.surface,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.point_of_sale_outlined, size: 16),
                      const SizedBox(width: 6),
                      const Text('Por cobrar'),
                      if (state.totalPedidosPendientes > 0) ...[
                        const SizedBox(width: 6),
                        Badge(label: Text('${state.totalPedidosPendientes}')),
                      ],
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 16),
                      SizedBox(width: 6),
                      Text('Historial'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Contenido ──────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [_buildPorCobrar(state), _buildHistorial(state)],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Tab: Por cobrar ───────────────────────────────────────────

  Widget _buildPorCobrar(CajaState state) {
    if (state.pedidosParaCobrar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay pedidos pendientes de cobro',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los pedidos "Finalizados" aparecerán aquí',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.pedidosParaCobrar.length,
      itemBuilder: (_, i) {
        final pedido = state.pedidosParaCobrar[i];
        return _PedidoCobrarCard(
          pedido: pedido,
          onCobrar: () => _cobrarPedido(pedido),
          isProcessing: state.isProcessing,
        );
      },
    );
  }

  // ── Tab: Historial ────────────────────────────────────────────

  Widget _buildHistorial(CajaState state) {
    final ventas = _verTodas ? state.todasLasVentas : state.ventasHoy;

    return Column(
      children: [
        // Toggle hoy / todas
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Mostrar:'),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Hoy'),
                selected: !_verTodas,
                onSelected: (_) => setState(() => _verTodas = false),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Todas'),
                selected: _verTodas,
                onSelected: (_) => setState(() => _verTodas = true),
              ),
            ],
          ),
        ),
        if (ventas.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _verTodas
                        ? 'No hay ventas registradas'
                        : 'No hay ventas hoy',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: ventas.length,
              itemBuilder: (_, i) {
                final v = ventas[i];
                return VentaCard(
                  venta: v,
                  onTap: () => _verTicket(context, v.id),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _iconForMetodo(MetodoPago m) {
    return switch (m) {
      MetodoPago.efectivo => Icons.payments_outlined,
      MetodoPago.tarjeta => Icons.credit_card_outlined,
      MetodoPago.transferencia => Icons.account_balance_outlined,
    };
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResumenCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PedidoCobrarCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onCobrar;
  final bool isProcessing;

  const _PedidoCobrarCard({
    required this.pedido,
    required this.onCobrar,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final minutos = pedido.tiempoTranscurrido.inMinutes;
    final urgente = minutos > 45;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Mesa / número
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: urgente
                    ? Colors.orange.withValues(alpha: 0.15)
                    : cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_restaurant_outlined,
                    color: urgente ? Colors.orange : cs.primary,
                    size: 18,
                  ),
                  Text(
                    pedido.mesaNombre ?? 'S/N',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: urgente ? Colors.orange : cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Info del pedido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${pedido.cantidadItems} items',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (urgente)
                        const Chip(
                          label: Text(
                            'Espera larga',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$minutos min transcurridos',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: urgente ? Colors.orange : cs.onSurfaceVariant,
                    ),
                  ),
                  if (pedido.items.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      pedido.items
                          .take(2)
                          .map((i) => i.productoNombre ?? '—')
                          .join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Total + botón cobrar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${pedido.totalCalculado.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: isProcessing ? null : onCobrar,
                  icon: const Icon(Icons.point_of_sale, size: 16),
                  label: const Text('Cobrar'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
