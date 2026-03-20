import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:restaurant_app/config/routes/app_router.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/theme/app_theme.dart';

/// Punto de entrada de la aplicación RestaurantApp.
///
/// Inicializa:
/// 1. Inyección de dependencias (GetIt)
/// 2. Base de datos SQLite
/// 3. Riverpod (gestión de estado)
/// 4. Material App con GoRouter
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar dependencias y base de datos
  await initDependencies();

  runApp(const ProviderScope(child: RestaurantApp()));
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
