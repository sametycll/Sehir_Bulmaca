/// XP kazanmaya sebep olan olayların tabanı (sealed class).
/// Strategy pattern / XpEngine bu sınıfları ayrıştırıp uygun kuralı işletir.
sealed class XpEvent {
  final String sourceId;
  final DateTime timestamp;

  XpEvent(this.sourceId) : timestamp = DateTime.now();
}

/// Şehir bulma olayı.
class CityFoundXpEvent extends XpEvent {
  final String cityName;

  CityFoundXpEvent({required this.cityName}) : super('city_found');
}

/// Seri tahmin kombo olayı.
class ComboXpEvent extends XpEvent {
  final int comboCount;

  ComboXpEvent({required this.comboCount}) : super('combo');
}

/// Oyun bitirme/tamamlama olayı.
class GameCompletedXpEvent extends XpEvent {
  final String modeId;
  final bool isRegion;

  GameCompletedXpEvent({
    required this.modeId,
    required this.isRegion,
  }) : super('game_completed');
}

/// Başarım (Achievement) açma olayı.
class AchievementUnlockedXpEvent extends XpEvent {
  final String achievementId;
  final int xpReward;

  AchievementUnlockedXpEvent({
    required this.achievementId,
    required this.xpReward,
  }) : super('achievement_unlocked');
}

/// Liderlik tablosu sıralama olayı.
class LeaderboardBonusXpEvent extends XpEvent {
  final int rank;

  LeaderboardBonusXpEvent({required this.rank}) : super('leaderboard_bonus');
}

/// Günlük giriş serisi (streak) olayı.
class DailyStreakXpEvent extends XpEvent {
  final int streakCount;

  DailyStreakXpEvent({required this.streakCount}) : super('daily_streak');
}
