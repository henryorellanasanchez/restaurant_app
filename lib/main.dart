import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/config/routes/app_router.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/theme/app_theme.dart';
import 'package:restaurant_app/services/database_service.dart';

/// Punto de entrada de la aplicación RestaurantApp.
///
/// Inicializa:
/// 1. Inyección de dependencias (GetIt)
/// 2. Base de datos SQLite
/// 3. Riverpod (gestión de estado)
/// 4. Material App con GoRouter
///


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌍 INICIALIZAR LOCALIZACIÓN PARA FECHAS
  await initializeDateFormatting('es', null);

  // 🖥️ CONFIGURAR TAMAÑO DE VENTANA PARA DESKTOP
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    // Configuración básica que funciona en Windows
    await windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // Configurar después de mostrar
    await windowManager.setSize(const Size(800, 600));
    await windowManager.setMinimumSize(const Size(400, 300));
    await windowManager.setResizable(true);
    await windowManager.setMinimizable(true);
    await windowManager.setMaximizable(true);
    await windowManager.setClosable(true);
    await windowManager.setTitle('Grupo el Gringo - Sistema de Gestión');

    // Para Windows, intentar restaurar si está minimizado
    if (Platform.isWindows) {
      await Future.delayed(const Duration(milliseconds: 200));
      await windowManager.restore(); // Asegurar que no esté minimizado
      await windowManager.focus();
    }
  }
  // 🔧 INICIALIZACIÓN ESPECÍFICA POR PLATAFORMA
  await _initializePlatformSpecific();

  // 🗄️ INICIALIZAR BASE DE DATOS DE FORMA SEGURA
  await _initDatabaseSafely();

  // Inicializar dependencias y base de datos
  await initDependencies();

  // Verificar si hay sesión activa

  runApp(ProviderScope(child: RestaurantApp()));
}

// 🚀 INICIALIZACIÓN ESPECÍFICA POR PLATAFORMA
Future<void> _initializePlatformSpecific() async {
  if (kIsWeb) {
    return;
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else if (Platform.isIOS || Platform.isAndroid) {
    // No hacer nada, usar el SQLite nativo de la plataforma
  }
}

// 🛡️ INICIALIZACIÓN SEGURA DE BASE DE DATOS
Future<void> _initDatabaseSafely() async {
  try {
    // Para iOS/Android, usar método directo sin servicios complejos
    if (Platform.isIOS || Platform.isAndroid) {
      await _initMobileDatabase();
    } else {
      // Para desktop, usar el DatabaseService normal
      await DatabaseService.database;
    }
  } catch (e) {
    // Intentar método fallback más seguro
    await _safeFallbackDatabaseInit();
  }
}

// 🔧 INICIALIZACIÓN DIRECTA PARA MÓVILES (EVITA SIGSEGV)
Future<void> _initMobileDatabase() async {
  try {
    final dbPath = join(await getDatabasesPath(), 'data.db');

    final File dbFile = File(dbPath);

    // Verificar si existe
    if (!await dbFile.exists()) {
      final ByteData data = await rootBundle.load('assets/database/data.db');
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await dbFile.writeAsBytes(bytes, flush: true);
    }

    // Verificar que se puede abrir
    final db = await openDatabase(dbPath, version: 1, readOnly: false);

    // Cerrar inmediatamente - solo verificamos que funcione
    await db.close();
  } catch (e) {
    rethrow;
  }
}

// 🔧 MÉTODO FALLBACK MEJORADO Y SEGURO

Future<void> _safeFallbackDatabaseInit() async {
  try {
    // Solo para plataformas móviles, usar el método tradicional
    if (Platform.isIOS || Platform.isAndroid) {
      final dbPath = join(await getDatabasesPath(), 'data.db');

      // Verificar si existe y es válida
      final File dbFile = File(dbPath);
      if (await dbFile.exists()) {
        try {
          final db = await openDatabase(
            dbPath,
            readOnly: true, // Solo lectura para verificación
          );
          await db.close();
          return;
        } catch (e) {
          await dbFile.delete();
        }
      }

      // Copiar desde assets solo si es necesario
      try {
        final ByteData data = await rootBundle.load('assets/database/data.db');
        final List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        await dbFile.writeAsBytes(bytes, flush: true);

        // Verificar que se puede abrir
        final db = await openDatabase(dbPath);
        await db.close();
      } catch (e) {
        throw Exception('No se pudo inicializar la base de datos');
      }
    }
  } catch (e) {
    // En este punto, la app continuará pero sin base de datos prepoblada
  }
}

/// Widget raíz de la aplicación.
class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ── Configuración general ─────────────────────────────────
      title: 'La Peña',
      debugShowCheckedModeBanner: false,

      // ── Tema Material 3 ───────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // ── Router ────────────────────────────────────────────────
      routerConfig: AppRouter.router,
    );
  }
}
