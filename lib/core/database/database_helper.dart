import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/database/database_tables.dart';
import 'package:restaurant_app/core/utils/pin_hasher.dart';
import 'package:restaurant_app/services/database_location_service.dart';

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
    if (kIsWeb) {
      final webFactory = databaseFactoryFfiWeb;
      return await webFactory.openDatabase(
        AppConstants.databaseName,
        options: OpenDatabaseOptions(
          version: AppConstants.databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
        ),
      );
    }

    final dbPath = await DatabaseLocationService.getDatabasePath();

    return await openDatabase(
      dbPath,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
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

  /// Inserta usuarios de prueba con PINs hasheados.
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
        'pin': PinHasher.hash(pin), // nunca guardar en texto plano
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
    if (oldVersion < 10) {
      // v10: metadatos de facturación/SRI en ventas
      await db.execute(
        'ALTER TABLE ventas ADD COLUMN cliente_identificacion TEXT',
      );
      await db.execute(
        "ALTER TABLE ventas ADD COLUMN tipo_comprobante TEXT NOT NULL DEFAULT 'ticket'",
      );
      await db.execute(
        "ALTER TABLE ventas ADD COLUMN sri_estado TEXT NOT NULL DEFAULT 'no_aplica'",
      );
      await db.execute('ALTER TABLE ventas ADD COLUMN sri_clave_acceso TEXT');
      await db.execute('ALTER TABLE ventas ADD COLUMN sri_mensaje TEXT');
    }
    if (oldVersion < 12) {
      // v12: tabla de secuenciales SRI
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sri_secuenciales (
          id TEXT NOT NULL,
          restaurant_id TEXT NOT NULL,
          ultimo_secuencial INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (id, restaurant_id)
        )
      ''');
    }
    if (oldVersion < 11) {
      // v11: datos básicos de horario/estado para reservaciones
      await db.execute(
        "ALTER TABLE reservaciones ADD COLUMN hora_inicio TEXT NOT NULL DEFAULT '19:00'",
      );
      await db.execute(
        "ALTER TABLE reservaciones ADD COLUMN hora_fin TEXT NOT NULL DEFAULT '20:30'",
      );
      await db.execute(
        'ALTER TABLE reservaciones ADD COLUMN numero_personas INTEGER NOT NULL DEFAULT 2',
      );
      await db.execute(
        "ALTER TABLE reservaciones ADD COLUMN estado TEXT NOT NULL DEFAULT 'pendiente'",
      );
      await db.execute('ALTER TABLE reservaciones ADD COLUMN tipo_evento TEXT');
      await db.execute(
        'ALTER TABLE reservaciones ADD COLUMN requerimientos TEXT',
      );
    }
    if (oldVersion < 13) {
      // v13: campos de texto editables en public_config
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN exp1_titulo TEXT NOT NULL DEFAULT 'Gastronomía Auténtica'",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN exp1_desc TEXT NOT NULL DEFAULT 'Recetas tradicionales elaboradas con ingredientes frescos de temporada.'",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN exp2_titulo TEXT NOT NULL DEFAULT 'Ambiente Familiar'",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN exp2_desc TEXT NOT NULL DEFAULT 'Un espacio cálido y acogedor ideal para toda ocasión especial.'",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN exp3_titulo TEXT NOT NULL DEFAULT 'Servicio Excepcional'",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN exp3_desc TEXT NOT NULL DEFAULT 'Atención personalizada que supera las expectativas de cada visita.'",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN titulo_menu TEXT NOT NULL DEFAULT 'Nuestro Menú'",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN subtitulo_menu TEXT NOT NULL DEFAULT 'Platos elaborados con ingredientes frescos de temporada'",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN titulo_reservas TEXT NOT NULL DEFAULT 'Reserva tu Mesa'",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN subtitulo_reservas TEXT NOT NULL DEFAULT 'Asegura tu lugar para una experiencia gastronómica especial'",
      );
    }

    if (oldVersion < 16) {
      // v16: hashear PINs de usuarios que están en texto plano
      final users = await db.query('usuarios', columns: ['id', 'pin']);
      for (final user in users) {
        final pin = user['pin'] as String?;
        if (pin != null && !PinHasher.isHashed(pin)) {
          await db.update(
            'usuarios',
            {'pin': PinHasher.hash(pin)},
            where: 'id = ?',
            whereArgs: [user['id']],
          );
        }
      }
    }
    if (oldVersion < 15) {
      // v15: tabla de clientes con cédula como PK
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clientes (
          cedula TEXT PRIMARY KEY,
          restaurant_id TEXT NOT NULL,
          nombre TEXT NOT NULL,
          apellido TEXT,
          telefono TEXT,
          email TEXT,
          direccion TEXT,
          fecha_nacimiento TEXT,
          notas TEXT,
          activo INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          updated_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id)
        )
      ''');
    }
    if (oldVersion < 14) {
      // v14: mapa de ubicación en public_config
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN map_url TEXT NOT NULL DEFAULT 'https://maps.app.goo.gl/KL4cFAxBxDDKmgaS9'",
      );
      await db.execute(
        'ALTER TABLE public_config ADD COLUMN map_lat REAL NOT NULL DEFAULT -2.9721229',
      );
      await db.execute(
        'ALTER TABLE public_config ADD COLUMN map_lng REAL NOT NULL DEFAULT -78.437791',
      );
    }

    if (oldVersion < 17) {
      // v17a: campos de mantelería y precio en reservaciones
      await db.execute(
        'ALTER TABLE reservaciones ADD COLUMN nombre_local_evento TEXT',
      );
      await db.execute('ALTER TABLE reservaciones ADD COLUMN manteles TEXT');
      await db.execute(
        'ALTER TABLE reservaciones ADD COLUMN color_manteleria TEXT',
      );
      await db.execute(
        'ALTER TABLE reservaciones ADD COLUMN precio_estimado REAL',
      );

      // v17b: datos corporativos en public_config
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN nombre_negocio TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN propietario TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN email_contacto TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN email_secundario TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN telefono_secundario TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE public_config ADD COLUMN logo_url TEXT NOT NULL DEFAULT ''",
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
