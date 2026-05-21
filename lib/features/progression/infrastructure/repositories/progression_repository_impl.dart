import 'dart:developer' as developer;
import '../../domain/entities/player_progress.dart';
import '../../domain/repositories/progression_repository.dart';
import '../datasources/firestore_progression_datasource.dart';
import '../datasources/local_progression_cache.dart';

/// Seviye ilerleme verisi repository implementasyonu.
/// Çevrimdışı (offline) öncelikli senkronizasyon mantığı içerir.
class ProgressionRepositoryImpl implements ProgressionRepository {
  final FirestoreProgressionDatasource firestoreDatasource;
  final LocalProgressionCache localCache;

  ProgressionRepositoryImpl({
    required this.firestoreDatasource,
    required this.localCache,
  });

  @override
  Future<PlayerProgress?> getProgress(String uid) async {
    // 1. Adım: Yerel önbellekteki veriyi hızlıca yükle
    final localProgress = await localCache.loadProgress(uid);

    // 2. Adım: Arka planda Firestore verisini çek ve senkronizasyon yap
    try {
      final remoteProgress = await firestoreDatasource.fetchProgress(uid);
      
      if (remoteProgress != null) {
        // Hangi taraftaki tecrübe puanı (XP) daha fazlaysa o veriyi en güncel kabul et.
        if (localProgress == null || remoteProgress.totalXp > localProgress.totalXp) {
          developer.log('[ProgressionRepository] Remote is newer. Syncing to local.');
          await localCache.saveProgress(remoteProgress);
          return remoteProgress;
        } else if (localProgress.totalXp > remoteProgress.totalXp) {
          developer.log('[ProgressionRepository] Local is newer (offline progress). Syncing to remote.');
          await firestoreDatasource.saveProgress(localProgress);
        }
      } else {
        // Sunucuda doküman yoksa ve yerelde varsa, yereli sunucuya eşitle
        if (localProgress != null) {
          developer.log('[ProgressionRepository] Initializing remote progression doc from local.');
          await firestoreDatasource.saveProgress(localProgress);
        }
      }
    } catch (e) {
      developer.log('[ProgressionRepository] Sync failed (offline mode): $e');
      // Çevrimdışı durumda yerel veriyle devam edilir, hata fırlatılmaz.
    }

    // Hem yerel hem de uzak veri null ise yeni bir profil oluştur
    return localProgress ?? PlayerProgress.empty(uid);
  }

  @override
  Future<void> saveProgress(PlayerProgress progress) async {
    try {
      // Yerel cache'i anında güncelle
      await localCache.saveProgress(progress);
      
      // Firestore güncellemesi
      await firestoreDatasource.saveProgress(progress);
    } catch (e) {
      developer.log('[ProgressionRepository] saveProgress Firestore error (will retry next sync): $e');
      // Firestore'a yazılamasa da local cache güncellendiği için offline mod desteklenir.
    }
  }
}
