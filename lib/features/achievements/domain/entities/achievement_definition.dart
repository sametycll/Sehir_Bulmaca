import 'package:flutter/foundation.dart';
import 'enums.dart';
import 'achievement.dart';
import '../services/achievement_condition.dart';

/// Statik başarım tanımı: kodda sabit olan ve Firestore'a yazılmayan veri.
///
/// [AchievementDefinition] progress bilgisi içermez — o [Achievement]'a aittir.
/// Bu ayrım, Firestore'da sadece progress tutmayı sağlar (okuma maliyeti minimal).
@immutable
class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCodePoint,
    required this.category,
    required this.rarity,
    required this.xpReward,
    required this.targetValue,
    required this.condition,
    this.isSecret = false,
  });

  final String id;
  final String title;
  final String description;
  final int iconCodePoint;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int xpReward;
  final int targetValue;
  final bool isSecret;

  /// Strategy pattern: her başarımın kendi koşul değerlendiricisi var.
  final AchievementCondition condition;

  /// Tanımı, Firestore'dan gelen progress ile birleştirerek domain entity'si oluşturur.
  Achievement toAchievement({
    int currentProgress = 0,
    bool isUnlocked = false,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      iconCodePoint: iconCodePoint,
      category: category,
      rarity: rarity,
      xpReward: xpReward,
      targetValue: targetValue,
      isSecret: isSecret,
      currentProgress: currentProgress,
      isUnlocked: isUnlocked,
      unlockedAt: unlockedAt,
    );
  }
}
