class DailyStreak {
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastClaimedDate; // Giriş serisi ödülünün en son alındığı tarih (gece yarısı tabanlı)
  final DateTime missionsResetAt; // Günlük sıfırlama zaman damgası
  final DateTime? lastActiveDate; // Serinin kontrolü için son aktif olunan gün

  DailyStreak({
    required this.currentStreak,
    required this.bestStreak,
    this.lastClaimedDate,
    required this.missionsResetAt,
    this.lastActiveDate,
  });

  DailyStreak copyWith({
    int? currentStreak,
    int? bestStreak,
    DateTime? lastClaimedDate,
    DateTime? missionsResetAt,
    DateTime? lastActiveDate,
  }) {
    return DailyStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastClaimedDate: lastClaimedDate ?? this.lastClaimedDate,
      missionsResetAt: missionsResetAt ?? this.missionsResetAt,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  factory DailyStreak.empty() {
    return DailyStreak(
      currentStreak: 0,
      bestStreak: 0,
      missionsResetAt: DateTime.now().add(const Duration(days: 1)),
    );
  }
}
