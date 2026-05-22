import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/game_mode.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../data/repositories/firestore_leaderboard_repository.dart';
import '../../data/local_leaderboard_service.dart';
import '../../../achievements/domain/entities/achievement_event.dart';
import '../../../achievements/presentation/providers/achievement_provider.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../../auth/domain/entities/app_user.dart';

// Firebase core providers
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Repository provider
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreLeaderboardRepository(firestore);
});

// State provider for active game mode selection in UI
final activeGameModeProvider = StateProvider<GameMode>((ref) => GameMode.allTurkey);

// Stream provider that watches active game mode and feeds top 100 entries in real-time
final leaderboardStreamProvider = StreamProvider.autoDispose<List<LeaderboardEntry>>((ref) {
  final mode = ref.watch(activeGameModeProvider);
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getLeaderboardStream(mode.id, limit: 100);
});

// Provider for current user's personal stats across ALL game modes (fetched once)
final myStatsProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final authState = ref.watch(authProvider);
  final firestore = ref.watch(firestoreProvider);
  final userId = authState.user?.uid;
  if (userId == null) return [];

  final snapshot = await firestore
      .collection('leaderboards')
      .where('userId', isEqualTo: userId)
      .get();

  return snapshot.docs
      .map((doc) => LeaderboardEntry.fromMap(doc.data(), docId: doc.id))
      .toList();
});

// Notifier provider for transactional operations (submitting, clearing)
final leaderboardNotifierProvider = AsyncNotifierProvider<LeaderboardNotifier, void>(() {
  return LeaderboardNotifier();
});

class LeaderboardNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle
  }

  /// Securely submits a score. Automatically checks Firebase Auth status
  /// and performs anonymous registration if no user is signed in to satisfy Security Rules.
  Future<void> submitScore({
    required String name,
    required GameMode mode,
    required int score,
    required int elapsedTime,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(leaderboardRepositoryProvider);

      var authState = ref.read(authProvider);
      AppUser? appUser = authState.user;
      
      // If user is not authenticated, sign them in anonymously
      if (appUser == null) {
        await ref.read(authProvider.notifier).signInAsGuest();
        authState = ref.read(authProvider);
        appUser = authState.user;
      }

      if (appUser == null) {
        throw Exception("Auth authentication failed. Unable to identify user.");
      }

      final entry = LeaderboardEntry.create(
        userId: appUser.uid,
        name: appUser.leaderboardName,
        modeId: mode.id,
        score: score,
        elapsedTime: elapsedTime,
        photoUrl: appUser.photoUrl,
      );

      // 1. Submit globally to Firestore
      await repository.submitScore(entry);

      // 2. Also back up to SharedPreferences for local high-score records (Offline Fallback)
      await LocalLeaderboardService.saveEntry(entry);

      // 3. Achievement event: leaderboard'a girildi
      ref
          .read(achievementProgressProvider.notifier)
          .processEvent(const LeaderboardEnteredEvent());
    });
  }

  /// Clears only the local offline high scores cache.
  /// (Global global leaderboard is protected and can only be cleared by admin panel/functions).
  Future<void> clearLocalCache() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await LocalLeaderboardService.clearLeaderboard();
    });
  }
}

// ==========================================
// BACKWARD COMPATIBILITY BRIDGE LAYER
// ==========================================
class CompatibilityLeaderboardNotifier extends AsyncNotifier<List<LeaderboardEntry>> {
  @override
  Future<List<LeaderboardEntry>> build() async {
    return LocalLeaderboardService.getEntries();
  }

  Future<void> addEntry(String name, int score, int elapsedTime) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Automatically routes old submissions to the new Firestore submission flow
      await ref.read(leaderboardNotifierProvider.notifier).submitScore(
        name: name,
        mode: GameMode.allTurkey,
        score: score,
        elapsedTime: elapsedTime,
      );
      return LocalLeaderboardService.getEntries();
    });
  }

  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(leaderboardNotifierProvider.notifier).clearLocalCache();
      return [];
    });
  }
}

final leaderboardProvider = AsyncNotifierProvider<CompatibilityLeaderboardNotifier, List<LeaderboardEntry>>(() {
  return CompatibilityLeaderboardNotifier();
});
