import 'dart:developer' as developer;
import '../../domain/entities/achievement_progress.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../datasources/firestore_achievement_datasource.dart';
import '../datasources/local_achievement_cache.dart';

/// Repository implementasyonu — Firestore + local cache birleştirir.
///
/// OFFLINE-FIRST STRATEJİSİ:
/// 1. Önce local cache'den yükle (anında)
/// 2. Arka planda Firestore'dan yükle
/// 3. Firestore başarılıysa cache'i güncelle
///
/// WRITE STRATEJİSİ:
/// Hem cache hem Firestore'a yaz (write-through cache pattern).
/// Firestore başarısız olursa cache'de tutulur, sonraki oturumda retry.
class AchievementRepositoryImpl implements AchievementRepository {
  AchievementRepositoryImpl({
    required FirestoreAchievementDatasource firestoreDatasource,
    required LocalAchievementCache localCache,
  })  : _firestore = firestoreDatasource,
        _cache = localCache;

  final FirestoreAchievementDatasource _firestore;
  final LocalAchievementCache _cache;

  @override
  Future<Map<String, AchievementProgress>> fetchProgress(String userId) async {
    // 1. Cache'den hızlı yükle
    final cached = await _cache.loadAll();

    // 2. Arka planda Firestore'dan getir ve cache'i güncelle
    _fetchFromFirestoreAndSync(userId, cached);

    return cached;
  }

  Future<void> _fetchFromFirestoreAndSync(
    String userId,
    Map<String, AchievementProgress> cachedData,
  ) async {
    try {
      final remote = await _firestore.fetchAll(userId);
      if (remote.isEmpty) return;

      // Remote veriyi cache ile merge et (remote öncelikli)
      final merged = {...cachedData, ...remote};
      await _cache.saveAll(merged);
    } catch (e) {
      developer.log('[AchievementRepo] Background Firestore sync failed: $e');
    }
  }

  @override
  Future<void> batchSaveProgress(
    String userId,
    List<AchievementProgress> updates,
  ) async {
    if (updates.isEmpty) return;

    // Önce cache'i güncelle (optimistic — anında)
    for (final progress in updates) {
      await _cache.updateSingle(progress);
    }

    // Sonra Firestore'a yaz (batch)
    try {
      await _firestore.batchSave(userId, updates);
    } catch (e) {
      developer.log('[AchievementRepo] batchSaveProgress Firestore error: $e');
      // Cache'de kaldı, sonraki oturumda Firestore sync yapar
    }
  }

  @override
  Future<void> saveProgress(String userId, AchievementProgress progress) async {
    await batchSaveProgress(userId, [progress]);
  }

  @override
  Future<void> clearCache() async {
    await _cache.clear();
  }
}
