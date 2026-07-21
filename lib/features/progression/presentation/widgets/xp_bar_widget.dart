import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Seviye ilerlemesini (XP) gösteren, animasyonlu ve neon parlamalı premium progress bar.
class XpBarWidget extends StatelessWidget {
  final int currentXp;
  final int xpToNextLevel;
  final double height;
  final bool showText;
  final Color barColor;

  const XpBarWidget({
    super.key,
    required this.currentXp,
    required this.xpToNextLevel,
    this.height = 16,
    this.showText = true,
    this.barColor = AppColors.secondary, // Neon turuncu/amber rengi veya yeşil
  });

  @override
  Widget build(BuildContext context) {
    // Bölünme sıfır hatasını önle
    final int maxVal = xpToNextLevel <= 0 ? 100 : xpToNextLevel;
    final double percentage = (currentXp / maxVal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // İlerleme Çubuğu Gövdesi
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: percentage),
          builder: (context, value, child) {
            return Container(
              height: height,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: FractionallySizedBox(
                widthFactor: value,
                heightFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        barColor,
                        barColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mevcut İlerleme',
                style: TextStyle(
                  color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$currentXp / $xpToNextLevel XP',
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
