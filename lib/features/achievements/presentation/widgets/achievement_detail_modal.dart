import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/enums.dart';
import '../utils/achievement_icon_helper.dart';

/// Achievement detay bottom sheet modal.
///
/// Bir kartın tap'inde açılır. Büyük ikon, açıklama,
/// XP ödülü, açılma tarihi ve detaylı progress bar içerir.
void showAchievementDetailModal(BuildContext context, Achievement achievement) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _AchievementDetailModal(achievement: achievement),
  );
}

class _AchievementDetailModal extends StatelessWidget {
  const _AchievementDetailModal({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(achievement.rarity.colorValue);
    final isLocked = !achievement.isUnlocked;
    final isSecret = achievement.isSecret && isLocked;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: rarityColor.withValues(alpha: isLocked ? 0.1 : 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Büyük ikon ──────────────────────────────────────
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: isLocked ? 0.05 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: rarityColor.withValues(alpha: isLocked ? 0.15 : 0.4),
                width: 2,
              ),
              boxShadow: isLocked
                  ? null
                  : [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: isLocked
                ? Icon(
                    Icons.lock_outline_rounded,
                    size: 36,
                    color: Colors.white.withValues(alpha: 0.25),
                  )
                : Icon(
                    getAchievementIcon(achievement.iconCodePoint),
                    size: 40,
                    color: rarityColor,
                  ),
          ),
          const SizedBox(height: 16),

          // ─── Başlık ve rarity ─────────────────────────────────
          Text(
            isSecret ? 'Gizli Başarım' : achievement.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          _RarityRow(rarity: achievement.rarity),
          const SizedBox(height: 16),

          // ─── Açıklama ─────────────────────────────────────────
          Text(
            isSecret ? 'Bu başarımı keşfetmek için oynamaya devam et.' : achievement.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // ─── İstatistikler ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.secondary,
                  label: 'XP Ödülü',
                  value: '+${achievement.xpReward}',
                  valueColor: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.flag_rounded,
                  iconColor: AppColors.primary,
                  label: 'Hedef',
                  value: '${achievement.targetValue}',
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Progress ─────────────────────────────────────────
          if (!isSecret) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'İlerleme',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondaryDark,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${achievement.currentProgress} / ${achievement.targetValue}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: rarityColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: achievement.progressRatio,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                      minHeight: 8,
                    ),
                  ),
                  if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          'Açıldı: ${_formatDate(achievement.unlockedAt!)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _RarityRow extends StatelessWidget {
  const _RarityRow({required this.rarity});
  final AchievementRarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = Color(rarity.colorValue);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.diamond_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          rarity.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }
}
