import 'package:flutter/material.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/mesas/domain/entities/mesa.dart';

/// Card visual de una mesa en el grid.
///
/// Muestra el número, capacidad y estado con color diferenciado.
/// Soporta tap y long press para interacción.
class MesaCard extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MesaCard({super.key, required this.mesa, this.onTap, this.onLongPress});

  Color _getColorByEstado(EstadoMesa estado) {
    switch (estado) {
      case EstadoMesa.libre:
        return AppColors.mesaLibre;
      case EstadoMesa.ocupada:
        return AppColors.mesaOcupada;
      case EstadoMesa.reservada:
        return AppColors.mesaReservada;
    }
  }

  IconData _getIconByEstado(EstadoMesa estado) {
    switch (estado) {
      case EstadoMesa.libre:
        return Icons.check_circle_outline_rounded;
      case EstadoMesa.ocupada:
        return Icons.people_rounded;
      case EstadoMesa.reservada:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorByEstado(mesa.estado);

    return Card(
      elevation: mesa.estado == EstadoMesa.ocupada ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icono de estado ────────────────────────────────
              Icon(_getIconByEstado(mesa.estado), color: color, size: 36),
              const SizedBox(height: 8),

              // ── Número / Nombre de mesa ────────────────────────
              Text(
                mesa.displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // ── Capacidad ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${mesa.capacidad}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Badge de estado ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mesa.estado.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // ── Nombre de reserva ──────────────────────────────
              if (mesa.estado == EstadoMesa.reservada &&
                  mesa.nombreReserva != null &&
                  mesa.nombreReserva!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mesaReservada.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.mesaReservada.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 11,
                        color: AppColors.mesaReservada,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          mesa.nombreReserva!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mesaReservada,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Indicador de unión ─────────────────────────────
              if (mesa.estaUnida) ...[
                const SizedBox(height: 4),
                Icon(Icons.link_rounded, size: 16, color: Colors.grey),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
