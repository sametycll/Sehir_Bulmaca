import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_mission_model.dart';
import '../models/daily_streak_model.dart';
import '../../domain/entities/daily_mission.dart';
import '../../domain/entities/daily_streak.dart';

/// Firestore üzerinden günlük görev ve giriş serisi (streak) verilerine erişen uzak veri kaynağı.
class FirestoreDailyDatasource {
  final FirebaseFirestore _firestore;

  FirestoreDailyDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Kullanıcının ana daily belgesini referans alır.
  DocumentReference<Map<String, dynamic>> _streakDoc(String userId) {
    return _firestore.collection('users').doc(userId).collection('daily').doc('main');
  }

  /// Kullanıcının görevler koleksiyonunu referans alır.
  CollectionReference<Map<String, dynamic>> _missionsCol(String userId) {
    return _firestore.collection('users').doc(userId).collection('daily').doc('main').collection('missions');
  }

  /// Firestore'dan kullanıcının streak durumunu çeker.
  Future<DailyStreak?> getDailyStreak(String userId) async {
    final snapshot = await _streakDoc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return DailyStreakModel.fromMap(snapshot.data()!);
  }

  /// Firestore'a kullanıcının streak durumunu kaydeder.
  Future<void> saveDailyStreak(String userId, DailyStreak streak) async {
    final map = DailyStreakModel.fromEntity(streak).toMap();
    await _streakDoc(userId).set(map, SetOptions(merge: true));
  }

  /// Firestore'dan kullanıcının aktif günlük görevlerini çeker.
  Future<List<DailyMission>> getDailyMissions(String userId) async {
    final snapshot = await _missionsCol(userId).get();
    return snapshot.docs.map((doc) {
      return DailyMissionModel.fromMap(doc.data(), docId: doc.id);
    }).toList();
  }

  /// Firestore'a kullanıcının görevlerini kaydeder.
  Future<void> saveDailyMissions(String userId, List<DailyMission> missions) async {
    final batch = _firestore.batch();
    
    for (final mission in missions) {
      final docRef = _missionsCol(userId).doc(mission.id);
      final map = DailyMissionModel.fromEntity(mission).toMap();
      batch.set(docRef, map, SetOptions(merge: true));
    }
    
    await batch.commit();
  }

  /// Batch kullanarak hem streak hem de görev verilerini tek seferde (atomik olarak) Firestore'a kaydeder.
  Future<void> saveDailyData(
    String userId,
    DailyStreak streak,
    List<DailyMission> missions,
  ) async {
    final batch = _firestore.batch();

    // Streak kaydetme
    final streakRef = _streakDoc(userId);
    final streakMap = DailyStreakModel.fromEntity(streak).toMap();
    batch.set(streakRef, streakMap, SetOptions(merge: true));

    // Mevcut görevleri temizlemek gerekirse veya doğrudan üzerine yazmak için
    // Görevleri tek tek set ediyoruz
    for (final mission in missions) {
      final missionRef = _missionsCol(userId).doc(mission.id);
      final missionMap = DailyMissionModel.fromEntity(mission).toMap();
      batch.set(missionRef, missionMap, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
