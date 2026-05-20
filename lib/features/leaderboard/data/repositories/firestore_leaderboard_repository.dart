import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';

class FirestoreLeaderboardRepository implements LeaderboardRepository {
  final FirebaseFirestore _firestore;

  FirestoreLeaderboardRepository(this._firestore);

  @override
  Future<void> submitScore(LeaderboardEntry entry) async {
    // Unique document ID per mode + user. This ensures exactly one high-score entry per player per game mode!
    final String docId = '${entry.modeId}__${entry.userId}';
    final docRef = _firestore.collection('leaderboards').doc(docId);

    try {
      // Fetch user's current high score for this mode (using server & cache options for optimal performance)
      final DocumentSnapshot<Map<String, dynamic>> snapshot = 
          await docRef.get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final int currentBestComposite = data['compositeScore'] as int? ?? 0;
          
          // Only overwrite the existing score if the new score is strictly better (higher compositeScore)
          if (entry.compositeScore > currentBestComposite) {
            await docRef.set(entry.toMap());
          }
        }
      } else {
        // No previous entry exists; write it directly
        await docRef.set(entry.toMap());
      }
    } catch (e) {
      // Enforce local fallback writing if offline, or rethrow
      // In production, we'll write to server; if offline, Firestore automatically caches and syncs later!
      await docRef.set(entry.toMap());
    }
  }

  @override
  Stream<List<LeaderboardEntry>> getLeaderboardStream(String modeId, {int limit = 100}) {
    // Realtime stream querying entries matching the game mode,
    // sorted descending by compositeScore to satisfy higher score and lower elapsedTime in a single index!
    return _firestore
        .collection('leaderboards')
        .where('modeId', isEqualTo: modeId)
        .orderBy('compositeScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LeaderboardEntry.fromMap(doc.data(), docId: doc.id);
          }).toList();
        });
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboardOnce(String modeId, {int limit = 100}) async {
    final querySnapshot = await _firestore
        .collection('leaderboards')
        .where('modeId', isEqualTo: modeId)
        .orderBy('compositeScore', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs.map((doc) {
      return LeaderboardEntry.fromMap(doc.data(), docId: doc.id);
    }).toList();
  }
}
