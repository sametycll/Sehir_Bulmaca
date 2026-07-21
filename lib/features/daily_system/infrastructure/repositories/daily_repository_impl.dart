import '../../domain/entities/daily_mission.dart';
import '../../domain/entities/daily_streak.dart';
import '../../domain/repositories/daily_repository.dart';
import '../datasources/firestore_daily_datasource.dart';
import '../datasources/local_daily_cache.dart';

/// [DailyRepository] arayüzünün somut implementasyonu.
/// Yerel öncelikli (local-first) veri erişimi ve uzak sunucu senkronizasyonunu yönetir.
class DailyRepositoryImpl implements DailyRepository {
  final LocalDailyCache _localCache;
  final FirestoreDailyDatasource _remoteDatasource;

  DailyRepositoryImpl({
    required LocalDailyCache localCache,
    required FirestoreDailyDatasource remoteDatasource,
  })  : _localCache = localCache,
        _remoteDatasource = remoteDatasource;

  @override
  Future<DailyStreak?> getDailyStreak(String userId) async {
    // 1. Önce yerel önbellekten okumayı dene
    final localStreak = await _localCache.getDailyStreak(userId);
    if (localStreak != null) {
      return localStreak;
    }

    // 2. Yerelde yoksa Firestore'dan çek
    try {
      final remoteStreak = await _remoteDatasource.getDailyStreak(userId);
      if (remoteStreak != null) {
        // Çekilen veriyi yerel önbelleğe kaydet
        await _localCache.saveDailyStreak(userId, remoteStreak);
        return remoteStreak;
      }
    } catch (e) {
      // Çevrimdışı olma durumunda veya hata durumunda sessizce yutulabilir
    }

    return null;
  }

  @override
  Future<void> saveDailyStreak(String userId, DailyStreak streak) async {
    // Önce lokale yaz
    await _localCache.saveDailyStreak(userId, streak);
    
    // Uzak Firestore'a yaz
    try {
      await _remoteDatasource.saveDailyStreak(userId, streak);
    } catch (e) {
      // Hata durumunda işlem yerelde kalır, çevrimdışı senkronizasyonda güncellenebilir
    }
  }

  @override
  Future<List<DailyMission>> getDailyMissions(String userId) async {
    // 1. Önce yerel önbelleğe bak
    final localMissions = await _localCache.getDailyMissions(userId);
    if (localMissions != null && localMissions.isNotEmpty) {
      return localMissions;
    }

    // 2. Yerelde yoksa Firestore'dan çek
    try {
      final remoteMissions = await _remoteDatasource.getDailyMissions(userId);
      if (remoteMissions.isNotEmpty) {
        await _localCache.saveDailyMissions(userId, remoteMissions);
        return remoteMissions;
      }
    } catch (e) {
      // Çevrimdışı hata yönetimi
    }

    return [];
  }

  @override
  Future<void> saveDailyMissions(String userId, List<DailyMission> missions) async {
    // Önce lokale yaz
    await _localCache.saveDailyMissions(userId, missions);

    // Sonra Firestore'a yaz
    try {
      await _remoteDatasource.saveDailyMissions(userId, missions);
    } catch (e) {
      // Çevrimdışı hata yönetimi
    }
  }

  @override
  Future<void> saveDailyData(
    String userId,
    DailyStreak streak,
    List<DailyMission> missions,
  ) async {
    // 1. Yerel verileri anında kaydet (Optimistic Update desteği için hızlı tepki)
    await _localCache.saveDailyStreak(userId, streak);
    await _localCache.saveDailyMissions(userId, missions);

    // 2. Firestore Batch ile uzak sunucuya kaydet
    try {
      await _remoteDatasource.saveDailyData(userId, streak, missions);
    } catch (e) {
      // Ağ hatası veya çevrimdışı kullanım durumunda Firestore kaydı başarısız olabilir.
      // Yerel cache güncel olduğu için oyun çalışmaya devam eder.
    }
  }
}
