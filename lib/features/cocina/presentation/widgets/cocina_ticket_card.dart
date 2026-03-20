import 'package:flutter/material.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/cocina/presentation/widgets/cocina_item_tile.dart';
import 'package:restaurant_app/features/pedidos/domain/entities/pedido.dart';

/// Ticket visual de un pedido para la pantalla de cocina.
///
/// Diseñado para pantallas grandes/tablets en modo oscuro.
/// Muestra: mesa, tiempo, estado, lista de items con toggle.
/// Botón principal para avanzar el estado del pedido.
class CocinaTicketCard extends StatelessWidget {
  final Pedido pedido;

  /// Callback para avanzar el estado del pedido completo.
  final VoidCallback? onAvanzar;

  /// Callback para alternar el estado de un item (id, estadoActual).
  final void Function(String itemId, EstadoPedido estadoActual)? onToggleItem;

  const CocinaTicketCard({
    super.key,
    required this.pedido,
    this.onAvanzar,
    this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colorEstado = _colorByEstado(pedido.estado);
    final elapsed = pedido.tiempoTranscurrido;
    final isUrgente = elapsed.inMinutes >= 20;

    return Card(
      color: cs.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUrgente
              ? AppColors.error.withValues(alpha: 0.8)
              : cs.outlineVariant,
          width: isUrgente ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────
          _buildHeader(theme, cs, colorEstado, elapsed, isUrgente),

          // ── Items ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: pedido.items
                  .map(
                    (item) => CocinaItemTile(
                      item: item,
                      onToggle: onToggleItem != null
                          ? () => onToggleItem!(item.id, item.estado)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),

          // ── Observaciones del pedido ─────────────────────────
          if (pedido.observaciones != null && pedido.observaciones!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.comment_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pedido.observaciones!,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Botón de acción ──────────────────────────────────
          if (onAvanzar != null && pedido.estado != EstadoPedido.finalizado)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ElevatedButton.icon(
                onPressed: onAvanzar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorEstado,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(_iconNextEstado(pedido.estado), size: 20),
                label: Text(
                  _labelNextEstado(pedido.estado),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

          if (pedido.estado == EstadoPedido.finalizado)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'LISTO PARA ENTREGAR',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme cs,
    Color colorEstado,
    Duration elapsed,
    bool isUrgente,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorEstado.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Mesa nombre
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.table_restaurant_rounded,
                  size: 18,
                  color: cs.onSurface,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    pedido.mesaNombre ?? 'Sin mesa',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Cantidad de items
          Text(
            '${pedido.cantidadItems} item${pedido.cantidadItems != 1 ? "s" : ""}',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),

          const SizedBox(width: 10),

          // Tiempo transcurrido (pulsante si urgente)
          _TimerBadge(
            elapsed: elapsed,
            isUrgente: isUrgente,
            onSurfaceVariant: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Color _colorByEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.creado:
        return AppColors.pedidoCreado;
      case EstadoPedido.aceptado:
        return AppColors.pedidoAceptado;
      case EstadoPedido.enPreparacion:
        return AppColors.pedidoEnPreparacion;
      case EstadoPedido.finalizado:
        return AppColors.pedidoFinalizado;
      case EstadoPedido.entregado:
        return AppColors.pedidoEntregado;
    }
  }

  String _labelNextEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.creado:
        return 'ACEPTAR PEDIDO';
      case EstadoPedido.aceptado:
        return 'INICIAR PREPARACIÓN';
      case EstadoPedido.enPreparacion:
        return 'MARCAR COMO LISTO';
      default:
        return '';
    }
  }

  IconData _iconNextEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.creado:
        return Icons.check_circle_outline_rounded;
      case EstadoPedido.aceptado:
        return Icons.restaurant_rounded;
      case EstadoPedido.enPreparacion:
        return Icons.done_all_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }
}

/// Badge con el tiempo transcurrido.
/// Parpadea en rojo cuando supera los 20 minutos.
class _TimerBadge extends StatelessWidget {
  final Duration elapsed;
  final bool isUrgente;
  final Color onSurfaceVariant;

  const _TimerBadge({
    required this.elapsed,
    required this.isUrgente,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    final mins = elapsed.inMinutes;
    final horas = elapsed.inHours;
    final texto = horas > 0 ? '${horas}h ${mins.remainder(60)}m' : '${mins}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isUrgente
            ? AppColors.error.withValues(alpha: 0.2)
            : onSurfaceVariant.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgente
              ? AppColors.error.withValues(alpha: 0.6)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgente ? Icons.warning_amber_rounded : Icons.access_time_rounded,
            size: 14,
            color: isUrgente ? AppColors.error : onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              color: isUrgente ? AppColors.error : onSurfaceVariant,
              fontSize: 13,
              fontWeight: isUrgente ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
