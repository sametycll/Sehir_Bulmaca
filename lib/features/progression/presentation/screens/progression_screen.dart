import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../providers/progression_provider.dart';
import '../widgets/xp_bar_widget.dart';
import '../../domain/services/level_calculator.dart';

/// Oyuncunun detaylı seviye ilerlemesini, unvanlarını, yaklaşan ödüllerini
/// ve oyun içi XP kazanım rehberini gösteren premium profil ekranı.
class ProgressionScreen extends ConsumerWidget {
  const ProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressionProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF070B11),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: progressAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Hata oluştu: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (progress) {
            final user = authState.user;
            final String displayName = user?.displayName ?? 'Gezgin';
            final String? photoUrl = user?.photoURL;
            final bool isGuest = authState.isGuest;
            final String currentTitle = LevelCalculator.getTitle(progress.level);

            return SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Üst Başlık (Custom AppBar)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => context.pop(),
                          ),
                          const Spacer(),
                          const Text(
                            'OYUNCU PROFİLİ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48), // Denge için
                        ],
                      ),
                    ),
                  ),

                  // 2. Büyük Profil Kartı (Avatar, Seviye, XP)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar ve Glow Border
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isGuest
                                    ? [Colors.grey.shade600, Colors.grey.shade800]
                                    : [AppColors.primary, const Color(0xFF007A80)],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: AppColors.surfaceDark,
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null
                                  ? Icon(
                                      isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                                      size: 48,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Oyuncu Adı
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: AppColors.textPrimaryDark,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Unvan Rozeti
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              currentTitle.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Seviye Göstergesi ve XP Barı
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SEVİYE',
                                    style: TextStyle(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    'Lvl ${progress.level}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'TOPLAM XP',
                                    style: TextStyle(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    '${progress.totalXp} XP',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // XP Bar
                          XpBarWidget(
                            currentXp: progress.currentXp,
                            xpToNextLevel: progress.xpToNextLevel,
                            height: 12,
                            showText: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Seviye İlerleme Yol Haritası (Timeline)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.alt_route_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'UNVAN İLERLEME YOLU',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final milestones = LevelCalculator.getMilestones();
                        final m = milestones[index];
                        final isUnlocked = progress.level >= m.level;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? AppColors.surfaceDark.withValues(alpha: 0.6)
                                : AppColors.surfaceDark.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isUnlocked
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.05),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Seviye Dairesi
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isUnlocked
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.03),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isUnlocked ? AppColors.primary : Colors.white24,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${m.level}',
                                    style: TextStyle(
                                      color: isUnlocked ? Colors.white : AppColors.textSecondaryDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Metin Detayları
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.title,
                                      style: TextStyle(
                                        color: isUnlocked ? Colors.white : AppColors.textSecondaryDark,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      m.description,
                                      style: TextStyle(
                                        color: isUnlocked
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryDark.withValues(alpha: 0.45),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Kilit Durumu
                              Icon(
                                isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                                color: isUnlocked ? AppColors.primary : Colors.white24,
                                size: 20,
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: LevelCalculator.getMilestones().length,
                    ),
                  ),

                  // 4. XP Rehberi / Breakdown
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'XP NASIL KAZANILIR?',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.35,
                      ),
                      delegate: SliverChildListDelegate(
                        [
                          _buildGuideCard(
                            title: 'Şehir Bulma',
                            value: '+10 XP',
                            subtitle: 'Her doğru tahmin',
                            icon: Icons.location_on_rounded,
                            color: const Color(0xFF10B981),
                          ),
                          _buildGuideCard(
                            title: 'Kombo Serisi',
                            value: '2x: +20 | 5x: +75',
                            subtitle: '4sn içinde hızlı tahminler',
                            icon: Icons.bolt_rounded,
                            color: const Color(0xFFFF8C00),
                          ),
                          _buildGuideCard(
                            title: 'Bölge Tamamlama',
                            value: '+250 XP',
                            subtitle: '7 coğrafi bölge modları',
                            icon: Icons.map_rounded,
                            color: const Color(0xFF3B82F6),
                          ),
                          _buildGuideCard(
                            title: 'Türkiye Bitirme',
                            value: '+1000 XP',
                            subtitle: 'Tüm 81 ili bitirme bonusu',
                            icon: Icons.emoji_events_rounded,
                            color: AppColors.secondary,
                          ),
                          _buildGuideCard(
                            title: 'Başarım Kilidi',
                            value: 'Ödüle Göre',
                            subtitle: 'Rozetleri toplayın',
                            icon: Icons.military_tech_rounded,
                            color: const Color(0xFFEC4899),
                          ),
                          _buildGuideCard(
                            title: 'Günlük Giriş',
                            value: '+100 XP+',
                            subtitle: 'Seriyi bozmadan oyna',
                            icon: Icons.calendar_today_rounded,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondaryDark.withValues(alpha: 0.6),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
