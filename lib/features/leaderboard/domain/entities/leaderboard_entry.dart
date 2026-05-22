import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String? id; // Firestore document ID
  final String userId; // Firebase Auth User ID
  final String name; // Nickname chosen by player
  final String modeId; // game mode identifier (e.g. 'all_turkey')
  final int score; // number of cities solved
  final int elapsedTime; // seconds taken
  final int compositeScore; // combined score & speed ranking value
  final DateTime date; // timestamp of scoring
  final String? photoUrl; // Profile photo URL

  LeaderboardEntry({
    this.id,
    required this.userId,
    required this.name,
    required this.modeId,
    required this.score,
    required this.elapsedTime,
    required this.compositeScore,
    required this.date,
    this.photoUrl,
  });

  /// Factory constructor to build an entry from a game output.
  /// Automatically calculates the compositeScore to enforce server-matching logic.
  factory LeaderboardEntry.create({
    required String userId,
    required String name,
    required String modeId,
    required int score,
    required int elapsedTime,
    String? photoUrl,
  }) {
    return LeaderboardEntry(
      userId: userId,
      name: name,
      modeId: modeId,
      score: score,
      elapsedTime: elapsedTime,
      compositeScore: calculateCompositeScore(score, elapsedTime),
      date: DateTime.now(),
      photoUrl: photoUrl,
    );
  }

  /// Calculates composite scoring: higher score is primary, lower time is secondary tiebreaker.
  /// Formula: (score * 100,000) + (100,000 - clampedTime)
  static int calculateCompositeScore(int score, int elapsedTime) {
    const int maxTimeConstant = 100000;
    final int clampedTime = elapsedTime.clamp(0, maxTimeConstant);
    return (score * maxTimeConstant) + (maxTimeConstant - clampedTime);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'modeId': modeId,
      'score': score,
      'elapsedTime': elapsedTime,
      'compositeScore': compositeScore,
      'date': Timestamp.fromDate(date),
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, {String? docId}) {
    // Handle date conversion: can be Timestamp (Firestore) or String (SharedPreferences/JSON fallback)
    DateTime parsedDate;
    final rawDate = map['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    final scoreVal = map['score'] as int;
    final elapsedTimeVal = map['elapsedTime'] as int;
    
    // Ensure we have a composite score (or calculate one if missing)
    final compositeVal = map['compositeScore'] as int? ?? 
        calculateCompositeScore(scoreVal, elapsedTimeVal);

    return LeaderboardEntry(
      id: docId ?? map['id'] as String?,
      userId: map['userId'] as String? ?? 'unknown',
      name: map['name'] as String? ?? 'Misafir',
      modeId: map['modeId'] as String? ?? 'all_turkey',
      score: scoreVal,
      elapsedTime: elapsedTimeVal,
      compositeScore: compositeVal,
      date: parsedDate,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  String toJson() => json.encode(toMapJsonFallback());

  Map<String, dynamic> toMapJsonFallback() {
    return {
      'userId': userId,
      'name': name,
      'modeId': modeId,
      'score': score,
      'elapsedTime': elapsedTime,
      'compositeScore': compositeScore,
      'date': date.toIso8601String(),
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  factory LeaderboardEntry.fromJson(String source) =>
      LeaderboardEntry.fromMap(json.decode(source) as Map<String, dynamic>);
}
