import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_mission_model.dart';
import '../models/daily_streak_model.dart';
import '../../domain/entities/daily_mission.dart';
import '../../domain/entities/daily_streak.dart';

/// Günlük görev ve giriş serisi (streak) verilerini yerel hafızada (SharedPreferences) saklayan cache katmanı.
class LocalDailyCache {
  static const String _missionPrefix = 'daily_missions_';
  static const String _streakPrefix = 'daily_streak_';

  const LocalDailyCache();

  /// Kullanıcının yerel olarak kaydedilmiş görevlerini çeker.
  Future<List<DailyMission>?> getDailyMissions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_missionPrefix$userId');
      if (jsonStr == null) return null;

      final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded.map((item) {
        return DailyMissionModel.fromMap(item as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      // Hata durumunda log atabiliriz veya null dönebiliriz.
      return null;
    }
  }

  /// Kullanıcının görevlerini yerel hafızaya kaydeder.
  Future<void> saveDailyMissions(String userId, List<DailyMission> missions) async {
    final prefs = await SharedPreferences.getInstance();
    final models = missions.map((m) => DailyMissionModel.fromEntity(m).toMap()).toList();
    final jsonStr = json.encode(models);
    await prefs.setString('$_missionPrefix$userId', jsonStr);
  }

  /// Kullanıcının yerel olarak kaydedilmiş streak verisini çeker.
  Future<DailyStreak?> getDailyStreak(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_streakPrefix$userId');
      if (jsonStr == null) return null;

      final Map<String, dynamic> decoded = json.decode(jsonStr) as Map<String, dynamic>;
      
      // SharedPreferences'tan okurken Timestamp yerine String formatında gelebilir.
      // DailyStreakModel.fromMap bu durumu desteklemektedir.
      return DailyStreakModel.fromMap(decoded);
    } catch (e) {
      return null;
    }
  }

  /// Kullanıcının streak verisini yerel hafızaya kaydeder.
  Future<void> saveDailyStreak(String userId, DailyStreak streak) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Firestore Timestamp'i json.encode edemeyeceği için DateTime formatında saklıyoruz.
    final model = DailyStreakModel.fromEntity(streak);
    final map = {
      'currentStreak': model.currentStreak,
      'bestStreak': model.bestStreak,
      'lastClaimedDate': model.lastClaimedDate?.toIso8601String(),
      'missionsResetAt': model.missionsResetAt.toIso8601String(),
      'lastActiveDate': model.lastActiveDate?.toIso8601String(),
    };
    
    final jsonStr = json.encode(map);
    await prefs.setString('$_streakPrefix$userId', jsonStr);
  }

  /// Kullanıcının tüm yerel daily verilerini siler.
  Future<void> clearDailyData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_missionPrefix$userId');
    await prefs.remove('$_streakPrefix$userId');
  }
}
