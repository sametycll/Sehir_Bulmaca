import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/achievement_progress.dart';

/// Offline cache katmanı — SharedPreferences tabanlı.
///
/// AMAÇ:
/// - Uygulama cold start'ta Firestore'u beklemeden anlık yükleme
/// - Airplane mode / kötü bağlantıda progress kaybını önleme
/// - Firestore'dan geldikten sonra cache güncellenir (write-through)
///
/// GÜNLÜK GİRİŞ SERİSİ:
/// Son giriş tarihi de buraya kaydedilir — Firestore okuma gerekmez.
class LocalAchievementCache {
  static const _progressKey = 'achievement_progress_cache';
  static const _lastLoginKey = 'achievement_last_login_date';
  static const _streakKey = 'achievement_login_streak';

  // ─── Progress Cache ───────────────────────────────────────────

  /// Tüm achievement progress'ini cache'den yükler.
  Future<Map<String, AchievementProgress>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_progressKey);
      if (json == null) return {};

      final Map<String, dynamic> decoded = jsonDecode(json);
      return decoded.map((key, value) {
        return MapEntry(
          key,
          _progressFromJson(key, value as Map<String, dynamic>),
        );
      });
    } catch (e) {
      developer.log('[AchievementCache] loadAll error: $e');
      return {};
    }
  }

  /// Tüm progress'i cache'e yazar (Firestore'dan gelen veri ile sync).
  Future<void> saveAll(Map<String, AchievementProgress> progressMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(progressMap.map(
        (key, value) => MapEntry(key, _progressToJson(value)),
      ));
      await prefs.setString(_progressKey, encoded);
    } catch (e) {
      developer.log('[AchievementCache] saveAll error: $e');
    }
  }

  /// Tek bir achievement'ı cache'de günceller (optimistic update).
  Future<void> updateSingle(AchievementProgress progress) async {
    final current = await loadAll();
    current[progress.achievementId] = progress;
    await saveAll(current);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
  }

  // ─── Daily Login Streak ───────────────────────────────────────

  /// Günlük giriş serisini hesaplar ve günceller.
  /// Dönüş değeri: (currentStreak, isNewDay)
  Future<({int streak, bool isNewDay})> checkAndUpdateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginStr = prefs.getString(_lastLoginKey);
      final savedStreak = prefs.getInt(_streakKey) ?? 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (lastLoginStr == null) {
        // İlk giriş
        await _saveStreak(prefs, today, 1);
        return (streak: 1, isNewDay: true);
      }

      final lastLogin = DateTime.parse(lastLoginStr);
      final lastDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);

      if (today == lastDay) {
        // Bugün zaten giriş yapılmış — streak değişmez
        return (streak: savedStreak, isNewDay: false);
      }

      final diff = today.difference(lastDay).inDays;

      if (diff == 1) {
        // Ardışık gün — seriyi devam ettir
        final newStreak = savedStreak + 1;
        await _saveStreak(prefs, today, newStreak);
        return (streak: newStreak, isNewDay: true);
      } else {
        // Seri kırıldı — sıfırla
        await _saveStreak(prefs, today, 1);
        return (streak: 1, isNewDay: true);
      }
    } catch (e) {
      developer.log('[AchievementCache] checkAndUpdateStreak error: $e');
      return (streak: 0, isNewDay: false);
    }
  }

  Future<void> _saveStreak(
    SharedPreferences prefs,
    DateTime date,
    int streak,
  ) async {
    await prefs.setString(_lastLoginKey, date.toIso8601String());
    await prefs.setInt(_streakKey, streak);
  }

  // ─── Serialization Helpers ────────────────────────────────────

  Map<String, dynamic> _progressToJson(AchievementProgress p) => {
        'progress': p.progress,
        'unlocked': p.unlocked,
        'unlockedAt': p.unlockedAt?.toIso8601String(),
      };

  AchievementProgress _progressFromJson(String id, Map<String, dynamic> json) {
    final rawDate = json['unlockedAt'];
    return AchievementProgress(
      achievementId: id,
      progress: json['progress'] as int? ?? 0,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: rawDate != null ? DateTime.tryParse(rawDate as String) : null,
    );
  }
}
