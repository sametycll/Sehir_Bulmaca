import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/enums.dart';
import '../utils/achievement_icon_helper.dart';

/// Achievement listesinde kullanılan kart widget'ı.
///
/// Kilitli başarımlar: opacity + blur + gizli isim (isSecret ise "???" göster)
/// Açık başarımlar: rarity rengi ile parlayan border, progress bar
class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  final Achievement achievement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(achievement.rarity.colorValue);
    final isLocked = !achievement.isUnlocked;
    final isSecret = achievement.isSecret && isLocked;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isLocked ? 0.45 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked
                  ? Colors.white.withValues(alpha: 0.06)
                  : rarityColor.withValues(alpha: 0.4),
              width: isLocked ? 1 : 1.5,
            ),
            boxShadow: isLocked
                ? null
                : [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.12),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ─── İkon ────────────────────────────────────────
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.white.withValues(alpha: 0.04)
                        : rarityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isLocked
                      ? Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 26,
                        )
                      : Icon(
                          getAchievementIcon(achievement.iconCodePoint),
                          color: rarityColor,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 14),

                // ─── İçerik ───────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isSecret ? '???' : achievement.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isLocked
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textPrimaryDark,
                              ),
                            ),
                          ),
                          // Rarity rozeti
                          _RarityBadge(rarity: achievement.rarity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSecret ? 'Gizli başarım' : achievement.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryDark,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // ─── Progress Bar ──────────────────────────
                      if (!isSecret) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: achievement.progressRatio,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.06),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    achievement.isUnlocked
                                        ? rarityColor
                                        : AppColors.textSecondaryDark
                                            .withValues(alpha: 0.4),
                                  ),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${achievement.currentProgress}/${achievement.targetValue}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: achievement.isUnlocked
                                    ? rarityColor
                                    : AppColors.textSecondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});
  final AchievementRarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = Color(rarity.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        rarity.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
