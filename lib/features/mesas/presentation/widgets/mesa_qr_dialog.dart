import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/features/mesas/domain/entities/mesa.dart';

/// Dialogo para mostrar el QR del menu publico por mesa.
class MesaQrDialog extends StatelessWidget {
  final Mesa mesa;

  const MesaQrDialog({super.key, required this.mesa});

  static Future<void> show(BuildContext context, {required Mesa mesa}) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => MesaQrDialog(mesa: mesa),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _buildMenuUrl(mesa.id);

    return AlertDialog(
      title: Text('QR ${mesa.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(data: url, size: 220, backgroundColor: Colors.white),
          const SizedBox(height: 12),
          Text(
            url,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  String _buildMenuUrl(String mesaId) {
    final base = AppConstants.publicMenuBaseUrl;
    return '$base?mesa=$mesaId';
  }
}
