import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/mesas/domain/entities/mesa.dart';
import 'package:restaurant_app/features/mesas/presentation/providers/mesas_provider.dart';
import 'package:restaurant_app/features/reservaciones/presentation/providers/reservas_provider.dart';
import 'package:restaurant_app/features/reservaciones/presentation/widgets/reserva_form_dialog.dart';

/// Pantalla de reservaciones (admin).
class ReservasPage extends ConsumerStatefulWidget {
  const ReservasPage({super.key});

  @override
  ConsumerState<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends ConsumerState<ReservasPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reservasProvider.notifier).loadMes(_focusedDay);
      ref.read(reservasProvider.notifier).loadDia(_selectedDay);
      ref.read(mesasProvider.notifier).loadMesas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservasProvider);
    final mesasState = ref.watch(mesasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservaciones'),
        actions: [
          IconButton(
            onPressed: () => _nuevaReserva(context, mesasState.mesas),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Nueva reservacion',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) => _eventsForDay(day, state),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              ref.read(reservasProvider.notifier).loadDia(selectedDay);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              ref.read(reservasProvider.notifier).loadMes(focusedDay);
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildDia(state),
          ),
        ],
      ),
    );
  }

  List<dynamic> _eventsForDay(DateTime day, ReservasState state) {
    final date = DateFormat('yyyy-MM-dd').format(day);
    final items = state.reservasMes.where((r) => r.fecha == date).toList();
    if (items.any((r) => r.tipo == TipoReserva.local)) {
      return ['local'];
    }
    return items;
  }

  Widget _buildDia(ReservasState state) {
    if (state.reservasDia.isEmpty) {
      return const Center(child: Text('No hay reservaciones este dia.'));
    }

    final local = state.reservasDia.any((r) => r.tipo == TipoReserva.local);

    return ListView.builder(
      itemCount: state.reservasDia.length,
      itemBuilder: (_, i) {
        final r = state.reservasDia[i];
        return ListTile(
          leading: Icon(
            r.tipo == TipoReserva.local
                ? Icons.storefront_rounded
                : Icons.table_restaurant_rounded,
            color: r.tipo == TipoReserva.local
                ? AppColors.warning
                : AppColors.primary,
          ),
          title: Text(
            r.tipo == TipoReserva.local
                ? 'Reserva de local'
                : (r.mesaNombre ?? 'Mesa'),
          ),
          subtitle: Text(
            '${r.clienteNombre} · ${r.clienteTelefono} · ${r.clienteEmail}',
          ),
          trailing: local && r.tipo != TipoReserva.local
              ? const Icon(Icons.lock_rounded, color: AppColors.error)
              : null,
        );
      },
    );
  }

  Future<void> _nuevaReserva(BuildContext context, List<Mesa> mesas) async {
    final result = await ReservaFormDialog.show(
      context,
      fecha: _selectedDay,
      mesas: mesas,
    );

    if (result == null || !mounted) return;

    final ok = await ref
        .read(reservasProvider.notifier)
        .crearReserva(
          tipo: result.tipo,
          fecha: _selectedDay,
          mesaId: result.mesaId,
          mesaNombre: result.mesaNombre,
          clienteNombre: result.clienteNombre,
          clienteTelefono: result.clienteTelefono,
          clienteEmail: result.clienteEmail,
          notas: result.notas,
        );

    if (!mounted) return;
    if (!ok) {
      final msg = ref.read(reservasProvider).errorMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg ?? 'Error al reservar')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reservacion creada')));
  }
}
