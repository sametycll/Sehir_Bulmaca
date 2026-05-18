import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local_leaderboard_service.dart';
import '../../domain/entities/leaderboard_entry.dart';

final leaderboardProvider = AsyncNotifierProvider<LeaderboardNotifier, List<LeaderboardEntry>>(() {
  return LeaderboardNotifier();
});

class LeaderboardNotifier extends AsyncNotifier<List<LeaderboardEntry>> {
  @override
  Future<List<LeaderboardEntry>> build() async {
    return LocalLeaderboardService.getEntries();
  }

  /// Yeni skor ekleme metodu
  Future<void> addEntry(String name, int score, int elapsedTime) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final entry = LeaderboardEntry(
        name: name,
        score: score,
        elapsedTime: elapsedTime,
        date: DateTime.now(),
      );
      await LocalLeaderboardService.saveEntry(entry);
      return LocalLeaderboardService.getEntries();
    });
  }

  /// Tüm sıralamayı sıfırlama metodu
  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await LocalLeaderboardService.clearLeaderboard();
      return [];
    });
  }
}
