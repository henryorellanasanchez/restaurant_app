import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/caja/domain/entities/venta.dart';

// ── Datos del establecimiento ─────────────────────────────────────────────
const _kNegocio = 'La Peña Bar & Restaurant';
const _kDireccion = 'Av. Principal #123, Col. Centro';
const _kTelefono = 'Tel: (55) 1234-5678';
const _kRedes = 'FB/IG: @LaPenaBar';

/// Diálogo que muestra el ticket/cuenta de una venta de forma profesional.
///
/// Diseñado para parecer un comprobante real de restaurante,
/// con encabezado del negocio, tabla de artículos, totales y
/// botón de impresión en formato térmico de 80 mm.
class TicketDialog extends StatelessWidget {
  final Venta venta;
  final String? mesaNombre;

  const TicketDialog({super.key, required this.venta, this.mesaNombre});

  static Future<void> show(
    BuildContext context, {
    required Venta venta,
    String? mesaNombre,
  }) {
    return showDialog(
      context: context,
      builder: (_) => TicketDialog(venta: venta, mesaNombre: mesaNombre),
    );
  }

  // ── Cálculos ────────────────────────────────────────────────────────────

  double get _descuento =>
      (venta.subtotal - venta.total).clamp(0.0, double.maxFinite);
  bool get _tieneDescuento => _descuento > 0.01;

  String get _folio =>
      '#${venta.id.replaceAll('-', '').toUpperCase().substring(0, 8)}';

  // ── Impresión PDF ────────────────────────────────────────────────────────

  Future<void> _imprimir(BuildContext context) async {
    final fmt = NumberFormat('#,##0.00', 'es_MX');
    final fecha = DateFormat('dd/MM/yyyy').format(venta.createdAt);
    final hora = DateFormat('HH:mm').format(venta.createdAt);

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        // Papel térmico de 80 mm, altura dinámica
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (ctx) {
          final normal = pw.TextStyle(fontSize: 9);
          final bold = pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          );
          final small = pw.TextStyle(fontSize: 7.5);
          final totalStyle = pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Encabezado negocio
              pw.Text(
                _kNegocio,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _kDireccion,
                style: small,
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(_kTelefono, style: small, textAlign: pw.TextAlign.center),
              pw.Text(_kRedes, style: small, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 6),
              pw.Divider(),
              pw.SizedBox(height: 4),

              // Folio + fecha
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Folio: $_folio', style: bold),
                  pw.Text('$fecha  $hora', style: normal),
                ],
              ),
              if (mesaNombre != null) ...[
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Mesa: $mesaNombre', style: normal),
                ),
              ],
              if (venta.cajeroNombre != null) ...[
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Atendió: ${venta.cajeroNombre}',
                    style: normal,
                  ),
                ),
              ],
              if (venta.clienteNombre != null ||
                  venta.clienteEmail != null) ...[
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Cliente: ${venta.clienteNombre ?? '-'}',
                    style: normal,
                  ),
                ),
                if (venta.clienteEmail != null &&
                    venta.clienteEmail!.isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(venta.clienteEmail!, style: small),
                  ),
              ],
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 4),

              // Tabla de artículos
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FixedColumnWidth(28),
                  2: const pw.FixedColumnWidth(54),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'ARTÍCULO',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'CNT',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'IMPORTE',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ],
                  ),
                  ...venta.detalles.map((d) {
                    final nombre = d.varianteNombre != null
                        ? '${d.productoNombre ?? '-'} (${d.varianteNombre})'
                        : (d.productoNombre ?? '—');
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                          child: pw.Text(nombre, style: small),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                          child: pw.Text(
                            '${d.cantidad}',
                            style: small,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                          child: pw.Text(
                            '\$${fmt.format(d.subtotal)}',
                            style: small,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 4),

              // Totales
              if (venta.subtotal != venta.total || venta.impuestos > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal', style: normal),
                    pw.Text('\$${fmt.format(venta.subtotal)}', style: normal),
                  ],
                ),
              if (_tieneDescuento) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Descuento', style: normal),
                    pw.Text('-\$${fmt.format(_descuento)}', style: normal),
                  ],
                ),
              ],
              if (venta.impuestos > 0) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('IVA', style: normal),
                    pw.Text('\$${fmt.format(venta.impuestos)}', style: normal),
                  ],
                ),
              ],
              pw.SizedBox(height: 2),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: totalStyle),
                  pw.Text('\$${fmt.format(venta.total)}', style: totalStyle),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 4),

              // Forma de pago
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Forma de pago: ${venta.metodoPago.label}',
                  style: bold,
                ),
              ),
              if (venta.descripcionPago != null &&
                  venta.descripcionPago!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(venta.descripcionPago!, style: small),
                ),
              ],

              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 6),

              // Pie
              pw.Center(
                child: pw.Text(
                  '¡Gracias por visitarnos!',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'Vuelva pronto  ·  $_kRedes',
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Este comprobante no es válido como factura fiscal.',
                  style: pw.TextStyle(fontSize: 6.5),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    if (!context.mounted) return;
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Ticket_$_folio',
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = NumberFormat('#,##0.00', 'es_MX');
    final fecha = DateFormat('dd/MM/yyyy').format(venta.createdAt);
    final hora = DateFormat('HH:mm').format(venta.createdAt);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 660),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Encabezado del negocio ─────────────────────────
            Container(
              width: double.infinity,
              color: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu, color: cs.onPrimary, size: 30),
                  const SizedBox(height: 6),
                  Text(
                    _kNegocio,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _kDireccion,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    _kTelefono,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    _kRedes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            // ── Cuerpo del ticket ──────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Folio + fecha/hora
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LabelSm('FOLIO', theme),
                              Text(
                                _folio,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _LabelSm('FECHA / HORA', theme),
                            Text(
                              '$fecha  $hora',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Mesa + cajero
                    if (mesaNombre != null || venta.cajeroNombre != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (mesaNombre != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LabelSm('MESA', theme),
                                  Text(
                                    mesaNombre!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (venta.cajeroNombre != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _LabelSm('ATENDIÓ', theme),
                                Text(
                                  venta.cajeroNombre!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],

                    if (venta.clienteNombre != null ||
                        venta.clienteEmail != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LabelSm('CLIENTE', theme),
                                Text(
                                  venta.clienteNombre ?? '—',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (venta.clienteEmail != null &&
                                    venta.clienteEmail!.isNotEmpty)
                                  Text(
                                    venta.clienteEmail!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    const _DashedDivider(),
                    const SizedBox(height: 10),

                    // Cabecera de la tabla de artículos
                    DefaultTextStyle.merge(
                      style: theme.textTheme.labelSmall!.copyWith(
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant,
                      ),
                      child: Row(
                        children: const [
                          Expanded(child: Text('ARTÍCULO')),
                          SizedBox(
                            width: 28,
                            child: Text('CNT', textAlign: TextAlign.center),
                          ),
                          SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: Text('IMPORTE', textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Artículos
                    ...venta.detalles.map((d) {
                      final nombre = d.varianteNombre != null
                          ? '${d.productoNombre ?? '-'} (${d.varianteNombre})'
                          : (d.productoNombre ?? '—');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                nombre,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${d.cantidad}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 72,
                              child: Text(
                                '\$${fmt.format(d.subtotal)}',
                                textAlign: TextAlign.right,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    const _DashedDivider(),
                    const SizedBox(height: 8),

                    // Subtotal / descuento / impuestos
                    if (venta.subtotal != venta.total ||
                        venta.impuestos > 0) ...[
                      _TotalsRow(
                        label: 'Subtotal',
                        valueStr: '\$${fmt.format(venta.subtotal)}',
                        theme: theme,
                      ),
                    ],
                    if (_tieneDescuento)
                      _TotalsRow(
                        label: 'Descuento',
                        valueStr: '-\$${fmt.format(_descuento)}',
                        theme: theme,
                        valueColor: Colors.green.shade700,
                      ),
                    if (venta.impuestos > 0)
                      _TotalsRow(
                        label: 'IVA (incluido)',
                        valueStr: '\$${fmt.format(venta.impuestos)}',
                        theme: theme,
                      ),

                    const SizedBox(height: 6),

                    // TOTAL destacado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '\$${fmt.format(venta.total)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    const _DashedDivider(),
                    const SizedBox(height: 8),

                    // Forma de pago
                    Row(
                      children: [
                        Icon(
                          _iconMetodo(venta.metodoPago),
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Forma de pago: ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          venta.metodoPago.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (venta.descripcionPago != null &&
                        venta.descripcionPago!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        venta.descripcionPago!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    const _DashedDivider(),
                    const SizedBox(height: 10),

                    // Pie de ticket
                    Center(
                      child: Text(
                        '¡Gracias por visitarnos!',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        'Vuelva pronto  ·  $_kRedes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Este comprobante no es válido como factura fiscal.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── Botones de acción ──────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _imprimir(context),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Imprimir'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconMetodo(MetodoPago m) => switch (m) {
    MetodoPago.efectivo => Icons.payments_outlined,
    MetodoPago.tarjeta => Icons.credit_card_outlined,
    MetodoPago.transferencia => Icons.account_balance_outlined,
  };
}

// ── Widgets auxiliares ───────────────────────────────────────────────────────

/// Etiqueta pequeña de sección en estilo ALL-CAPS.
class _LabelSm extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _LabelSm(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Divisor con línea punteada estilo ticket térmico.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashW = 5.0;
        const gapW = 4.0;
        final count = (constraints.maxWidth / (dashW + gapW)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: 1,
              margin: const EdgeInsets.only(right: gapW),
              color: color,
            ),
          ),
        );
      },
    );
  }
}

/// Fila de totales (subtotal, descuento, IVA).
class _TotalsRow extends StatelessWidget {
  final String label;
  final String valueStr;
  final ThemeData theme;
  final Color? valueColor;

  const _TotalsRow({
    required this.label,
    required this.valueStr,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            valueStr,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
