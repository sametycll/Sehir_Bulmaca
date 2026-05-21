import '../entities/achievement_definition.dart';
import '../entities/enums.dart';
import 'achievement_condition.dart';

/// Tüm başarım tanımlarının merkezi deposu.
///
/// YENİ BAŞARIM EKLEMEK:
/// Bu listeye tek satır eklemek yeterlidir.
/// Engine, provider ve UI otomatik olarak dahil eder.
///
/// ÖNEMLİ: ID'ler Firestore belge ID'leri ile birebir eşleşmelidir.
/// Değiştirme: eski ID'leri asla değiştirme, mevcut kullanıcı datası kaybolur.
class AchievementDefinitions {
  const AchievementDefinitions._();

  static const List<AchievementDefinition> all = [
    // ─────────────────────────────────────────────────────────
    // KEŞİF (EXPLORATION)
    // ─────────────────────────────────────────────────────────
    AchievementDefinition(
      id: 'first_city',
      title: 'İlk Adım',
      description: 'İlk şehri bul.',
      iconCodePoint: 0xe574, // Icons.explore_rounded
      category: AchievementCategory.exploration,
      rarity: AchievementRarity.common,
      xpReward: 10,
      targetValue: 1,
      condition: CityFoundIncrementalCondition(),
    ),
    AchievementDefinition(
      id: 'cities_10',
      title: 'Şehir Kaşifi',
      description: 'Toplam 10 şehir bul.',
      iconCodePoint: 0xe574,
      category: AchievementCategory.exploration,
      rarity: AchievementRarity.common,
      xpReward: 25,
      targetValue: 10,
      condition: CityFoundIncrementalCondition(),
    ),
    AchievementDefinition(
      id: 'cities_50',
      title: 'Yarı Haritacı',
      description: 'Toplam 50 şehir bul.',
      iconCodePoint: 0xe574,
      category: AchievementCategory.exploration,
      rarity: AchievementRarity.rare,
      xpReward: 75,
      targetValue: 50,
      condition: CityFoundIncrementalCondition(),
    ),
    AchievementDefinition(
      id: 'cities_100',
      title: 'Harita Ustası',
      description: 'Toplam 100 şehir bul.',
      iconCodePoint: 0xe574,
      category: AchievementCategory.exploration,
      rarity: AchievementRarity.epic,
      xpReward: 150,
      targetValue: 100,
      condition: CityFoundIncrementalCondition(),
    ),
    AchievementDefinition(
      id: 'cities_500',
      title: 'Deneyimli Kaşif',
      description: 'Toplam 500 şehir bul.',
      iconCodePoint: 0xef14, // Icons.bolt_rounded
      category: AchievementCategory.exploration,
      rarity: AchievementRarity.epic,
      xpReward: 300,
      targetValue: 500,
      condition: CityFoundIncrementalCondition(),
    ),
    AchievementDefinition(
      id: 'cities_1000',
      title: 'Efsane Kaşif',
      description: 'Toplam 1000 şehir bul. Gerçek bir coğrafya ustasısın!',
      iconCodePoint: 0xef50, // Icons.star_rounded
      category: AchievementCategory.exploration,
      rarity: AchievementRarity.legendary,
      xpReward: 1000,
      targetValue: 1000,
      condition: CityFoundIncrementalCondition(),
    ),

    // ─────────────────────────────────────────────────────────
    // KOMBO (COMBO)
    // ─────────────────────────────────────────────────────────
    AchievementDefinition(
      id: 'first_combo',
      title: 'İlk Kombo',
      description: '4 saniye içinde arka arkaya 2 şehir bul.',
      iconCodePoint: 0xef14, // Icons.bolt_rounded
      category: AchievementCategory.combo,
      rarity: AchievementRarity.common,
      xpReward: 15,
      targetValue: 1,
      condition: ComboThresholdCondition(minCombo: 2),
    ),
    AchievementDefinition(
      id: 'combo_x5',
      title: 'Kombo Makinesi',
      description: 'x5 kombo yap.',
      iconCodePoint: 0xef14,
      category: AchievementCategory.combo,
      rarity: AchievementRarity.rare,
      xpReward: 50,
      targetValue: 1,
      condition: ComboThresholdCondition(minCombo: 5),
    ),
    AchievementDefinition(
      id: 'combo_x10',
      title: 'Kombo Efsanesi',
      description: 'x10 kombo yap. İnanılmaz bir hız!',
      iconCodePoint: 0xef14,
      category: AchievementCategory.combo,
      rarity: AchievementRarity.legendary,
      xpReward: 200,
      targetValue: 1,
      condition: ComboThresholdCondition(minCombo: 10),
    ),

    // ─────────────────────────────────────────────────────────
    // TAMAMLAMA (COMPLETION)
    // ─────────────────────────────────────────────────────────
    AchievementDefinition(
      id: 'first_game',
      title: 'İlk Oyun',
      description: 'İlk oyununu tamamla.',
      iconCodePoint: 0xef55, // Icons.emoji_events_rounded
      category: AchievementCategory.completion,
      rarity: AchievementRarity.common,
      xpReward: 20,
      targetValue: 1,
      condition: GameCompletedIncrementalCondition(),
    ),
    AchievementDefinition(
      id: 'all_turkey',
      title: 'Türkiye Şampiyonu',
      description: 'Tüm Türkiye modunda 81 ili eksiksiz bul.',
      iconCodePoint: 0xef55,
      category: AchievementCategory.completion,
      rarity: AchievementRarity.epic,
      xpReward: 500,
      targetValue: 1,
      condition: GameModeCompletedCondition(
        modeId: 'all_turkey',
        requireAllCities: true,
      ),
    ),
    AchievementDefinition(
      id: 'region_karadeniz',
      title: 'Karadeniz Fatihi',
      description: 'Karadeniz Bölgesi modunu tamamla.',
      iconCodePoint: 0xe2b7, // Icons.forest_rounded
      category: AchievementCategory.completion,
      rarity: AchievementRarity.rare,
      xpReward: 100,
      targetValue: 1,
      condition: GameModeCompletedCondition(
        modeId: 'karadeniz',
        requireAllCities: true,
      ),
    ),
    AchievementDefinition(
      id: 'region_marmara',
      title: 'Marmara Efendisi',
      description: 'Marmara Bölgesi modunu tamamla.',
      iconCodePoint: 0xe7d4, // Icons.water_rounded
      category: AchievementCategory.completion,
      rarity: AchievementRarity.rare,
      xpReward: 100,
      targetValue: 1,
      condition: GameModeCompletedCondition(
        modeId: 'marmara',
        requireAllCities: true,
      ),
    ),

    // ─────────────────────────────────────────────────────────
    // HIZ (SPEED)
    // ─────────────────────────────────────────────────────────
    AchievementDefinition(
      id: 'blitz_30',
      title: 'Hız Ustası',
      description: '60 Saniye Yarışı modunda 30 şehir bul.',
      iconCodePoint: 0xf08b, // Icons.speed_rounded
      category: AchievementCategory.speed,
      rarity: AchievementRarity.rare,
      xpReward: 150,
      targetValue: 1,
      condition: BlitzMinCitiesCondition(minCities: 30),
    ),
    AchievementDefinition(
      id: 'blitz_50',
      title: 'Işık Hızı',
      description: '60 Saniye Yarışı modunda 50 şehir bul.',
      iconCodePoint: 0xf08b,
      category: AchievementCategory.speed,
      rarity: AchievementRarity.legendary,
      xpReward: 500,
      targetValue: 1,
      condition: BlitzMinCitiesCondition(minCities: 50),
      isSecret: true,
    ),

    // ─────────────────────────────────────────────────────────
    // LİDERLİK (LEADERBOARD)
    // ─────────────────────────────────────────────────────────
    AchievementDefinition(
      id: 'first_leaderboard',
      title: 'Liderlik Girişi',
      description: 'Küresel liderlik tablosuna ilk girişini yap.',
      iconCodePoint: 0xf04b, // Icons.leaderboard_rounded
      category: AchievementCategory.leaderboard,
      rarity: AchievementRarity.rare,
      xpReward: 75,
      targetValue: 1,
      condition: LeaderboardEnteredCondition(),
    ),

    // ─────────────────────────────────────────────────────────
    // SERİ (STREAK)
    // ─────────────────────────────────────────────────────────
    AchievementDefinition(
      id: 'streak_3',
      title: '3 Günlük Seri',
      description: '3 gün üst üste oyna.',
      iconCodePoint: 0xeec6, // Icons.local_fire_department_rounded
      category: AchievementCategory.streak,
      rarity: AchievementRarity.rare,
      xpReward: 60,
      targetValue: 3,
      condition: DailyStreakCondition(),
    ),
    AchievementDefinition(
      id: 'streak_7',
      title: 'Haftalık Oyuncu',
      description: '7 gün üst üste oyna.',
      iconCodePoint: 0xeec6,
      category: AchievementCategory.streak,
      rarity: AchievementRarity.epic,
      xpReward: 200,
      targetValue: 7,
      condition: DailyStreakCondition(),
    ),
  ];

  /// ID ile hızlı arama — engine ve provider'lar kullanır.
  static final Map<String, AchievementDefinition> _byId = {
    for (final d in all) d.id: d,
  };

  static AchievementDefinition? findById(String id) => _byId[id];

  /// Kategoriye göre filtrelenmiş liste.
  static List<AchievementDefinition> byCategory(AchievementCategory cat) =>
      all.where((d) => d.category == cat).toList();
}
