import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/sync/sync_record.dart';

/// Servicio para enviar operaciones del sync_log a Firestore.
class SyncCloudService {
  /// Valida que Firebase esté inicializado y disponible.
  Future<void> ensureAvailable() async {
    try {
      await _ensureFirebaseInitialized();
    } catch (e) {
      throw StateError(
        'Firebase no está configurado para sincronización. '
        'Completa la configuración de Firebase (apps + archivos de plataforma) e intenta de nuevo.\nDetalle: $e',
      );
    }
  }

  Future<void> pushRecord(SyncRecord record) async {
    await ensureAvailable();

    final firestore = FirebaseFirestore.instance;
    final docRef = firestore
        .collection('restaurantes')
        .doc(AppConstants.defaultRestaurantId)
        .collection(record.tabla)
        .doc(record.registroId);

    switch (record.operacion) {
      case SyncOperation.insert:
      case SyncOperation.update:
        await docRef.set(_buildPayload(record), SetOptions(merge: true));
      case SyncOperation.delete:
        await docRef.delete();
    }

    await firestore.collection('sync_audit').doc(record.id).set({
      'tabla': record.tabla,
      'registro_id': record.registroId,
      'operacion': record.operacion.name,
      'created_at_local': record.createdAt.toIso8601String(),
      'synced_at': FieldValue.serverTimestamp(),
    });
  }

  Map<String, dynamic> _buildPayload(SyncRecord record) {
    final payload = <String, dynamic>{
      ...?record.datos,
      '_sync': {
        'record_id': record.id,
        'operation': record.operacion.name,
        'source': 'restaurant_app',
        'created_at_local': record.createdAt.toIso8601String(),
        'synced_at': FieldValue.serverTimestamp(),
      },
    };

    if (record.datos == null || record.datos!.isEmpty) {
      payload['id'] = record.registroId;
    }

    return payload;
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp();
  }
}
