import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/reservaciones/domain/entities/reserva.dart';
import 'package:restaurant_app/features/reservaciones/domain/usecases/reserva_usecases.dart';
import 'package:uuid/uuid.dart';

/// Estado de reservaciones.
class ReservasState {
  final List<Reserva> reservasMes;
  final List<Reserva> reservasDia;
  final bool isLoading;
  final String? errorMessage;

  const ReservasState({
    this.reservasMes = const [],
    this.reservasDia = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ReservasState copyWith({
    List<Reserva>? reservasMes,
    List<Reserva>? reservasDia,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReservasState(
      reservasMes: reservasMes ?? this.reservasMes,
      reservasDia: reservasDia ?? this.reservasDia,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ReservasNotifier extends StateNotifier<ReservasState> {
  final CreateReserva _createReserva;
  final GetReservasByMonth _getByMonth;
  final GetReservasByDate _getByDate;

  ReservasNotifier({
    required CreateReserva createReserva,
    required GetReservasByMonth getByMonth,
    required GetReservasByDate getByDate,
  }) : _createReserva = createReserva,
       _getByMonth = getByMonth,
       _getByDate = getByDate,
       super(const ReservasState());

  Future<void> loadMes(DateTime month, [String? restaurantId]) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final rid = restaurantId ?? AppConstants.defaultRestaurantId;
    final start = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(month.year, month.month, 1));
    final end = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(month.year, month.month + 1, 0));

    final result = await _getByMonth([rid, start, end]);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, errorMessage: f.message),
      (items) => state = state.copyWith(isLoading: false, reservasMes: items),
    );
  }

  Future<void> loadDia(DateTime day, [String? restaurantId]) async {
    final rid = restaurantId ?? AppConstants.defaultRestaurantId;
    final date = DateFormat('yyyy-MM-dd').format(day);
    final result = await _getByDate([rid, date]);
    result.fold(
      (f) => state = state.copyWith(errorMessage: f.message),
      (items) => state = state.copyWith(reservasDia: items),
    );
  }

  Future<bool> crearReserva({
    required TipoReserva tipo,
    required DateTime fecha,
    String? mesaId,
    String? mesaNombre,
    required String clienteNombre,
    required String clienteTelefono,
    required String clienteEmail,
    String? notas,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(fecha);

    final reservas = state.reservasMes
        .where((r) => r.fecha == dateStr)
        .toList();
    final localReservado = reservas.any((r) => r.tipo == TipoReserva.local);

    if (tipo == TipoReserva.local && reservas.isNotEmpty) {
      state = state.copyWith(errorMessage: 'Ya hay reservas en esa fecha');
      return false;
    }

    if (tipo == TipoReserva.mesa) {
      if (localReservado) {
        state = state.copyWith(
          errorMessage: 'El local esta reservado en esa fecha',
        );
        return false;
      }
      if (mesaId == null || mesaId.isEmpty) {
        state = state.copyWith(errorMessage: 'Selecciona una mesa');
        return false;
      }
      final mesaReservada = reservas.any(
        (r) => r.tipo == TipoReserva.mesa && r.mesaId == mesaId,
      );
      if (mesaReservada) {
        state = state.copyWith(
          errorMessage: 'La mesa ya esta reservada en esa fecha',
        );
        return false;
      }
    }

    final reserva = Reserva(
      id: const Uuid().v4(),
      restaurantId: AppConstants.defaultRestaurantId,
      tipo: tipo,
      mesaId: mesaId,
      mesaNombre: mesaNombre,
      fecha: dateStr,
      clienteNombre: clienteNombre,
      clienteTelefono: clienteTelefono,
      clienteEmail: clienteEmail,
      notas: notas,
      createdAt: DateTime.now(),
    );

    final result = await _createReserva(reserva);
    return result.fold(
      (f) {
        state = state.copyWith(errorMessage: f.message);
        return false;
      },
      (_) async {
        await loadMes(fecha);
        await loadDia(fecha);
        return true;
      },
    );
  }
}

final reservasProvider = StateNotifierProvider<ReservasNotifier, ReservasState>(
  (ref) {
    return ReservasNotifier(
      createReserva: sl<CreateReserva>(),
      getByMonth: sl<GetReservasByMonth>(),
      getByDate: sl<GetReservasByDate>(),
    );
  },
);
