import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/mesas/presentation/providers/mesas_provider.dart';
import 'package:restaurant_app/features/reservaciones/presentation/providers/reservas_provider.dart';

/// Calendario publico de disponibilidad.
class ReservasPublicPage extends ConsumerStatefulWidget {
  const ReservasPublicPage({super.key});

  @override
  ConsumerState<ReservasPublicPage> createState() => _ReservasPublicPageState();
}

class _ReservasPublicPageState extends ConsumerState<ReservasPublicPage> {
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
    final reservas = ref.watch(reservasProvider);
    final mesas = ref.watch(mesasProvider).mesas;

    return Scaffold(
      appBar: AppBar(title: const Text('Fechas disponibles')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) => _eventsForDay(day, reservas),
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
                color: AppColors.secondary,
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
          Expanded(child: _buildDisponibilidad(reservas, mesas)),
        ],
      ),
    );
  }

  List<dynamic> _eventsForDay(DateTime day, ReservasState state) {
    final date = DateFormat('yyyy-MM-dd').format(day);
    final items = state.reservasMes.where((r) => r.fecha == date).toList();
    return items;
  }

  Widget _buildDisponibilidad(ReservasState reservas, List mesas) {
    final date = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final items = reservas.reservasMes.where((r) => r.fecha == date).toList();
    final local = items.any((r) => r.tipo == TipoReserva.local);

    if (local) {
      return const Center(
        child: Text('Local reservado. No hay disponibilidad.'),
      );
    }

    final reservedMesaIds = items
        .where((r) => r.mesaId != null)
        .map((r) => r.mesaId)
        .toSet();
    final disponibles = mesas.length - reservedMesaIds.length;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Disponibles: $disponibles',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Reservadas: ${reservedMesaIds.length}'),
        ],
      ),
    );
  }
}
