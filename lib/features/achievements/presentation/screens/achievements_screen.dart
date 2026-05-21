import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/enums.dart';
import '../providers/achievement_provider.dart';
import '../widgets/achievement_card.dart';
import '../widgets/achievement_detail_modal.dart';

/// Achievement listesi ekranı.
///
/// SliverAppBar + SliverList kombinasyonu ile performanslı scroll.
/// Kategorilere göre filtreleme, unlock sayısı özeti, rarity'ye göre gruplar.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  AchievementCategory? _selectedCategory; // null = tümü

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementProgressProvider);
    final achievements = ref.watch(achievementListProvider);
    final unlockedCount = ref.watch(unlockedAchievementsCountProvider);
    final totalXp = ref.watch(totalXpProvider);

    final filtered = _selectedCategory == null
        ? achievements
        : achievements.where((a) => a.category == _selectedCategory).toList();

    // Önce açılmış, sonra kilitliler
    filtered.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) return a.isUnlocked ? -1 : 1;
      return a.rarity.index.compareTo(b.rarity.index);
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // ─── SliverAppBar ──────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.backgroundDark,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'BAŞARIMLAR',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            centerTitle: true,
          ),

          // ─── Stats Header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(unlockedCount, achievements.length, totalXp),
          ),

          // ─── Kategori Filtresi ─────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryFilterDelegate(
              selectedCategory: _selectedCategory,
              onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
            ),
          ),

          // ─── Achievement Listesi ───────────────────────────────
          achievementsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Text(
                    'Başarımlar yüklenemedi\n$err',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondaryDark),
                  ),
                ),
              ),
            ),
            data: (_) => filtered.isEmpty
                ? const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: Center(
                        child: Text(
                          'Bu kategoride başarım yok',
                          style: TextStyle(color: AppColors.textSecondaryDark),
                        ),
                      ),
                    ),
                  )

                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final a = filtered[i];
                          return AchievementCard(
                            achievement: a,
                            onTap: () => showAchievementDetailModal(context, a),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int unlocked, int total, int xp) {
    final ratio = total > 0 ? unlocked / total : 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unlocked / $total açıldı',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    'Toplam $xp XP kazandın',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CATEGORY FILTER DELEGATE
// ─────────────────────────────────────────────────────────────────

class _CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  _CategoryFilterDelegate({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final AchievementCategory? selectedCategory;
  final ValueChanged<AchievementCategory?> onCategoryChanged;

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: Container(
        color: AppColors.backgroundDark,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _CategoryChip(
                  label: 'Tümü',
                  isSelected: selectedCategory == null,
                  onTap: () => onCategoryChanged(null),
                ),
                const SizedBox(width: 8),
                ...AchievementCategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: cat.label,
                        isSelected: selectedCategory == cat,
                        onTap: () => onCategoryChanged(cat),
                        iconCodePoint: cat.iconCodePoint,
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryFilterDelegate oldDelegate) =>
      oldDelegate.selectedCategory != selectedCategory;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconCodePoint,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? iconCodePoint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconCodePoint != null) ...[
              Icon(
                IconData(iconCodePoint!, fontFamily: 'MaterialIcons'),
                size: 13,
                color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
