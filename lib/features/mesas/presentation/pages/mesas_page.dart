import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/mesas/domain/entities/mesa.dart';
import 'package:restaurant_app/features/mesas/presentation/providers/mesas_provider.dart';
import 'package:restaurant_app/features/mesas/presentation/providers/llamados_provider.dart';
import 'package:restaurant_app/features/mesas/presentation/widgets/mesa_card.dart';
import 'package:restaurant_app/features/mesas/presentation/widgets/mesa_form_dialog.dart';
import 'package:restaurant_app/features/mesas/presentation/widgets/mesa_qr_dialog.dart';

/// Página principal del módulo de Mesas.
///
/// Muestra un grid de mesas con colores por estado.
/// Permite crear, editar, eliminar y cambiar estado.
class MesasPage extends ConsumerStatefulWidget {
  const MesasPage({super.key});

  @override
  ConsumerState<MesasPage> createState() => _MesasPageState();
}

class _MesasPageState extends ConsumerState<MesasPage> {
  static const _uuid = Uuid();
  EstadoMesa? _filtroEstado;

  @override
  void initState() {
    super.initState();
    // Cargar mesas al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mesasProvider.notifier).loadMesas();
      ref.read(llamadosProvider.notifier).loadPendientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mesasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Mesas'),
        actions: [
          _buildLlamadosBadge(),
          // ── Reservar local completo ──────────────────────────
          TextButton.icon(
            onPressed: () => _showReservarLocalDialog(context),
            icon: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Reservar Local',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          // ── Filtro por estado ────────────────────────────────
          _buildFilterChip(null, 'Todas', state.totalMesas),
          _buildFilterChip(EstadoMesa.libre, 'Libres', state.totalLibres),
          _buildFilterChip(EstadoMesa.ocupada, 'Ocupadas', state.totalOcupadas),
          const SizedBox(width: 16),
        ],
      ),
      // ── FAB: Crear mesa ─────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Mesa'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildFilterChip(EstadoMesa? estado, String label, int count) {
    final isSelected = _filtroEstado == estado;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        label: Text('$label ($count)'),
        onSelected: (_) {
          setState(() => _filtroEstado = estado);
        },
        selectedColor: estado != null
            ? _getColorByEstado(estado).withValues(alpha: 0.2)
            : AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildBody(MesasState state) {
    // ── Error ──────────────────────────────────────────────────
    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(state.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(mesasProvider.notifier).loadMesas(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // ── Cargando ───────────────────────────────────────────────
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── Sin mesas ──────────────────────────────────────────────
    if (state.mesas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay mesas configuradas',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Presiona "Nueva Mesa" para agregar la primera',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    // ── Grid de mesas ──────────────────────────────────────────
    final mesasFiltradas = _filtroEstado == null
        ? state.mesas
        : state.mesas.where((m) => m.estado == _filtroEstado).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final maxExtent = width < 480
              ? 160.0
              : width < 800
              ? 190.0
              : 220.0;
          final aspect = width < 480 ? 0.95 : 0.85;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxExtent,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspect,
            ),
            itemCount: mesasFiltradas.length,
            itemBuilder: (context, index) {
              final mesa = mesasFiltradas[index];
              return MesaCard(
                mesa: mesa,
                onTap: () => _showMesaOptions(context, mesa),
                onLongPress: () => _showEditDialog(context, mesa),
              );
            },
          );
        },
      ),
    );
  }

  // ── Acciones ─────────────────────────────────────────────────

  Future<void> _showCreateDialog(BuildContext context) async {
    final nextNum = await ref.read(mesasProvider.notifier).nextNumero();

    if (!mounted) return;

    final result = await showDialog<Mesa>(
      context: context,
      builder: (_) => MesaFormDialog(
        nextNumero: nextNum,
        restaurantId: AppConstants.defaultRestaurantId,
      ),
    );

    if (result != null) {
      final mesa = result.copyWith(id: _uuid.v4());
      await ref.read(mesasProvider.notifier).crearMesa(mesa);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mesa ${mesa.numero} creada')));
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, Mesa mesa) async {
    final result = await showDialog<Mesa>(
      context: context,
      builder: (_) => MesaFormDialog(
        mesa: mesa,
        nextNumero: mesa.numero,
        restaurantId: mesa.restaurantId,
      ),
    );

    if (result != null) {
      await ref.read(mesasProvider.notifier).actualizarMesa(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesa ${result.numero} actualizada')),
        );
      }
    }
  }

  void _showMesaOptions(BuildContext context, Mesa mesa) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.table_restaurant_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      mesa.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getColorByEstado(
                          mesa.estado,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        mesa.estado.label,
                        style: TextStyle(
                          color: _getColorByEstado(mesa.estado),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // ── Cambiar estado ──────────────────────────────
              ...EstadoMesa.values
                  .where((e) => e != mesa.estado && e != EstadoMesa.reservada)
                  .map(
                    (estado) => ListTile(
                      leading: Icon(
                        Icons.circle,
                        color: _getColorByEstado(estado),
                        size: 20,
                      ),
                      title: Text('Marcar como ${estado.label}'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ref
                            .read(mesasProvider.notifier)
                            .cambiarEstado(mesa.id, estado, mesa.restaurantId);
                      },
                    ),
                  ),

              // ── QR del menu ─────────────────────────────────
              ListTile(
                leading: const Icon(
                  Icons.qr_code_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Ver QR del menú'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showQrDialog(mesa);
                },
              ),

              // ── Reservar / Liberar ──────────────────────────
              if (mesa.estado != EstadoMesa.reservada)
                ListTile(
                  leading: const Icon(
                    Icons.event_available_rounded,
                    color: AppColors.mesaReservada,
                  ),
                  title: const Text('Reservar mesa'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReservarDialog(context, mesa);
                  },
                ),
              if (mesa.estado == EstadoMesa.reservada)
                ListTile(
                  leading: const Icon(
                    Icons.event_busy_rounded,
                    color: AppColors.mesaLibre,
                  ),
                  title: Text(
                    mesa.nombreReserva != null
                        ? 'Liberar reserva (${mesa.nombreReserva})'
                        : 'Liberar reserva',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _liberarReserva(context, mesa);
                  },
                ),

              const Divider(),

              // ── Editar ──────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.info),
                title: const Text('Editar mesa'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(context, mesa);
                },
              ),

              // ── Eliminar ────────────────────────────────────
              ListTile(
                leading: const Icon(
                  Icons.delete_rounded,
                  color: AppColors.error,
                ),
                title: const Text('Eliminar mesa'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, mesa);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrDialog(Mesa mesa) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rootContext = Navigator.of(context, rootNavigator: true).context;
      MesaQrDialog.show(rootContext, mesa: mesa);
    });
  }

  Widget _buildLlamadosBadge() {
    final llamados = ref.watch(llamadosProvider);
    final count = llamados.totalPendientes;

    return IconButton(
      tooltip: 'Llamados a mesero',
      onPressed: () => _showLlamadosSheet(context),
      icon: count > 0
          ? Badge(
              label: Text('$count'),
              child: const Icon(Icons.campaign_rounded),
            )
          : const Icon(Icons.campaign_outlined),
    );
  }

  void _showLlamadosSheet(BuildContext context) {
    final state = ref.read(llamadosProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.campaign_rounded),
                title: Text('Llamados a mesero'),
              ),
              const Divider(),
              if (state.pendientes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay llamados pendientes.'),
                ),
              if (state.pendientes.isNotEmpty)
                ...state.pendientes.map(
                  (l) => ListTile(
                    leading: const Icon(Icons.table_restaurant_rounded),
                    title: Text(l.mesaNombre ?? l.mesaId ?? 'Mesa'),
                    subtitle: Text('Solicitado: ${_formatHora(l.createdAt)}'),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref
                            .read(llamadosProvider.notifier)
                            .marcarAtendido(
                              l.id,
                              AppConstants.defaultRestaurantId,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Atender'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatHora(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _confirmDelete(BuildContext context, Mesa mesa) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar mesa'),
        content: Text('¿Estás seguro de eliminar ${mesa.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(mesasProvider.notifier)
          .eliminarMesa(mesa.id, mesa.restaurantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${mesa.displayName} eliminada')),
        );
      }
    }
  }

  // ── Diálogos de reserva ─────────────────────────────────────

  Future<void> _showReservarDialog(BuildContext context, Mesa mesa) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reservar ${mesa.displayName}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre de la reserva',
              hintText: 'Ej: Familia García',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Reservar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final nombre = controller.text.trim();
      final ok = await ref
          .read(mesasProvider.notifier)
          .reservarMesa(mesa, nombre, mesa.restaurantId);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '${mesa.displayName} reservada para "$nombre"'
                : 'Error al reservar la mesa',
          ),
        ),
      );
    }
    controller.dispose();
  }

  Future<void> _showReservarLocalDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reservar todo el local'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre del grupo o institución',
              hintText: 'Ej: Corporación ACME',
              prefixIcon: Icon(Icons.groups_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Reservar Local'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final nombre = controller.text.trim();
      final count = await ref
          .read(mesasProvider.notifier)
          .reservarTodoElLocal(nombre, AppConstants.defaultRestaurantId);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? '$count mesas reservadas para "$nombre"'
                : 'No hay mesas libres para reservar',
          ),
        ),
      );
    }
    controller.dispose();
  }

  Future<void> _liberarReserva(BuildContext context, Mesa mesa) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(mesasProvider.notifier).liberarReserva(mesa);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? '${mesa.displayName} liberada' : 'Error al liberar la reserva',
        ),
      ),
    );
  }

  Color _getColorByEstado(EstadoMesa estado) {
    switch (estado) {
      case EstadoMesa.libre:
        return AppColors.mesaLibre;
      case EstadoMesa.ocupada:
        return AppColors.mesaOcupada;
      case EstadoMesa.reservada:
        return AppColors.mesaReservada;
    }
  }
}
