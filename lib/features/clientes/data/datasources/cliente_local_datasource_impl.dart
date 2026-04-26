import 'package:restaurant_app/core/database/database_helper.dart';
import 'package:restaurant_app/core/errors/exceptions.dart';
import 'package:restaurant_app/features/clientes/data/datasources/cliente_local_datasource.dart';
import 'package:restaurant_app/features/clientes/data/models/cliente_model.dart';
import 'package:restaurant_app/features/clientes/domain/repositories/cliente_repository.dart';

/// Implementación SQLite del datasource de Clientes.
class ClienteLocalDataSourceImpl implements ClienteLocalDataSource {
  const ClienteLocalDataSourceImpl({required DatabaseHelper dbHelper})
    : _db = dbHelper;

  final DatabaseHelper _db;

  static const _table = 'clientes';

  @override
  Future<List<ClienteModel>> getClientes(String restaurantId) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'restaurant_id = ? AND activo = 1',
        whereArgs: [restaurantId],
        orderBy: 'nombre ASC, apellido ASC',
      );
      return rows.map(ClienteModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener clientes: $e');
    }
  }

  @override
  Future<ClienteModel?> getClienteByCedula(String cedula) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'cedula = ? AND activo = 1',
        whereArgs: [cedula.trim()],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return ClienteModel.fromMap(rows.first);
    } catch (e) {
      throw DatabaseException(message: 'Error al buscar cliente: $e');
    }
  }

  @override
  Future<List<ClienteModel>> buscarClientes(
    String restaurantId,
    String query,
  ) async {
    try {
      final like = '%${query.trim()}%';
      final rows = await _db.rawQuery(
        '''
        SELECT * FROM $_table
        WHERE restaurant_id = ?
          AND activo = 1
          AND (
            cedula      LIKE ? OR
            nombre      LIKE ? OR
            apellido    LIKE ? OR
            email       LIKE ? OR
            telefono    LIKE ?
          )
        ORDER BY nombre ASC, apellido ASC
        LIMIT 50
        ''',
        [restaurantId, like, like, like, like, like],
      );
      return rows.map(ClienteModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException(message: 'Error al buscar clientes: $e');
    }
  }

  @override
  Future<ClienteModel> createCliente(ClienteModel cliente) async {
    try {
      // Verificar duplicado antes de insertar (refuerzo a nivel app)
      final existing = await getClienteByCedula(cliente.cedula);
      if (existing != null) {
        throw const BusinessException(
          message: 'Ya existe un cliente registrado con esa cédula.',
        );
      }
      await _db.insert(_table, cliente.toMap());
      return cliente;
    } on BusinessException {
      rethrow;
    } catch (e) {
      throw DatabaseException(message: 'Error al registrar cliente: $e');
    }
  }

  @override
  Future<ClienteModel> updateCliente(ClienteModel cliente) async {
    try {
      final updated = ClienteModel.fromMap({
        ...cliente.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await _db.update(
        _table,
        updated.toMap(),
        where: 'cedula = ?',
        whereArgs: [cliente.cedula],
      );
      return updated;
    } catch (e) {
      throw DatabaseException(message: 'Error al actualizar cliente: $e');
    }
  }

  @override
  Future<void> deleteCliente(String cedula) async {
    try {
      await _db.update(
        _table,
        {'activo': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'cedula = ?',
        whereArgs: [cedula],
      );
    } catch (e) {
      throw DatabaseException(message: 'Error al eliminar cliente: $e');
    }
  }

  @override
  Future<ClienteResumen> getResumenCliente(
    String cedula,
    String restaurantId,
  ) async {
    try {
      final rows = await _db.rawQuery(
        '''
        SELECT
          COUNT(*)            AS total_visitas,
          COALESCE(SUM(total), 0)  AS total_gastado,
          MIN(created_at)     AS primera_visita,
          MAX(created_at)     AS ultima_visita
        FROM ventas
        WHERE cliente_identificacion = ?
          AND restaurant_id = ?
        ''',
        [cedula, restaurantId],
      );

      if (rows.isEmpty) {
        return ClienteResumen(
          cedula: cedula,
          totalVisitas: 0,
          totalGastado: 0,
          ticketPromedio: 0,
        );
      }

      final row = rows.first;
      final totalVisitas = (row['total_visitas'] as int?) ?? 0;
      final totalGastado = (row['total_gastado'] as num?)?.toDouble() ?? 0.0;

      return ClienteResumen(
        cedula: cedula,
        totalVisitas: totalVisitas,
        totalGastado: totalGastado,
        ticketPromedio: totalVisitas > 0 ? totalGastado / totalVisitas : 0,
        primeraVisita: row['primera_visita'] != null
            ? DateTime.tryParse(row['primera_visita'] as String)
            : null,
        ultimaVisita: row['ultima_visita'] != null
            ? DateTime.tryParse(row['ultima_visita'] as String)
            : null,
      );
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener resumen: $e');
    }
  }
}
