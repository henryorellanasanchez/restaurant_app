import 'package:restaurant_app/core/database/database_helper.dart';
import 'package:restaurant_app/core/errors/exceptions.dart';
import 'package:restaurant_app/features/mesas/data/datasources/llamado_local_datasource.dart';
import 'package:restaurant_app/features/mesas/data/models/llamado_mesero_model.dart';

/// Implementacion SQLite del datasource de llamados a mesero.
class LlamadoLocalDataSourceImpl implements LlamadoLocalDataSource {
  final DatabaseHelper _dbHelper;

  LlamadoLocalDataSourceImpl({required DatabaseHelper dbHelper})
    : _dbHelper = dbHelper;

  static const _table = 'llamados_mesero';

  @override
  Future<void> createLlamado(LlamadoMeseroModel llamado) async {
    try {
      await _dbHelper.insert(_table, llamado.toMap());
    } catch (e) {
      throw DatabaseException(message: 'Error al crear llamado: $e');
    }
  }

  @override
  Future<List<LlamadoMeseroModel>> getPendientes(String restaurantId) async {
    try {
      final results = await _dbHelper.rawQuery(
        '''
        SELECT l.*, m.nombre AS mesa_nombre, m.numero AS mesa_numero
        FROM $_table l
        LEFT JOIN mesas m ON l.mesa_id = m.id
        WHERE l.restaurant_id = ?
          AND l.estado = 'pendiente'
        ORDER BY l.created_at ASC
        ''',
        [restaurantId],
      );

      return results.map((row) {
        final map = Map<String, dynamic>.from(row);
        if (map['mesa_nombre'] == null && map['mesa_numero'] != null) {
          map['mesa_nombre'] = 'Mesa ${map['mesa_numero']}';
        }
        return LlamadoMeseroModel.fromMap(map);
      }).toList();
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener llamados: $e');
    }
  }

  @override
  Future<void> marcarAtendido(String id) async {
    try {
      await _dbHelper.update(
        _table,
        {'estado': 'atendido', 'atendido_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException(message: 'Error al atender llamado: $e');
    }
  }
}
