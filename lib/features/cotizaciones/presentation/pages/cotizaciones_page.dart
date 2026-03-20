import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/features/cotizaciones/domain/entities/cotizacion.dart';
import 'package:restaurant_app/features/cotizaciones/domain/usecases/cotizacion_usecases.dart';
import 'package:restaurant_app/features/reservaciones/presentation/providers/reservas_provider.dart';
import 'package:restaurant_app/features/cotizaciones/presentation/providers/cotizaciones_provider.dart';

class CotizacionesPage extends ConsumerWidget {
  const CotizacionesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cotizacionesAsync = ref.watch(cotizacionesProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(cotizacionesProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: cotizacionesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No hay cotizaciones registradas.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = items[i];
              final fecha = DateFormat('dd/MM/yyyy').format(c.createdAt);
              final evento = c.fechaEvento == null || c.fechaEvento!.isEmpty
                  ? null
                  : DateFormat(
                      'dd/MM/yyyy',
                    ).format(DateTime.parse(c.fechaEvento!));
              return Card(
                elevation: 1,
                child: ListTile(
                  onTap: () => _showDetalle(context, ref, c),
                  leading: Icon(
                    Icons.request_quote_outlined,
                    color: c.reservaLocal
                        ? AppColors.secondary
                        : AppColors.info,
                  ),
                  title: Text(c.clienteNombre),
                  subtitle: Text(
                    _buildSubtitle(
                      fecha: fecha,
                      telefono: c.clienteTelefono,
                      evento: evento,
                      personas: c.personas,
                      reservaLocal: c.reservaLocal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(c.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _labelEstado(c.estado),
                        style: TextStyle(
                          fontSize: 11,
                          color: _colorEstado(c.estado),
                        ),
                      ),
                      if (c.reservaLocal)
                        const Text(
                          'Reserva local',
                          style: TextStyle(fontSize: 11, color: AppColors.info),
                        ),
                      const SizedBox(height: 4),
                      IconButton(
                        tooltip: 'Copiar telefono',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: c.clienteTelefono),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Telefono copiado')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (e, __) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String _buildSubtitle({
    required String fecha,
    required String telefono,
    required String? evento,
    required int? personas,
    required bool reservaLocal,
  }) {
    final buffer = StringBuffer('Fecha: $fecha · Tel: $telefono');
    if (reservaLocal) buffer.write(' · Reserva local');
    if (evento != null) buffer.write(' · Evento: $evento');
    if (personas != null && personas > 0) {
      buffer.write(' · Personas: $personas');
    }
    return buffer.toString();
  }

  String _labelEstado(String estado) {
    return switch (estado) {
      'aceptada' => 'Aceptada',
      'rechazada' => 'Rechazada',
      _ => 'Pendiente',
    };
  }

  Color _colorEstado(String estado) {
    return switch (estado) {
      'aceptada' => Colors.green,
      'rechazada' => AppColors.error,
      _ => AppColors.textSecondary,
    };
  }

  Future<void> _showDetalle(
    BuildContext context,
    WidgetRef ref,
    Cotizacion c,
  ) async {
    final currencyFormat = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
    );
    final evento = c.fechaEvento == null || c.fechaEvento!.isEmpty
        ? null
        : DateFormat('dd/MM/yyyy').format(DateTime.parse(c.fechaEvento!));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.request_quote_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.clienteNombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _labelEstado(c.estado),
                      style: TextStyle(
                        color: _colorEstado(c.estado),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow('Telefono', c.clienteTelefono),
                _infoRow('Correo', c.clienteEmail),
                _infoRow('Total', currencyFormat.format(c.total)),
                if (evento != null) _infoRow('Evento', evento),
                if (c.personas != null && c.personas! > 0)
                  _infoRow('Personas', '${c.personas}'),
                if (c.comidaPreferida != null && c.comidaPreferida!.isNotEmpty)
                  _infoRow('Comida', c.comidaPreferida!),
                if (c.notas != null && c.notas!.isNotEmpty)
                  _infoRow('Notas', c.notas!),
                const SizedBox(height: 12),
                _infoRow('Reserva local', c.reservaLocal ? 'Si' : 'No'),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchWhatsApp(context, c),
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callPhone(context, c.clienteTelefono),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Llamar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: c.clienteTelefono),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Telefono copiado')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copiar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (c.estado == 'pendiente') ...[
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _aceptarCotizacion(context, ref, c),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Aceptar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rechazarCotizacion(context, ref, c),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Rechazar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _aceptarCotizacion(
    BuildContext context,
    WidgetRef ref,
    Cotizacion c,
  ) async {
    if (c.fechaEvento == null || c.fechaEvento!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta la fecha del evento')),
      );
      return;
    }

    final fecha = DateTime.parse(c.fechaEvento!);
    await ref.read(reservasProvider.notifier).loadMes(fecha);

    bool ok = true;
    if (c.reservaLocal) {
      ok = await ref
          .read(reservasProvider.notifier)
          .crearReserva(
            tipo: TipoReserva.local,
            fecha: fecha,
            clienteNombre: c.clienteNombre,
            clienteTelefono: c.clienteTelefono,
            clienteEmail: c.clienteEmail,
            notas: c.notas,
          );
    }

    if (!ok) {
      if (context.mounted) {
        final msg = ref.read(reservasProvider).errorMessage;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg ?? 'No se pudo agendar')));
      }
      return;
    }

    final result = await sl<UpdateCotizacionEstado>()(
      UpdateCotizacionEstadoParams(cotizacionId: c.id, estado: 'aceptada'),
    );

    if (context.mounted) {
      result.fold(
        (f) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.message))),
        (_) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cotizacion aceptada'))),
      );
      Navigator.pop(context);
      ref.invalidate(cotizacionesProvider);
    }
  }

  Future<void> _rechazarCotizacion(
    BuildContext context,
    WidgetRef ref,
    Cotizacion c,
  ) async {
    final result = await sl<UpdateCotizacionEstado>()(
      UpdateCotizacionEstadoParams(cotizacionId: c.id, estado: 'rechazada'),
    );

    if (context.mounted) {
      result.fold(
        (f) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.message))),
        (_) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cotizacion rechazada'))),
      );
      Navigator.pop(context);
      ref.invalidate(cotizacionesProvider);
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, Cotizacion c) async {
    final phone = _sanitizePhone(c.clienteTelefono);
    if (phone.isEmpty) return;
    final message = _buildWhatsappMessage(c);
    final uri = Uri.https('wa.me', '/$phone', {'text': message});
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  Future<void> _callPhone(BuildContext context, String telefono) async {
    final phone = _sanitizePhone(telefono);
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar llamada')),
      );
    }
  }

  String _sanitizePhone(String telefono) {
    return telefono.replaceAll(RegExp(r'\D'), '');
  }

  String _buildWhatsappMessage(Cotizacion c) {
    final evento = c.fechaEvento == null || c.fechaEvento!.isEmpty
        ? 'sin fecha definida'
        : c.fechaEvento!;
    final personas = c.personas != null && c.personas! > 0
        ? 'Personas: ${c.personas}'
        : 'Personas: por confirmar';
    final tipo = c.reservaLocal ? 'reserva de local' : 'cotizacion';
    return 'Hola, somos ${AppConstants.appFullName}. '
        'Nos comunicamos contigo por tu solicitud de $tipo. '
        'Evento: $evento. $personas.';
  }
}
