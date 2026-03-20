import 'package:get_it/get_it.dart';
import 'package:restaurant_app/core/database/database_helper.dart';
import 'package:restaurant_app/core/sync/sync_manager.dart';
import 'package:restaurant_app/features/auth/presentation/providers/auth_provider.dart';

// ── Mesas ────────────────────────────────────────────────────────────
import 'package:restaurant_app/features/mesas/data/datasources/mesa_local_datasource.dart';
import 'package:restaurant_app/features/mesas/data/datasources/mesa_local_datasource_impl.dart';
import 'package:restaurant_app/features/mesas/data/datasources/llamado_local_datasource.dart';
import 'package:restaurant_app/features/mesas/data/datasources/llamado_local_datasource_impl.dart';
import 'package:restaurant_app/features/mesas/data/repositories/mesa_repository_impl.dart';
import 'package:restaurant_app/features/mesas/data/repositories/llamado_repository_impl.dart';
import 'package:restaurant_app/features/mesas/domain/repositories/mesa_repository.dart';
import 'package:restaurant_app/features/mesas/domain/repositories/llamado_repository.dart';
import 'package:restaurant_app/features/mesas/domain/usecases/mesa_usecases.dart';
import 'package:restaurant_app/features/mesas/domain/usecases/llamado_usecases.dart';

// ── Pedidos ──────────────────────────────────────────────────────────
import 'package:restaurant_app/features/pedidos/data/datasources/pedido_local_datasource.dart';
import 'package:restaurant_app/features/pedidos/data/datasources/pedido_local_datasource_impl.dart';
import 'package:restaurant_app/features/pedidos/data/repositories/pedido_repository_impl.dart';
import 'package:restaurant_app/features/pedidos/domain/repositories/pedido_repository.dart';
import 'package:restaurant_app/features/pedidos/domain/usecases/pedido_usecases.dart';

// ── Menú ─────────────────────────────────────────────────────────────
import 'package:restaurant_app/features/menu/data/datasources/menu_local_datasource.dart';
import 'package:restaurant_app/features/menu/data/datasources/menu_local_datasource_impl.dart';
import 'package:restaurant_app/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:restaurant_app/features/menu/domain/repositories/menu_repository.dart';
import 'package:restaurant_app/features/menu/domain/usecases/menu_usecases.dart';

// ── Cotizaciones ───────────────────────────────────────────────────
import 'package:restaurant_app/features/cotizaciones/data/datasources/cotizacion_local_datasource.dart';
import 'package:restaurant_app/features/cotizaciones/data/datasources/cotizacion_local_datasource_impl.dart';
import 'package:restaurant_app/features/cotizaciones/data/repositories/cotizacion_repository_impl.dart';
import 'package:restaurant_app/features/cotizaciones/domain/repositories/cotizacion_repository.dart';
import 'package:restaurant_app/features/cotizaciones/domain/usecases/cotizacion_usecases.dart';

// ── Reservaciones ──────────────────────────────────────────────────
import 'package:restaurant_app/features/reservaciones/data/datasources/reserva_local_datasource.dart';
import 'package:restaurant_app/features/reservaciones/data/datasources/reserva_local_datasource_impl.dart';
import 'package:restaurant_app/features/reservaciones/data/repositories/reserva_repository_impl.dart';
import 'package:restaurant_app/features/reservaciones/domain/repositories/reserva_repository.dart';
import 'package:restaurant_app/features/reservaciones/domain/usecases/reserva_usecases.dart';

// ── Caja ─────────────────────────────────────────────────────────────
import 'package:restaurant_app/features/caja/data/datasources/caja_local_datasource.dart';
import 'package:restaurant_app/features/caja/data/datasources/caja_local_datasource_impl.dart';
import 'package:restaurant_app/features/caja/data/repositories/caja_repository_impl.dart';
import 'package:restaurant_app/features/caja/domain/repositories/caja_repository.dart';
import 'package:restaurant_app/features/caja/domain/usecases/caja_usecases.dart';

// ── Reportes ──────────────────────────────────────────────────────────
import 'package:restaurant_app/features/reportes/data/datasources/reportes_local_datasource.dart';
import 'package:restaurant_app/features/reportes/data/datasources/reportes_local_datasource_impl.dart';
import 'package:restaurant_app/features/reportes/data/repositories/reportes_repository_impl.dart';
import 'package:restaurant_app/features/reportes/domain/repositories/reportes_repository.dart';
import 'package:restaurant_app/features/reportes/domain/usecases/reportes_usecases.dart';

// ── Usuarios ─────────────────────────────────────────────────────────
import 'package:restaurant_app/features/usuarios/data/datasources/usuario_local_datasource.dart';
import 'package:restaurant_app/features/usuarios/data/datasources/usuario_local_datasource_impl.dart';
import 'package:restaurant_app/features/usuarios/data/repositories/usuario_repository_impl.dart';
import 'package:restaurant_app/features/usuarios/domain/repositories/usuario_repository.dart';
import 'package:restaurant_app/features/usuarios/domain/usecases/usuario_usecases.dart';

/// Service Locator global.
///
/// Usa [GetIt] para inyección de dependencias.
/// Aquí se registran todas las dependencias del sistema:
/// - Database helpers
/// - Repositorios
/// - Casos de uso
/// - Managers
final sl = GetIt.instance;

/// Inicializa todas las dependencias de la aplicación.
///
/// Se llama una vez al inicio en [main.dart].
Future<void> initDependencies() async {
  // ── Core ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  sl.registerLazySingleton<SyncManager>(() => SyncManager());
  sl.registerLazySingleton<AuthChangeNotifier>(() => AuthChangeNotifier());

  // ── Features ─────────────────────────────────────────────────────
  _initMesas();
  _initPedidos();
  _initMenu();
  _initCotizaciones();
  _initReservas();
  _initCaja();
  _initReportes();
  _initUsuarios();

  // Inicializar la base de datos
  await sl<DatabaseHelper>().database;
}

/// Registra las dependencias del módulo de Mesas.
void _initMesas() {
  // DataSources
  sl.registerLazySingleton<MesaLocalDataSource>(
    () => MesaLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<LlamadoLocalDataSource>(
    () => LlamadoLocalDataSourceImpl(dbHelper: sl()),
  );
  // Repositories
  sl.registerLazySingleton<MesaRepository>(
    () => MesaRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<LlamadoRepository>(
    () => LlamadoRepositoryImpl(dataSource: sl()),
  );
  // Use Cases
  sl.registerLazySingleton(() => GetMesas(sl()));
  sl.registerLazySingleton(() => GetMesaById(sl()));
  sl.registerLazySingleton(() => CreateMesa(sl()));
  sl.registerLazySingleton(() => UpdateMesa(sl()));
  sl.registerLazySingleton(() => DeleteMesa(sl()));
  sl.registerLazySingleton(() => UpdateEstadoMesa(sl()));
  sl.registerLazySingleton(() => GetNextNumeroMesa(sl()));
  sl.registerLazySingleton(() => CreateLlamado(sl()));
  sl.registerLazySingleton(() => GetLlamadosPendientes(sl()));
  sl.registerLazySingleton(() => MarcarLlamadoAtendido(sl()));
}

/// Registra las dependencias del módulo de Pedidos.
void _initPedidos() {
  // DataSources
  sl.registerLazySingleton<PedidoLocalDataSource>(
    () => PedidoLocalDataSourceImpl(dbHelper: sl()),
  );
  // Repositories
  sl.registerLazySingleton<PedidoRepository>(
    () => PedidoRepositoryImpl(localDataSource: sl()),
  );
  // Use Cases - Pedidos
  sl.registerLazySingleton(() => GetPedidos(sl()));
  sl.registerLazySingleton(() => GetPedidosActivos(sl()));
  sl.registerLazySingleton(() => GetPedidosByMesa(sl()));
  sl.registerLazySingleton(() => GetPedidoById(sl()));
  sl.registerLazySingleton(() => CreatePedido(sl()));
  sl.registerLazySingleton(() => UpdatePedido(sl()));
  sl.registerLazySingleton(() => UpdateEstadoPedido(sl()));
  sl.registerLazySingleton(() => DeletePedido(sl()));
  // Use Cases - Pedido Items
  sl.registerLazySingleton(() => GetItemsByPedido(sl()));
  sl.registerLazySingleton(() => AddPedidoItem(sl()));
  sl.registerLazySingleton(() => UpdatePedidoItem(sl()));
  sl.registerLazySingleton(() => DeletePedidoItem(sl()));
  sl.registerLazySingleton(() => UpdateEstadoItem(sl()));
}

/// Registra las dependencias del módulo de Menú.
void _initMenu() {
  // DataSources
  sl.registerLazySingleton<MenuLocalDataSource>(
    () => MenuLocalDataSourceImpl(dbHelper: sl()),
  );
  // Repositories
  sl.registerLazySingleton<MenuRepository>(
    () => MenuRepositoryImpl(dataSource: sl()),
  );
  // Use Cases - Categorías
  sl.registerLazySingleton(() => GetCategorias(sl()));
  sl.registerLazySingleton(() => GetCategoriaById(sl()));
  sl.registerLazySingleton(() => CreateCategoria(sl()));
  sl.registerLazySingleton(() => UpdateCategoria(sl()));
  sl.registerLazySingleton(() => DeleteCategoria(sl()));
  sl.registerLazySingleton(() => ReordenarCategorias(sl()));
  // Use Cases - Productos
  sl.registerLazySingleton(() => GetProductos(sl()));
  sl.registerLazySingleton(() => GetProductosByCategoria(sl()));
  sl.registerLazySingleton(() => GetProductoById(sl()));
  sl.registerLazySingleton(() => CreateProducto(sl()));
  sl.registerLazySingleton(() => UpdateProducto(sl()));
  sl.registerLazySingleton(() => DeleteProducto(sl()));
  sl.registerLazySingleton(() => ToggleDisponibilidad(sl()));
  // Use Cases - Variantes
  sl.registerLazySingleton(() => GetVariantesByProducto(sl()));
  sl.registerLazySingleton(() => CreateVariante(sl()));
  sl.registerLazySingleton(() => UpdateVariante(sl()));
  sl.registerLazySingleton(() => DeleteVariante(sl()));
}

/// Registra las dependencias del módulo de Cotizaciones.
void _initCotizaciones() {
  sl.registerLazySingleton<CotizacionLocalDataSource>(
    () => CotizacionLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<CotizacionRepository>(
    () => CotizacionRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => CreateCotizacion(sl()));
  sl.registerLazySingleton(() => GetCotizaciones(sl()));
  sl.registerLazySingleton(() => UpdateCotizacionEstado(sl()));
}

/// Registra las dependencias del módulo de Reservaciones.
void _initReservas() {
  sl.registerLazySingleton<ReservaLocalDataSource>(
    () => ReservaLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<ReservaRepository>(
    () => ReservaRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => CreateReserva(sl()));
  sl.registerLazySingleton(() => GetReservasByMonth(sl()));
  sl.registerLazySingleton(() => GetReservasByDate(sl()));
}

/// Registra las dependencias del módulo de Caja.
void _initCaja() {
  // DataSources
  sl.registerLazySingleton<CajaLocalDataSource>(
    () => CajaLocalDataSourceImpl(dbHelper: sl()),
  );
  // Repositories
  sl.registerLazySingleton<CajaRepository>(
    () => CajaRepositoryImpl(dataSource: sl()),
  );
  // Use Cases
  sl.registerLazySingleton(() => RegistrarVenta(sl()));
  sl.registerLazySingleton(() => GetVentas(sl()));
  sl.registerLazySingleton(() => GetVentasByFecha(sl()));
  sl.registerLazySingleton(() => GetVentaById(sl()));
  sl.registerLazySingleton(() => GetVentaByPedido(sl()));
  sl.registerLazySingleton(() => GetPedidosParaCobrar(sl()));
}

/// Registra las dependencias del módulo de Reportes.
void _initReportes() {
  // DataSources
  sl.registerLazySingleton<ReportesLocalDataSource>(
    () => ReportesLocalDataSourceImpl(dbHelper: sl()),
  );
  // Repositories
  sl.registerLazySingleton<ReportesRepository>(
    () => ReportesRepositoryImpl(dataSource: sl()),
  );
  // Use Cases
  sl.registerLazySingleton(() => GetResumenVentas(sl()));
  sl.registerLazySingleton(() => GetVentasPorDia(sl()));
  sl.registerLazySingleton(() => GetTopProductos(sl()));
  sl.registerLazySingleton(() => GetVentasPorMetodo(sl()));
  sl.registerLazySingleton(() => GetVentasPorMesero(sl()));
}

/// Registra las dependencias del módulo de Usuarios.
void _initUsuarios() {
  sl.registerLazySingleton<UsuarioLocalDataSource>(
    () => UsuarioLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<UsuarioRepository>(
    () => UsuarioRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetUsuarios(sl()));
  sl.registerLazySingleton(() => GetUsuarioById(sl()));
  sl.registerLazySingleton(() => GetUsuariosByRol(sl()));
  sl.registerLazySingleton(() => CreateUsuario(sl()));
  sl.registerLazySingleton(() => UpdateUsuario(sl()));
  sl.registerLazySingleton(() => DeleteUsuario(sl()));
  sl.registerLazySingleton(() => VerificarPin(sl()));
}
