import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'daily_notifier.dart';

/// Gece yarısı sıfırlanma zamanına (missionsResetAt) kalan süreyi saniye saniye geri sayarak sunan provider.
/// UI tarafında kalan sürenin "14:32:05" veya "14sa 32dk" şeklinde güncel kalmasını sağlar.
final resetTimerProvider = StreamProvider.autoDispose<String>((ref) {
  final dailyState = ref.watch(dailyStateProvider);
  
  if (dailyState.isLoading) {
    return Stream.value('--:--:--');
  }

  final resetTime = dailyState.streak.missionsResetAt;

  // Saniyede bir tetiklenen stream oluşturuyoruz.
  return Stream.periodic(const Duration(seconds: 1), (_) {
    final now = DateTime.now();
    final difference = resetTime.difference(now);

    if (difference.isNegative) {
      // Süre dolduğunda sayacı sıfırla veya yeniden init yapılmasını bekle
      return '00:00:00';
    }

    final hours = difference.inHours.toString().padLeft(2, '0');
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  });
});
