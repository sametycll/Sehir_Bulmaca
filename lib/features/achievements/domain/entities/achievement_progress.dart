import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore'da `users/{uid}/achievements/{achievementId}` belgesinin modeli.
///
/// Sadece progress verisi tutulur — tanım bilgileri local'dedir.
/// Bu yaklaşım Firestore okuma maliyetini minimize eder.
class AchievementProgress {
  const AchievementProgress({
    required this.achievementId,
    required this.progress,
    required this.unlocked,
    this.unlockedAt,
  });

  final String achievementId;
  final int progress;
  final bool unlocked;
  final DateTime? unlockedAt;

  Map<String, dynamic> toFirestore() {
    return {
      'achievementId': achievementId,
      'progress': progress,
      'unlocked': unlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }

  factory AchievementProgress.fromFirestore(Map<String, dynamic> data) {
    final rawDate = data['unlockedAt'];
    DateTime? parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    }

    return AchievementProgress(
      achievementId: data['achievementId'] as String? ?? '',
      progress: data['progress'] as int? ?? 0,
      unlocked: data['unlocked'] as bool? ?? false,
      unlockedAt: parsedDate,
    );
  }

  AchievementProgress copyWith({
    int? progress,
    bool? unlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementProgress(
      achievementId: achievementId,
      progress: progress ?? this.progress,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// Engine'in evaluate sonucu — hangi achievement güncellendi.
class AchievementUpdate {
  const AchievementUpdate({
    required this.achievementId,
    required this.newProgress,
    required this.targetValue,
    required this.wasJustUnlocked,
  });

  final String achievementId;
  final int newProgress;
  final int targetValue;

  /// Bu event ile tam olarak şu an açıldı mı?
  /// (Daha önce açılmış olanlar hariç tutulur — tekrar bildirim gösterilmez.)
  final bool wasJustUnlocked;
}
