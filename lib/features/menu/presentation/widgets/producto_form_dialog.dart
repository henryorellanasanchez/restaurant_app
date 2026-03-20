import 'package:flutter/material.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/features/menu/domain/entities/categoria.dart';
import 'package:restaurant_app/features/menu/domain/entities/producto.dart';
import 'package:restaurant_app/features/menu/domain/entities/variante.dart';
import 'package:uuid/uuid.dart';

/// Diálogo para crear o editar un producto del menú.
///
/// Incluye nombre, descripción, precio base, categoría, disponibilidad
/// y gestión de variantes inline.
class ProductoFormDialog extends StatefulWidget {
  final Producto? producto;
  final List<Categoria> categorias;

  const ProductoFormDialog({
    super.key,
    this.producto,
    required this.categorias,
  });

  static Future<Producto?> show(
    BuildContext context, {
    Producto? producto,
    required List<Categoria> categorias,
  }) {
    return showDialog<Producto>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductoFormDialog(
        producto: producto,
        categorias: categorias,
      ),
    );
  }

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _precioCtrl;
  late String _categoriaId;
  bool _disponible = true;
  bool _activo = true;
  List<_VarianteEditable> _variantes = [];

  bool get _isEditing => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _precioCtrl = TextEditingController(
        text: p != null ? p.precio.toStringAsFixed(2) : '');
    _categoriaId = p?.categoriaId ??
        (widget.categorias.isNotEmpty
            ? widget.categorias.first.id
            : '');
    _disponible = p?.disponible ?? true;
    _activo = p?.activo ?? true;
    _variantes = (p?.variantes ?? [])
        .map((v) => _VarianteEditable.fromEntity(v))
        .toList();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    for (final v in _variantes) {
      v.dispose();
    }
    super.dispose();
  }

  void _addVariante() {
    setState(() {
      _variantes.add(_VarianteEditable());
    });
  }

  void _removeVariante(int index) {
    setState(() {
      _variantes[index].dispose();
      _variantes.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final productoId = widget.producto?.id ?? const Uuid().v4();

    final variantesEntidades = _variantes.map((v) {
      return Variante(
        id: v.id ?? const Uuid().v4(),
        productoId: productoId,
        nombre: v.nombreCtrl.text.trim(),
        precio:
            double.tryParse(v.precioCtrl.text.trim()) ?? 0.0,
        activo: true,
        createdAt: v.createdAt ?? now,
        updatedAt: now,
      );
    }).toList();

    final producto = Producto(
      id: productoId,
      restaurantId: widget.producto?.restaurantId ??
          AppConstants.defaultRestaurantId,
      categoriaId: _categoriaId,
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      precio:
          double.tryParse(_precioCtrl.text.trim()) ?? 0.0,
      disponible: _disponible,
      activo: _activo,
      createdAt: widget.producto?.createdAt ?? now,
      updatedAt: now,
      variantes: variantesEntidades,
    );

    Navigator.of(context).pop(producto);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Nombre ──────────────────────────────────────
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Ej: Hamburguesa Clásica',
                    prefixIcon: Icon(Icons.fastfood_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Descripción ──────────────────────────────────
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ingredientes, alérgenos, etc. (opcional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Precio + Categoría ───────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Precio *',
                          prefixText: '\$ ',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Requerido';
                          }
                          final parsed = double.tryParse(v.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Precio inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _categoriaId.isEmpty ? null : _categoriaId,
                        decoration: const InputDecoration(
                          labelText: 'Categoría *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: widget.categorias
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.nombre),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _categoriaId = v);
                          }
                        },
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? 'Selecciona una categoría'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Disponible ───────────────────────────────────
                SwitchListTile.adaptive(
                  title: const Text('Disponible ahora'),
                  subtitle: Text(
                    _disponible
                        ? 'Visible para los pedidos'
                        : 'No se puede pedir',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: _disponible,
                  onChanged: (v) => setState(() => _disponible = v),
                  contentPadding: EdgeInsets.zero,
                ),

                const Divider(height: 24),

                // ── Variantes ────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Variantes (opcional)',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addVariante,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Añadir'),
                    ),
                  ],
                ),
                if (_variantes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Sin variantes — el precio base aplica para todos.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: _variantes.length,
                    itemBuilder: (_, i) {
                      final v = _variantes[i];
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: v.nombreCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Nombre variante ${i + 1}',
                                  hintText: 'Ej: Grande',
                                  isDense: true,
                                ),
                                validator: (val) {
                                  if (val == null ||
                                      val.trim().isEmpty) {
                                    return 'Requerido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: v.precioCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Precio',
                                  prefixText: '\$ ',
                                  isDense: true,
                                ),
                                validator: (val) {
                                  if (val == null ||
                                      val.trim().isEmpty) {
                                    return 'Requerido';
                                  }
                                  final p =
                                      double.tryParse(val.trim());
                                  if (p == null || p < 0) {
                                    return 'Inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: theme.colorScheme.error,
                              onPressed: () => _removeVariante(i),
                              tooltip: 'Eliminar variante',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}

/// Modelo editable de una variante dentro del formulario.
class _VarianteEditable {
  final String? id;
  final DateTime? createdAt;
  final TextEditingController nombreCtrl;
  final TextEditingController precioCtrl;

  _VarianteEditable({
    this.id,
    this.createdAt,
    TextEditingController? nombreCtrl,
    TextEditingController? precioCtrl,
  })  : nombreCtrl = nombreCtrl ?? TextEditingController(),
        precioCtrl = precioCtrl ?? TextEditingController();

  factory _VarianteEditable.fromEntity(Variante v) {
    return _VarianteEditable(
      id: v.id,
      createdAt: v.createdAt,
      nombreCtrl: TextEditingController(text: v.nombre),
      precioCtrl:
          TextEditingController(text: v.precio.toStringAsFixed(2)),
    );
  }

  void dispose() {
    nombreCtrl.dispose();
    precioCtrl.dispose();
  }
}
