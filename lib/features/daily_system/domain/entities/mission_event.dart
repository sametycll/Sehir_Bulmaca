sealed class MissionEvent {
  const MissionEvent();
}

/// Oyuncu bir şehir bulduğunda
class CityFoundMissionEvent extends MissionEvent {
  final String modeId;
  final int comboCount;

  const CityFoundMissionEvent({
    required this.modeId,
    required this.comboCount,
  });
}

/// Bir oyun modu başarıyla tamamlandığında
class GameCompletedMissionEvent extends MissionEvent {
  final String modeId;
  final int score;

  const GameCompletedMissionEvent({
    required this.modeId,
    required this.score,
  });
}

/// Oyuncu XP kazandığında
class XpEarnedMissionEvent extends MissionEvent {
  final int amount;

  const XpEarnedMissionEvent({
    required this.amount,
  });
}

/// Yeni bir başarım (achievement) açıldığında
class AchievementUnlockedMissionEvent extends MissionEvent {
  const AchievementUnlockedMissionEvent();
}

/// Oyuncu oyunu açık tutup oynadığında (dakika bazlı takip)
class PlayTimeMissionEvent extends MissionEvent {
  final int minutes;

  const PlayTimeMissionEvent({
    required this.minutes,
  });
}
