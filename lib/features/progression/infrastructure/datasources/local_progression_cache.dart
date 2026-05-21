import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/player_progress.dart';

/// Seviye ilerleme verilerini yerel hafızada (SharedPreferences) saklayan cache katmanı.
/// Amaç: İnternet kesintilerinde veri kaybını önleme ve açılışta Firestore beklemeden anında yükleme.
class LocalProgressionCache {
  static const _progressionKeyPrefix = 'player_progression_cache_';

  String _getKey(String uid) => '$_progressionKeyPrefix$uid';

  /// Yerelde kayıtlı oyuncu ilerleme verisini yükler.
  Future<PlayerProgress?> loadProgress(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_getKey(uid));
      if (jsonStr == null) return null;

      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return PlayerProgress(
        uid: uid,
        level: json['level'] as int? ?? 1,
        currentXp: json['currentXp'] as int? ?? 0,
        totalXp: json['totalXp'] as int? ?? 0,
        xpToNextLevel: json['xpToNextLevel'] as int? ?? 100,
        lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ?? DateTime.now(),
        prestigeLevel: json['prestigeLevel'] as int? ?? 0,
      );
    } catch (e) {
      developer.log('[LocalProgressionCache] loadProgress error: $e');
      return null;
    }
  }

  /// Oyuncu ilerleme verisini yerel cache'e kaydeder.
  Future<void> saveProgress(PlayerProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonMap = {
        'level': progress.level,
        'currentXp': progress.currentXp,
        'totalXp': progress.totalXp,
        'xpToNextLevel': progress.xpToNextLevel,
        'lastUpdated': progress.lastUpdated.toIso8601String(),
        'prestigeLevel': progress.prestigeLevel,
      };
      await prefs.setString(_getKey(progress.uid), jsonEncode(jsonMap));
      developer.log('[LocalProgressionCache] Saved progress locally for ${progress.uid}');
    } catch (e) {
      developer.log('[LocalProgressionCache] saveProgress error: $e');
    }
  }

  /// Yerel veriyi temizler (oturum kapatıldığında veya sıfırlandığında).
  Future<void> clearProgress(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getKey(uid));
    } catch (e) {
      developer.log('[LocalProgressionCache] clearProgress error: $e');
    }
  }
}
