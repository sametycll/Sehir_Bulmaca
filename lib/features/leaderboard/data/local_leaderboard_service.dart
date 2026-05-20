import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/leaderboard_entry.dart';

class LocalLeaderboardService {
  static const String _key = 'local_leaderboard';

  /// Liderlik tablosundaki tüm kayıtları getirir (Sıralanmış olarak)
  static Future<List<LeaderboardEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    
    if (jsonString == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      final entries = jsonList
          .map((item) => LeaderboardEntry.fromMap(item as Map<String, dynamic>))
          .toList();

      // Sıralama Algoritması:
      // 1. Skora göre azalan (Daha çok şehir bilen üstte)
      // 2. Skorlar eşitse, zamana göre artan (Daha hızlı bitiren üstte)
      // 3. Her ikisi de eşitse, daha yeni tarihli olan üstte
      entries.sort((a, b) {
        if (b.score != a.score) {
          return b.score.compareTo(a.score);
        }
        if (a.elapsedTime != b.elapsedTime) {
          return a.elapsedTime.compareTo(b.elapsedTime);
        }
        return b.date.compareTo(a.date);
      });

      return entries;
    } catch (e) {
      // Hata durumunda boş liste dön ve bozuk veriyi sıfırla
      return [];
    }
  }

  /// Yeni bir skor kaydeder ve sıralanmış listeyi günceller
  static Future<void> saveEntry(LeaderboardEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    
    // Yeni kaydı ekle
    entries.add(entry);

    // Tekrar sırala
    entries.sort((a, b) {
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }
      if (a.elapsedTime != b.elapsedTime) {
        return a.elapsedTime.compareTo(b.elapsedTime);
      }
      return b.date.compareTo(a.date);
    });

    // Listeyi kaydet (Timestamp yerine yerel hafızaya uygun olan toMapJsonFallback metodunu kullanıyoruz)
    final String jsonString = json.encode(entries.map((e) => e.toMapJsonFallback()).toList());
    await prefs.setString(_key, jsonString);
  }

  /// Liderlik tablosunu tamamen temizler
  static Future<void> clearLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
