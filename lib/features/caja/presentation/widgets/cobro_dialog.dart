import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/caja/domain/entities/venta.dart';
import 'package:restaurant_app/features/caja/presentation/providers/caja_provider.dart';
import 'package:restaurant_app/features/pedidos/domain/entities/pedido.dart';

/// Diálogo de cobro de un pedido.
///
/// Muestra el resumen de items, permite seleccionar método de pago,
/// aplicar descuento y confirmar el cobro.
class CobroDialog extends ConsumerStatefulWidget {
  final Pedido pedido;

  const CobroDialog({super.key, required this.pedido});

  /// Muestra el diálogo y retorna la [Venta] creada o null si se canceló.
  static Future<Venta?> show(BuildContext context, {required Pedido pedido}) {
    return showDialog<Venta>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CobroDialog(pedido: pedido),
    );
  }

  @override
  ConsumerState<CobroDialog> createState() => _CobroDialogState();
}

class _CobroDialogState extends ConsumerState<CobroDialog> {
  MetodoPago _metodoPago = MetodoPago.efectivo;
  final _descuentoCtrl = TextEditingController(text: '0');
  final _descripcionCtrl = TextEditingController();
  final _efectivoCtrl = TextEditingController();
  final _clienteNombreCtrl = TextEditingController();
  final _clienteEmailCtrl = TextEditingController();
  bool _procesando = false;

  double get _subtotal => widget.pedido.totalCalculado;
  double get _descuento => double.tryParse(_descuentoCtrl.text) ?? 0;
  double get _total => (_subtotal - _descuento).clamp(0.0, _subtotal);
  double get _cambio {
    final efectivo = double.tryParse(_efectivoCtrl.text) ?? 0;
    return (efectivo - _total).clamp(0.0, double.maxFinite);
  }

  @override
  void dispose() {
    _descuentoCtrl.dispose();
    _descripcionCtrl.dispose();
    _efectivoCtrl.dispose();
    _clienteNombreCtrl.dispose();
    _clienteEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final email = _clienteEmailCtrl.text.trim();
    if (email.isNotEmpty && !_isEmailValid(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo electrónico inválido')),
      );
      return;
    }
    setState(() => _procesando = true);
    final venta = await ref
        .read(cajaProvider.notifier)
        .cobrarPedido(
          pedido: widget.pedido,
          metodoPago: _metodoPago,
          descuento: _descuento,
          descripcion: _descripcionCtrl.text.trim().isEmpty
              ? null
              : _descripcionCtrl.text.trim(),
          clienteNombre: _clienteNombreCtrl.text.trim().isEmpty
              ? null
              : _clienteNombreCtrl.text.trim(),
          clienteEmail: email.isEmpty ? null : email,
        );
    if (!mounted) return;
    setState(() => _procesando = false);
    Navigator.of(context).pop(venta);
  }

  bool _isEmailValid(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.point_of_sale_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cobrar Pedido${widget.pedido.mesaNombre != null ? ' · ${widget.pedido.mesaNombre}' : ''}',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Resumen de items ──────────────────────────────
              Text(
                'Detalle del pedido',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ...widget.pedido.items.map((item) {
                      final nombre = item.varianteNombre != null
                          ? '${item.productoNombre ?? 'Producto'} (${item.varianteNombre})'
                          : (item.productoNombre ?? 'Producto');
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${item.cantidad}×',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nombre,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              '\$${item.subtotal.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Divider(height: 1, color: cs.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Spacer(),
                          Text('Subtotal: ', style: theme.textTheme.bodyMedium),
                          Text(
                            '\$${_subtotal.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Descuento ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _descuentoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Descuento',
                        prefixText: '\$ ',
                        hintText: '0.00',
                        isDense: true,
                        prefixIcon: Icon(Icons.discount_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Total final
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TOTAL A COBRAR',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Cliente (opcional) ──────────────────────────
              Text(
                'Cliente (opcional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clienteNombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del cliente',
                        isDense: true,
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _clienteEmailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        isDense: true,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Método de pago ────────────────────────────────
              Text(
                'Método de pago',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: MetodoPago.values.map((m) {
                  final selected = _metodoPago == m;
                  return ChoiceChip(
                    label: Text(m.label),
                    avatar: Icon(_iconForMetodo(m), size: 16),
                    selected: selected,
                    onSelected: (_) => setState(() => _metodoPago = m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // ── Efectivo recibido (solo si es efectivo) ───────
              if (_metodoPago == MetodoPago.efectivo) ...[
                TextFormField(
                  controller: _efectivoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Efectivo recibido',
                    prefixText: '\$ ',
                    hintText: '0.00',
                    isDense: true,
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if ((double.tryParse(_efectivoCtrl.text) ?? 0) >= _total) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.change_circle_outlined,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cambio: \$${_cambio.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],

              // ── Descripción opcional ─────────────────────────
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas del pago (opcional)',
                  hintText: 'Ej: Referencia transferencia, etc.',
                  isDense: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: _procesando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _procesando ? null : _confirmar,
          icon: _procesando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(_procesando ? 'Procesando…' : 'Confirmar cobro'),
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
