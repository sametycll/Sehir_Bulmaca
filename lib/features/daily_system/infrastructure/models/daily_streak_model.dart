import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/daily_streak.dart';

class DailyStreakModel extends DailyStreak {
  DailyStreakModel({
    required super.currentStreak,
    required super.bestStreak,
    super.lastClaimedDate,
    required super.missionsResetAt,
    super.lastActiveDate,
  });

  factory DailyStreakModel.fromMap(Map<String, dynamic> map) {
    final int currentVal = _toInt(map['currentStreak'], 0);
    final int bestVal = _toInt(map['bestStreak'], 0);

    DateTime? parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    final DateTime? lastClaimedVal = parseDate(map['lastClaimedDate']);
    final DateTime? resetVal = parseDate(map['missionsResetAt']);
    final DateTime? lastActiveVal = parseDate(map['lastActiveDate']);

    return DailyStreakModel(
      currentStreak: currentVal,
      bestStreak: bestVal,
      lastClaimedDate: lastClaimedVal,
      missionsResetAt: resetVal ?? DateTime.now().add(const Duration(days: 1)),
      lastActiveDate: lastActiveVal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastClaimedDate': lastClaimedDate != null ? Timestamp.fromDate(lastClaimedDate!) : null,
      'missionsResetAt': Timestamp.fromDate(missionsResetAt),
      'lastActiveDate': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
    };
  }

  factory DailyStreakModel.fromEntity(DailyStreak entity) {
    return DailyStreakModel(
      currentStreak: entity.currentStreak,
      bestStreak: entity.bestStreak,
      lastClaimedDate: entity.lastClaimedDate,
      missionsResetAt: entity.missionsResetAt,
      lastActiveDate: entity.lastActiveDate,
    );
  }
}

/// Firestore veya SharedPreferences'tan gelen sayısal değerleri güvenli biçimde int'e dönüştürür.
/// Değer double olarak gelse bile (örn: 5.0) hata vermeden çalışır.
int _toInt(dynamic val, int defaultValue) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) return int.tryParse(val) ?? defaultValue;
  return defaultValue;
}
