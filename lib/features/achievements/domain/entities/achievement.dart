import 'package:flutter/foundation.dart';
import 'enums.dart';

/// Domain entity — bir başarımın tüm verilerini (tanım + progress) içerir.
///
/// Freezed yerine el yazımı immutable class kullanılıyor:
/// 1. Ek kod üretimi adımı gerektirmez (build_runner).
/// 2. Achievement'lar state'te nadiren değişir — copyWith yeterlidir.
/// 3. Domain katmanı Flutter'a bağımlı olmamalı, ancak @immutable
///    annotation'ı foundation.dart'tan gelir ve kabul edilebilir.
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCodePoint,
    required this.category,
    required this.rarity,
    required this.xpReward,
    required this.targetValue,
    this.isSecret = false,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  /// Firestore'daki belge ID'si ile eşleşen benzersiz kimlik.
  final String id;

  final String title;
  final String description;

  /// IconData.codePoint — Flutter Icon widget ile kullanılır.
  final int iconCodePoint;

  final AchievementCategory category;
  final AchievementRarity rarity;

  /// Açıldığında verilen XP miktarı (gelecekte profil sisteminde kullanılabilir).
  final int xpReward;

  /// Hedef değer: örneğin "10 şehir bul" için targetValue = 10.
  final int targetValue;

  /// Gizli başarımlar: listedeki adı/açıklaması maskelenir.
  final bool isSecret;

  // --- Progress alanları (Firestore'dan yüklenir) ---

  /// Mevcut ilerleme. Örnek: 7 şehir bulundu ise currentProgress = 7.
  final int currentProgress;

  /// Başarım açıldı mı?
  final bool isUnlocked;

  /// Açılma tarihi (isUnlocked = true ise null olmaz).
  final DateTime? unlockedAt;

  // --- Computed properties ---

  /// 0.0 ile 1.0 arasında ilerleme oranı.
  double get progressRatio =>
      targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;

  /// İlerlemenin yüzde değeri (UI'da göstermek için).
  int get progressPercent => (progressRatio * 100).round();

  /// Kalan hedef sayısı.
  int get remaining => (targetValue - currentProgress).clamp(0, targetValue);

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    int? iconCodePoint,
    AchievementCategory? category,
    AchievementRarity? rarity,
    int? xpReward,
    int? targetValue,
    bool? isSecret,
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      xpReward: xpReward ?? this.xpReward,
      targetValue: targetValue ?? this.targetValue,
      isSecret: isSecret ?? this.isSecret,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Achievement && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Achievement(id: $id, progress: $currentProgress/$targetValue, unlocked: $isUnlocked)';
}
