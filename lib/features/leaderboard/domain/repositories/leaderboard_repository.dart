import '../entities/leaderboard_entry.dart';

abstract class LeaderboardRepository {
  /// Submits a player's score to the global leaderboard.
  Future<void> submitScore(LeaderboardEntry entry);

  /// Returns a real-time stream of the top N players for a specific game mode.
  /// Automatically ordered by score (descending) and elapsedTime (ascending) using compositeScore.
  Stream<List<LeaderboardEntry>> getLeaderboardStream(String modeId, {int limit = 100});

  /// Fetches a one-time snapshot of the top N players for a specific game mode.
  Future<List<LeaderboardEntry>> getLeaderboardOnce(String modeId, {int limit = 100});
}
