/// Achievement sistemini tetikleyen event'ler — sealed class (Dart 3).
///
/// Sealed class tercih edildi çünkü:
/// - Exhaustive switch: compile-time güvence, yeni event eklendiğinde
///   tüm handler'lar güncellenmek zorunda kalır.
/// - Tip-güvenli: stringly-typed event ID'lerden kaçınılır.
/// - Engine'deki HashMap index, runtimeType ile çalışır → O(1) lookup.
sealed class AchievementEvent {
  const AchievementEvent();
}

/// Oyunda bir şehir doğru tahmin edildiğinde.
final class CityFoundEvent extends AchievementEvent {
  const CityFoundEvent({
    required this.totalFoundInSession, // Bu oyundaki toplam bulunan sayısı
    required this.comboCount,          // Mevcut kombo sayısı
    required this.modeId,              // Oyun modu ID'si
  });

  final int totalFoundInSession;
  final int comboCount;
  final String modeId;
}

/// Kombo sayısı belirli bir eşiğe ulaştığında.
final class ComboReachedEvent extends AchievementEvent {
  const ComboReachedEvent({required this.comboCount});
  final int comboCount;
}

/// Bir oyun tamamlandığında (bayrak veya süre doldu).
final class GameCompletedEvent extends AchievementEvent {
  const GameCompletedEvent({
    required this.modeId,
    required this.citiesFound,   // Bu oyunda bulunan şehir sayısı
    required this.elapsedTime,   // Saniye cinsinden geçen süre
    required this.isAllFound,    // Tüm şehirler bulundu mu?
  });

  final String modeId;
  final int citiesFound;
  final int elapsedTime;
  final bool isAllFound;
}

/// Liderlik tablosuna ilk kez veya daha iyi bir skor ile girildiğinde.
final class LeaderboardEnteredEvent extends AchievementEvent {
  const LeaderboardEnteredEvent();
}

/// Günlük giriş yapıldığında (auth başarılı olduğunda tetiklenir).
final class DailyLoginEvent extends AchievementEvent {
  const DailyLoginEvent({required this.currentStreak});
  final int currentStreak; // Mevcut seri (gün sayısı)
}
