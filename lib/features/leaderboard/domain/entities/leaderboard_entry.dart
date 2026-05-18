import 'dart:convert';

class LeaderboardEntry {
  final String name;
  final int score; // Doğru bilinen şehir sayısı (max 81)
  final int elapsedTime; // Saniye cinsinden geçen süre
  final DateTime date;

  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.elapsedTime,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'score': score,
      'elapsedTime': elapsedTime,
      'date': date.toIso8601String(),
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      name: map['name'] as String,
      score: map['score'] as int,
      elapsedTime: map['elapsedTime'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory LeaderboardEntry.fromJson(String source) =>
      LeaderboardEntry.fromMap(json.decode(source) as Map<String, dynamic>);
}
