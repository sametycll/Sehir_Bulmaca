import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_mission.dart';
import '../../domain/entities/daily_streak.dart';
import '../../domain/entities/mission_event.dart';
import '../../domain/repositories/daily_repository.dart';
import '../../domain/services/mission_engine.dart';
import '../../domain/services/daily_time_service.dart';
import '../../infrastructure/datasources/firestore_daily_datasource.dart';
import '../../infrastructure/datasources/local_daily_cache.dart';
import '../../infrastructure/repositories/daily_repository_impl.dart';
import '../../../progression/domain/entities/xp_event.dart';
import '../../../progression/presentation/providers/progression_provider.dart';
import '../../../auth/presentation/auth_notifier.dart';

// ─────────────────────────────────────────────────────────────────
// ALTYAPI SAĞLAYICILARI (INFRASTRUCTURE PROVIDERS)
// ─────────────────────────────────────────────────────────────────

final dailyLocalCacheProvider = Provider<LocalDailyCache>((ref) {
  return const LocalDailyCache();
});

final dailyFirestoreDatasourceProvider = Provider<FirestoreDailyDatasource>((ref) {
  return FirestoreDailyDatasource();
});

final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  return DailyRepositoryImpl(
    localCache: ref.watch(dailyLocalCacheProvider),
    remoteDatasource: ref.watch(dailyFirestoreDatasourceProvider),
  );
});

final dailyTimeServiceProvider = Provider<DailyTimeService>((ref) {
  return const DailyTimeService();
});

// ─────────────────────────────────────────────────────────────────
// GÜNLÜK GÖREV TAMAMLANMA KUYRUĞU (FIFO QUEUE)
// ─────────────────────────────────────────────────────────────────

final completedMissionsQueueProvider =
    StateNotifierProvider<CompletedMissionsQueueNotifier, List<DailyMission>>((ref) {
  return CompletedMissionsQueueNotifier();
});

class CompletedMissionsQueueNotifier extends StateNotifier<List<DailyMission>> {
  CompletedMissionsQueueNotifier() : super([]);

  bool _isShowing = false;
  bool get isShowing => _isShowing;

  void enqueue(DailyMission mission) {
    state = [...state, mission];
  }

  DailyMission? dequeue() {
    if (state.isEmpty) {
      _isShowing = false;
      return null;
    }
    final first = state.first;
    state = state.sublist(1);
    _isShowing = state.isNotEmpty;
    return first;
  }

  void markAsShowing(bool showing) {
    _isShowing = showing;
  }

  void clear() {
    state = [];
    _isShowing = false;
  }
}

// ─────────────────────────────────────────────────────────────────
// GÜNLÜK SİSTEM DURUMU (DAILY STATE)
// ─────────────────────────────────────────────────────────────────

class DailyState {
  final bool isLoading;
  final DailyStreak streak;
  final List<DailyMission> missions;
  final bool isTimeManipulated;
  final String? errorMessage;

  DailyState({
    required this.isLoading,
    required this.streak,
    required this.missions,
    required this.isTimeManipulated,
    this.errorMessage,
  });

  DailyState copyWith({
    bool? isLoading,
    DailyStreak? streak,
    List<DailyMission>? missions,
    bool? isTimeManipulated,
    String? errorMessage,
  }) {
    return DailyState(
      isLoading: isLoading ?? this.isLoading,
      streak: streak ?? this.streak,
      missions: missions ?? this.missions,
      isTimeManipulated: isTimeManipulated ?? this.isTimeManipulated,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory DailyState.initial() {
    return DailyState(
      isLoading: true,
      streak: DailyStreak.empty(),
      missions: [],
      isTimeManipulated: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// DAILY SYSTEM RIVERPOD NOTIFIER
// ─────────────────────────────────────────────────────────────────

final dailyStateProvider =
    StateNotifierProvider<DailyNotifier, DailyState>((ref) {
  final uid = ref.watch(authProvider.select((state) => state.user?.uid));
  return DailyNotifier(ref, uid);
});

class DailyNotifier extends StateNotifier<DailyState> {
  final Ref _ref;
  Timer? _saveTimer;
  DailyState? _pendingSaveState;
  final String? _currentUserId;

  DailyNotifier(this._ref, this._currentUserId) : super(DailyState.initial()) {
    final uid = _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      // Riverpod build aşamasında senkron state güncellemesini önlemek için microtask kullanıyoruz
      Future.microtask(() => init(uid));
    } else {
      // Kullanıcı yoksa loading durumunu kapatıp boş state atıyoruz
      state = DailyState(
        isLoading: false,
        streak: DailyStreak.empty(),
        missions: [],
        isTimeManipulated: false,
      );
    }
  }

  void _cancelTimer() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _pendingSaveState = null;
  }

  /// Günlük sistemi verilerini yükler ve sıfırlanma (reset) zamanlarını denetler.
  Future<void> init(String userId) async {
    state = state.copyWith(isLoading: true);
    _cancelTimer();

    try {
      final timeService = _ref.read(dailyTimeServiceProvider);
      final repo = _ref.read(dailyRepositoryProvider);

      // 1. Ağ üzerinden gerçek saati al
      final networkTime = await timeService.getNetworkTime();
      final deviceTime = DateTime.now();

      // 2. Zaman manipülasyonu (anti-cheat) tespiti
      final isManipulated = timeService.isTimeManipulated(networkTime, deviceTime);

      // 3. Mevcut verileri çek
      DailyStreak? streak = await repo.getDailyStreak(userId);
      List<DailyMission> missions = await repo.getDailyMissions(userId);

      // 4. Günlük verilerin sıfırlanma veya ilk oluşturulma kontrolü
      bool needsReset = false;

      if (streak == null) {
        // İlk kez oluşturuluyor
        streak = DailyStreak(
          currentStreak: 0,
          bestStreak: 0,
          missionsResetAt: timeService.calculateNextResetTime(networkTime),
        );
        needsReset = true;
      } else {
        // Eğer ağ saati, sıfırlanma zamanından büyük veya eşitse yeni güne girilmiştir
        if (networkTime.isAfter(streak.missionsResetAt)) {
          needsReset = true;
        }
      }

      if (needsReset || missions.isEmpty) {
        developer.log('[DailyNotifier] Günlük görevler sıfırlanıyor/yeni gün başlatılıyor.');
        
        // Streak durumunu kontrol et ve güncelle
        final streakResult = timeService.checkStreak(
          streak.currentStreak,
          streak.bestStreak,
          streak.lastActiveDate,
          networkTime,
        );

        streak = DailyStreak(
          currentStreak: streakResult.newStreak,
          bestStreak: streakResult.newBestStreak,
          lastClaimedDate: streakResult.shouldIncrease ? null : streak.lastClaimedDate, // Yeni günde claim hakkı sıfırlanır
          missionsResetAt: timeService.calculateNextResetTime(networkTime),
          lastActiveDate: networkTime,
        );

        // Yeni günlük görevleri üret
        missions = MissionEngine.generateDailyMissions();

        // Yerel ve uzak veritabanına anında kaydet
        await repo.saveDailyData(userId, streak, missions);
      }

      state = DailyState(
        isLoading: false,
        streak: streak,
        missions: missions,
        isTimeManipulated: isManipulated,
      );

    } catch (e) {
      developer.log('[DailyNotifier] Yükleme hatası: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Veriler yüklenirken bir hata oluştu.',
      );
    }
  }

  /// Oyun içinde gerçekleşen olayları (event) tetikler ve görevleri günceller.
  void triggerEvent(MissionEvent event) {
    if (state.isLoading || state.isTimeManipulated || _currentUserId == null) return;

    final updatedMissions = MissionEngine.processEvent(state.missions, event);

    // Tamamlanan görevleri tespit et
    for (int i = 0; i < state.missions.length; i++) {
      final oldM = state.missions[i];
      final newM = updatedMissions[i];

      // Eğer görev yeni tamamlandıysa (eski durum completed değilken yeni durum completed ise)
      if (!oldM.isCompleted && newM.isCompleted) {
        developer.log('[DailyNotifier] Görev tamamlandı: ${newM.title}');
        _ref.read(completedMissionsQueueProvider.notifier).enqueue(newM);
      }
    }

    state = state.copyWith(missions: updatedMissions);

    // Değişikliği Firestore'a debounced kaydet
    _scheduleSave();
  }

  /// Bir görevin tamamlandığı onaylandığında ödülünü (XP) talep eder.
  Future<void> claimMission(String missionId) async {
    final userId = _currentUserId;
    if (userId == null || state.isTimeManipulated) return;

    final updatedMissions = state.missions.map((mission) {
      if (mission.id == missionId && mission.isCompleted && !mission.isClaimed) {
        // Görevi ödüllendirilmiş olarak işaretle
        final updated = mission.copyWith(isClaimed: true);

        // progressionProvider üzerinden XP olayını tetikle
        _ref.read(progressionProvider.notifier).trackEvent(
              DailyMissionCompletedXpEvent(
                missionId: mission.id,
                xpReward: mission.xpReward,
              ),
            );

        return updated;
      }
      return mission;
    }).toList();

    state = state.copyWith(missions: updatedMissions);

    // Hemen yerel ve uzak veritabanına kaydet
    await _ref.read(dailyRepositoryProvider).saveDailyData(
          userId,
          state.streak,
          state.missions,
        );
  }

  /// Günlük giriş serisi (streak) ödülünü talep eder.
  Future<void> claimStreakBonus() async {
    final userId = _currentUserId;
    if (userId == null || state.isTimeManipulated) return;

    final currentStreak = state.streak;
    
    // Günde sadece 1 kez alınabilir
    if (currentStreak.lastClaimedDate != null) {
      final timeService = _ref.read(dailyTimeServiceProvider);
      final networkTime = await timeService.getNetworkTime();
      if (timeService.isSameDay(currentStreak.lastClaimedDate!, networkTime)) {
        // Bugün zaten alınmış
        return;
      }
    }

    final networkTime = await _ref.read(dailyTimeServiceProvider).getNetworkTime();

    final updatedStreak = currentStreak.copyWith(
      lastClaimedDate: networkTime,
      lastActiveDate: networkTime,
    );

    state = state.copyWith(streak: updatedStreak);

    // progressionProvider üzerinden XP olayını tetikle
    await _ref.read(progressionProvider.notifier).trackEvent(
          DailyStreakXpEvent(streakCount: updatedStreak.currentStreak),
        );

    // Hemen yerel ve uzak veritabanına kaydet
    await _ref.read(dailyRepositoryProvider).saveDailyData(
          userId,
          state.streak,
          state.missions,
        );
  }

  /// Değişen verileri veritabanına kaydetmek üzere debounce eder.
  void _scheduleSave() {
    final userId = _currentUserId;
    if (userId == null) return;

    _pendingSaveState = state;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () async {
      if (_pendingSaveState == null) return;

      final toSave = _pendingSaveState!;
      _pendingSaveState = null;

      try {
        await _ref.read(dailyRepositoryProvider).saveDailyData(
              userId,
              toSave.streak,
              toSave.missions,
            );
      } catch (e) {
        developer.log('[DailyNotifier] Firestore senkronizasyon hatası: $e');
      }
    });
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
