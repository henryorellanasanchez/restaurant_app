import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/auth/presentation/pages/login_page.dart';
import 'package:restaurant_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:restaurant_app/features/home/presentation/pages/home_page.dart';
import 'package:restaurant_app/features/mesas/presentation/pages/mesas_page.dart';
import 'package:restaurant_app/features/pedidos/presentation/pages/pedidos_page.dart';
import 'package:restaurant_app/features/pedidos/presentation/pages/nuevo_pedido_page.dart';
import 'package:restaurant_app/features/cocina/presentation/pages/cocina_page.dart';
import 'package:restaurant_app/features/menu/presentation/pages/menu_page.dart';
import 'package:restaurant_app/features/caja/presentation/pages/caja_page.dart';
import 'package:restaurant_app/features/reportes/presentation/pages/reportes_page.dart';
import 'package:restaurant_app/features/usuarios/presentation/pages/usuarios_page.dart';
import 'package:restaurant_app/features/sincronizacion/presentation/pages/sincronizacion_page.dart';
import 'package:restaurant_app/features/cotizaciones/presentation/pages/cotizaciones_page.dart';
import 'package:restaurant_app/features/home/presentation/widgets/main_scaffold.dart';
import 'package:restaurant_app/features/menu/presentation/pages/menu_public_page.dart';
import 'package:restaurant_app/features/reservaciones/presentation/pages/reservas_page.dart';
import 'package:restaurant_app/features/reservaciones/presentation/pages/reservas_public_page.dart';

/// Configuración de rutas de la aplicación.
///
/// Usa [GoRouter] con [ShellRoute] para mantener la barra
/// de navegación lateral persistente en todas las secciones.
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Rutas nombradas para navegación tipada.
  static const String login = '/login';
  static const String home = '/';
  static const String mesas = '/mesas';
  static const String pedidos = '/pedidos';
  static const String nuevoPedido = '/pedidos/nuevo';
  static const String cocina = '/cocina';
  static const String menu = '/menu';
  static const String menuPublico = '/menu-public';
  static const String reservas = '/reservas';
  static const String reservasPublico = '/reservas-public';
  static const String cotizaciones = '/cotizaciones';
  static const String caja = '/caja';
  static const String reportes = '/reportes';
  static const String usuarios = '/usuarios';
  static const String sincronizacion = '/sincronizacion';

  /// Retorna la ruta inicial según el rol del usuario.
  static String _homeRouteForRole(RolUsuario rol) {
    return switch (rol) {
      RolUsuario.cocina => cocina,
      _ => home,
    };
  }

  static bool _isRouteAllowedForRole(RolUsuario rol, String location) {
    if (rol.esAdmin) return true;

    if (location == menuPublico || location.startsWith('$menuPublico/')) {
      return true;
    }
    if (location == reservasPublico ||
        location.startsWith('$reservasPublico/')) {
      return true;
    }

    final allowed = switch (rol) {
      RolUsuario.cocina => {cocina},
      RolUsuario.cajero => {home, pedidos, caja, reportes},
      RolUsuario.mesero => {home, mesas, pedidos},
      RolUsuario.administrador => {
        home,
        mesas,
        pedidos,
        cocina,
        menu,
        reservas,
        cotizaciones,
        caja,
        reportes,
        usuarios,
        sincronizacion,
      },
    };

    return allowed.any(
      (route) => location == route || location.startsWith('$route/'),
    );
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: home,
    refreshListenable: sl<AuthChangeNotifier>(),
    redirect: (context, state) {
      final auth = sl<AuthChangeNotifier>();
      final isLoggedIn = auth.isAuthenticated;
      final isLoginRoute = state.matchedLocation == login;

      if (!isLoggedIn &&
          (state.matchedLocation == menuPublico ||
              state.matchedLocation.startsWith('$menuPublico/'))) {
        return null;
      }
      if (!isLoggedIn &&
          (state.matchedLocation == reservasPublico ||
              state.matchedLocation.startsWith('$reservasPublico/'))) {
        return null;
      }
      if (!isLoggedIn && !isLoginRoute) return login;
      if (isLoggedIn && isLoginRoute) {
        return _homeRouteForRole(auth.usuario!.rol);
      }
      if (isLoggedIn &&
          !_isRouteAllowedForRole(auth.usuario!.rol, state.matchedLocation)) {
        return _homeRouteForRole(auth.usuario!.rol);
      }
      return null;
    },
    routes: [
      // ── Login (fuera del shell) ──────────────────────────────────
      GoRoute(
        path: login,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),

      // ── Menu publico (sin autenticacion) ─────────────────────────
      GoRoute(
        path: menuPublico,
        pageBuilder: (context, state) {
          final mesaId = state.uri.queryParameters['mesa'];
          return NoTransitionPage(child: MenuPublicPage(mesaId: mesaId));
        },
      ),

      // ── Reservas publicas (sin autenticacion) ─────────────────────
      GoRoute(
        path: reservasPublico,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ReservasPublicPage()),
      ),

      // Shell route: Mantiene el scaffold principal con NavigationRail
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: mesas,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MesasPage()),
          ),
          GoRoute(
            path: pedidos,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PedidosPage()),
          ),
          GoRoute(
            path: nuevoPedido,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NuevoPedidoPage()),
          ),
          GoRoute(
            path: cocina,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CocinaPage()),
          ),
          GoRoute(
            path: menu,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MenuPage()),
          ),
          GoRoute(
            path: reservas,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReservasPage()),
          ),
          GoRoute(
            path: cotizaciones,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CotizacionesPage()),
          ),
          GoRoute(
            path: caja,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CajaPage()),
          ),
          GoRoute(
            path: reportes,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportesPage()),
          ),
          GoRoute(
            path: usuarios,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UsuariosPage()),
          ),
          GoRoute(
            path: sincronizacion,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SincronizacionPage()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Página no encontrada: ${state.uri}')),
    ),
  );
}
