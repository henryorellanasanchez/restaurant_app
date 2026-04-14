import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_app/config/routes/app_router.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:restaurant_app/features/cotizaciones/presentation/providers/cotizacion_cart_provider.dart';
import 'package:restaurant_app/features/cotizaciones/presentation/widgets/cotizacion_sheet.dart';
import 'package:restaurant_app/features/menu/presentation/providers/menu_provider.dart';
import 'package:restaurant_app/features/menu/presentation/widgets/public_producto_card.dart';
import 'package:restaurant_app/features/mesas/presentation/providers/llamados_provider.dart';

/// Menu publico accesible por QR.
///
/// Solo muestra categorias, productos disponibles e imagenes.
class MenuPublicPage extends ConsumerStatefulWidget {
  final String? mesaId;

  const MenuPublicPage({super.key, this.mesaId});

  @override
  ConsumerState<MenuPublicPage> createState() => _MenuPublicPageState();
}

class _MenuPublicPageState extends ConsumerState<MenuPublicPage>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _tabCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuProvider.notifier).loadMenu();
    });
  }

  void _syncTabController(int categoriaCount) {
    final totalTabs = categoriaCount + 1;
    if (_tabController == null || _tabCount != totalTabs) {
      _tabController?.dispose();
      _tabController = TabController(length: totalTabs, vsync: this);
      _tabCount = totalTabs;
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          final notifier = ref.read(menuProvider.notifier);
          final state = ref.read(menuProvider);
          if (_tabController!.index == 0) {
            notifier.seleccionarCategoria(null);
          } else {
            final cat = state.categorias[_tabController!.index - 1];
            notifier.seleccionarCategoria(cat.id);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String? _resolveReturnRoute() {
    final usuario = sl<AuthChangeNotifier>().usuario;
    if (usuario == null) return null;

    if (AppRouter.isRouteAllowedForRole(usuario.rol, AppRouter.menu)) {
      return AppRouter.menu;
    }
    if (AppRouter.isRouteAllowedForRole(usuario.rol, AppRouter.home)) {
      return AppRouter.home;
    }
    return null;
  }

  Widget _buildLeadingButton(BuildContext context) {
    final returnRoute = _resolveReturnRoute();

    if (returnRoute == null) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const SizedBox.expand(),
        ),
      );
    }

    return IconButton(
      tooltip: 'Regresar',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.maybePop();
          return;
        }
        context.go(returnRoute);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuProvider);
    final cart = ref.watch(cotizacionCartProvider);
    _syncTabController(state.categorias.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F6B76),
        foregroundColor: Colors.white,
        leading: _buildLeadingButton(context),
        title: _buildHeaderTitle(context),
        actions: [
          IconButton(
            tooltip: 'Cotizar',
            onPressed: () =>
                CotizacionSheet.show(context, mesaId: widget.mesaId),
            icon: cart.totalItems > 0
                ? Badge(
                    label: Text('${cart.totalItems}'),
                    child: const Icon(Icons.request_quote_outlined),
                  )
                : const Icon(Icons.request_quote_outlined),
          ),
          IconButton(
            tooltip: 'Fechas disponibles',
            onPressed: () => context.go(AppRouter.reservasPublico),
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          if (widget.mesaId != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  avatar: const Icon(Icons.table_restaurant_rounded, size: 16),
                  label: Text(widget.mesaId!),
                ),
              ),
            ),
        ],
        bottom: _tabController == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(46),
                child: Container(
                  color: const Color(0xFF0B5A63),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      const Tab(text: 'Todos'),
                      ...state.categorias.map((c) => Tab(text: c.nombre)),
                    ],
                  ),
                ),
              ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, state),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context, MenuState state) {
    if (state.errorMessage != null) {
      return Center(
        child: Text(
          state.errorMessage!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    final productos = state.categoriaSeleccionadaId == null
        ? state.productosDisponibles
        : state.productosDisponibles
              .where((p) => p.categoriaId == state.categoriaSeleccionadaId)
              .toList();

    final cart = ref.watch(cotizacionCartProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildHeroCard(context),
        const SizedBox(height: 12),
        _buildPromoBanner(context),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Menu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              '${productos.length} items',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (productos.isEmpty)
          Text(
            'No hay productos disponibles',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (productos.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final maxExtent = width < 520
                  ? 220.0
                  : width < 900
                  ? 260.0
                  : 300.0;
              final aspect = width < 520 ? 0.74 : 0.76;
              return GridView.builder(
                itemCount: productos.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxExtent,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: aspect,
                ),
                itemBuilder: (_, i) {
                  final producto = productos[i];
                  final count = cart.items
                      .where((it) => it.producto.id == producto.id)
                      .fold(0, (sum, it) => sum + it.cantidad);
                  return PublicProductoCard(
                    producto: producto,
                    cantidad: count,
                    onAdd: () => ref
                        .read(cotizacionCartProvider.notifier)
                        .addProducto(producto),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildHeaderTitle(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo_la_pena.jpg',
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.restaurant_rounded, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appFullName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Menu digital',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6B76), Color(0xFF0B5A63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo_la_pena.jpg',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.restaurant_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido a ${AppConstants.appName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explora nuestros platos y arma tu cotizacion en un minuto.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E1D7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFD18B2C),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Promociones del dia: pregunta a tu mesero por combos y bebidas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final canCall = widget.mesaId != null;
    final cart = ref.watch(cotizacionCartProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () =>
                  CotizacionSheet.show(context, mesaId: widget.mesaId),
              icon: const Icon(Icons.request_quote_outlined),
              label: Text(
                cart.totalItems > 0
                    ? 'Cotizar (${cart.totalItems})'
                    : 'Cotizar',
              ),
            ),
          ),
          if (canCall) ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _callWaiter,
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('Llamar mesero'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _callWaiter() async {
    final mesaId = widget.mesaId;
    if (mesaId == null) return;

    final ok = await ref
        .read(llamadosProvider.notifier)
        .crearLlamado(
          restaurantId: AppConstants.defaultRestaurantId,
          mesaId: mesaId,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Mesero solicitado. En breve se acercara.'
              : 'No se pudo enviar el llamado',
        ),
      ),
    );
  }
}
