/// Constantes globales de la aplicación.
///
/// Centraliza valores fijos usados en toda la app para evitar
/// magic numbers y facilitar mantenimiento.
class AppConstants {
  AppConstants._();

  // ── Información de la App ──────────────────────────────────────────
  static const String appName = 'La Peña';
  static const String appFullName = 'La Peña Bar & Restaurant';
  static const String appVersion = '1.0.0';

  // ── Moneda ───────────────────────────────────────────────────────────────
  static const String currencySymbol = '\$';
  static const String currencyCode = 'USD';

  // ── Contacto ─────────────────────────────────────────────────────────────
  static const String facebookUrl =
      'https://www.facebook.com/profile.php?id=100089948505536';
  static const String contactPhone = '809-000-0000';
  static const String contactWhatsapp = '809-000-0000';
  static const String contactEmail = 'contacto@lapena.com';

  // ── Base de datos ────────────────────────────────────────────────────────
  static const String databaseName = 'la_pena.db';
  static const int databaseVersion = 9;

  // ── Menú público (QR) ─────────────────────────────────────────────
  /// URL base del menú público para generar QR.
  /// Ejemplo: https://menu.restaurante.com/menu-public
  static const String publicMenuBaseUrl =
      'https://menu.restaurante.com/menu-public';

  // ── Multi-restaurante ────────────────────────────────────────────────────
  /// ID del restaurante La Peña.
  static const String defaultRestaurantId = 'la_pena_001';

  // ── Estados de Mesa ────────────────────────────────────────────────
  static const String mesaLibre = 'libre';
  static const String mesaOcupada = 'ocupada';
  static const String mesaReservada = 'reservada';

  // ── Estados de Pedido ──────────────────────────────────────────────
  static const String pedidoCreado = 'creado';
  static const String pedidoAceptado = 'aceptado';
  static const String pedidoEnPreparacion = 'en_preparacion';
  static const String pedidoFinalizado = 'finalizado';
  static const String pedidoEntregado = 'entregado';

  // ── Métodos de Pago ────────────────────────────────────────────────
  static const String pagoEfectivo = 'efectivo';
  static const String pagoTarjeta = 'tarjeta';
  static const String pagoTransferencia = 'transferencia';

  // ── Roles ──────────────────────────────────────────────────────────
  static const String rolAdministrador = 'administrador';
  static const String rolCajero = 'cajero';
  static const String rolMesero = 'mesero';
  static const String rolCocina = 'cocina';

  // ── Sync ───────────────────────────────────────────────────────────
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxSyncRetries = 3;
}
