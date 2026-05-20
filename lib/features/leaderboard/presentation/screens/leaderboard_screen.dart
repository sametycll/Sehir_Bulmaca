import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/game_mode.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(activeGameModeProvider);
    final leaderboardAsync = ref.watch(leaderboardStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'LİDERLİK TABLOSU',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryDark),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: AppColors.textSecondaryDark, size: 24),
            tooltip: 'Yerel Önbelleği Temizle',
            onPressed: () => _showClearLocalConfirmation(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Premium Game Mode Selector (Horizontal sliding tabs with micro-animations)
          const SizedBox(height: 16),
          _buildModeSelector(context, ref, selectedMode),
          const SizedBox(height: 16),

          // 2. Active Mode Information Bar
          _buildActiveModeInfoBar(selectedMode),

          // 3. Leaderboard Listing / Dynamic Content
          Expanded(
            child: leaderboardAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Bağlantı hatası oluştu: $err\nLütfen internet bağlantınızı kontrol edin.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error, fontSize: 15),
                  ),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return _buildEmptyState(context, selectedMode);
                }

                return Column(
                  children: [
                    // Kolon Başlıkları
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 40, child: Text('SIRA', style: _headerStyle)),
                          const Expanded(child: Text('OYUNCU', style: _headerStyle)),
                          SizedBox(
                            width: 80, 
                            child: Text(
                              'ŞEHİR', 
                              textAlign: TextAlign.center, 
                              style: _headerStyle.copyWith(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 80, child: Text('SÜRE', textAlign: TextAlign.center, style: _headerStyle)),
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
                          
                          // Degrees colors and cup icons
                          Color? rowBgColor;
                          Widget rankWidget;
                          
                          if (rank == 1) {
                            rowBgColor = const Color(0xFFFFD700).withValues(alpha: 0.08); // Gold
                            rankWidget = const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 24);
                          } else if (rank == 2) {
                            rowBgColor = const Color(0xFFC0C0C0).withValues(alpha: 0.08); // Silver
                            rankWidget = const Icon(Icons.emoji_events_rounded, color: Color(0xFFC0C0C0), size: 24);
                          } else if (rank == 3) {
                            rowBgColor = const Color(0xFFCD7F32).withValues(alpha: 0.08); // Bronze
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                    '${entry.score} / ${selectedMode.maxScore}',
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
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, WidgetRef ref, GameMode selectedMode) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: GameMode.values.length,
        itemBuilder: (context, index) {
          final mode = GameMode.values[index];
          final isSelected = mode == selectedMode;

          // Custom Icons for each game mode
          IconData iconData;
          Color activeGlowColor;
          switch (mode) {
            case GameMode.allTurkey:
              iconData = Icons.explore_rounded;
              activeGlowColor = AppColors.primary;
              break;
            case GameMode.timeAttack:
              iconData = Icons.bolt_rounded;
              activeGlowColor = Colors.amber;
              break;
            case GameMode.blitzChallenge:
              iconData = Icons.timer_outlined;
              activeGlowColor = Colors.redAccent;
              break;
            case GameMode.marmara:
              iconData = Icons.water_rounded;
              activeGlowColor = const Color(0xFF4FC3F7);
              break;
            case GameMode.ege:
              iconData = Icons.beach_access_rounded;
              activeGlowColor = const Color(0xFF26C6DA);
              break;
            case GameMode.akdeniz:
              iconData = Icons.wb_sunny_rounded;
              activeGlowColor = const Color(0xFFFF8A65);
              break;
            case GameMode.icAnadolu:
              iconData = Icons.landscape_rounded;
              activeGlowColor = const Color(0xFFA5D6A7);
              break;
            case GameMode.karadeniz:
              iconData = Icons.forest_rounded;
              activeGlowColor = const Color(0xFF80CBC4);
              break;
            case GameMode.doguAnadolu:
              iconData = Icons.terrain_rounded;
              activeGlowColor = const Color(0xFFCE93D8);
              break;
            case GameMode.guneydoguAnadolu:
              iconData = Icons.filter_drama_rounded;
              activeGlowColor = const Color(0xFFFFCC02);
              break;
          }

          return GestureDetector(
            onTap: () {
              ref.read(activeGameModeProvider.notifier).state = mode;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected 
                    ? activeGlowColor.withValues(alpha: 0.15) 
                    : AppColors.surfaceDark.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected 
                      ? activeGlowColor.withValues(alpha: 0.6) 
                      : AppColors.surfaceDark,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeGlowColor.withValues(alpha: 0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    iconData,
                    size: 18,
                    color: isSelected ? activeGlowColor : AppColors.textSecondaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mode.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.textPrimaryDark : AppColors.textSecondaryDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveModeInfoBar(GameMode mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceDark.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: AppColors.success),
              const SizedBox(width: 8),
              const Text(
                'Küresel Sıralama',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          Text(
            'Toplam Hedef: ${mode.maxScore} İl',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, GameMode mode) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Henüz Skor Kaydı Yok',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${mode.title} modunda ilk dereceyi alan sen ol!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/game'),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('OYUNA BAŞLA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearLocalConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.surfaceDark, width: 1),
          ),
          title: const Text(
            'Önbelleği Temizle',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
          ),
          content: const Text(
            'Yerel cihazınızda kayıtlı olan çevrimdışı skor geçmişini silmek istiyor musunuz? Bu işlem küresel (online) liderlik tablosunu etkilemez.',
            style: TextStyle(color: AppColors.textSecondaryDark),
          ),
          actions: [
            TextButton(
              child: const Text('İPTAL', style: TextStyle(color: AppColors.textSecondaryDark)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'SİL', 
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ref.read(leaderboardNotifierProvider.notifier).clearLocalCache();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yerel önbellek başarıyla temizlendi.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
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
