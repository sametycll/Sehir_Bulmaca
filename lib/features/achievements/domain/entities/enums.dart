// Achievement sisteminin tüm enum tanımları.
// Merkezi tutulması, hem domain hem UI katmanının aynı enum'ları
// kullanmasını garantiler — stringly typed yaklaşımdan kaçınılır.

/// Başarımın nadirliği: UI'da renk ve ses efekti için kullanılır.
enum AchievementRarity {
  common,    // Gri — kolay başarımlar
  rare,      // Mavi — orta zorluk
  epic,      // Mor — zor başarımlar
  legendary, // Altın — çok zor / özel
}

/// Başarımın kategorisi: achievement ekranında gruplamak için.
enum AchievementCategory {
  exploration,  // Şehir keşfi
  combo,        // Kombo yapmak
  speed,        // Hız modu başarımları
  completion,   // Oyun/mod tamamlama
  leaderboard,  // Liderlik tablosu
  streak,       // Günlük giriş serisi
  special,      // Özel / gizli
}

extension AchievementRarityExtension on AchievementRarity {
  String get label {
    switch (this) {
      case AchievementRarity.common:    return 'Yaygın';
      case AchievementRarity.rare:      return 'Nadir';
      case AchievementRarity.epic:      return 'Epik';
      case AchievementRarity.legendary: return 'Efsanevi';
    }
  }

  /// UI'da kullanılacak renk. AppColors'a bağımlılık olmadan tanımlanır
  /// (domain katmanı UI'dan bağımsız olmalı).
  int get colorValue {
    switch (this) {
      case AchievementRarity.common:    return 0xFF9E9E9E; // Gri
      case AchievementRarity.rare:      return 0xFF4FC3F7; // Açık mavi
      case AchievementRarity.epic:      return 0xFFCE93D8; // Mor
      case AchievementRarity.legendary: return 0xFFFFD700; // Altın
    }
  }
}

extension AchievementCategoryExtension on AchievementCategory {
  String get label {
    switch (this) {
      case AchievementCategory.exploration:  return 'Keşif';
      case AchievementCategory.combo:        return 'Kombo';
      case AchievementCategory.speed:        return 'Hız';
      case AchievementCategory.completion:   return 'Tamamlama';
      case AchievementCategory.leaderboard:  return 'Liderlik';
      case AchievementCategory.streak:       return 'Seri';
      case AchievementCategory.special:      return 'Özel';
    }
  }

  int get iconCodePoint {
    switch (this) {
      case AchievementCategory.exploration:  return 0xe574; // Icons.explore_rounded
      case AchievementCategory.combo:        return 0xef14; // Icons.bolt_rounded
      case AchievementCategory.speed:        return 0xf08b; // Icons.speed_rounded
      case AchievementCategory.completion:   return 0xef55; // Icons.emoji_events_rounded
      case AchievementCategory.leaderboard:  return 0xf04b; // Icons.leaderboard_rounded
      case AchievementCategory.streak:       return 0xeec6; // Icons.local_fire_department_rounded
      case AchievementCategory.special:      return 0xef50; // Icons.star_rounded
    }
  }
}
