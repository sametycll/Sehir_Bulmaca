enum MissionTier {
  easy,
  medium,
  hard,
  legendary;

  String get title {
    switch (this) {
      case MissionTier.easy:
        return 'Kolay';
      case MissionTier.medium:
        return 'Orta';
      case MissionTier.hard:
        return 'Zor';
      case MissionTier.legendary:
        return 'Efsanevi';
    }
  }
}

class DailyMission {
  final String id;
  final String title;
  final String description;
  final String type; // Örn: 'city_found', 'combo', 'game_completed', 'xp_earned', 'achievement_unlocked', 'play_time'
  final int targetProgress;
  final int currentProgress;
  final MissionTier tier;
  final bool isCompleted;
  final bool isClaimed;
  final int xpReward;
  final String? targetParameter; // Ek parametre filtresi (Örn: oyun modu ID'si)

  DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetProgress,
    required this.currentProgress,
    required this.tier,
    required this.isCompleted,
    required this.isClaimed,
    required this.xpReward,
    this.targetParameter,
  });

  DailyMission copyWith({
    int? currentProgress,
    bool? isCompleted,
    bool? isClaimed,
  }) {
    return DailyMission(
      id: id,
      title: title,
      description: description,
      type: type,
      targetProgress: targetProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      tier: tier,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      xpReward: xpReward,
      targetParameter: targetParameter,
    );
  }
}
