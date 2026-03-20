import 'package:restaurant_app/core/database/database_helper.dart';
import 'package:restaurant_app/core/errors/exceptions.dart';
import 'package:restaurant_app/features/caja/data/datasources/caja_local_datasource.dart';
import 'package:restaurant_app/features/caja/data/models/venta_detalle_model.dart';
import 'package:restaurant_app/features/caja/data/models/venta_model.dart';
import 'package:restaurant_app/features/pedidos/data/models/pedido_item_model.dart';
import 'package:restaurant_app/features/pedidos/data/models/pedido_model.dart';

/// Implementación SQLite del datasource de Caja.
class CajaLocalDataSourceImpl implements CajaLocalDataSource {
  final DatabaseHelper _dbHelper;

  CajaLocalDataSourceImpl({required DatabaseHelper dbHelper})
    : _dbHelper = dbHelper;

  static const _tableVentas = 'ventas';
  static const _tableDetalles = 'venta_detalles';
  static const _tablePedidos = 'pedidos';
  static const _tableMesas = 'mesas';
  static const _tablePedidoItems = 'pedido_items';

  // ── Registro de venta ─────────────────────────────────────────

  @override
  Future<void> registrarVenta(VentaModel venta, {String? mesaId}) async {
    try {
      await _dbHelper.transaction((txn) async {
        // 1. Insertar venta principal
        await txn.insert(_tableVentas, venta.toMap());

        // 2. Insertar detalles de la venta
        for (final detalle in venta.detalles) {
          final detalleModel = VentaDetalleModel.fromEntity(detalle);
          await txn.insert(_tableDetalles, detalleModel.toMap());
        }

        // 3. Marcar el pedido como entregado
        await txn.update(
          _tablePedidos,
          {
            'estado': 'entregado',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [venta.pedidoId],
        );

        // 4. Liberar la mesa si aplica
        if (mesaId != null) {
          await txn.update(
            _tableMesas,
            {'estado': 'libre', 'updated_at': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [mesaId],
          );
        }
      });
    } catch (e) {
      throw DatabaseException(message: 'Error al registrar venta: $e');
    }
  }

  // ── Consultas de ventas ───────────────────────────────────────

  @override
  Future<List<VentaModel>> getVentas(String restaurantId) async {
    try {
      final results = await _dbHelper.rawQuery(
        '''
        SELECT v.*, u.nombre AS cajero_nombre
        FROM $_tableVentas v
        LEFT JOIN usuarios u ON v.cajero_id = u.id
        WHERE v.restaurant_id = ?
        ORDER BY v.created_at DESC
        ''',
        [restaurantId],
      );
      return results.map((row) => VentaModel.fromMap(row)).toList();
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener ventas: $e');
    }
  }

  @override
  Future<List<VentaModel>> getVentasByFecha(
    String restaurantId,
    DateTime fecha,
  ) async {
    try {
      final fechaStr = fecha.toIso8601String().substring(0, 10);
      final results = await _dbHelper.rawQuery(
        '''
        SELECT v.*, u.nombre AS cajero_nombre
        FROM $_tableVentas v
        LEFT JOIN usuarios u ON v.cajero_id = u.id
        WHERE v.restaurant_id = ?
          AND date(v.created_at) = ?
        ORDER BY v.created_at DESC
        ''',
        [restaurantId, fechaStr],
      );
      return results.map((row) => VentaModel.fromMap(row)).toList();
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener ventas por fecha: $e');
    }
  }

  @override
  Future<VentaModel?> getVentaById(String id) async {
    try {
      final results = await _dbHelper.rawQuery(
        '''
        SELECT v.*, u.nombre AS cajero_nombre
        FROM $_tableVentas v
        LEFT JOIN usuarios u ON v.cajero_id = u.id
        WHERE v.id = ?
        ''',
        [id],
      );
      if (results.isEmpty) return null;

      final detalles = await _getDetallesByVenta(id);
      return VentaModel.fromMap(results.first, detalles: detalles);
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener venta: $e');
    }
  }

  @override
  Future<VentaModel?> getVentaByPedido(String pedidoId) async {
    try {
      final results = await _dbHelper.rawQuery(
        '''
        SELECT v.*, u.nombre AS cajero_nombre
        FROM $_tableVentas v
        LEFT JOIN usuarios u ON v.cajero_id = u.id
        WHERE v.pedido_id = ?
        ORDER BY v.created_at DESC
        LIMIT 1
        ''',
        [pedidoId],
      );
      if (results.isEmpty) return null;
      final detalles = await _getDetallesByVenta(results.first['id'] as String);
      return VentaModel.fromMap(results.first, detalles: detalles);
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener venta por pedido: $e');
    }
  }

  @override
  Future<List<PedidoModel>> getPedidosParaCobrar(String restaurantId) async {
    try {
      final results = await _dbHelper.rawQuery(
        '''
        SELECT p.*,
               m.nombre AS mesa_nombre,
               m.numero AS mesa_numero,
               u.nombre AS mesero_nombre
        FROM $_tablePedidos p
        LEFT JOIN mesas m ON p.mesa_id = m.id
        LEFT JOIN usuarios u ON p.mesero_id = u.id
        WHERE p.restaurant_id = ?
          AND p.estado = 'finalizado'
        ORDER BY p.created_at ASC
        ''',
        [restaurantId],
      );

      final pedidos = <PedidoModel>[];
      for (final row in results) {
        final mesaNombre =
            row['mesa_nombre'] as String? ??
            (row['mesa_numero'] != null ? 'Mesa ${row['mesa_numero']}' : null);
        final map = Map<String, dynamic>.from(row);
        map['mesa_nombre'] = mesaNombre;

        final items = await _getItemsByPedido(row['id'] as String);
        pedidos.add(PedidoModel.fromMap(map, items: items));
      }
      return pedidos;
    } catch (e) {
      throw DatabaseException(
        message: 'Error al obtener pedidos para cobrar: $e',
      );
    }
  }

  // ── Helpers privados ──────────────────────────────────────────

  Future<List<VentaDetalleModel>> _getDetallesByVenta(String ventaId) async {
    final results = await _dbHelper.query(
      _tableDetalles,
      where: 'venta_id = ?',
      whereArgs: [ventaId],
    );
    return results.map((r) => VentaDetalleModel.fromMap(r)).toList();
  }

  Future<List<PedidoItemModel>> _getItemsByPedido(String pedidoId) async {
    final results = await _dbHelper.rawQuery(
      '''
      SELECT pi.*,
             p.nombre AS producto_nombre,
             v.nombre AS variante_nombre
      FROM $_tablePedidoItems pi
      LEFT JOIN productos p ON pi.producto_id = p.id
      LEFT JOIN variantes v ON pi.variante_id = v.id
      WHERE pi.pedido_id = ?
      ORDER BY pi.created_at ASC
      ''',
      [pedidoId],
    );
    return results.map((r) => PedidoItemModel.fromMap(r)).toList();
  }
}
