import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/reportes/domain/entities/reporte_metodo_pago.dart';
import 'package:restaurant_app/features/reportes/domain/entities/reporte_producto_vendido.dart';
import 'package:restaurant_app/features/reportes/domain/entities/reporte_resumen.dart';
import 'package:restaurant_app/features/reportes/domain/entities/reporte_venta_dia.dart';
import 'package:restaurant_app/features/reportes/presentation/providers/reportes_provider.dart';

/// Página principal de Reportes y Analítica.
///
/// Muestra KPIs, gráfica de ventas por día (BarChart),
/// top productos, métodos de pago (PieChart) y ranking de meseros.
class ReportesPage extends ConsumerStatefulWidget {
  const ReportesPage({super.key});

  @override
  ConsumerState<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends ConsumerState<ReportesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportesProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: Column(
        children: [
          _Header(
            filtro: state.filtro,
            isLoading: state.isLoading,
            onFiltroChanged: (f) =>
                ref.read(reportesProvider.notifier).cambiarFiltro(f),
            onRefresh: () =>
                ref.read(reportesProvider.notifier).cargarReportes(),
          ),
          ColoredBox(
            color: colors.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_rounded), text: 'Resumen'),
                Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Ventas'),
                Tab(
                  icon: Icon(Icons.restaurant_menu_rounded),
                  text: 'Productos',
                ),
                Tab(icon: Icon(Icons.credit_card_rounded), text: 'Métodos'),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? _ErrorView(
                    error: state.error!,
                    onRetry: () =>
                        ref.read(reportesProvider.notifier).cargarReportes(),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _TabResumen(resumen: state.resumen, moneda: _moneda),
                      _TabVentas(
                        ventasPorDia: state.ventasPorDia,
                        moneda: _moneda,
                      ),
                      _TabProductos(
                        productos: state.topProductos,
                        moneda: _moneda,
                      ),
                      _TabMetodos(
                        metodos: state.ventasPorMetodo,
                        meseros: state.ventasPorMesero,
                        moneda: _moneda,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.filtro,
    required this.isLoading,
    required this.onFiltroChanged,
    required this.onRefresh,
  });

  final FiltroFecha filtro;
  final bool isLoading;
  final ValueChanged<FiltroFecha> onFiltroChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Icon(Icons.analytics_rounded, size: 24),
          const SizedBox(width: 10),
          Text(
            'Reportes',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ...FiltroFecha.values.map(
            (f) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChoiceChip(
                label: Text(f.label),
                selected: filtro == f,
                onSelected: (_) => onFiltroChanged(f),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: isLoading ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

// ── Error View ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ── Tab Resumen ────────────────────────────────────────────────────────────────

class _TabResumen extends StatelessWidget {
  const _TabResumen({required this.resumen, required this.moneda});

  final ResumenVentas? resumen;
  final NumberFormat moneda;

  @override
  Widget build(BuildContext context) {
    if (resumen == null || !resumen!.tieneVentas) {
      return const _EmptyState(
        mensaje: 'Sin ventas en el período seleccionado',
      );
    }

    final r = resumen!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final maxExtent = width < 520
                ? 260.0
                : width < 900
                ? 300.0
                : 360.0;
            final aspect = width < 520 ? 1.7 : 2.2;
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxExtent,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspect,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (_, i) {
                final cards = [
                  _KpiCard(
                    title: 'Total ventas',
                    value: moneda.format(r.totalVentas),
                    icon: Icons.attach_money_rounded,
                    color: Colors.green,
                  ),
                  _KpiCard(
                    title: 'Transacciones',
                    value: r.cantidadVentas.toString(),
                    icon: Icons.receipt_long_rounded,
                    color: Colors.blue,
                  ),
                  _KpiCard(
                    title: 'Ticket promedio',
                    value: moneda.format(r.promedioTicket),
                    icon: Icons.trending_up_rounded,
                    color: Colors.orange,
                  ),
                  _KpiCard(
                    title: 'Ticket máximo',
                    value: moneda.format(r.ticketMaximo),
                    icon: Icons.star_rounded,
                    color: Colors.purple,
                  ),
                ];
                return cards[i];
              },
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.trending_down_rounded,
              color: Colors.teal,
            ),
            title: const Text('Ticket mínimo'),
            trailing: Text(
              moneda.format(r.ticketMinimo),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab Ventas ─────────────────────────────────────────────────────────────────

class _TabVentas extends StatelessWidget {
  const _TabVentas({required this.ventasPorDia, required this.moneda});

  final List<VentaPorDia> ventasPorDia;
  final NumberFormat moneda;

  @override
  Widget build(BuildContext context) {
    if (ventasPorDia.isEmpty) {
      return const _EmptyState(
        mensaje: 'Sin ventas en el período seleccionado',
      );
    }

    final maxVal = ventasPorDia
        .map((v) => v.total)
        .reduce((a, b) => a > b ? a : b);
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Ventas por día',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxVal * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: colors.outlineVariant, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            '\$${_compactVal(value)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= ventasPorDia.length) {
                            return const SizedBox.shrink();
                          }
                          final parts = ventasPorDia[idx].fecha.split('-');
                          final label = parts.length == 3
                              ? '${parts[2]}/${parts[1]}'
                              : ventasPorDia[idx].fecha;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(ventasPorDia.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: ventasPorDia[i].total,
                          color: colors.primary,
                          width: ventasPorDia.length > 20 ? 6 : 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final v = ventasPorDia[group.x];
                        return BarTooltipItem(
                          '${v.fecha}\n${moneda.format(rod.toY)}\n'
                          '${v.cantidadVentas} venta(s)',
                          const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Detalle diario', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...ventasPorDia.reversed.map(
          (v) => ListTile(
            dense: true,
            leading: const Icon(Icons.calendar_today_rounded, size: 18),
            title: Text(v.fecha),
            subtitle: Text('${v.cantidadVentas} venta(s)'),
            trailing: Text(
              moneda.format(v.total),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _compactVal(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}

// ── Tab Productos ──────────────────────────────────────────────────────────────

class _TabProductos extends StatelessWidget {
  const _TabProductos({required this.productos, required this.moneda});

  final List<ProductoVendido> productos;
  final NumberFormat moneda;

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return const _EmptyState(mensaje: 'Sin productos vendidos en el período');
    }

    final maxCantidad = productos.first.cantidadVendida.toDouble();
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Top ${productos.length} productos más vendidos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(productos.length, (i) {
          final p = productos[i];
          final pct = maxCantidad > 0 ? p.cantidadVendida / maxCantidad : 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: colors.primaryContainer,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (p.categoriaNombre != null)
                              Text(
                                p.categoriaNombre!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.outline,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${p.cantidadVendida} uds.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            moneda.format(p.totalIngresado),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: pct,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: colors.surfaceContainerHigh,
                    color: i == 0
                        ? colors.primary
                        : i == 1
                        ? colors.secondary
                        : colors.tertiary,
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Tab Métodos ────────────────────────────────────────────────────────────────

class _TabMetodos extends StatefulWidget {
  const _TabMetodos({
    required this.metodos,
    required this.meseros,
    required this.moneda,
  });

  final List<VentaPorMetodo> metodos;
  final List<dynamic> meseros;
  final NumberFormat moneda;

  @override
  State<_TabMetodos> createState() => _TabMetodosState();
}

class _TabMetodosState extends State<_TabMetodos> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.metodos.isEmpty) {
      return const _EmptyState(
        mensaje: 'Sin ventas en el período seleccionado',
      );
    }

    final colors = Theme.of(context).colorScheme;
    final metodoColors = [
      colors.primary,
      colors.secondary,
      colors.tertiary,
      colors.error,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Ventas por método de pago',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  height: 180,
                  width: 180,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(widget.metodos.length, (i) {
                        final m = widget.metodos[i];
                        final isTouched = _touchedIndex == i;
                        return PieChartSectionData(
                          value: m.total,
                          color: metodoColors[i % metodoColors.length],
                          radius: isTouched ? 70 : 60,
                          title: '${m.porcentaje.toStringAsFixed(1)}%',
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(widget.metodos.length, (i) {
                      final m = widget.metodos[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: metodoColors[i % metodoColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _labelMetodo(m.metodoPago),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${m.cantidad} tx  •  '
                                    '${widget.moneda.format(m.total)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.meseros.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Ranking por mesero',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...widget.meseros.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: i == 0
                    ? Colors.amber
                    : i == 1
                    ? Colors.grey.shade400
                    : colors.surfaceContainerHigh,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: i < 2 ? Colors.white : colors.onSurface,
                  ),
                ),
              ),
              title: Text(m.nombre as String),
              subtitle: Text('${m.cantidadPedidos} pedido(s)'),
              trailing: Text(
                widget.moneda.format(m.total as double),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  String _labelMetodo(MetodoPago m) {
    switch (m) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.tarjeta:
        return 'Tarjeta';
      case MetodoPago.transferencia:
        return 'Transferencia';
    }
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 11, color: colors.outline),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
