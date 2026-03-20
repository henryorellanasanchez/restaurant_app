import 'package:flutter/material.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/pedidos/domain/entities/pedido_item.dart';

/// Tile de un item dentro del ticket de cocina.
///
/// Muestra: nombre del producto, cantidad, observaciones.
/// Permite marcar el item como listo con un toque.
class CocinaItemTile extends StatelessWidget {
  final PedidoItem item;
  final VoidCallback? onToggle;

  const CocinaItemTile({super.key, required this.item, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isListo = item.estado == EstadoPedido.finalizado;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isListo
              ? AppColors.success.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isListo
                ? AppColors.success.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // ── Ícono de estado ──────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isListo
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey(isListo),
                color: isListo ? AppColors.success : AppColors.textSecondary,
                size: 22,
              ),
            ),

            const SizedBox(width: 10),

            // ── Cantidad ─────────────────────────────────────
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${item.cantidad}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ── Nombre producto + observaciones ──────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productoNombre ?? 'Producto',
                    style: TextStyle(
                      color: isListo ? cs.onSurfaceVariant : cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration: isListo
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (item.varianteNombre != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.varianteNombre!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (item.observaciones != null &&
                      item.observaciones!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 12,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.observaciones!,
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
