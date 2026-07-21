import 'dart:io';

/// Günlük görevler ve giriş serisi (streak) için zaman kontrolü ve hile koruması (anti-cheat) sağlayan servis.
class DailyTimeService {
  const DailyTimeService();

  /// Google.com'a HTTP HEAD isteği atarak response header'ındaki 'date' alanından güvenli dünya saatini (UTC) almaya çalışır.
  /// Çevrimdışı veya hata durumunda cihaz saatini geri döner.
  Future<DateTime> getNetworkTime() async {
    final client = HttpClient();
    // Zaman aşımını kısa tutalım ki kullanıcıyı bekletmeyelim (maksimum 2 saniye)
    client.connectionTimeout = const Duration(seconds: 2);
    try {
      final request = await client.headUrl(Uri.parse('https://www.google.com'));
      final response = await request.close();
      final dateHeader = response.headers.value(HttpHeaders.dateHeader);
      
      if (dateHeader != null) {
        final parsedDate = HttpDate.parse(dateHeader);
        return parsedDate.toLocal(); // Yerel saate çevir
      }
    } catch (e) {
      // Ağ hatası veya çevrimdışı olma durumunda cihaz saatini fallback olarak döner.
    } finally {
      client.close();
    }
    return DateTime.now();
  }

  /// Cihaz saati ile güvenli ağ saati arasında hileli bir fark olup olmadığını denetler.
  /// Fark 5 dakikadan fazlaysa true döner (Kullanıcı cihaz saatini manuel değiştirmiş olabilir).
  bool isTimeManipulated(DateTime networkTime, DateTime deviceTime) {
    final difference = deviceTime.difference(networkTime).inMinutes.abs();
    return difference > 5;
  }

  /// Kullanıcının yerel saatine göre bir sonraki gece yarısı (00:00:00) zamanını hesaplar.
  DateTime calculateNextResetTime(DateTime now) {
    return DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
  }

  /// İki tarihin aynı takvim gününe (Yıl/Ay/Gün) ait olup olmadığını kontrol eder.
  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Kullanıcının giriş serisinin (streak) bozulup bozulmadığını kontrol eder.
  /// Kurallar:
  /// - Son aktif gün ile bugün aynı gün ise streak değişmez (artış olmaz).
  /// - Son aktif günden itibaren 36 saatten fazla süre geçmişse seri bozulur (streak 0 olur).
  /// - Son aktif günden sonra yeni bir güne girilmiş ve 36 saat aşılmamışsa streak 1 artar.
  StreakCheckResult checkStreak(
    int currentStreak,
    int bestStreak,
    DateTime? lastActiveDate,
    DateTime now,
  ) {
    if (lastActiveDate == null) {
      // İlk kez giriş yapılıyor
      return StreakCheckResult(
        newStreak: 1,
        newBestStreak: bestStreak < 1 ? 1 : bestStreak,
        shouldIncrease: true,
        isBroken: false,
      );
    }

    final localNow = now;
    final localLastActive = lastActiveDate.toLocal();

    // Aynı gün içindeyse streak artmaz, ama bozulmaz da
    if (isSameDay(localLastActive, localNow)) {
      return StreakCheckResult(
        newStreak: currentStreak == 0 ? 1 : currentStreak,
        newBestStreak: bestStreak,
        shouldIncrease: false,
        isBroken: false,
      );
    }

    // Farklı bir gündeyiz. 36 saatlik süre (Grace Period) aşılmış mı kontrol edelim
    final difference = localNow.difference(localLastActive);
    if (difference.inHours > 36) {
      // Seri bozulmuş, 0'dan başlıyor
      return StreakCheckResult(
        newStreak: 1,
        newBestStreak: bestStreak,
        shouldIncrease: true,
        isBroken: true,
      );
    }

    // Yeni güne girilmiş ve 36 saat aşılmamış -> Seri artar
    final nextStreak = currentStreak + 1;
    final nextBest = nextStreak > bestStreak ? nextStreak : bestStreak;
    return StreakCheckResult(
      newStreak: nextStreak,
      newBestStreak: nextBest,
      shouldIncrease: true,
      isBroken: false,
    );
  }
}

/// Giriş serisi kontrolü sonucunda dönen veri yapısı.
class StreakCheckResult {
  final int newStreak;
  final int newBestStreak;
  final bool shouldIncrease;
  final bool isBroken;

  const StreakCheckResult({
    required this.newStreak,
    required this.newBestStreak,
    required this.shouldIncrease,
    required this.isBroken,
  });
}
