import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seviye atlama olaylarının detaylarını taşıyan immutable model.
class LevelUpDetails {
  final int fromLevel;
  final int toLevel;
  final String titleGained;

  const LevelUpDetails({
    required this.fromLevel,
    required this.toLevel,
    required this.titleGained,
  });
}

/// Seviye atlama popuplarını yöneten FIFO kuyruk sağlayıcısı (Level Up Queue Provider).
/// Aynı anda birden fazla seviye atlanması durumunda popupların üst üste binmesini önler.
final levelUpQueueProvider =
    StateNotifierProvider<LevelUpQueueNotifier, List<LevelUpDetails>>((ref) {
  return LevelUpQueueNotifier();
});

class LevelUpQueueNotifier extends StateNotifier<List<LevelUpDetails>> {
  LevelUpQueueNotifier() : super([]);

  bool _isShowing = false;
  VoidCallback? _onAllDismissed;

  /// Şu anda aktif olarak bir seviye atlama popup'ı gösteriliyor mu?
  bool get isShowing => _isShowing;

  /// Yeni bir seviye atlama olayını kuyruğa ekler.
  void enqueue(LevelUpDetails details) {
    debugPrint('📥 [QUEUE-DEBUG] enqueue called: ${details.fromLevel} -> ${details.toLevel}');
    state = [...state, details];
    debugPrint('📥 [QUEUE-DEBUG] Queue size now: ${state.length}, isShowing=$_isShowing');
  }

  /// Mevcut popup kapatıldığında çağrılır, sıradakine geçiş sağlar.
  void dequeue() {
    debugPrint('📤 [QUEUE-DEBUG] dequeue called. Queue size before: ${state.length}');
    if (state.isEmpty) {
      _isShowing = false;
      _triggerAllDismissed();
      return;
    }
    state = state.sublist(1);
    _isShowing = state.isNotEmpty;
    debugPrint('📤 [QUEUE-DEBUG] Queue size after: ${state.length}, isShowing=$_isShowing');
    if (state.isEmpty) {
      _triggerAllDismissed();
    }
  }

  /// Popup gösterilmeye başlandığında işaretlenir.
  void markAsShowing() {
    debugPrint('👁️ [QUEUE-DEBUG] markAsShowing called');
    _isShowing = true;
  }

  /// Tüm kuyruğu temizler.
  void clearAll() {
    state = [];
    _isShowing = false;
    _onAllDismissed = null;
  }

  /// Bekleyen elemanların yeniden işlenmesini sağlamak için dinleyicileri tetikler.
  void forceNotify() {
    debugPrint('🔔 [QUEUE-DEBUG] forceNotify called. Queue size: ${state.length}');
    state = [...state];
  }

  /// Seviye atlama popuplarını başlatır. Eğer kuyruk boşsa doğrudan [onComplete] çalışır.
  void startProcessing({required VoidCallback onComplete}) {
    debugPrint('🚀 [QUEUE-DEBUG] startProcessing called. Queue size: ${state.length}, isShowing=$_isShowing');
    if (state.isEmpty) {
      debugPrint('🚀 [QUEUE-DEBUG] Queue is empty, calling onComplete immediately');
      onComplete();
    } else {
      _onAllDismissed = onComplete;
      forceNotify();
    }
  }

  void _triggerAllDismissed() {
    debugPrint('✅ [QUEUE-DEBUG] _triggerAllDismissed called. hasCallback=${_onAllDismissed != null}');
    if (_onAllDismissed != null) {
      final callback = _onAllDismissed!;
      _onAllDismissed = null;
      callback();
    }
  }
}
