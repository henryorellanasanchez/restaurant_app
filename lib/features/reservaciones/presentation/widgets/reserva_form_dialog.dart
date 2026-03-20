import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/mesas/domain/entities/mesa.dart';

/// Dialogo para crear una reservacion.
class ReservaFormDialog extends StatefulWidget {
  final DateTime fecha;
  final List<Mesa> mesas;

  const ReservaFormDialog({
    super.key,
    required this.fecha,
    required this.mesas,
  });

  static Future<_ReservaFormResult?> show(
    BuildContext context, {
    required DateTime fecha,
    required List<Mesa> mesas,
  }) {
    return showDialog<_ReservaFormResult>(
      context: context,
      builder: (_) => ReservaFormDialog(fecha: fecha, mesas: mesas),
    );
  }

  @override
  State<ReservaFormDialog> createState() => _ReservaFormDialogState();
}

class _ReservaFormDialogState extends State<ReservaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  TipoReserva _tipo = TipoReserva.mesa;
  String? _mesaId;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fechaStr = DateFormat('dd/MM/yyyy').format(widget.fecha);

    return AlertDialog(
      title: Text('Reservar $fechaStr'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<TipoReserva>(
                value: _tipo,
                items: TipoReserva.values
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                decoration: const InputDecoration(
                  labelText: 'Tipo de reserva',
                  prefixIcon: Icon(Icons.event_available_rounded),
                ),
              ),
              const SizedBox(height: 10),
              if (_tipo == TipoReserva.mesa)
                DropdownButtonFormField<String>(
                  value: _mesaId,
                  items: widget.mesas
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _mesaId = v),
                  decoration: const InputDecoration(
                    labelText: 'Mesa',
                    prefixIcon: Icon(Icons.table_restaurant_rounded),
                  ),
                  validator: (v) {
                    if (_tipo == TipoReserva.mesa && (v == null || v.isEmpty)) {
                      return 'Selecciona una mesa';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Telefono',
                  prefixIcon: Icon(Icons.call_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!regex.hasMatch(value)) return 'Correo invalido';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            final mesa = widget.mesas.where((m) => m.id == _mesaId).toList();
            Navigator.pop(
              context,
              _ReservaFormResult(
                tipo: _tipo,
                mesaId: _mesaId,
                mesaNombre: mesa.isNotEmpty ? mesa.first.displayName : null,
                clienteNombre: _nombreCtrl.text.trim(),
                clienteTelefono: _telefonoCtrl.text.trim(),
                clienteEmail: _emailCtrl.text.trim(),
                notas: _notasCtrl.text.trim().isEmpty
                    ? null
                    : _notasCtrl.text.trim(),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _ReservaFormResult {
  final TipoReserva tipo;
  final String? mesaId;
  final String? mesaNombre;
  final String clienteNombre;
  final String clienteTelefono;
  final String clienteEmail;
  final String? notas;

  const _ReservaFormResult({
    required this.tipo,
    required this.mesaId,
    required this.mesaNombre,
    required this.clienteNombre,
    required this.clienteTelefono,
    required this.clienteEmail,
    required this.notas,
  });
}
