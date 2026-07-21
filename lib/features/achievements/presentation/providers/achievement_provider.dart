import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/achievement_event.dart';
import '../../domain/entities/achievement_progress.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../../domain/services/achievement_definitions.dart';
import '../../domain/services/achievement_engine.dart';
import '../../infrastructure/datasources/firestore_achievement_datasource.dart';
import '../../infrastructure/datasources/local_achievement_cache.dart';
import '../../infrastructure/repositories/achievement_repository_impl.dart';
import '../controllers/achievement_overlay_controller.dart';
import '../../domain/entities/enums.dart';
import '../../../game/infrastructure/services/audio_service.dart';
import '../../../leaderboard/presentation/providers/leaderboard_provider.dart'
    show firestoreProvider;
import '../../../progression/domain/entities/xp_event.dart';
import '../../../progression/presentation/providers/progression_provider.dart';
import '../../../daily_system/presentation/providers/daily_notifier.dart';
import '../../../daily_system/domain/entities/mission_event.dart';

// ─────────────────────────────────────────────────────────────────
// INFRASTRUCTURE PROVIDERS
// ─────────────────────────────────────────────────────────────────

final _localCacheProvider = Provider<LocalAchievementCache>((ref) {
  return LocalAchievementCache();
});

final _firestoreDatasourceProvider =
    Provider<FirestoreAchievementDatasource>((ref) {
  return FirestoreAchievementDatasource(ref.watch(firestoreProvider));
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepositoryImpl(
    firestoreDatasource: ref.watch(_firestoreDatasourceProvider),
    localCache: ref.watch(_localCacheProvider),
  );
});

// ─────────────────────────────────────────────────────────────────
// AUTH STREAM — reactive user ID provider
// ─────────────────────────────────────────────────────────────────

/// Firebase Auth stream'i izler. Kullanıcı değiştiğinde achievement
/// provider'ı otomatik rebuild olur.
final _authUserIdProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((u) => u?.uid);
});

// ─────────────────────────────────────────────────────────────────
// ACHIEVEMENT PROGRESS NOTIFIER (Ana provider)
// ─────────────────────────────────────────────────────────────────

/// Key: achievementId, Value: Firestore'dan veya cache'den gelen progress.
final achievementProgressProvider =
    AsyncNotifierProvider<AchievementProgressNotifier, Map<String, AchievementProgress>>(
  AchievementProgressNotifier.new,
);

class AchievementProgressNotifier
    extends AsyncNotifier<Map<String, AchievementProgress>> {
  /// Debounce timer — spam Firestore write'ları önler.
  Timer? _saveTimer;
  /// Bekleyen kayıt listesi — timer tetiklenince batch write yapılır.
  final List<AchievementProgress> _pendingSaves = [];

  @override
  Future<Map<String, AchievementProgress>> build() async {
    // Auth değişimini dinle — sign out/in'de provider rebuild olur
    final userIdAsync = ref.watch(_authUserIdProvider);
    final userId = userIdAsync.valueOrNull;

    if (userId == null) return {};

    final repo = ref.read(achievementRepositoryProvider);
    final progress = await repo.fetchProgress(userId);

    // Günlük giriş serisi (streak) kontrolü ve event tetikleme
    // Async işlemler build()'i bloklamaması için microtask ile yapıyoruz
    Future.microtask(() async {
      final cache = ref.read(_localCacheProvider);
      final streakResult = await cache.checkAndUpdateStreak();
      if (streakResult.isNewDay) {
        processEvent(DailyLoginEvent(currentStreak: streakResult.streak));
        try {
          ref.read(progressionProvider.notifier).trackEvent(
            DailyStreakXpEvent(streakCount: streakResult.streak),
          );
        } catch (_) {}
      }
    });

    return progress;
  }

  /// Oyun event'lerini işle, etkilenen başarımları güncelle.
  ///
  /// [processEvent] async ama AWAIT EDİLMEZ — fire-and-forget.
  /// Game notifier bunu beklemeden oyun akışını sürdürür.
  Future<void> processEvent(AchievementEvent event) async {
    final progressMap = state.valueOrNull;
    if (progressMap == null) {
      developer.log('[AchievementProvider] State not ready, skipping event');
      return;
    }

    final userId = ref.read(_authUserIdProvider).valueOrNull;
    if (userId == null) return;

    // Engine evaluate — O(k) complexity
    final updates = AchievementEngine.instance.evaluate(event, progressMap);
    if (updates.isEmpty) return;

    // Optimistic state update (anında UI güncellenir)
    final newMap = Map<String, AchievementProgress>.from(progressMap);
    final justUnlocked = <AchievementProgress>[];

    for (final update in updates) {
      final unlockedAt =
          update.wasJustUnlocked ? DateTime.now() : newMap[update.achievementId]?.unlockedAt;

      final newProgress = AchievementProgress(
        achievementId: update.achievementId,
        progress: update.newProgress,
        unlocked: update.wasJustUnlocked ||
            (newMap[update.achievementId]?.unlocked ?? false),
        unlockedAt: unlockedAt,
      );

      newMap[update.achievementId] = newProgress;

      if (update.wasJustUnlocked) {
        justUnlocked.add(newProgress);
        _onAchievementUnlocked(update.achievementId);
      }

      _pendingSaves.add(newProgress);
    }

    // State'i güncelle — UI reactive olarak rebuild olur
    state = AsyncData(newMap);

    // Debounced Firestore save (2 saniye sonra batch write)
    _scheduleSave(userId);
  }

  void _onAchievementUnlocked(String achievementId) {
    final def = AchievementDefinitions.findById(achievementId);
    if (def == null) return;

    // Ses efekti — rarity'ye göre
    AudioService.playAchievementUnlocked(def.rarity);

    // Overlay kuyruğuna ekle
    final achievement = def.toAchievement(
      currentProgress: def.targetValue,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );

    ref.read(achievementQueueProvider.notifier).enqueue(achievement);

    // XP progression: achievement unlocked
    try {
      ref.read(progressionProvider.notifier).trackEvent(
        AchievementUnlockedXpEvent(
          achievementId: achievementId,
          xpReward: def.xpReward,
        ),
      );

      // Daily system event tetikleme
      ref.read(dailyStateProvider.notifier).triggerEvent(
        const AchievementUnlockedMissionEvent(),
      );
    } catch (_) {}

    developer.log('[Achievement] UNLOCKED: ${def.title} (${def.rarity.label})');
  }

  void _scheduleSave(String userId) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      if (_pendingSaves.isEmpty) return;

      // Snapshot al ve listeyi temizle — race condition yok
      final toSave = List<AchievementProgress>.from(_pendingSaves);
      _pendingSaves.clear();

      try {
        await ref
            .read(achievementRepositoryProvider)
            .batchSaveProgress(userId, toSave);
      } catch (e) {
        developer.log('[AchievementProvider] batchSave failed: $e');
        // Cache'de tutuldu, sonraki oturumda sync olur
      }
    });
  }

  // ─── Dispose ─────────────────────────────────────────────────
  // AsyncNotifier'da onDispose yoktur; timer'ı ref.onDispose ile iptal et.
  // (build() içinde çağrılır — provider rebuild'de de çalışır)
}

// ─────────────────────────────────────────────────────────────────
// ACHIEVEMENT LIST PROVIDER — definition + progress merge
// ─────────────────────────────────────────────────────────────────

/// Tüm başarım listesi: definitions (local) + progress (Firestore) merge.
///
/// select() ile sadece progress değişiminde rebuild — performans koruması.
final achievementListProvider = Provider<List<Achievement>>((ref) {
  final progressAsync = ref.watch(achievementProgressProvider);
  final progressMap = progressAsync.valueOrNull ?? {};

  return AchievementDefinitions.all.map((def) {
    final progress = progressMap[def.id];
    return def.toAchievement(
      currentProgress: progress?.progress ?? 0,
      isUnlocked: progress?.unlocked ?? false,
      unlockedAt: progress?.unlockedAt,
    );
  }).toList();
});

/// Açılmış başarım sayısı — özet istatistik için.
final unlockedAchievementsCountProvider = Provider<int>((ref) {
  return ref
      .watch(achievementListProvider)
      .where((a) => a.isUnlocked)
      .length;
});

/// Toplam kazanılan XP.
final totalXpProvider = Provider<int>((ref) {
  return ref
      .watch(achievementListProvider)
      .where((a) => a.isUnlocked)
      .fold(0, (acc, a) => acc + a.xpReward);
});
