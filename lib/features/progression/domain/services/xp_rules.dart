import '../entities/xp_event.dart';

/// XP hesaplama ve açıklama üretme kuralları için taban strateji sınıfı.
abstract class XpRule<T extends XpEvent> {
  const XpRule();

  /// Bu kuralın ilgili event'i işleyip işleyemeyeceğini denetler.
  bool canHandle(XpEvent event) => event is T;

  /// Event için kazanılacak tecrübe puanını (XP) hesaplar.
  int calculateXp(T event);

  /// UI veya istatistiklerde gösterilecek açıklama metnini üretir.
  String getDescription(T event);
}

/// Şehir bulma olayı XP kuralı.
class CityFoundXpRule extends XpRule<CityFoundXpEvent> {
  const CityFoundXpRule();

  @override
  int calculateXp(CityFoundXpEvent event) => 10; // Her şehir: +10 XP

  @override
  String getDescription(CityFoundXpEvent event) => '${event.cityName} Bulundu';
}

/// Kombo tahmin olayı XP kuralı.
class ComboXpRule extends XpRule<ComboXpEvent> {
  const ComboXpRule();

  // Kombo sayısı -> XP ödülü eşleşmesi. Modüler tasarım, if-else gerektirmez.
  static const Map<int, int> _comboRewards = {
    2: 20,  // x2 combo: +20 XP
    5: 75,  // x5 combo: +75 XP
  };

  @override
  int calculateXp(ComboXpEvent event) {
    return _comboRewards[event.comboCount] ?? 0;
  }

  @override
  String getDescription(ComboXpEvent event) => 'x${event.comboCount} Kombo Bonusu 🔥';
}

/// Oyun bitirme/tamamlama olayı XP kuralı.
class GameCompletedXpRule extends XpRule<GameCompletedXpEvent> {
  const GameCompletedXpRule();

  @override
  int calculateXp(GameCompletedXpEvent event) {
    if (event.modeId == 'all_turkey') {
      return 1000; // Tüm Türkiye tamamlama: +1000 XP
    }
    if (event.isRegion) {
      return 250;  // Bölge modu tamamlama: +250 XP
    }
    return 100;    // Diğer modlar (Zamana karşı, vb.) tamamlama: +100 XP
  }

  @override
  String getDescription(GameCompletedXpEvent event) {
    if (event.modeId == 'all_turkey') {
      return 'Türkiye Haritası Tamamlandı! 🏆';
    }
    return 'Oyun Modu Başarıyla Bitti';
  }
}

/// Başarım kazanma olayı XP kuralı.
class AchievementUnlockedXpRule extends XpRule<AchievementUnlockedXpEvent> {
  const AchievementUnlockedXpRule();

  @override
  int calculateXp(AchievementUnlockedXpEvent event) => event.xpReward;

  @override
  String getDescription(AchievementUnlockedXpEvent event) => 'Yeni Başarım Açıldı! 🎖️';
}

/// Liderlik tablosu sıralaması XP kuralı.
class LeaderboardBonusXpRule extends XpRule<LeaderboardBonusXpEvent> {
  const LeaderboardBonusXpRule();

  @override
  int calculateXp(LeaderboardBonusXpEvent event) {
    // İlk 10 sıralama bonusu
    if (event.rank <= 10) {
      return 200; // İlk 10 bonusu: +200 XP
    }
    return 50; // Sıralama tablosuna giriş bonusu: +50 XP
  }

  @override
  String getDescription(LeaderboardBonusXpEvent event) {
    if (event.rank <= 10) {
      return 'Liderlik Tablosu İlk 10 Bonusu 🥇';
    }
    return 'Liderlik Tablosuna Giriş Bonusu';
  }
}

/// Günlük giriş serisi XP kuralı.
class DailyStreakXpRule extends XpRule<DailyStreakXpEvent> {
  const DailyStreakXpRule();

  @override
  int calculateXp(DailyStreakXpEvent event) {
    // Seri gün sayısına göre artan ödül, taban 100 XP + her gün için 20 XP
    return 100 + (event.streakCount * 20);
  }

  @override
  String getDescription(DailyStreakXpEvent event) => '${event.streakCount} Günlük Seri Giriş Bonusu ⚡';
}

/// Günlük görev tamamlama XP kuralı.
class DailyMissionCompletedXpRule extends XpRule<DailyMissionCompletedXpEvent> {
  const DailyMissionCompletedXpRule();

  @override
  int calculateXp(DailyMissionCompletedXpEvent event) => event.xpReward;

  @override
  String getDescription(DailyMissionCompletedXpEvent event) => 'Günlük Görev Tamamlandı! 🎯';
}
