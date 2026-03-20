import 'package:restaurant_app/core/database/database_helper.dart';
import 'package:restaurant_app/core/errors/exceptions.dart';
import 'package:restaurant_app/features/reservaciones/data/datasources/reserva_local_datasource.dart';
import 'package:restaurant_app/features/reservaciones/data/models/reserva_model.dart';

/// Implementacion SQLite del datasource de reservaciones.
class ReservaLocalDataSourceImpl implements ReservaLocalDataSource {
  final DatabaseHelper _dbHelper;

  ReservaLocalDataSourceImpl({required DatabaseHelper dbHelper})
    : _dbHelper = dbHelper;

  static const _table = 'reservaciones';

  @override
  Future<void> createReserva(ReservaModel reserva) async {
    try {
      await _dbHelper.insert(_table, reserva.toMap());
    } catch (e) {
      throw DatabaseException(message: 'Error al crear reserva: $e');
    }
  }

  @override
  Future<List<ReservaModel>> getReservasByMonth(
    String restaurantId,
    String startDate,
    String endDate,
  ) async {
    try {
      final results = await _dbHelper.rawQuery(
        '''
        SELECT r.*, m.nombre AS mesa_nombre, m.numero AS mesa_numero
        FROM $_table r
        LEFT JOIN mesas m ON r.mesa_id = m.id
        WHERE r.restaurant_id = ?
          AND r.fecha >= ?
          AND r.fecha <= ?
        ORDER BY r.fecha ASC
        ''',
        [restaurantId, startDate, endDate],
      );

      return results.map((row) {
        final map = Map<String, dynamic>.from(row);
        if (map['mesa_nombre'] == null && map['mesa_numero'] != null) {
          map['mesa_nombre'] = 'Mesa ${map['mesa_numero']}';
        }
        return ReservaModel.fromMap(map);
      }).toList();
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener reservas: $e');
    }
  }

  @override
  Future<List<ReservaModel>> getReservasByDate(
    String restaurantId,
    String date,
  ) async {
    try {
      final results = await _dbHelper.rawQuery(
        '''
        SELECT r.*, m.nombre AS mesa_nombre, m.numero AS mesa_numero
        FROM $_table r
        LEFT JOIN mesas m ON r.mesa_id = m.id
        WHERE r.restaurant_id = ?
          AND r.fecha = ?
        ORDER BY r.created_at ASC
        ''',
        [restaurantId, date],
      );

      return results.map((row) {
        final map = Map<String, dynamic>.from(row);
        if (map['mesa_nombre'] == null && map['mesa_numero'] != null) {
          map['mesa_nombre'] = 'Mesa ${map['mesa_numero']}';
        }
        return ReservaModel.fromMap(map);
      }).toList();
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener reservas: $e');
    }
  }
}
