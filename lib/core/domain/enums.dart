// Enumeraciones del dominio del sistema.
//
// Centralizan los estados y tipos posibles para mantener
// type-safety en toda la aplicación.

// ── Estados de Mesa ──────────────────────────────────────────────────

/// Estados posibles de una mesa.
enum EstadoMesa {
  libre('libre', 'Libre'),
  ocupada('ocupada', 'Ocupada'),
  reservada('reservada', 'Reservada');

  final String value;
  final String label;

  const EstadoMesa(this.value, this.label);

  /// Convierte un string de la BD a enum.
  static EstadoMesa fromString(String value) {
    return EstadoMesa.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoMesa.libre,
    );
  }
}

// ── Estados de Pedido ────────────────────────────────────────────────

/// Estados posibles de un pedido.
///
/// Flujo: creado → aceptado → en_preparacion → finalizado → entregado
enum EstadoPedido {
  creado('creado', 'Creado'),
  aceptado('aceptado', 'Aceptado'),
  enPreparacion('en_preparacion', 'En Preparación'),
  finalizado('finalizado', 'Finalizado'),
  entregado('entregado', 'Entregado');

  final String value;
  final String label;

  const EstadoPedido(this.value, this.label);

  static EstadoPedido fromString(String value) {
    return EstadoPedido.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoPedido.creado,
    );
  }

  /// Verifica si el pedido puede ser editado.
  /// Solo se puede editar en estado 'creado' o 'aceptado'.
  bool get esEditable =>
      this == EstadoPedido.creado || this == EstadoPedido.aceptado;

  /// Verifica si el pedido está activo (no entregado).
  bool get esActivo => this != EstadoPedido.entregado;
}

// ── Métodos de Pago ──────────────────────────────────────────────────

/// Métodos de pago soportados.
enum MetodoPago {
  efectivo('efectivo', 'Efectivo'),
  tarjeta('tarjeta', 'Tarjeta'),
  transferencia('transferencia', 'Transferencia');

  final String value;
  final String label;

  const MetodoPago(this.value, this.label);

  static MetodoPago fromString(String value) {
    return MetodoPago.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MetodoPago.efectivo,
    );
  }
}

// ── Roles de Usuario ─────────────────────────────────────────────────

/// Roles del sistema con permisos diferenciados.
enum RolUsuario {
  administrador('administrador', 'Administrador'),
  cajero('cajero', 'Cajero'),
  mesero('mesero', 'Mesero'),
  cocina('cocina', 'Cocina');

  final String value;
  final String label;

  const RolUsuario(this.value, this.label);

  static RolUsuario fromString(String value) {
    return RolUsuario.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RolUsuario.mesero,
    );
  }

  /// El administrador tiene acceso total.
  bool get esAdmin => this == RolUsuario.administrador;

  /// Puede ver reportes (admin y cajero).
  bool get puedeVerReportes =>
      this == RolUsuario.administrador || this == RolUsuario.cajero;

  /// Puede gestionar pedidos (admin, mesero, cajero).
  bool get puedeGestionarPedidos => this != RolUsuario.cocina;

  /// Puede gestionar caja (admin y cajero).
  bool get puedeGestionarCaja =>
      this == RolUsuario.administrador || this == RolUsuario.cajero;
}

// ── Operaciones de Sincronización ────────────────────────────────────

/// Tipo de operación para el log de sincronización.
enum OperacionSync {
  insert('insert'),
  update('update'),
  delete('delete');

  final String value;

  const OperacionSync(this.value);

  static OperacionSync fromString(String value) {
    return OperacionSync.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OperacionSync.insert,
    );
  }
}

// ── Llamados a Mesero ───────────────────────────────────────────────

/// Estado de un llamado a mesero.
enum EstadoLlamado {
  pendiente('pendiente', 'Pendiente'),
  atendido('atendido', 'Atendido');

  final String value;
  final String label;

  const EstadoLlamado(this.value, this.label);

  static EstadoLlamado fromString(String value) {
    return EstadoLlamado.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoLlamado.pendiente,
    );
  }
}

// ── Reservaciones ───────────────────────────────────────────────────

/// Tipo de reservacion.
enum TipoReserva {
  mesa('mesa', 'Mesa'),
  local('local', 'Local');

  final String value;
  final String label;

  const TipoReserva(this.value, this.label);

  static TipoReserva fromString(String value) {
    return TipoReserva.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TipoReserva.mesa,
    );
  }
}
