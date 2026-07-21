import '../entities/daily_mission.dart';
import '../entities/daily_streak.dart';

abstract class DailyRepository {
  /// Cihazın yerel zamanına ve timezone bilgisine göre günlük durum (streak, sıfırlanma tarihi) çeker
  Future<DailyStreak?> getDailyStreak(String userId);

  /// Günlük durum bilgisini kaydeder
  Future<void> saveDailyStreak(String userId, DailyStreak streak);

  /// Kullanıcının mevcut aktif günlük görevlerini çeker
  Future<List<DailyMission>> getDailyMissions(String userId);

  /// Kullanıcının günlük görevlerini kaydeder
  Future<void> saveDailyMissions(String userId, List<DailyMission> missions);

  /// Tek seferde hem görevleri hem de streak verilerini kaydeder (Batch write desteği için)
  Future<void> saveDailyData(String userId, DailyStreak streak, List<DailyMission> missions);
}
