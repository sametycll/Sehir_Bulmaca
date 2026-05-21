import 'package:cloud_firestore/cloud_firestore.dart';

/// Oyuncunun seviye ve tecrübe puanı (XP) ilerlemesini temsil eden immutable veri modeli.
class PlayerProgress {
  final String uid;
  final int level;
  final int currentXp;
  final int totalXp;
  final int xpToNextLevel;
  final DateTime lastUpdated;
  final int prestigeLevel; // Gelecekteki prestij seviyeleri için destek

  const PlayerProgress({
    required this.uid,
    required this.level,
    required this.currentXp,
    required this.totalXp,
    required this.xpToNextLevel,
    required this.lastUpdated,
    this.prestigeLevel = 0,
  });

  /// Boş/Yeni bir oyuncu profil ilerlemesi döner.
  factory PlayerProgress.empty(String uid) {
    return PlayerProgress(
      uid: uid,
      level: 1,
      currentXp: 0,
      totalXp: 0,
      xpToNextLevel: 100, // Level 1 -> 2 için gereken XP
      lastUpdated: DateTime.now(),
      prestigeLevel: 0,
    );
  }

  /// Firestore belgesinden domain modeline dönüştürür.
  factory PlayerProgress.fromFirestore(String uid, Map<String, dynamic> json) {
    final rawDate = json['lastUpdated'];
    DateTime parsedDate = DateTime.now();
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    return PlayerProgress(
      uid: uid,
      level: json['level'] as int? ?? 1,
      currentXp: json['currentXp'] as int? ?? 0,
      totalXp: json['totalXp'] as int? ?? 0,
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 100,
      lastUpdated: parsedDate,
      prestigeLevel: json['prestigeLevel'] as int? ?? 0,
    );
  }

  /// Domain modelini Firestore belgesine dönüştürür.
  Map<String, dynamic> toFirestore() {
    return {
      'level': level,
      'currentXp': currentXp,
      'totalXp': totalXp,
      'xpToNextLevel': xpToNextLevel,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'prestigeLevel': prestigeLevel,
    };
  }

  /// Immutable yapıda nesneyi güncellemek için copyWith metodu.
  PlayerProgress copyWith({
    String? uid,
    int? level,
    int? currentXp,
    int? totalXp,
    int? xpToNextLevel,
    DateTime? lastUpdated,
    int? prestigeLevel,
  }) {
    return PlayerProgress(
      uid: uid ?? this.uid,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      totalXp: totalXp ?? this.totalXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      prestigeLevel: prestigeLevel ?? this.prestigeLevel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProgress &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          level == other.level &&
          currentXp == other.currentXp &&
          totalXp == other.totalXp &&
          xpToNextLevel == other.xpToNextLevel &&
          lastUpdated == other.lastUpdated &&
          prestigeLevel == other.prestigeLevel;

  @override
  int get hashCode =>
      uid.hashCode ^
      level.hashCode ^
      currentXp.hashCode ^
      totalXp.hashCode ^
      xpToNextLevel.hashCode ^
      lastUpdated.hashCode ^
      prestigeLevel.hashCode;

  @override
  String toString() {
    return 'PlayerProgress(uid: $uid, level: $level, currentXp: $currentXp, totalXp: $totalXp, xpToNextLevel: $xpToNextLevel, prestigeLevel: $prestigeLevel)';
  }
}
