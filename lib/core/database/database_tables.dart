/// Definición de todas las tablas de la base de datos.
///
/// Centraliza los scripts SQL de creación para facilitar
/// mantenimiento y migraciones futuras.
///
/// IMPORTANTE: Todas las tablas incluyen [restaurant_id]
/// para soportar multi-restaurante desde el inicio.
class DatabaseTables {
  DatabaseTables._();

  /// Script de creación de todas las tablas.
  static List<String> get createTableStatements => [
    _createRestaurantsTable,
    _createUsersTable,
    _createMesasTable,
    _createCategoriasTable,
    _createProductosTable,
    _createVariantesTable,
    _createPedidosTable,
    _createPedidoItemsTable,
    _createVentasTable,
    _createVentaDetallesTable,
    _createLlamadosTable,
    _createCotizacionesTable,
    _createCotizacionItemsTable,
    _createReservasTable,
    _createIngredientesTable,
    _createProductoIngredientesTable,
    _createSyncLogTable,
    _createSriSecuencialesTable,
    _createPublicConfigTable,
    _createClientesTable,
  ];

  // ── Restaurantes ───────────────────────────────────────────────────
  static const String _createRestaurantsTable = '''
    CREATE TABLE IF NOT EXISTS restaurantes (
      id TEXT PRIMARY KEY,
      nombre TEXT NOT NULL,
      direccion TEXT,
      telefono TEXT,
      logo_url TEXT,
      configuracion TEXT,
      activo INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''';

  // ── Usuarios ───────────────────────────────────────────────────────
  static const String _createUsersTable = '''
    CREATE TABLE IF NOT EXISTS usuarios (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      email TEXT,
      pin TEXT,
      rol TEXT NOT NULL,
      activo INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id)
    )
  ''';

  // ── Mesas ──────────────────────────────────────────────────────────
  static const String _createMesasTable = '''
    CREATE TABLE IF NOT EXISTS mesas (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      numero INTEGER NOT NULL,
      nombre TEXT,
      capacidad INTEGER NOT NULL DEFAULT 4,
      estado TEXT NOT NULL DEFAULT 'libre',
      mesa_union_id TEXT,
      nombre_reserva TEXT,
      posicion_x REAL DEFAULT 0,
      posicion_y REAL DEFAULT 0,
      activo INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id)
    )
  ''';

  // ── Categorías del Menú ────────────────────────────────────────────
  static const String _createCategoriasTable = '''
    CREATE TABLE IF NOT EXISTS categorias (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      descripcion TEXT,
      orden INTEGER NOT NULL DEFAULT 0,
      activo INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id)
    )
  ''';

  // ── Productos ──────────────────────────────────────────────────────
  static const String _createProductosTable = '''
    CREATE TABLE IF NOT EXISTS productos (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      categoria_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      descripcion TEXT,
      precio REAL NOT NULL,
      imagen_url TEXT,
      disponible INTEGER NOT NULL DEFAULT 1,
      activo INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id),
      FOREIGN KEY (categoria_id) REFERENCES categorias(id)
    )
  ''';

  // ── Variantes de Producto ──────────────────────────────────────────
  static const String _createVariantesTable = '''
    CREATE TABLE IF NOT EXISTS variantes (
      id TEXT PRIMARY KEY,
      producto_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      precio REAL NOT NULL,
      activo INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (producto_id) REFERENCES productos(id)
    )
  ''';

  // ── Pedidos ────────────────────────────────────────────────────────
  static const String _createPedidosTable = '''
    CREATE TABLE IF NOT EXISTS pedidos (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      mesa_id TEXT,
      mesero_id TEXT,
      estado TEXT NOT NULL DEFAULT 'creado',
      observaciones TEXT,
      total REAL NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id),
      FOREIGN KEY (mesa_id) REFERENCES mesas(id),
      FOREIGN KEY (mesero_id) REFERENCES usuarios(id)
    )
  ''';

  // ── Items de Pedido ────────────────────────────────────────────────
  static const String _createPedidoItemsTable = '''
    CREATE TABLE IF NOT EXISTS pedido_items (
      id TEXT PRIMARY KEY,
      pedido_id TEXT NOT NULL,
      producto_id TEXT NOT NULL,
      variante_id TEXT,
      cantidad INTEGER NOT NULL DEFAULT 1,
      precio_unitario REAL NOT NULL,
      observaciones TEXT,
      estado TEXT NOT NULL DEFAULT 'creado',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (pedido_id) REFERENCES pedidos(id),
      FOREIGN KEY (producto_id) REFERENCES productos(id),
      FOREIGN KEY (variante_id) REFERENCES variantes(id)
    )
  ''';

  // ── Ventas (Caja) ─────────────────────────────────────────────────
  static const String _createVentasTable = '''
    CREATE TABLE IF NOT EXISTS ventas (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      pedido_id TEXT NOT NULL,
      cajero_id TEXT,
      cliente_nombre TEXT,
      cliente_email TEXT,
      cliente_identificacion TEXT,
      metodo_pago TEXT NOT NULL,
      tipo_comprobante TEXT NOT NULL DEFAULT 'ticket',
      sri_estado TEXT NOT NULL DEFAULT 'no_aplica',
      subtotal REAL NOT NULL,
      impuestos REAL NOT NULL DEFAULT 0,
      total REAL NOT NULL,
      descripcion_pago TEXT,
      sri_clave_acceso TEXT,
      sri_mensaje TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id),
      FOREIGN KEY (pedido_id) REFERENCES pedidos(id),
      FOREIGN KEY (cajero_id) REFERENCES usuarios(id)
    )
  ''';

  // ── Detalle de Ventas ──────────────────────────────────────────────
  static const String _createVentaDetallesTable = '''
    CREATE TABLE IF NOT EXISTS venta_detalles (
      id TEXT PRIMARY KEY,
      venta_id TEXT NOT NULL,
      producto_id TEXT NOT NULL,
      variante_id TEXT,
      cantidad INTEGER NOT NULL,
      precio_unitario REAL NOT NULL,
      subtotal REAL NOT NULL,
      FOREIGN KEY (venta_id) REFERENCES ventas(id),
      FOREIGN KEY (producto_id) REFERENCES productos(id)
    )
  ''';

  // ── Llamados a Mesero ─────────────────────────────────────────────
  static const String _createLlamadosTable = '''
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
  ''';

  // ── Cotizaciones ─────────────────────────────────────────────────
  static const String _createCotizacionesTable = '''
    CREATE TABLE IF NOT EXISTS cotizaciones (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      mesa_id TEXT,
      cliente_nombre TEXT NOT NULL,
      cliente_telefono TEXT NOT NULL,
      cliente_email TEXT NOT NULL,
      estado TEXT NOT NULL DEFAULT 'pendiente',
      reserva_local INTEGER NOT NULL DEFAULT 0,
      personas INTEGER,
      fecha_evento TEXT,
      comida_preferida TEXT,
      notas TEXT,
      subtotal REAL NOT NULL,
      total REAL NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id),
      FOREIGN KEY (mesa_id) REFERENCES mesas(id)
    )
  ''';

  static const String _createCotizacionItemsTable = '''
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
  ''';

  // ── Reservaciones ────────────────────────────────────────────────
  static const String _createReservasTable = '''
    CREATE TABLE IF NOT EXISTS reservaciones (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      tipo TEXT NOT NULL,
      mesa_id TEXT,
      fecha TEXT NOT NULL,
      hora_inicio TEXT NOT NULL DEFAULT '19:00',
      hora_fin TEXT NOT NULL DEFAULT '20:30',
      numero_personas INTEGER NOT NULL DEFAULT 2,
      estado TEXT NOT NULL DEFAULT 'pendiente',
      tipo_evento TEXT,
      cliente_nombre TEXT NOT NULL,
      cliente_telefono TEXT NOT NULL,
      cliente_email TEXT NOT NULL,
      notas TEXT,
      requerimientos TEXT,
      nombre_local_evento TEXT,
      manteles TEXT,
      color_manteleria TEXT,
      precio_estimado REAL,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id),
      FOREIGN KEY (mesa_id) REFERENCES mesas(id)
    )
  ''';

  // ── Ingredientes (Inventario Opcional) ─────────────────────────────
  static const String _createIngredientesTable = '''
    CREATE TABLE IF NOT EXISTS ingredientes (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      unidad_medida TEXT NOT NULL,
      stock_actual REAL NOT NULL DEFAULT 0,
      stock_minimo REAL NOT NULL DEFAULT 0,
      costo_unitario REAL DEFAULT 0,
      activo INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (restaurant_id) REFERENCES restaurantes(id)
    )
  ''';

  // ── Relación Producto-Ingrediente ──────────────────────────────────
  static const String _createProductoIngredientesTable = '''
    CREATE TABLE IF NOT EXISTS producto_ingredientes (
      id TEXT PRIMARY KEY,
      producto_id TEXT NOT NULL,
      ingrediente_id TEXT NOT NULL,
      cantidad_requerida REAL NOT NULL,
      FOREIGN KEY (producto_id) REFERENCES productos(id),
      FOREIGN KEY (ingrediente_id) REFERENCES ingredientes(id)
    )
  ''';

  // ── Secuenciales SRI ──────────────────────────────────────────────
  static const String _createSriSecuencialesTable = '''
    CREATE TABLE IF NOT EXISTS sri_secuenciales (
      id TEXT NOT NULL,
      restaurant_id TEXT NOT NULL,
      ultimo_secuencial INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (id, restaurant_id)
    )
  ''';

  // ── Configuración de Página Pública ─────────────────────────────────
  static const String _createPublicConfigTable = '''
    CREATE TABLE IF NOT EXISTS public_config (
      restaurant_id TEXT PRIMARY KEY,
      slogan TEXT NOT NULL DEFAULT '',
      descripcion TEXT NOT NULL DEFAULT '',
      telefono TEXT NOT NULL DEFAULT '',
      whatsapp TEXT NOT NULL DEFAULT '',
      direccion TEXT NOT NULL DEFAULT '',
      horarios TEXT NOT NULL DEFAULT '[]',
      facebook TEXT NOT NULL DEFAULT '',
      instagram TEXT NOT NULL DEFAULT '',
      mostrar_boton_menu INTEGER NOT NULL DEFAULT 1,
      mostrar_boton_reservas INTEGER NOT NULL DEFAULT 1,
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      exp1_titulo TEXT NOT NULL DEFAULT 'Gastronomía Auténtica',
      exp1_desc TEXT NOT NULL DEFAULT 'Recetas tradicionales elaboradas con ingredientes frescos de temporada.',
      exp2_titulo TEXT NOT NULL DEFAULT 'Ambiente Familiar',
      exp2_desc TEXT NOT NULL DEFAULT 'Un espacio cálido y acogedor ideal para toda ocasión especial.',
      exp3_titulo TEXT NOT NULL DEFAULT 'Servicio Excepcional',
      exp3_desc TEXT NOT NULL DEFAULT 'Atención personalizada que supera las expectativas de cada visita.',
      titulo_menu TEXT NOT NULL DEFAULT 'Nuestro Menú',
      subtitulo_menu TEXT NOT NULL DEFAULT 'Platos elaborados con ingredientes frescos de temporada',
      titulo_reservas TEXT NOT NULL DEFAULT 'Reserva tu Mesa',
      subtitulo_reservas TEXT NOT NULL DEFAULT 'Asegura tu lugar para una experiencia gastronómica especial',
      map_url TEXT NOT NULL DEFAULT 'https://maps.app.goo.gl/KL4cFAxBxDDKmgaS9',
      map_lat REAL NOT NULL DEFAULT -2.9721229,
      map_lng REAL NOT NULL DEFAULT -78.437791,
      nombre_negocio TEXT NOT NULL DEFAULT '',
      propietario TEXT NOT NULL DEFAULT '',
      email_contacto TEXT NOT NULL DEFAULT '',
      email_secundario TEXT NOT NULL DEFAULT '',
      telefono_secundario TEXT NOT NULL DEFAULT '',
      logo_url TEXT NOT NULL DEFAULT ''
    )
  ''';

  // ── Clientes ──────────────────────────────────────────────────────
  static const String _createClientesTable = '''
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
  ''';

  // ── Log de Sincronización ──────────────────────────────────────────
  static const String _createSyncLogTable = '''
    CREATE TABLE IF NOT EXISTS sync_log (
      id TEXT PRIMARY KEY,
      tabla TEXT NOT NULL,
      registro_id TEXT NOT NULL,
      operacion TEXT NOT NULL,
      datos TEXT,
      sincronizado INTEGER NOT NULL DEFAULT 0,
      intentos INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''';
}
