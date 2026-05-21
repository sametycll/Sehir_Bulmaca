import '../entities/achievement_event.dart';

/// Strategy Pattern: her başarım kendi koşulunu değerlendirir.
///
/// Engine, olayları alırken `handledEventTypes` kullanarak
/// bir HashMap index'i oluşturur. Bu sayede her event için
/// sadece ilgili condition'lar çağrılır — O(n²) döngüden kaçınılır.
///
/// Yeni başarım eklemek için:
/// 1. `AchievementCondition` implementasyonu yaz
/// 2. `AchievementDefinitions` listesine ekle
/// → başka hiçbir yer değişmez!
abstract class AchievementCondition {
  const AchievementCondition();

  /// Bu condition'ın dinlediği event türleri.
  /// Engine bu bilgiyle lookup tablosu oluşturur.
  Set<Type> get handledEventTypes;

  /// Verilen event ve mevcut progress'e göre yeni progress değerini döner.
  /// null dönerse bu condition bu event'e tepki vermez.
  int? evaluate(AchievementEvent event, int currentProgress);
}

// ─────────────────────────────────────────────────────────────────
// CONCRETE CONDITIONS
// ─────────────────────────────────────────────────────────────────

/// Her bulunan şehir için progress'i 1 artırır.
/// "İlk Şehir", "10 Şehir", "100 Şehir" gibi kümülatif başarımlar için.
class CityFoundIncrementalCondition extends AchievementCondition {
  const CityFoundIncrementalCondition();

  @override
  Set<Type> get handledEventTypes => {CityFoundEvent};

  @override
  int? evaluate(AchievementEvent event, int currentProgress) {
    if (event is CityFoundEvent) {
      return currentProgress + 1;
    }
    return null;
  }
}

/// Belirli bir kombo sayısına ulaşıldığında açılan başarımlar.
/// Binary: 0 veya 1 (ya açık ya kapalı).
class ComboThresholdCondition extends AchievementCondition {
  const ComboThresholdCondition({required this.minCombo});
  final int minCombo;

  @override
  Set<Type> get handledEventTypes => {ComboReachedEvent};

  @override
  int? evaluate(AchievementEvent event, int currentProgress) {
    if (event is ComboReachedEvent && event.comboCount >= minCombo) {
      return 1; // Binary başarım
    }
    return null;
  }
}

/// Belirli bir oyun modu tamamlandığında açılır.
/// [modeId] null ise herhangi bir mod kabul edilir.
/// [minCities] null ise mod'daki tüm şehirler gerekir (isAllFound = true).
class GameModeCompletedCondition extends AchievementCondition {
  const GameModeCompletedCondition({
    this.modeId,
    this.minCities,
    this.requireAllCities = false,
  });

  final String? modeId;
  final int? minCities;
  final bool requireAllCities;

  @override
  Set<Type> get handledEventTypes => {GameCompletedEvent};

  @override
  int? evaluate(AchievementEvent event, int currentProgress) {
    if (event is! GameCompletedEvent) return null;
    if (modeId != null && event.modeId != modeId) return null;
    if (requireAllCities && !event.isAllFound) return null;
    if (minCities != null && event.citiesFound < minCities!) return null;
    return 1;
  }
}

/// Blitz modunda belirli sayıda şehir bulma başarımı.
class BlitzMinCitiesCondition extends AchievementCondition {
  const BlitzMinCitiesCondition({required this.minCities});
  final int minCities;

  @override
  Set<Type> get handledEventTypes => {GameCompletedEvent};

  @override
  int? evaluate(AchievementEvent event, int currentProgress) {
    if (event is GameCompletedEvent &&
        event.modeId == 'blitz_challenge' &&
        event.citiesFound >= minCities) {
      return 1;
    }
    return null;
  }
}

/// Liderlik tablosuna girildiğinde tetiklenir. Binary.
class LeaderboardEnteredCondition extends AchievementCondition {
  const LeaderboardEnteredCondition();

  @override
  Set<Type> get handledEventTypes => {LeaderboardEnteredEvent};

  @override
  int? evaluate(AchievementEvent event, int currentProgress) {
    if (event is LeaderboardEnteredEvent) return 1;
    return null;
  }
}

/// Günlük giriş serisini izler. Her login günü progress 1 artar.
/// Ancak engine dışında streak kırılması SharedPreferences tarafından yönetilir.
class DailyStreakCondition extends AchievementCondition {
  const DailyStreakCondition();

  @override
  Set<Type> get handledEventTypes => {DailyLoginEvent};

  @override
  int? evaluate(AchievementEvent event, int currentProgress) {
    if (event is DailyLoginEvent) {
      // currentStreak zaten doğru hesaplanmış olarak gelir (cache katmanından)
      return event.currentStreak;
    }
    return null;
  }
}

/// Her tamamlanan oyun için progress artırır.
class GameCompletedIncrementalCondition extends AchievementCondition {
  const GameCompletedIncrementalCondition();

  @override
  Set<Type> get handledEventTypes => {GameCompletedEvent};

  @override
  int? evaluate(AchievementEvent event, int currentProgress) {
    if (event is GameCompletedEvent) return currentProgress + 1;
    return null;
  }
}
