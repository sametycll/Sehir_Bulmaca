import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/achievement.dart';

/// Overlay popup kuyruğu yöneticisi.
///
/// PROBLEM:
/// Aynı anda birden fazla achievement açılabilir (örn: "İlk Şehir" + "10 Şehir").
/// Bunları aynı anda göstermek kötü UX yaratır.
///
/// ÇÖZÜM:
/// FIFO queue. Mevcut popup bitince bir sonraki gösterilir.
/// game_screen.dart bu kuyruğu dinler ve overlay'i yönetir.
final achievementQueueProvider =
    StateNotifierProvider<AchievementQueueNotifier, List<Achievement>>((ref) {
  return AchievementQueueNotifier();
});

class AchievementQueueNotifier extends StateNotifier<List<Achievement>> {
  AchievementQueueNotifier() : super([]);

  bool _isShowing = false;

  /// Kuyruğa yeni bir başarım ekler.
  /// Eğer hiçbir popup gösterilmiyorsa hemen tetiklenir.
  void enqueue(Achievement achievement) {
    state = [...state, achievement];
    // İlk eleman eklendi ve hiç popup yoksa, listener otomatik tetikler.
    // game_screen.dart state'i izler ve ilk elemanı gösterir.
  }

  /// Mevcut popup tamamlandığında çağrılır.
  /// Kuyruktaki bir sonraki başarıma geçilir.
  void dequeue() {
    if (state.isEmpty) {
      _isShowing = false;
      return;
    }
    state = state.sublist(1); // İlk elemanı kaldır
    _isShowing = state.isNotEmpty;
  }

  /// game_screen.dart'ın mevcut durumu kontrol etmesi için.
  bool get isShowing => _isShowing;

  void markAsShowing() {
    _isShowing = true;
  }

  void clearAll() {
    state = [];
    _isShowing = false;
  }
}
