import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/player_progress.dart';

/// Seviye ilerleme verilerini Firestore üzerinde saklayan uzak veri kaynağı.
/// Yapı: users/{uid}/progression/main (Tek Doküman)
class FirestoreProgressionDatasource {
  final FirebaseFirestore _firestore;

  FirestoreProgressionDatasource(this._firestore);

  DocumentReference<Map<String, dynamic>> _docRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('progression').doc('main');

  /// Firestore'daki güncel ilerleme verisini getirir.
  Future<PlayerProgress?> fetchProgress(String uid) async {
    try {
      final doc = await _docRef(uid).get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return PlayerProgress.fromFirestore(uid, doc.data()!);
    } catch (e) {
      developer.log('[FirestoreProgressionDatasource] fetchProgress error: $e');
      return null;
    }
  }

  /// İlerleme verisini Firestore'a yazar.
  Future<void> saveProgress(PlayerProgress progress) async {
    try {
      await _docRef(progress.uid).set(
        progress.toFirestore(),
        SetOptions(merge: true),
      );
      developer.log('[FirestoreProgressionDatasource] Saved progress to Firestore for ${progress.uid}');
    } catch (e) {
      developer.log('[FirestoreProgressionDatasource] saveProgress error: $e');
      rethrow;
    }
  }
}
