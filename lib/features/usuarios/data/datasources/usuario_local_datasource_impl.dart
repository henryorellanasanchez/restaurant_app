import 'package:restaurant_app/core/database/database_helper.dart';
import 'package:restaurant_app/features/usuarios/data/datasources/usuario_local_datasource.dart';
import 'package:restaurant_app/features/usuarios/data/models/usuario_model.dart';

/// Implementación SQLite del datasource de Usuarios.
class UsuarioLocalDataSourceImpl implements UsuarioLocalDataSource {
  const UsuarioLocalDataSourceImpl({required DatabaseHelper dbHelper})
    : _dbHelper = dbHelper;

  final DatabaseHelper _dbHelper;

  @override
  Future<List<UsuarioModel>> getUsuarios(String restaurantId) async {
    final rows = await _dbHelper.query(
      'usuarios',
      where: 'restaurant_id = ? AND activo = 1',
      whereArgs: [restaurantId],
      orderBy: 'nombre ASC',
    );
    return rows.map(UsuarioModel.fromMap).toList();
  }

  @override
  Future<UsuarioModel?> getUsuarioById(String id) async {
    final rows = await _dbHelper.query(
      'usuarios',
      where: 'id = ? AND activo = 1',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UsuarioModel.fromMap(rows.first);
  }

  @override
  Future<UsuarioModel> createUsuario(UsuarioModel usuario) async {
    await _dbHelper.insert('usuarios', usuario.toMap());
    return usuario;
  }

  @override
  Future<UsuarioModel> updateUsuario(UsuarioModel usuario) async {
    final updated = UsuarioModel.fromMap({
      ...usuario.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await _dbHelper.update(
      'usuarios',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
    return updated;
  }

  @override
  Future<void> deleteUsuario(String id) async {
    await _dbHelper.update(
      'usuarios',
      {'activo': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<UsuarioModel?> verificarPin(String restaurantId, String pin) async {
    final rows = await _dbHelper.query(
      'usuarios',
      where: 'restaurant_id = ? AND pin = ? AND activo = 1',
      whereArgs: [restaurantId, pin],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UsuarioModel.fromMap(rows.first);
  }

  @override
  Future<List<UsuarioModel>> getUsuariosByRol(
    String restaurantId,
    String rol,
  ) async {
    final rows = await _dbHelper.query(
      'usuarios',
      where: 'restaurant_id = ? AND rol = ? AND activo = 1',
      whereArgs: [restaurantId, rol],
      orderBy: 'nombre ASC',
    );
    return rows.map(UsuarioModel.fromMap).toList();
  }
}
