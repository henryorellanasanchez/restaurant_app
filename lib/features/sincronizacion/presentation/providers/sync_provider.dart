import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/sync/sync_manager.dart';
import 'package:restaurant_app/core/sync/sync_record.dart';

// ── Estado ─────────────────────────────────────────────────────────────────────

class SyncState {
  /// Todos los registros del log (pendientes + sincronizados).
  final List<SyncRecord> registros;
  final bool isLoading;
  final bool isSyncing;
  final DateTime? ultimaSync;
  final String? error;
  final String? successMessage;

  const SyncState({
    this.registros = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.ultimaSync,
    this.error,
    this.successMessage,
  });

  List<SyncRecord> get pendientes =>
      registros.where((r) => !r.sincronizado).toList();

  List<SyncRecord> get sincronizados =>
      registros.where((r) => r.sincronizado).toList();

  int get totalPendientes => pendientes.length;
  bool get tienePendientes => pendientes.isNotEmpty;

  SyncState copyWith({
    List<SyncRecord>? registros,
    bool? isLoading,
    bool? isSyncing,
    DateTime? ultimaSync,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return SyncState(
      registros: registros ?? this.registros,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      ultimaSync: ultimaSync ?? this.ultimaSync,
      error: clearError ? null : error ?? this.error,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier({required SyncManager syncManager})
    : _syncManager = syncManager,
      super(const SyncState()) {
    loadRegistros();
    // Refresca cada 30 segundos para reflejar operaciones recientes de la app
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadRegistros(),
    );
  }

  final SyncManager _syncManager;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Carga todos los registros del sync_log.
  Future<void> loadRegistros() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pendientes = await _syncManager.obtenerPendientes();
      final sincronizados = await _syncManager.obtenerSincronizados();
      state = state.copyWith(
        isLoading: false,
        registros: [...pendientes, ...sincronizados],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Simula la sincronización marcando todos los pendientes como sincronizados.
  ///
  /// En producción con Firebase activado, este método enviará los datos
  /// a Firestore antes de marcar como sincronizados.
  Future<void> sincronizarAhora() async {
    if (!state.tienePendientes) {
      state = state.copyWith(
        successMessage: 'No hay operaciones pendientes de sincronizar',
      );
      return;
    }

    state = state.copyWith(isSyncing: true, clearError: true);
    int procesados = 0;
    int errores = 0;

    for (final record in state.pendientes) {
      try {
        // TODO: Cuando Firebase esté activado, enviar datos a Firestore aquí
        // await _firebaseService.push(record);
        await _syncManager.marcarSincronizado(record.id);
        procesados++;
      } catch (e) {
        await _syncManager.incrementarIntentos(record.id);
        errores++;
      }
    }

    final msg = errores == 0
        ? '$procesados operación(es) sincronizada(s) correctamente'
        : '$procesados sincronizadas, $errores con error';

    state = state.copyWith(
      isSyncing: false,
      ultimaSync: DateTime.now(),
      successMessage: msg,
    );

    await loadRegistros();
  }

  /// Elimina del log todos los registros ya sincronizados con más de [dias] días.
  Future<void> limpiarHistorial({int dias = 7}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _syncManager.limpiarSincronizados(dias: dias);
      await loadRegistros();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Historial limpiado (registros > $dias días)',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(syncManager: sl());
});
