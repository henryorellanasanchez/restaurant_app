import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/config/routes/app_router.dart';
import 'package:restaurant_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:restaurant_app/features/mesas/presentation/providers/mesas_provider.dart';
import 'package:restaurant_app/features/pedidos/presentation/providers/pedidos_provider.dart';
import 'package:restaurant_app/features/reportes/domain/usecases/reportes_usecases.dart';
import 'package:restaurant_app/features/cotizaciones/domain/usecases/cotizacion_usecases.dart';

/// Provider que obtiene el total de ventas de hoy.
final _ventasHoyProvider = FutureProvider.autoDispose<double>((ref) async {
  final now = DateTime.now();
  final inicio = DateTime(now.year, now.month, now.day);
  final fin = DateTime(now.year, now.month, now.day, 23, 59, 59);

  final result = await sl<GetResumenVentas>()(
    FiltroReporteParams(
      restaurantId: AppConstants.defaultRestaurantId,
      fechaInicio: inicio,
      fechaFin: fin,
    ),
  );
  return result.fold((_) => 0.0, (resumen) => resumen.totalVentas);
});

final _cotizacionesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final result = await sl<GetCotizaciones>()(AppConstants.defaultRestaurantId);
  return result.fold((_) => 0, (items) => items.length);
});

/// Página de inicio / Dashboard principal.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Cargar datos al entrar al dashboard
    Future.microtask(() {
      ref.read(mesasProvider.notifier).loadMesas();
      ref.read(pedidosProvider.notifier).loadPedidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mesasState = ref.watch(mesasProvider);
    final pedidosState = ref.watch(pedidosProvider);
    final rol = sl<AuthChangeNotifier>().usuario?.rol;
    final puedeVerFinanzas = rol != RolUsuario.mesero;
    final puedeVerCotizaciones = rol == RolUsuario.administrador;
    final ventasHoyAsync = puedeVerFinanzas
        ? ref.watch(_ventasHoyProvider)
        : const AsyncValue<double>.data(0);
    final cotizacionesAsync = puedeVerCotizaciones
        ? ref.watch(_cotizacionesCountProvider)
        : const AsyncValue<int>.data(0);

    final totalVentasHoy = ventasHoyAsync.maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );
    final cotizacionesCount = cotizacionesAsync.maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );

    final currencyFormat = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.read(mesasProvider.notifier).loadMesas();
              ref.read(pedidosProvider.notifier).loadPedidos();
              if (puedeVerFinanzas) ref.invalidate(_ventasHoyProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            Text(
              'Resumen de hoy',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxis = _getCrossAxisCount(context);
                final totalSpacing = 16 * (crossAxis - 1);
                final cardWidth =
                    (constraints.maxWidth - totalSpacing) / crossAxis;
                final aspect = cardWidth < 240 ? 1.35 : 1.7;
                return GridView.count(
                  crossAxisCount: crossAxis,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspect,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _DashboardCard(
                      icon: Icons.table_restaurant_rounded,
                      title: 'Mesas',
                      value: mesasState.isLoading
                          ? '...'
                          : '${mesasState.totalLibres}/${mesasState.totalMesas}',
                      subtitle: 'Disponibles / Total',
                      color: AppColors.mesaLibre,
                    ),
                    _DashboardCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Pedidos Activos',
                      value: pedidosState.isLoading
                          ? '...'
                          : '${pedidosState.totalActivos}',
                      subtitle: 'En proceso',
                      color: AppColors.pedidoEnPreparacion,
                    ),
                    _DashboardCard(
                      icon: Icons.table_restaurant_rounded,
                      title: 'Mesas Ocupadas',
                      value: mesasState.isLoading
                          ? '...'
                          : '${mesasState.totalOcupadas}',
                      subtitle: 'Con clientes',
                      color: AppColors.mesaOcupada,
                    ),
                    if (puedeVerFinanzas)
                      _DashboardCard(
                        icon: Icons.point_of_sale_rounded,
                        title: 'Ventas del Día',
                        value: totalVentasHoy == null
                            ? '...'
                            : currencyFormat.format(totalVentasHoy),
                        subtitle: 'Total hoy',
                        color: AppColors.primary,
                      ),
                    if (puedeVerCotizaciones)
                      _DashboardCard(
                        icon: Icons.request_quote_rounded,
                        title: 'Cotizaciones',
                        value: cotizacionesCount == null
                            ? '...'
                            : '$cotizacionesCount',
                        subtitle: 'Solicitudes',
                        color: AppColors.secondary,
                        onTap: () => context.go(AppRouter.cotizaciones),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final fecha = DateFormat('dd/MM/yyyy').format(now);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'La Peña Bar & Restaurant',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bienvenido al sistema',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.textHint),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  fecha,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    return 2;
  }
}

/// Card genérica del dashboard.
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
