import 'package:restaurant_app/core/database/database_helper.dart';
import 'package:restaurant_app/core/errors/exceptions.dart';
import 'package:restaurant_app/features/pagina_publica/data/datasources/public_config_datasource.dart';
import 'package:restaurant_app/features/pagina_publica/data/models/public_config_model.dart';

class PublicConfigDatasourceImpl implements PublicConfigDatasource {
  const PublicConfigDatasourceImpl({required DatabaseHelper dbHelper})
    : _db = dbHelper;

  final DatabaseHelper _db;
  static const _table = 'public_config';

  @override
  Future<PublicConfigModel?> getConfig(String restaurantId) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'restaurant_id = ?',
        whereArgs: [restaurantId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return PublicConfigModel.fromMap(rows.first);
    } catch (e) {
      throw DatabaseException(
        message: 'Error al obtener configuración pública: $e',
      );
    }
  }

  @override
  Future<PublicConfigModel> saveConfig(PublicConfigModel config) async {
    try {
      final map = config.toMap();
      // Upsert: insertar o reemplazar si ya existe para el restaurant_id
      await _db.rawQuery(
        '''INSERT OR REPLACE INTO $_table
           (restaurant_id, slogan, descripcion, telefono, whatsapp, direccion,
            horarios, facebook, instagram, mostrar_boton_menu,
            mostrar_boton_reservas, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          map['restaurant_id'],
          map['slogan'],
          map['descripcion'],
          map['telefono'],
          map['whatsapp'],
          map['direccion'],
          map['horarios'],
          map['facebook'],
          map['instagram'],
          map['mostrar_boton_menu'],
          map['mostrar_boton_reservas'],
          map['updated_at'],
        ],
      );
      return config;
    } catch (e) {
      throw DatabaseException(
        message: 'Error al guardar configuración pública: $e',
      );
    }
  }
}
