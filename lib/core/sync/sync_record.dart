/// Enumeración de operaciones de sincronización.
enum SyncOperation { insert, update, delete }

/// Representa un registro pendiente de sincronización.
///
/// Cuando el sistema funciona offline, cada operación CRUD
/// se registra en [sync_log] para sincronizarse con Firebase
/// cuando haya conexión disponible.
class SyncRecord {
  final String id;
  final String tabla;
  final String registroId;
  final SyncOperation operacion;
  final Map<String, dynamic>? datos;
  final bool sincronizado;
  final int intentos;
  final DateTime createdAt;

  const SyncRecord({
    required this.id,
    required this.tabla,
    required this.registroId,
    required this.operacion,
    this.datos,
    this.sincronizado = false,
    this.intentos = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tabla': tabla,
      'registro_id': registroId,
      'operacion': operacion.name,
      'datos': datos?.toString(),
      'sincronizado': sincronizado ? 1 : 0,
      'intentos': intentos,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SyncRecord.fromMap(Map<String, dynamic> map) {
    return SyncRecord(
      id: map['id'] as String,
      tabla: map['tabla'] as String,
      registroId: map['registro_id'] as String,
      operacion: SyncOperation.values.firstWhere(
        (e) => e.name == map['operacion'],
      ),
      sincronizado: (map['sincronizado'] as int) == 1,
      intentos: map['intentos'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
