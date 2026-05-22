import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/player_progress.dart';
import '../../domain/entities/xp_event.dart';
import '../../domain/repositories/progression_repository.dart';
import '../../domain/services/level_calculator.dart';
import '../../domain/services/xp_engine.dart';
import '../../infrastructure/datasources/firestore_progression_datasource.dart';
import '../../infrastructure/datasources/local_progression_cache.dart';
import '../../infrastructure/repositories/progression_repository_impl.dart';
import 'level_up_queue_provider.dart';
import '../../../game/infrastructure/services/audio_service.dart';
import '../../../leaderboard/presentation/providers/leaderboard_provider.dart'
    show firestoreProvider;

// ─────────────────────────────────────────────────────────────────
// INFRASTRUCTURE PROVIDERS
// ─────────────────────────────────────────────────────────────────

final _localCacheProvider = Provider<LocalProgressionCache>((ref) {
  return LocalProgressionCache();
});

final _firestoreDatasourceProvider = Provider<FirestoreProgressionDatasource>((ref) {
  return FirestoreProgressionDatasource(ref.watch(firestoreProvider));
});

final progressionRepositoryProvider = Provider<ProgressionRepository>((ref) {
  return ProgressionRepositoryImpl(
    firestoreDatasource: ref.watch(_firestoreDatasourceProvider),
    localCache: ref.watch(_localCacheProvider),
  );
});

// ─────────────────────────────────────────────────────────────────
// AUTH USER STREAM
// ─────────────────────────────────────────────────────────────────

final _authUserIdProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((u) => u?.uid);
});

// ─────────────────────────────────────────────────────────────────
// PROGRESSION NOTIFIER
// ─────────────────────────────────────────────────────────────────

final progressionProvider =
    AsyncNotifierProvider<ProgressionNotifier, PlayerProgress>(
  ProgressionNotifier.new,
);

class ProgressionNotifier extends AsyncNotifier<PlayerProgress> {
  Timer? _saveTimer;
  PlayerProgress? _pendingSaveProgress;

  @override
  Future<PlayerProgress> build() async {
    // Auth değişimlerini dinle — Giriş/Çıkış yapıldığında notifier otomatik sıfırlanır/yenilenir
    final userIdAsync = ref.watch(_authUserIdProvider);
    final userId = userIdAsync.valueOrNull;

    if (userId == null) {
      return PlayerProgress.empty('');
    }

    final repo = ref.read(progressionRepositoryProvider);
    final progress = await repo.getProgress(userId);
    return progress ?? PlayerProgress.empty(userId);
  }

  /// Yeni bir XP olayı gönderir ve ilerlemeyi günceller.
  /// optimistic: Yerel cache ve state anında güncellenir.
  /// debounced: Firestore senkronizasyonu 3 saniye ertelenerek spam write önlenir.
  Future<void> trackEvent(XpEvent event) async {
    debugPrint('🟡 [LEVEL-DEBUG] trackEvent called: ${event.runtimeType}, sourceId=${event.sourceId}');
    
    final currentProgress = state.valueOrNull;
    if (currentProgress == null || currentProgress.uid.isEmpty) {
      debugPrint('🔴 [LEVEL-DEBUG] Progress state not ready! valueOrNull=$currentProgress, uid=${currentProgress?.uid}');
      developer.log('[ProgressionProvider] Progress state not ready or anonymous, skipping event.');
      return;
    }

    debugPrint('🟢 [LEVEL-DEBUG] Current progress: level=${currentProgress.level}, totalXp=${currentProgress.totalXp}, uid=${currentProgress.uid}');

    // 1. XP Engine ile ödül miktarını hesapla
    final xpResult = XpEngine.instance.evaluate(event);
    debugPrint('🟢 [LEVEL-DEBUG] XP result: xp=${xpResult.xp}, hasReward=${xpResult.hasReward}, desc=${xpResult.description}');
    if (!xpResult.hasReward) {
      debugPrint('🔴 [LEVEL-DEBUG] No XP reward, skipping.');
      return;
    }

    final newTotalXp = currentProgress.totalXp + xpResult.xp;
    final newLevel = LevelCalculator.calculateLevel(newTotalXp);
    
    final levelUpOccurred = newLevel > currentProgress.level;
    debugPrint('🟢 [LEVEL-DEBUG] newTotalXp=$newTotalXp, newLevel=$newLevel, oldLevel=${currentProgress.level}, levelUpOccurred=$levelUpOccurred');

    // 2. Seviyeye göre XP detaylarını güncelle
    final totalXpToReachCurrent = LevelCalculator.totalXpToReachLevel(newLevel);
    final currentXp = newTotalXp - totalXpToReachCurrent;
    final xpToNextLevel = LevelCalculator.xpToNextLevelForLevel(newLevel);

    final updatedProgress = currentProgress.copyWith(
      level: newLevel,
      totalXp: newTotalXp,
      currentXp: currentXp,
      xpToNextLevel: xpToNextLevel,
      lastUpdated: DateTime.now(),
    );

    // 3. UI'ı ve local cache'i anında güncelle (Optimistic Update)
    state = AsyncData(updatedProgress);
    await ref.read(_localCacheProvider).saveProgress(updatedProgress);

    // 4. Seviye atlama kontrolü
    if (levelUpOccurred) {
      debugPrint('🎉 [LEVEL-DEBUG] LEVEL UP DETECTED! ${currentProgress.level} -> $newLevel');
      developer.log('[Progression] Level Up! ${currentProgress.level} -> $newLevel');
      
      // Çoklu seviye atlama desteği: Her bir seviye geçişini tek tek kuyruğa ekle
      for (int i = currentProgress.level; i < newLevel; i++) {
        final details = LevelUpDetails(
          fromLevel: i,
          toLevel: i + 1,
          titleGained: LevelCalculator.getTitle(i + 1),
        );
        debugPrint('🎉 [LEVEL-DEBUG] Enqueuing level up: ${details.fromLevel} -> ${details.toLevel}, title=${details.titleGained}');
        ref.read(levelUpQueueProvider.notifier).enqueue(details);
      }
      
      final queueSize = ref.read(levelUpQueueProvider).length;
      debugPrint('🎉 [LEVEL-DEBUG] Queue size after enqueue: $queueSize');
    } else {
      // Normal XP kazanım sesi
      AudioService.playCorrect();
    }

    // 5. Uçan XP Metni Gösterimi (Global Overlay tetiklemesi)
    _triggerXpFloatingText(xpResult.xp, event.sourceId == 'combo' || event.sourceId == 'game_completed');

    // 6. Firestore Senkronizasyonunu Debounce Et (3 saniye)
    _scheduleFirestoreSave(updatedProgress);
  }

  void _scheduleFirestoreSave(PlayerProgress progress) {
    _pendingSaveProgress = progress;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () async {
      if (_pendingSaveProgress == null) return;
      
      final toSave = _pendingSaveProgress!;
      _pendingSaveProgress = null;

      try {
        await ref.read(progressionRepositoryProvider).saveProgress(toSave);
      } catch (e) {
        developer.log('[ProgressionProvider] Debounced Firestore save failed: $e');
        // Hata durumunda yerel cache'de saklı kaldığı için veri kaybolmaz.
      }
    });
  }

  /// Global overlay kullanarak uçan XP yazısı üretir.
  void _triggerXpFloatingText(int xp, bool isBonus) {
    // presentation/widgets/xp_gain_floating_text.dart dosyasındaki
    // static helper metot kullanılarak Overlay'e eklenir.
    // game_screen.dart veya herhangi bir ekranda çalışır.
    try {
      XpFloatingOverlayService.show(
        xp: xp,
        isBonus: isBonus,
      );
    } catch (e) {
      developer.log('[ProgressionProvider] Failed to show floating XP overlay: $e');
    }
  }
}

/// Floating XP tetiklemesi için boş bir placeholder/interface sınıf.
/// Gerçek implementasyon presentation/widgets/xp_gain_floating_text.dart içinde yapılacak.
class XpFloatingOverlayService {
  static void Function(int xp, bool isBonus)? _showCallback;

  static void register(void Function(int xp, bool isBonus) callback) {
    _showCallback = callback;
  }

  static void show({required int xp, required bool isBonus}) {
    if (_showCallback != null) {
      _showCallback!(xp, isBonus);
    }
  }
}
