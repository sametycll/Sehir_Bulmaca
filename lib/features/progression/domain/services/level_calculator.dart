import 'dart:math' as math;

/// Seviye (Level) ve Tecrübe Puanı (XP) arasındaki matematiksel hesaplamaları
/// ve unvan atamalarını yöneten yardımcı servis.
class LevelCalculator {
  const LevelCalculator._();

  /// Toplam tecrübe puanından (Total XP) oyuncunun mevcut seviyesini hesaplar.
  /// Formül (Quadratic):
  /// L = floor((-25 + sqrt(5625 + 100 * totalXp)) / 50)
  static int calculateLevel(int totalXp) {
    if (totalXp <= 0) return 1;

    try {
      final discriminant = 5625 + 100 * totalXp;
      final root = math.sqrt(discriminant);
      final level = ((-25 + root) / 50).floor();
      return math.max(1, level);
    } catch (_) {
      return 1;
    }
  }

  /// Belirli bir seviyeye ulaşmak için gereken KÜMÜLATİF (toplam) XP miktarını döner.
  /// L=1 için 0 XP, L=2 için 100 XP, L=3 için 250 XP, L=4 için 450 XP, vb.
  /// Formül:
  /// totalXp = 25 * L^2 + 25 * L - 50
  static int totalXpToReachLevel(int level) {
    if (level <= 1) return 0;
    return 25 * level * level + 25 * level - 50;
  }

  /// Verilen seviyeden bir sonraki seviyeye geçmek için gereken XP miktarını hesaplar.
  /// L=1 iken (2'ye geçmek için) 100 XP, L=2 iken 150 XP, L=3 iken 200 XP, vb.
  /// Formül:
  /// xpNeeded = 50 * L + 50
  static int xpToNextLevelForLevel(int level) {
    if (level < 1) return 100;
    return 50 * level + 50;
  }

  /// Seviyeye göre oyuncuya verilecek unvanı (Rank Title) döner.
  static String getTitle(int level) {
    if (level >= 50) return 'Coğrafya Efsanesi';
    if (level >= 20) return 'Türkiye Fatihi';
    if (level >= 10) return 'Bölge Ustası';
    if (level >= 5) return 'Harita Kaşifi';
    return 'Çaylak Gezgin';
  }

  /// Gelecek veya geçmiş ödülleri/unvanları listelemek için tüm milestoneları döner.
  static List<LevelMilestone> getMilestones() {
    return const [
      LevelMilestone(level: 1, title: 'Çaylak Gezgin', description: 'Keşfe başlama seviyesi'),
      LevelMilestone(level: 5, title: 'Harita Kaşifi', description: 'Şehirlerin yerlerini tanımaya başladın'),
      LevelMilestone(level: 10, title: 'Bölge Ustası', description: 'Coğrafi bölgelere hakimiyet kazandın'),
      LevelMilestone(level: 20, title: 'Türkiye Fatihi', description: 'Tüm ülkeyi avucunun içi gibi biliyorsun'),
      LevelMilestone(level: 50, title: 'Coğrafya Efsanesi', description: 'Seni alt edebilecek hiçbir şehir yok!'),
    ];
  }
}

/// Her bir unvan/milestone seviye tanımı.
class LevelMilestone {
  final int level;
  final String title;
  final String description;

  const LevelMilestone({
    required this.level,
    required this.title,
    required this.description,
  });
}
