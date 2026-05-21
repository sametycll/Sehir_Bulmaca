import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/achievement_progress.dart';

/// Firestore veri kaynağı.
///
/// YAPIİ: users/{uid}/achievements/{achievementId}
///
/// Neden subcollection?
/// - Her achievement bağımsız güncellenebilir (partial update)
/// - Batch write ile birden fazlası aynı anda yazılabilir
/// - Admin panelinden tek achievement görüntülenebilir
///
/// Alternati (tek document): users/{uid}/achievementData
/// Avantaj: 1 read, Dezavantaj: document büyüdükçe write amplification.
/// 20 achievement için subcollection daha maintainable.
class FirestoreAchievementDatasource {
  FirestoreAchievementDatasource(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('achievements');

  /// Tüm achievement progress'ini tek sorguda çeker.
  /// Maliyet: max 20 document read/session start (kabul edilebilir).
  Future<Map<String, AchievementProgress>> fetchAll(String userId) async {
    try {
      final snapshot = await _collection(userId).get(
        // Önce cache'den dene, sonra server — offline destek
        const GetOptions(source: Source.serverAndCache),
      );

      return {
        for (final doc in snapshot.docs)
          doc.id: AchievementProgress.fromFirestore(doc.data()),
      };
    } catch (e) {
      developer.log('[AchievementFirestore] fetchAll error: $e');
      return {};
    }
  }

  /// Birden fazla achievement'ı tek batch write ile kaydeder.
  /// Firestore batch: maks 500 op — 20 achievement için yeterli.
  Future<void> batchSave(
    String userId,
    List<AchievementProgress> updates,
  ) async {
    if (updates.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final col = _collection(userId);

      for (final progress in updates) {
        final docRef = col.doc(progress.achievementId);
        batch.set(docRef, progress.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();
      developer.log(
        '[AchievementFirestore] Batch saved ${updates.length} achievement(s)',
      );
    } catch (e) {
      developer.log('[AchievementFirestore] batchSave error: $e');
      rethrow;
    }
  }
}
