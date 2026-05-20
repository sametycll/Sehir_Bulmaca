import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/game_mode.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../data/repositories/firestore_leaderboard_repository.dart';
import '../../data/local_leaderboard_service.dart';

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
      final auth = ref.read(firebaseAuthProvider);
      final repository = ref.read(leaderboardRepositoryProvider);

      User? currentUser = auth.currentUser;
      
      // If user is not authenticated, sign them in anonymously
      if (currentUser == null) {
        final userCredential = await auth.signInAnonymously();
        currentUser = userCredential.user;
      }

      if (currentUser == null) {
        throw Exception("Auth authentication failed. Unable to identify user.");
      }

      final entry = LeaderboardEntry.create(
        userId: currentUser.uid,
        name: name.trim().isEmpty ? 'Misafir' : name.trim(),
        modeId: mode.id,
        score: score,
        elapsedTime: elapsedTime,
      );

      // 1. Submit globally to Firestore
      await repository.submitScore(entry);

      // 2. Also back up to SharedPreferences for local high-score records (Offline Fallback)
      await LocalLeaderboardService.saveEntry(entry);
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
