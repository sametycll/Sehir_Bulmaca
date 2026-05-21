import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/enums.dart';

/// Oyun içi achievement unlock overlay widget'ı.
///
/// Mevcut FloatingNotificationWidget ile aynı OverlayEntry mimarisi kullanılır.
/// Aynı global Overlay katmanında çalışır → clipping sorunu yok.
///
/// Animasyon: aşağıdan slide-up + neon glow + fade out
/// Queue: AchievementQueueNotifier yönetir, çakışma olmaz.
class AchievementUnlockOverlay extends StatefulWidget {
  const AchievementUnlockOverlay({
    super.key,
    required this.achievement,
    required this.onFinished,
  });

  final Achievement achievement;
  final VoidCallback onFinished;

  @override
  State<AchievementUnlockOverlay> createState() =>
      _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState extends State<AchievementUnlockOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // Aşağıdan yukarı slide (ilk 300ms hızlı giriş)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 2.0),
      end: const Offset(0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.12, curve: Curves.easeOutCubic),
    ));

    // Opacity: giriş → bekle → çıkış
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_controller);

    // Neon glow pulse
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.6),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.0),
        weight: 60,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rarityColor = Color(widget.achievement.rarity.colorValue);

    return Positioned(
      // Ekranın alt-orta kısmına konumlandır (navigation bar'ın üstü)
      bottom: size.height * 0.12,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: _buildCard(rarityColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(Color rarityColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(
              alpha: 0.15 + (_glowAnimation.value * 0.25),
            ),
            blurRadius: 20 + (_glowAnimation.value * 20),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // İkon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rarityColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(
              IconData(
                widget.achievement.iconCodePoint,
                fontFamily: 'MaterialIcons',
              ),
              color: rarityColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // Metin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 12,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'BAŞARIM AÇILDI!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.achievement.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.achievement.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // XP rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '+${widget.achievement.xpReward}XP',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay'i global katmana enjekte eden yardımcı fonksiyon.
/// game_screen.dart'tan çağrılır.
OverlayEntry createAchievementOverlayEntry({
  required Achievement achievement,
  required VoidCallback onFinished,
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => AchievementUnlockOverlay(
      achievement: achievement,
      onFinished: () {
        entry.remove();
        onFinished();
      },
    ),
  );
  return entry;
}
