import '../entities/achievement_event.dart';
import '../entities/achievement_progress.dart';
import '../entities/achievement_definition.dart';
import 'achievement_definitions.dart';

/// Event-driven achievement evaluation engine.
///
/// PERFORMANS STRATEJİSİ:
/// Başlangıçta definitions listesini bir HashMap index'e çevirir:
///   Map type_to_list_index
///
/// Her event geldiğinde sadece ilgili condition'lar çalışır.
/// 18 achievement, 5 event tipi → ortalama 3-4 condition/event.
/// O(k) complexity, k = ilgili condition sayısı. O(n²) yok.
class AchievementEngine {
  AchievementEngine._({required Map<Type, List<_IndexEntry>> index})
      : _index = index;

  final Map<Type, List<_IndexEntry>> _index;

  /// Singleton instance — engine definitions sabittir, tekrar oluşturmaya gerek yok.
  static final AchievementEngine instance = AchievementEngine._build();

  factory AchievementEngine._build() {
    final index = <Type, List<_IndexEntry>>{};

    for (final def in AchievementDefinitions.all) {
      for (final eventType in def.condition.handledEventTypes) {
        index.putIfAbsent(eventType, () => []).add(_IndexEntry(def));
      }
    }

    return AchievementEngine._(index: index);
  }

  /// Verilen event'i değerlendirerek etkilenen achievement'ları döner.
  ///
  /// [progressMap]: achievementId → currentProgress (Firestore'dan yüklenmiş)
  ///
  /// Döndürülen liste sadece değişen achievement'ları içerir.
  /// Değişmeyen achievement'lar dahil edilmez → gereksiz Firestore write yok.
  List<AchievementUpdate> evaluate(
    AchievementEvent event,
    Map<String, AchievementProgress> progressMap,
  ) {
    final eventType = event.runtimeType;
    final entries = _index[eventType];
    if (entries == null || entries.isEmpty) return const [];

    final updates = <AchievementUpdate>[];

    for (final entry in entries) {
      final id = entry.definition.id;
      final current = progressMap[id];

      // Zaten açılmış başarımlar için tekrar değerlendirme yapma
      if (current != null && current.unlocked) continue;

      final currentProgress = current?.progress ?? 0;
      final newProgress =
          entry.definition.condition.evaluate(event, currentProgress);

      if (newProgress == null || newProgress == currentProgress) continue;

      final clamped = newProgress.clamp(0, entry.definition.targetValue);
      final wasJustUnlocked =
          clamped >= entry.definition.targetValue && currentProgress < entry.definition.targetValue;

      updates.add(AchievementUpdate(
        achievementId: id,
        newProgress: clamped,
        targetValue: entry.definition.targetValue,
        wasJustUnlocked: wasJustUnlocked,
      ));
    }

    return updates;
  }
}

/// Engine'in dahili index girdisi.
class _IndexEntry {
  const _IndexEntry(this.definition);
  final AchievementDefinition definition;
}
