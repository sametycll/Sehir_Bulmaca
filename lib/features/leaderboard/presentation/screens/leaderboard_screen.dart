import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('LİDERLİK TABLOSU'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryDark),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 28),
            tooltip: 'Tabloyu Sıfırla',
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Hata oluştu: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Henüz Skor Kaydı Yok',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hemen oyuna başla ve ilk dereceyi sen al!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/game'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('OYUNA BAŞLA'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Kolon Başlıkları
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 40, child: Text('SIRA', style: _headerStyle)),
                    Expanded(child: Text('OYUNCU', style: _headerStyle)),
                    SizedBox(width: 80, child: Text('ŞEHİR', textAlign: TextAlign.center, style: _headerStyle)),
                    SizedBox(width: 80, child: Text('SÜRE', textAlign: TextAlign.center, style: _headerStyle)),
                  ],
                ),
              ),

              // Sıralama Listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final rank = index + 1;
                    
                    // İlk 3 dereceye özel renkler ve kupalar
                    Color? rowBgColor;
                    Widget rankWidget;
                    
                    if (rank == 1) {
                      rowBgColor = const Color(0xFFFFD700).withValues(alpha: 0.08); // Altın
                      rankWidget = const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 24);
                    } else if (rank == 2) {
                      rowBgColor = const Color(0xFFC0C0C0).withValues(alpha: 0.08); // Gümüş
                      rankWidget = const Icon(Icons.emoji_events_rounded, color: Color(0xFFC0C0C0), size: 24);
                    } else if (rank == 3) {
                      rowBgColor = const Color(0xFFCD7F32).withValues(alpha: 0.08); // Bronz
                      rankWidget = const Icon(Icons.emoji_events_rounded, color: Color(0xFFCD7F32), size: 24);
                    } else {
                      rankWidget = Text(
                        '$rank',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondaryDark,
                        ),
                      );
                    }

                    final minutes = (entry.elapsedTime / 60).floor();
                    final seconds = entry.elapsedTime % 60;
                    final formattedTime = 
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: rowBgColor ?? AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: rank <= 3 
                              ? (rank == 1 
                                  ? const Color(0xFFFFD700) 
                                  : rank == 2 
                                      ? const Color(0xFFC0C0C0) 
                                      : const Color(0xFFCD7F32)).withValues(alpha: 0.3)
                              : AppColors.surfaceDark,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Center(
                              child: rankWidget,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              entry.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w500,
                                color: rank == 1 ? const Color(0xFFFFD700) : AppColors.textPrimaryDark,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${entry.score} / 81',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer_outlined, size: 14, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  formattedTime,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Tabloyu Sıfırla'),
          content: const Text('Liderlik tablosundaki tüm dereceleri silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              child: const Text('İPTAL', style: TextStyle(color: AppColors.textSecondaryDark)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('TÜMÜNÜ SİL', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onPressed: () {
                ref.read(leaderboardProvider.notifier).clearAll();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.bold,
  color: AppColors.textSecondaryDark,
  letterSpacing: 1.2,
);
