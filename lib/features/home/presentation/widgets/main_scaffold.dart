import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_app/config/routes/app_router.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/auth/presentation/providers/auth_provider.dart';

/// Scaffold principal de la aplicación.
///
/// Contiene un [NavigationRail] lateral persistente que permite
/// navegar entre los módulos principales del sistema.
///
/// Se adapta automáticamente:
/// - Pantallas grandes → NavigationRail expandido
/// - Tablets → NavigationRail compacto
/// - Móvil → BottomNavigationBar (futuro)
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  /// Todos los items de navegación del sistema.
  static const _allNavItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Inicio',
      path: AppRouter.home,
      roles: {RolUsuario.administrador, RolUsuario.cajero, RolUsuario.mesero},
    ),
    _NavItem(
      icon: Icons.table_restaurant_rounded,
      label: 'Mesas',
      path: AppRouter.mesas,
      roles: {RolUsuario.administrador, RolUsuario.mesero},
    ),
    _NavItem(
      icon: Icons.receipt_long_rounded,
      label: 'Pedidos',
      path: AppRouter.pedidos,
      roles: {RolUsuario.administrador, RolUsuario.cajero, RolUsuario.mesero},
    ),
    _NavItem(
      icon: Icons.soup_kitchen_rounded,
      label: 'Cocina',
      path: AppRouter.cocina,
      roles: {RolUsuario.administrador, RolUsuario.cocina},
    ),
    _NavItem(
      icon: Icons.restaurant_menu_rounded,
      label: 'Menú',
      path: AppRouter.menu,
      roles: {RolUsuario.administrador},
    ),
    _NavItem(
      icon: Icons.calendar_month_rounded,
      label: 'Reservas',
      path: AppRouter.reservas,
      roles: {RolUsuario.administrador},
    ),
    _NavItem(
      icon: Icons.request_quote_rounded,
      label: 'Cotizaciones',
      path: AppRouter.cotizaciones,
      roles: {RolUsuario.administrador},
    ),
    _NavItem(
      icon: Icons.point_of_sale_rounded,
      label: 'Caja',
      path: AppRouter.caja,
      roles: {RolUsuario.administrador, RolUsuario.cajero},
    ),
    _NavItem(
      icon: Icons.analytics_rounded,
      label: 'Reportes',
      path: AppRouter.reportes,
      roles: {RolUsuario.administrador, RolUsuario.cajero},
    ),
    _NavItem(
      icon: Icons.manage_accounts_rounded,
      label: 'Usuarios',
      path: AppRouter.usuarios,
      roles: {RolUsuario.administrador},
    ),
    _NavItem(
      icon: Icons.sync_rounded,
      label: 'Sincronización',
      path: AppRouter.sincronizacion,
      roles: {RolUsuario.administrador},
    ),
  ];

  List<_NavItem> _itemsForRole(RolUsuario rol) =>
      _allNavItems.where((item) => item.roles.contains(rol)).toList();

  int _getSelectedIndex(BuildContext context, List<_NavItem> items) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < items.length; i++) {
      if (location == items[i].path) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = sl<AuthChangeNotifier>();
    final usuario = auth.usuario;
    final rol = usuario?.rol ?? RolUsuario.mesero;
    final navItems = _itemsForRole(rol);
    final selectedIndex = _getSelectedIndex(context, navItems);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;

    return Scaffold(
      body: Row(
        children: [
          // ── Barra de Navegación Lateral ──────────────────────────
          NavigationRail(
            extended: isWideScreen,
            minExtendedWidth: 200,
            backgroundColor: Colors.white,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              context.go(navItems[index].path);
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo_la_pena.jpg',
                      width: isWideScreen ? 80 : 40,
                      height: isWideScreen ? 80 : 40,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                  ),
                  if (isWideScreen) ...[
                    const SizedBox(height: 6),
                    Text(
                      'La Peña',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Bar & House',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                    if (usuario != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        usuario.nombre,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        usuario.rol.label,
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Cerrar sesión',
                color: AppColors.secondary,
                onPressed: () {
                  auth.logout();
                },
              ),
            ),
            destinations: navItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.icon, color: AppColors.primary),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),

          // ── Separador visual ────────────────────────────────────
          const VerticalDivider(thickness: 1, width: 1),

          // ── Contenido principal ─────────────────────────────────
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Modelo interno de un item de navegación.
class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  final Set<RolUsuario> roles;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.roles,
  });
}
