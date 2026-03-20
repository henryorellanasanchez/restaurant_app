import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/database/database_tables.dart';

/// Helper singleton para gestionar la base de datos SQLite.
///
/// Implementa patrón Singleton para garantizar una única instancia
/// de la conexión a la base de datos en toda la aplicación.
///
/// Usa [sqflite_common_ffi_web] para soporte web.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  /// Obtiene la instancia de la base de datos.
  /// Si no existe, la crea e inicializa las tablas.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos SQLite.
  Future<Database> _initDatabase() async {
    // Usar la factory para web
    final databaseFactory = databaseFactoryFfiWeb;

    final db = await databaseFactory.openDatabase(
      AppConstants.databaseName,
      options: OpenDatabaseOptions(
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      ),
    );

    return db;
  }

  /// Crea todas las tablas en la primera ejecución.
  Future<void> _onCreate(Database db, int version) async {
    for (final statement in DatabaseTables.createTableStatements) {
      await db.execute(statement);
    }

    final now = DateTime.now().toIso8601String();

    // ── Restaurante La Peña ──────────────────────────────────────
    await db.insert('restaurantes', {
      'id': AppConstants.defaultRestaurantId,
      'nombre': AppConstants.appFullName,
      'activo': 1,
      'created_at': now,
      'updated_at': now,
    });

    // ── 10 Mesas ─────────────────────────────────────────────────
    for (int i = 1; i <= 10; i++) {
      await db.insert('mesas', {
        'id': 'mesa_la_pena_${i.toString().padLeft(2, '0')}',
        'restaurant_id': AppConstants.defaultRestaurantId,
        'numero': i,
        'nombre': 'Mesa $i',
        'capacidad': 4,
        'estado': 'libre',
        'posicion_x': 0.0,
        'posicion_y': 0.0,
        'activo': 1,
        'created_at': now,
        'updated_at': now,
      });
    }

    // ── 6 Categorías del Menú ────────────────────────────────────
    final categorias = [
      ('cat_lp_01', 'Entradas', 'Aperitivos y entradas de la casa', 1),
      ('cat_lp_02', 'Platos Principales', 'Especialidades del chef', 2),
      ('cat_lp_03', 'Acompañamientos', 'Guarniciones y acompañamientos', 3),
      ('cat_lp_04', 'Comidas Ligeras', 'Snacks y bocadillos', 4),
      ('cat_lp_05', 'Bebidas', 'Colas, cervezas y bebidas frías', 5),
      (
        'cat_lp_06',
        'Jugos y Refrescos',
        'Jugos naturales y bebidas especiales',
        6,
      ),
    ];

    for (final (id, nombre, descripcion, orden) in categorias) {
      await db.insert('categorias', {
        'id': id,
        'restaurant_id': AppConstants.defaultRestaurantId,
        'nombre': nombre,
        'descripcion': descripcion,
        'orden': orden,
        'activo': 1,
        'created_at': now,
        'updated_at': now,
      });
    }

    // ── Usuarios de prueba ───────────────────────────────────────
    await _insertSeedUsers(db, now);
  }

  /// Inserta usuarios de prueba con PINs conocidos.
  Future<void> _insertSeedUsers(Database db, String now) async {
    final users = [
      ('usr_admin_01', 'Administrador', 'administrador', '1111'),
      ('usr_cajero_01', 'Cajero', 'cajero', '2222'),
      ('usr_mesero_01', 'Mesero', 'mesero', '3333'),
      ('usr_cocina_01', 'Cocina', 'cocina', '4444'),
    ];
    for (final (id, nombre, rol, pin) in users) {
      await db.insert('usuarios', {
        'id': id,
        'restaurant_id': AppConstants.defaultRestaurantId,
        'nombre': nombre,
        'pin': pin,
        'rol': rol,
        'activo': 1,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  /// Maneja migraciones entre versiones de la base de datos.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: agregar columna nombre_reserva a mesas
      await db.execute('ALTER TABLE mesas ADD COLUMN nombre_reserva TEXT');
    }
    if (oldVersion < 3) {
      // v3: insertar usuarios de prueba si no existen
      final now = DateTime.now().toIso8601String();
      await _insertSeedUsers(db, now);
    }
    if (oldVersion < 4) {
      // v4: agregar datos de cliente a ventas
      await db.execute('ALTER TABLE ventas ADD COLUMN cliente_nombre TEXT');
      await db.execute('ALTER TABLE ventas ADD COLUMN cliente_email TEXT');
    }
    if (oldVersion < 5) {
      // v5: tabla de llamados a mesero
      await db.execute('''
        CREATE TABLE IF NOT EXISTS llamados_mesero (
          id TEXT PRIMARY KEY,
          restaurant_id TEXT NOT NULL,
          mesa_id TEXT,
          estado TEXT NOT NULL DEFAULT 'pendiente',
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          atendido_at TEXT,
          FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id),
          FOREIGN KEY (mesa_id) REFERENCES mesas(id)
        )
      ''');
    }
    if (oldVersion < 6) {
      // v6: tablas de cotizaciones
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cotizaciones (
          id TEXT PRIMARY KEY,
          restaurant_id TEXT NOT NULL,
          mesa_id TEXT,
          cliente_nombre TEXT NOT NULL,
          cliente_telefono TEXT NOT NULL,
          cliente_email TEXT NOT NULL,
          subtotal REAL NOT NULL,
          total REAL NOT NULL,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id),
          FOREIGN KEY (mesa_id) REFERENCES mesas(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cotizacion_items (
          id TEXT PRIMARY KEY,
          cotizacion_id TEXT NOT NULL,
          producto_id TEXT NOT NULL,
          producto_nombre TEXT NOT NULL,
          cantidad INTEGER NOT NULL,
          precio_unitario REAL NOT NULL,
          subtotal REAL NOT NULL,
          FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones(id),
          FOREIGN KEY (producto_id) REFERENCES productos(id)
        )
      ''');
    }
    if (oldVersion < 7) {
      // v7: tabla de reservaciones
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reservaciones (
          id TEXT PRIMARY KEY,
          restaurant_id TEXT NOT NULL,
          tipo TEXT NOT NULL,
          mesa_id TEXT,
          fecha TEXT NOT NULL,
          cliente_nombre TEXT NOT NULL,
          cliente_telefono TEXT NOT NULL,
          cliente_email TEXT NOT NULL,
          notas TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id),
          FOREIGN KEY (mesa_id) REFERENCES mesas(id)
        )
      ''');
    }
    if (oldVersion < 8) {
      // v8: campos adicionales en cotizaciones
      await db.execute(
        'ALTER TABLE cotizaciones ADD COLUMN reserva_local INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE cotizaciones ADD COLUMN personas INTEGER');
      await db.execute('ALTER TABLE cotizaciones ADD COLUMN fecha_evento TEXT');
      await db.execute(
        'ALTER TABLE cotizaciones ADD COLUMN comida_preferida TEXT',
      );
      await db.execute('ALTER TABLE cotizaciones ADD COLUMN notas TEXT');
    }
    if (oldVersion < 9) {
      // v9: estado de cotizacion
      await db.execute(
        "ALTER TABLE cotizaciones ADD COLUMN estado TEXT NOT NULL DEFAULT 'pendiente'",
      );
    }
  }

  /// Se ejecuta cada vez que se abre la base de datos.
  Future<void> _onOpen(Database db) async {
    // Habilitar foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ── Métodos CRUD Genéricos ─────────────────────────────────────────

  /// Inserta un registro en la tabla indicada.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Obtiene todos los registros de una tabla (con filtro opcional).
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  /// Actualiza registros en una tabla.
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.update(table, data, where: where, whereArgs: whereArgs);
  }

  /// Elimina registros de una tabla.
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Ejecuta una consulta SQL directa.
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  /// Ejecuta una operación dentro de una transacción.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  /// Cierra la conexión a la base de datos.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
