import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/menu/domain/entities/producto.dart';

/// Tarjeta de producto para el menu publico.
class PublicProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onAdd;
  final int cantidad;

  const PublicProductoCard({
    super.key,
    required this.producto,
    this.onAdd,
    this.cantidad = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildImage(producto.imagenUrl, cs)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (producto.descripcion != null &&
                    producto.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    producto.descripcion!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${AppConstants.currencySymbol}${producto.precio.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (cantidad > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'x$cantidad',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Agregar',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? imageValue, ColorScheme cs) {
    final raw = imageValue?.trim();
    if (raw == null || raw.isEmpty) return _placeholder(cs);

    if (raw.startsWith('data:image')) {
      final commaIndex = raw.indexOf(',');
      if (commaIndex == -1) return _placeholder(cs);

      try {
        return Image.memory(
          base64Decode(raw.substring(commaIndex + 1)),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: 720,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, __, ___) => _placeholder(cs),
        );
      } catch (_) {
        return _placeholder(cs);
      }
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return Image.network(
        raw,
        fit: BoxFit.cover,
        cacheWidth: 720,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) => _placeholder(cs),
      );
    }

    if (raw.startsWith('assets/')) {
      return Image.asset(
        raw,
        fit: BoxFit.cover,
        cacheWidth: 720,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) => _placeholder(cs),
      );
    }

    return _placeholder(cs);
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.photo_outlined, color: cs.onSurfaceVariant, size: 44),
    );
  }
}
