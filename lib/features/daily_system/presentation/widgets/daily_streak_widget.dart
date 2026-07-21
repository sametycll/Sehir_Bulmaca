import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daily_notifier.dart';
import '../../domain/entities/daily_streak.dart';
import '../../../game/infrastructure/services/audio_service.dart';

/// Alev animasyonlu ve haftalık giriş durum göstergeli, premium tasarımlı Günlük Giriş Serisi (Streak) Widget'ı.
class DailyStreakWidget extends ConsumerStatefulWidget {
  const DailyStreakWidget({super.key});

  @override
  ConsumerState<DailyStreakWidget> createState() => _DailyStreakWidgetState();
}

class _DailyStreakWidgetState extends ConsumerState<DailyStreakWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Alevin nabız (pulse) gibi sürekli büyümesi ve küçülmesi için animasyon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.10).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyStateProvider);
    if (dailyState.isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final streak = dailyState.streak;
    final isManipulated = dailyState.isTimeManipulated;

    // Bugün ödül alınmış mı kontrolü
    bool isClaimedToday = false;
    if (streak.lastClaimedDate != null) {
      final now = DateTime.now();
      isClaimedToday = streak.lastClaimedDate!.year == now.year &&
          streak.lastClaimedDate!.month == now.month &&
          streak.lastClaimedDate!.day == now.day;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1B4B), // Çok koyu çivit mavisi
            const Color(0xFF311B92).withOpacity(0.8), // Koyu mor
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isClaimedToday ? Colors.amber.withOpacity(0.4) : Colors.white12,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isClaimedToday
                ? Colors.amber.withOpacity(0.15)
                : Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Üst Bölüm: Alev Animasyonu ve Streak Sayacı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: IgnorePointer(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [
                                Colors.yellow,
                                Colors.orange,
                                Colors.redAccent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds);
                          },
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            size: 42,
                            color: isClaimedToday ? Colors.white : Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${streak.currentStreak} GÜNLÜK SERİ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'En İyi Seri: ${streak.bestStreak} Gün',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Sağ Buton: Talep etme (Claim) butonu veya tamamlandı ibaresi
              isManipulated
                  ? const Text(
                      'Zaman Hatası ⚠️',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    )
                  : isClaimedToday
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'ALINDI',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            AudioService.playCorrect(); // Ses efekti
                            await ref.read(dailyStateProvider.notifier).claimStreakBonus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: Colors.amber.withOpacity(0.4),
                          ),
                          child: const Text(
                            'ÖDÜLÜ AL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // Alt Bölüm: Haftalık Gün Durumu Göstergesi (Consecutive Days)
          _buildWeeklyStatus(streak),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatus(DailyStreak streak) {
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 = Pazartesi, 7 = Pazar

    // Haftanın gün adları
    final daysOfWeek = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayIndex = index + 1; // 1-7
        final isToday = dayIndex == todayWeekday;
        
        // Geçmiş günler için serinin aktif olup olmadığını kontrol edelim
        // Basitlik açısından, eğer mevcut streak haftanın günlerinden fazla ise
        // geçmiş günleri aktif gösterebiliriz. Ya da son aktif güne göre renklendiririz.
        bool isDayActive = false;
        
        if (dayIndex < todayWeekday) {
          // Bugün Cuma (5) ise ve streak 3 ise Çarşamba (3), Perşembe (4) ve Cuma (5) aktif olmalı.
          final diff = todayWeekday - dayIndex;
          if (streak.currentStreak > diff) {
            isDayActive = true;
          }
        } else if (isToday) {
          // Bugün giriş ödülü alınmışsa aktif göster
          if (streak.lastClaimedDate != null) {
            final now = DateTime.now();
            isDayActive = streak.lastClaimedDate!.year == now.year &&
                streak.lastClaimedDate!.month == now.month &&
                streak.lastClaimedDate!.day == now.day;
          }
        }

        return Column(
          children: [
            Text(
              daysOfWeek[index],
              style: TextStyle(
                color: isToday ? Colors.amber : Colors.white38,
                fontSize: 11,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDayActive
                    ? Colors.amber.withOpacity(0.2)
                    : isToday
                        ? Colors.white.withOpacity(0.05)
                        : Colors.transparent,
                border: Border.all(
                  color: isDayActive
                      ? Colors.amber
                      : isToday
                          ? Colors.amber.withOpacity(0.6)
                          : Colors.white12,
                  width: isToday ? 2 : 1,
                ),
                boxShadow: isDayActive
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: isDayActive
                    ? const Icon(
                        Icons.check,
                        color: Colors.amber,
                        size: 16,
                      )
                    : isToday
                        ? const Icon(
                            Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          )
                        : Text(
                            '$dayIndex',
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
