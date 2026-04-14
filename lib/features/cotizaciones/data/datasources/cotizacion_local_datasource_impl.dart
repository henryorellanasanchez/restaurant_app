import 'package:restaurant_app/core/database/database_helper.dart';
import 'package:restaurant_app/core/errors/exceptions.dart';
import 'package:restaurant_app/features/cotizaciones/data/datasources/cotizacion_local_datasource.dart';
import 'package:restaurant_app/features/cotizaciones/data/models/cotizacion_item_model.dart';
import 'package:restaurant_app/features/cotizaciones/data/models/cotizacion_model.dart';

/// Implementacion SQLite del datasource de cotizaciones.
class CotizacionLocalDataSourceImpl implements CotizacionLocalDataSource {
  final DatabaseHelper _dbHelper;

  CotizacionLocalDataSourceImpl({required DatabaseHelper dbHelper})
    : _dbHelper = dbHelper;

  static const _tableCotizaciones = 'cotizaciones';
  static const _tableItems = 'cotizacion_items';

  @override
  Future<void> createCotizacion(CotizacionModel cotizacion) async {
    try {
      await _dbHelper.transaction((txn) async {
        await txn.insert(_tableCotizaciones, cotizacion.toMap());
        for (final item in cotizacion.items) {
          final itemModel = CotizacionItemModel.fromEntity(item);
          await txn.insert(_tableItems, itemModel.toMap());
        }
      });
    } catch (e) {
      throw DatabaseException(message: 'Error al crear cotizacion: $e');
    }
  }

  @override
  Future<List<CotizacionModel>> getCotizaciones(String restaurantId) async {
    try {
      final rows = await _dbHelper.query(
        _tableCotizaciones,
        where: 'restaurant_id = ?',
        whereArgs: [restaurantId],
        orderBy: 'created_at DESC',
      );

      final cotizaciones = <CotizacionModel>[];
      for (final row in rows) {
        final itemsRows = await _dbHelper.query(
          _tableItems,
          where: 'cotizacion_id = ?',
          whereArgs: [row['id']],
          orderBy: 'rowid ASC',
        );
        final items = itemsRows.map(CotizacionItemModel.fromMap).toList();
        cotizaciones.add(CotizacionModel.fromMap(row, items: items));
      }

      return cotizaciones;
    } catch (e) {
      throw DatabaseException(message: 'Error al listar cotizaciones: $e');
    }
  }

  @override
  Future<void> updateEstado(String cotizacionId, String estado) async {
    try {
      await _dbHelper.update(
        _tableCotizaciones,
        {'estado': estado},
        where: 'id = ?',
        whereArgs: [cotizacionId],
      );
    } catch (e) {
      throw DatabaseException(message: 'Error al actualizar cotizacion: $e');
    }
  }
}
