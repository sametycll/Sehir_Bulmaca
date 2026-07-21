import 'dart:developer' as developer;
import '../entities/xp_event.dart';
import 'xp_rules.dart';

/// XP hesaplamalarını event bazlı koşturan kural motoru (Rule Engine).
/// Strategy Pattern kurallarını sırayla kontrol ederek uygun olanı çalıştırır.
class XpEngine {
  XpEngine._();

  static final XpEngine instance = XpEngine._();

  final List<XpRule<XpEvent>> _rules = const [
    CityFoundXpRule(),
    ComboXpRule(),
    GameCompletedXpRule(),
    AchievementUnlockedXpRule(),
    LeaderboardBonusXpRule(),
    DailyStreakXpRule(),
    DailyMissionCompletedXpRule(),
  ];

  /// Gelen bir [XpEvent]'i kurallar süzgecinden geçirerek XP miktarını ve açıklamasını döner.
  XpResult evaluate(XpEvent event) {
    for (final rule in _rules) {
      if (rule.canHandle(event)) {
        try {
          final xp = rule.calculateXp(event);
          final description = rule.getDescription(event);
          
          developer.log('[XpEngine] Processed: ${event.runtimeType} -> +$xp XP ($description)');
          return XpResult(xp: xp, description: description);
        } catch (e) {
          developer.log('[XpEngine] Error processing rule for event ${event.runtimeType}: $e');
        }
      }
    }
    developer.log('[XpEngine] No rule found for event: ${event.runtimeType}');
    return const XpResult(xp: 0, description: '');
  }
}

/// XP motorunun değerlendirme sonucu.
class XpResult {
  final int xp;
  final String description;

  const XpResult({
    required this.xp,
    required this.description,
  });

  bool get hasReward => xp > 0;
}
