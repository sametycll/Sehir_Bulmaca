import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/auth_notifier.dart';
import '../../domain/entities/game_mode.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';

// Tab seçimi için state provider
final _leaderboardTabProvider = StateProvider.autoDispose<int>((ref) => 0);

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(_leaderboardTabProvider);

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildTabBar(context, ref, selectedTab),
        ),
      ),
      body: selectedTab == 0
          ? const _GlobalLeaderboardTab()
          : const _MyStatsTab(),
    );
  }

  Widget _buildTabBar(BuildContext context, WidgetRef ref, int selectedTab) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceDark, width: 1),
      ),
      child: Row(
        children: [
          _buildTabItem(
            ref: ref,
            index: 0,
            selectedTab: selectedTab,
            icon: Icons.public_rounded,
            label: 'Küresel Sıralama',
          ),
          _buildTabItem(
            ref: ref,
            index: 1,
            selectedTab: selectedTab,
            icon: Icons.person_rounded,
            label: 'İstatistiklerim',
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required WidgetRef ref,
    required int index,
    required int selectedTab,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(_leaderboardTabProvider.notifier).state = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                  letterSpacing: 0.3,
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

// ─────────────────────────────────────────
// SEKME 1: Küresel Liderlik Tablosu
// ─────────────────────────────────────────
class _GlobalLeaderboardTab extends ConsumerWidget {
  const _GlobalLeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(activeGameModeProvider);
    final leaderboardAsync = ref.watch(leaderboardStreamProvider);

    return Column(
      children: [
        // 1. Game Mode Selector
        const SizedBox(height: 16),
        _buildModeSelector(context, ref, selectedMode),
        const SizedBox(height: 12),

        // 2. Active Mode Info Bar
        _buildActiveModeInfoBar(selectedMode),
        const SizedBox(height: 16), // ← Buradaki boşluk arttırıldı

        // 3. Kolon başlıkları + Liste
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
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12), // bottom: 8→12
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        width: 1,
                      ),
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
                        return _buildLeaderboardRow(entries[index], index + 1, selectedMode);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
            onTap: () => ref.read(activeGameModeProvider.notifier).state = mode,
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
                  Icon(iconData, size: 18,
                      color: isSelected ? activeGlowColor : AppColors.textSecondaryDark),
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

  Widget _buildLeaderboardRow(LeaderboardEntry entry, int rank, GameMode selectedMode) {
    Color? rowBgColor;
    Widget rankWidget;

    if (rank == 1) {
      rowBgColor = const Color(0xFFFFD700).withValues(alpha: 0.08);
      rankWidget = const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 24);
    } else if (rank == 2) {
      rowBgColor = const Color(0xFFC0C0C0).withValues(alpha: 0.08);
      rankWidget = const Icon(Icons.emoji_events_rounded, color: Color(0xFFC0C0C0), size: 24);
    } else if (rank == 3) {
      rowBgColor = const Color(0xFFCD7F32).withValues(alpha: 0.08);
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
                          : const Color(0xFFCD7F32))
                  .withValues(alpha: 0.3)
              : AppColors.surfaceDark,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 32, child: Center(child: rankWidget)),
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
                child: const Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Henüz Skor Kaydı Yok',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${mode.title} modunda ilk dereceyi alan sen ol!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/game'),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('OYUNA BAŞLA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SEKME 2: Benim İstatistiklerim
// ─────────────────────────────────────────
class _MyStatsTab extends ConsumerWidget {
  const _MyStatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final myStatsAsync = ref.watch(myStatsProvider);
    final user = authState.user;

    return myStatsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Veriler yüklenemedi: $err',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return _buildNoStatsState(context);
        }

        // Tüm modları doldur: var olan entry'leri modeId ile eşleştir
        final Map<String, LeaderboardEntry> entryByMode = {
          for (final e in entries) e.modeId: e,
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kullanıcı Profil Kartı
              _buildProfileCard(user?.displayName ?? 'Oyuncu', authState.isGuest),
              const SizedBox(height: 20),

              // Özet istatistik kartları
              _buildSummaryRow(entries),
              const SizedBox(height: 24),

              // Başlık
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'MOD BAZLI EN İYİ SKORLARIM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),

              // Her oyun modu için kart
              ...GameMode.values.map((mode) {
                final entry = entryByMode[mode.id];
                return _buildModeStatCard(mode, entry);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(String displayName, bool isGuest) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isGuest
                        ? Colors.orange.withValues(alpha: 0.15)
                        : AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isGuest
                          ? Colors.orange.withValues(alpha: 0.4)
                          : AppColors.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    isGuest ? 'Misafir Oyuncu' : 'Kayıtlı Oyuncu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isGuest ? Colors.orange : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(List<LeaderboardEntry> entries) {
    final totalModes = entries.length;
    final bestScore = entries.isEmpty ? 0 : entries.map((e) => e.score).reduce((a, b) => a > b ? a : b);
    final bestTime = entries.isEmpty ? 0 : entries.map((e) => e.elapsedTime).reduce((a, b) => a < b ? a : b);
    final bestMin = (bestTime / 60).floor();
    final bestSec = bestTime % 60;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.sports_esports_rounded,
            iconColor: AppColors.primary,
            value: '$totalModes',
            label: 'Oynadığı Mod',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.location_city_rounded,
            iconColor: AppColors.success,
            value: '$bestScore',
            label: 'En Yüksek Şehir',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.timer_rounded,
            iconColor: AppColors.secondary,
            value: '${bestMin.toString().padLeft(2, '0')}:${bestSec.toString().padLeft(2, '0')}',
            label: 'En Hızlı Süre',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: iconColor,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeStatCard(GameMode mode, LeaderboardEntry? entry) {
    final hasData = entry != null;

    // Her mod için renk ve ikon
    Color modeColor;
    IconData modeIcon;
    switch (mode) {
      case GameMode.allTurkey:
        modeColor = AppColors.primary;
        modeIcon = Icons.explore_rounded;
        break;
      case GameMode.timeAttack:
        modeColor = Colors.amber;
        modeIcon = Icons.bolt_rounded;
        break;
      case GameMode.blitzChallenge:
        modeColor = Colors.redAccent;
        modeIcon = Icons.timer_outlined;
        break;
      case GameMode.marmara:
        modeColor = const Color(0xFF4FC3F7);
        modeIcon = Icons.water_rounded;
        break;
      case GameMode.ege:
        modeColor = const Color(0xFF26C6DA);
        modeIcon = Icons.beach_access_rounded;
        break;
      case GameMode.akdeniz:
        modeColor = const Color(0xFFFF8A65);
        modeIcon = Icons.wb_sunny_rounded;
        break;
      case GameMode.icAnadolu:
        modeColor = const Color(0xFFA5D6A7);
        modeIcon = Icons.landscape_rounded;
        break;
      case GameMode.karadeniz:
        modeColor = const Color(0xFF80CBC4);
        modeIcon = Icons.forest_rounded;
        break;
      case GameMode.doguAnadolu:
        modeColor = const Color(0xFFCE93D8);
        modeIcon = Icons.terrain_rounded;
        break;
      case GameMode.guneydoguAnadolu:
        modeColor = const Color(0xFFFFCC02);
        modeIcon = Icons.filter_drama_rounded;
        break;
    }

    final minutes = hasData ? (entry.elapsedTime / 60).floor() : 0;
    final seconds = hasData ? entry.elapsedTime % 60 : 0;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Tamamlanma yüzdesi
    final double progress = hasData ? (entry.score / mode.maxScore).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData
              ? modeColor.withValues(alpha: 0.3)
              : AppColors.surfaceDark.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Mod ikonu
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: hasData ? 0.15 : 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(modeIcon, color: hasData ? modeColor : AppColors.textSecondaryDark.withValues(alpha: 0.4), size: 22),
              ),
              const SizedBox(width: 12),
              // Mod adı
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: hasData ? AppColors.textPrimaryDark : AppColors.textSecondaryDark.withValues(alpha: 0.5),
                      ),
                    ),
                    if (!hasData)
                      const Text(
                        'Henüz oynanmadı',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                      ),
                  ],
                ),
              ),
              // Skor & Süre (sadece data varsa)
              if (hasData) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Şehir skoru
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_city_rounded, size: 13, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.score} / ${mode.maxScore}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Süre
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
          // İlerleme çubuğu (sadece data varsa)
          if (hasData) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: modeColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(modeColor),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '%${(progress * 100).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: modeColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoStatsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz İstatistik Yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bir oyun tamamladıktan sonra\nistatistiklerin burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go('/game'),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('OYUNA BAŞLA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.bold,
  color: AppColors.textSecondaryDark,
  letterSpacing: 1.2,
);
