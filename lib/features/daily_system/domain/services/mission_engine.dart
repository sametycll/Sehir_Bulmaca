import 'dart:math';
import '../entities/daily_mission.dart';
import '../entities/mission_event.dart';

/// Olay tabanlı görev ilerleme motoru (Mission Engine).
/// strategy pattern kullanarak gelen olaylara göre görevlerin ilerlemesini günceller.
class MissionEngine {
  const MissionEngine();

  /// Gelen bir [MissionEvent] olayını işler ve mevcut görevlerin ilerlemelerini günceller.
  /// Tamamlanan görevlerin durumunu günceller.
  static List<DailyMission> processEvent(List<DailyMission> currentMissions, MissionEvent event) {
    return currentMissions.map((mission) {
      if (mission.isCompleted) return mission;

      int progressDelta = 0;

      switch (event) {
        case CityFoundMissionEvent e:
          if (mission.type == 'city_found') {
            // Eğer belirli bir mod kısıtlaması varsa ve eşleşmiyorsa pas geç
            if (mission.targetParameter != null && mission.targetParameter != e.modeId) {
              break;
            }
            progressDelta = 1;
          } else if (mission.type == 'combo') {
            // Combo kontrolü (Örn: En az X combo yapıldığında ilerlemeyi 1 artır)
            final requiredCombo = int.tryParse(mission.targetParameter ?? '3') ?? 3;
            if (e.comboCount >= requiredCombo) {
              progressDelta = 1;
            }
          }
          break;

        case GameCompletedMissionEvent e:
          if (mission.type == 'game_completed') {
            if (mission.targetParameter != null && mission.targetParameter != e.modeId) {
              break;
            }
            progressDelta = 1;
          } else if (mission.type == 'cities_in_mode') {
            // Belirli bir oyun modunda kazanılan toplam puan/bulunan şehir sayısı
            if (mission.targetParameter != null && mission.targetParameter == e.modeId) {
              progressDelta = e.score;
            }
          }
          break;

        case XpEarnedMissionEvent e:
          if (mission.type == 'xp_earned') {
            progressDelta = e.amount;
          }
          break;

        case AchievementUnlockedMissionEvent _:
          if (mission.type == 'achievement_unlocked') {
            progressDelta = 1;
          }
          break;

        case PlayTimeMissionEvent e:
          if (mission.type == 'play_time') {
            progressDelta = e.minutes;
          }
          break;
      }

      if (progressDelta > 0) {
        final newProgress = (mission.currentProgress + progressDelta).clamp(0, mission.targetProgress);
        final completed = newProgress >= mission.targetProgress;
        return mission.copyWith(
          currentProgress: newProgress,
          isCompleted: completed,
        );
      }

      return mission;
    }).toList();
  }

  /// Günlük görev havuzu (Master Mission Pool).
  /// Buradan her gün rastgele görevler seçilir.
  static final List<DailyMission> _masterMissionPool = [
    // Kolay Görevler (Easy)
    DailyMission(
      id: 'easy_city_found_5',
      title: 'Hızlı Bulucu',
      description: 'Hangi modda olursa olsun 5 şehir bul.',
      type: 'city_found',
      targetProgress: 5,
      currentProgress: 0,
      tier: MissionTier.easy,
      isCompleted: false,
      isClaimed: false,
      xpReward: 100,
    ),
    DailyMission(
      id: 'easy_combo_3',
      title: 'İyi Odaklanma',
      description: 'En az 3 kombo yap (3 şehri ardı ardına hatasız bul).',
      type: 'combo',
      targetProgress: 1,
      currentProgress: 0,
      tier: MissionTier.easy,
      isCompleted: false,
      isClaimed: false,
      xpReward: 100,
      targetParameter: '3',
    ),
    DailyMission(
      id: 'easy_game_completed_1',
      title: 'İlk Adım',
      description: 'Herhangi bir oyun modunda 1 oyunu tamamla.',
      type: 'game_completed',
      targetProgress: 1,
      currentProgress: 0,
      tier: MissionTier.easy,
      isCompleted: false,
      isClaimed: false,
      xpReward: 120,
    ),

    // Orta Görevler (Medium)
    DailyMission(
      id: 'medium_city_found_15',
      title: 'Harita Kaşifi',
      description: 'Herhangi bir modda toplam 15 şehir bul.',
      type: 'city_found',
      targetProgress: 15,
      currentProgress: 0,
      tier: MissionTier.medium,
      isCompleted: false,
      isClaimed: false,
      xpReward: 200,
    ),
    DailyMission(
      id: 'medium_combo_5',
      title: 'Kombo Ustası',
      description: 'En az 5 kombo yap (5 şehri ardı ardına hatasız bul).',
      type: 'combo',
      targetProgress: 1,
      currentProgress: 0,
      tier: MissionTier.medium,
      isCompleted: false,
      isClaimed: false,
      xpReward: 250,
      targetParameter: '5',
    ),
    DailyMission(
      id: 'medium_play_time_10',
      title: 'Sadık Oyuncu',
      description: 'Toplam 10 dakika boyunca şehir bulmaca oyna.',
      type: 'play_time',
      targetProgress: 10,
      currentProgress: 0,
      tier: MissionTier.medium,
      isCompleted: false,
      isClaimed: false,
      xpReward: 250,
    ),

    // Zor Görevler (Hard)
    DailyMission(
      id: 'hard_combo_8',
      title: 'Zihin Fırtınası',
      description: 'En az 8 kombo yap (8 şehri ardı ardına hatasız bul).',
      type: 'combo',
      targetProgress: 1,
      currentProgress: 0,
      tier: MissionTier.hard,
      isCompleted: false,
      isClaimed: false,
      xpReward: 400,
      targetParameter: '8',
    ),
    DailyMission(
      id: 'hard_game_completed_time_attack_3',
      title: 'Zamana Karşı Yarış',
      description: 'Zamana Karşı modunda 3 oyun tamamla.',
      type: 'game_completed',
      targetProgress: 3,
      currentProgress: 0,
      tier: MissionTier.hard,
      isCompleted: false,
      isClaimed: false,
      xpReward: 450,
      targetParameter: 'time_attack',
    ),
    DailyMission(
      id: 'hard_xp_earned_1000',
      title: 'Tecrübe Avcısı',
      description: 'Bugün oyunlardan toplam 1000 XP kazan.',
      type: 'xp_earned',
      targetProgress: 1000,
      currentProgress: 0,
      tier: MissionTier.hard,
      isCompleted: false,
      isClaimed: false,
      xpReward: 500,
    ),

    // Efsanevi Görevler (Legendary)
    DailyMission(
      id: 'legendary_all_turkey_completed_1',
      title: 'Türkiye Fatihi',
      description: 'Tüm Türkiye modunu başarıyla tamamla.',
      type: 'game_completed',
      targetProgress: 1,
      currentProgress: 0,
      tier: MissionTier.legendary,
      isCompleted: false,
      isClaimed: false,
      xpReward: 1000,
      targetParameter: 'all_turkey',
    ),
    DailyMission(
      id: 'legendary_city_found_50',
      title: 'Coğrafya Profesörü',
      description: 'Toplam 50 şehir bul.',
      type: 'city_found',
      targetProgress: 50,
      currentProgress: 0,
      tier: MissionTier.legendary,
      isCompleted: false,
      isClaimed: false,
      xpReward: 1000,
    ),
  ];

  /// Belirli bir gün için rastgele günlük görev havuzu oluşturur.
  /// Standart olarak: 1 Kolay, 1 Orta, 1 Zor görev seçer.
  /// (Gerekirse efsanevi görev çıkma şansı da eklenmiştir: %10 ihtimalle Zor yerine Efsanevi)
  static List<DailyMission> generateDailyMissions({int seedOffset = 0}) {
    final now = DateTime.now();
    // Her gün aynı tohum (seed) değerini kullanarak tüm kullanıcılar için veya
    // gün bazlı deterministic görevler üretiriz.
    final seed = now.year * 10000 + now.month * 100 + now.day + seedOffset;
    final random = Random(seed);

    final easyMissions = _masterMissionPool.where((m) => m.tier == MissionTier.easy).toList();
    final mediumMissions = _masterMissionPool.where((m) => m.tier == MissionTier.medium).toList();
    final hardMissions = _masterMissionPool.where((m) => m.tier == MissionTier.hard).toList();
    final legendaryMissions = _masterMissionPool.where((m) => m.tier == MissionTier.legendary).toList();

    final List<DailyMission> selected = [];

    // 1. Kolay Görev Seçimi
    if (easyMissions.isNotEmpty) {
      final idx = random.nextInt(easyMissions.length);
      selected.add(_cloneMission(easyMissions[idx], random));
    }

    // 2. Orta Görev Seçimi
    if (mediumMissions.isNotEmpty) {
      final idx = random.nextInt(mediumMissions.length);
      selected.add(_cloneMission(mediumMissions[idx], random));
    }

    // 3. Zor veya Efsanevi Görev Seçimi (%10 efsanevi, %90 zor)
    final roll = random.nextDouble();
    if (roll < 0.10 && legendaryMissions.isNotEmpty) {
      final idx = random.nextInt(legendaryMissions.length);
      selected.add(_cloneMission(legendaryMissions[idx], random));
    } else if (hardMissions.isNotEmpty) {
      final idx = random.nextInt(hardMissions.length);
      selected.add(_cloneMission(hardMissions[idx], random));
    }

    return selected;
  }

  /// Görev şablonunu klonlayarak benzersiz bir ID verir (Çakışmaları önlemek için gün bazlı)
  static DailyMission _cloneMission(DailyMission template, Random random) {
    final now = DateTime.now();
    final uniqueId = '${template.id}_${now.year}_${now.month}_${now.day}';
    return DailyMission(
      id: uniqueId,
      title: template.title,
      description: template.description,
      type: template.type,
      targetProgress: template.targetProgress,
      currentProgress: 0,
      tier: template.tier,
      isCompleted: false,
      isClaimed: false,
      xpReward: template.xpReward,
      targetParameter: template.targetParameter,
    );
  }
}
