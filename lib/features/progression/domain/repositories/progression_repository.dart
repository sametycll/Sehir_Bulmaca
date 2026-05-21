import '../entities/player_progress.dart';

/// Seviye ilerleme verilerinin cache ve uzak veritabanı (Firestore)
/// işlemlerini soyutlayan repository arayüzü.
abstract class ProgressionRepository {
  /// Kullanıcının seviye ilerleme verisini getirir.
  /// Önce local cache'e, yoksa veya güncel değilse Firestore'a bakar.
  Future<PlayerProgress?> getProgress(String uid);

  /// Kullanıcının seviye ilerleme verisini hem local cache'e hem de Firestore'a kaydeder.
  Future<void> saveProgress(PlayerProgress progress);
}
