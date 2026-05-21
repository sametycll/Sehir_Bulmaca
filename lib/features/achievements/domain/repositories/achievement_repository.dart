import '../entities/achievement_progress.dart';

/// Repository abstract interface — domain katmanı infrastructure'a bağımlı olmaz.
/// Dependency Inversion Principle (DIP) uygulaması.
///
/// Mock implementasyonu unit test yazmayı kolaylaştırır.
abstract class AchievementRepository {
  /// Kullanıcının tüm achievement progress'ini tek sorguda getirir.
  /// Key: achievementId, Value: AchievementProgress
  Future<Map<String, AchievementProgress>> fetchProgress(String userId);

  /// Birden fazla achievement progress'ini batch write ile Firestore'a kaydeder.
  /// Batch write: tek bir network round-trip ile birden fazla belge yazılır.
  Future<void> batchSaveProgress(
    String userId,
    List<AchievementProgress> updates,
  );

  /// Tek bir achievement progress'ini kaydeder (acil durumlar için).
  Future<void> saveProgress(String userId, AchievementProgress progress);

  /// Offline cache'i temizler (test veya hesap değişimi için).
  Future<void> clearCache();
}
