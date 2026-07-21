import '../../domain/entities/daily_mission.dart';

class DailyMissionModel extends DailyMission {
  DailyMissionModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required super.targetProgress,
    required super.currentProgress,
    required super.tier,
    required super.isCompleted,
    required super.isClaimed,
    required super.xpReward,
    super.targetParameter,
  });

  factory DailyMissionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final String idVal = docId ?? map['id'] as String? ?? '';
    final String titleVal = map['title'] as String? ?? '';
    final String descriptionVal = map['description'] as String? ?? '';
    final String typeVal = map['type'] as String? ?? '';
    final int targetVal = _toInt(map['targetProgress'], 1);
    final int currentVal = _toInt(map['currentProgress'], 0);
    final int xpRewardVal = _toInt(map['xpReward'], 100);
    final String? paramVal = map['targetParameter'] as String?;
    final bool completedVal = map['isCompleted'] as bool? ?? false;
    final bool claimedVal = map['isClaimed'] as bool? ?? false;

    // MissionTier çözümleme
    final String tierStr = map['tier'] as String? ?? 'easy';
    final MissionTier tierVal = MissionTier.values.firstWhere(
      (t) => t.name == tierStr,
      orElse: () => MissionTier.easy,
    );

    return DailyMissionModel(
      id: idVal,
      title: titleVal,
      description: descriptionVal,
      type: typeVal,
      targetProgress: targetVal,
      currentProgress: currentVal,
      tier: tierVal,
      isCompleted: completedVal,
      isClaimed: claimedVal,
      xpReward: xpRewardVal,
      targetParameter: paramVal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'targetProgress': targetProgress,
      'currentProgress': currentProgress,
      'tier': tier.name,
      'isCompleted': isCompleted,
      'isClaimed': isClaimed,
      'xpReward': xpReward,
      if (targetParameter != null) 'targetParameter': targetParameter,
    };
  }

  factory DailyMissionModel.fromEntity(DailyMission entity) {
    return DailyMissionModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      type: entity.type,
      targetProgress: entity.targetProgress,
      currentProgress: entity.currentProgress,
      tier: entity.tier,
      isCompleted: entity.isCompleted,
      isClaimed: entity.isClaimed,
      xpReward: entity.xpReward,
      targetParameter: entity.targetParameter,
    );
  }
}

/// Firestore veya SharedPreferences'tan gelen sayısal değerleri güvenli biçimde int'e dönüştürür.
/// Değer double olarak gelse bile (örn: 100.0) hata vermeden çalışır.
int _toInt(dynamic val, int defaultValue) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) return int.tryParse(val) ?? defaultValue;
  return defaultValue;
}
