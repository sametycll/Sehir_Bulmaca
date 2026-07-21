import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/infrastructure/services/audio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/services/level_calculator.dart';

/// Oyun sonunda XP ilerlemesini ve seviye atlama durumunu gösteren premium dialog.
/// showDialog ile çağrılır — overlay mekanizmasına bağımlı değildir, güvenilirdir.
class XpProgressDialog extends StatefulWidget {
  /// Oyun öncesi seviye
  final int previousLevel;
  /// Oyun öncesi toplam XP
  final int previousTotalXp;
  /// Oyun sonrası seviye
  final int newLevel;
  /// Oyun sonrası toplam XP
  final int newTotalXp;
  /// Bu oyunda kazanılan toplam XP
  final int xpGained;

  const XpProgressDialog({
    super.key,
    required this.previousLevel,
    required this.previousTotalXp,
    required this.newLevel,
    required this.newTotalXp,
    required this.xpGained,
  });

  @override
  State<XpProgressDialog> createState() => _XpProgressDialogState();
}

class _XpProgressDialogState extends State<XpProgressDialog>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _particleController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  late final Animation<double> _progressAnimation;
  late final Animation<double> _xpCountAnimation;
  late final List<_Particle> _particles;

  bool get _isLevelUp => widget.newLevel > widget.previousLevel;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeIn = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    _scaleIn = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    );

    _progressAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.85, curve: Curves.easeInOut),
    );

    _xpCountAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    );

    // Particle patlama animasyonu (sadece seviye atlama durumunda)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _generateParticles();

    _mainController.forward();
    if (_isLevelUp) {
      _particleController.forward();
      _triggerHaptics();
      AudioService.playSuccess();
    } else if (widget.xpGained > 0) {
      HapticFeedback.mediumImpact();
      AudioService.playCorrect();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _generateParticles() {
    final random = math.Random();
    _particles = List.generate(30, (_) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double velocity = 120.0 + random.nextDouble() * 180.0;
      final double size = 3.0 + random.nextDouble() * 6.0;
      final colors = [
        AppColors.secondary,
        const Color(0xFFFFD700),
        AppColors.primary,
        const Color(0xFFFF1493),
        const Color(0xFF10B981),
      ];
      return _Particle(
        dx: math.cos(angle) * velocity,
        dy: math.sin(angle) * velocity,
        size: size,
        color: colors[random.nextInt(colors.length)],
      );
    });
  }

  Future<void> _triggerHaptics() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  /// XP barı için başlangıç ve bitiş yüzdelerini hesaplar
  double _getProgressFraction(int totalXp, int level) {
    final xpForCurrentLevel = LevelCalculator.totalXpToReachLevel(level);
    final currentXp = totalXp - xpForCurrentLevel;
    final needed = LevelCalculator.xpToNextLevelForLevel(level);
    if (needed <= 0) return 1.0;
    return (currentXp / needed).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final startFraction = _getProgressFraction(widget.previousTotalXp, widget.previousLevel);
    
    // Eğer seviye atlandıysa bar 0'dan dolmaya başlamalı (yeni seviyedeki ilerleme)
    final double endFraction;
    if (_isLevelUp) {
      endFraction = _getProgressFraction(widget.newTotalXp, widget.newLevel);
    } else {
      endFraction = _getProgressFraction(widget.newTotalXp, widget.newLevel);
    }

    final newXpToNext = LevelCalculator.xpToNextLevelForLevel(widget.newLevel);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Partikül patlaması (seviye atlama durumunda)
          if (_isLevelUp)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleController.value,
                    ),
                  );
                },
              ),
            ),

          // Ana kart
          ScaleTransition(
            scale: _scaleIn,
            child: FadeTransition(
              opacity: _fadeIn,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1524),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: _isLevelUp
                        ? AppColors.secondary.withValues(alpha: 0.4)
                        : const Color(0xFF10B981).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isLevelUp ? AppColors.secondary : const Color(0xFF10B981))
                          .withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Üst İkon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (_isLevelUp ? AppColors.secondary : const Color(0xFF10B981))
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (_isLevelUp ? AppColors.secondary : const Color(0xFF10B981))
                              .withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isLevelUp
                            ? Icons.workspace_premium_rounded
                            : Icons.trending_up_rounded,
                        color: _isLevelUp ? AppColors.secondary : const Color(0xFF10B981),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Başlık
                    Text(
                      _isLevelUp 
                          ? 'SEVİYE ATLADIN!' 
                          : (widget.xpGained > 0 ? 'XP KAZANDIN!' : 'SEVİYE İLERLEMESİ'),
                      style: TextStyle(
                        color: _isLevelUp ? AppColors.secondary : const Color(0xFF10B981),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        shadows: [
                          Shadow(
                            color: (_isLevelUp ? AppColors.secondary : const Color(0xFF10B981))
                                .withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Seviye gösterimi
                    if (_isLevelUp) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LevelBadge(level: widget.previousLevel),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white60,
                              size: 28,
                            ),
                          ),
                          _LevelBadge(level: widget.newLevel, highlight: true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        LevelCalculator.getTitle(widget.newLevel),
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      _LevelBadge(level: widget.newLevel, highlight: true),
                      const SizedBox(height: 8),
                      Text(
                        LevelCalculator.getTitle(widget.newLevel),
                        style: TextStyle(
                          color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Kazanılan XP gösterimi
                    AnimatedBuilder(
                      animation: _xpCountAnimation,
                      builder: (context, child) {
                        final animatedXp = (_xpCountAnimation.value * widget.xpGained).toInt();
                        final hasXp = widget.xpGained > 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: (hasXp ? const Color(0xFF10B981) : Colors.white24).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (hasXp ? const Color(0xFF10B981) : Colors.white24).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            hasXp ? '+$animatedXp XP' : '0 XP',
                            style: TextStyle(
                              color: hasXp ? const Color(0xFF10B981) : AppColors.textSecondaryDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // XP İlerleme Barı
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SEVİYE ${widget.newLevel} İLERLEME',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  final currentFraction = _isLevelUp
                                      ? (_progressAnimation.value * endFraction)
                                      : startFraction +
                                          (_progressAnimation.value *
                                              (endFraction - startFraction));
                                  final currentXpVal = (currentFraction * newXpToNext).toInt();
                                  return Text(
                                    '$currentXpVal / $newXpToNext XP',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                final double fillFraction;
                                if (_isLevelUp) {
                                  // Seviye atlandıysa: 0 → yeni seviyedeki ilerleme
                                  fillFraction = _progressAnimation.value * endFraction;
                                } else {
                                  // Normal ilerleme: eski → yeni
                                  fillFraction = startFraction +
                                      (_progressAnimation.value *
                                          (endFraction - startFraction));
                                }
                                return FractionallySizedBox(
                                  widthFactor: fillFraction.clamp(0.0, 1.0),
                                  heightFactor: 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _isLevelUp
                                            ? [AppColors.secondary, const Color(0xFFFFD700)]
                                            : [const Color(0xFF10B981), const Color(0xFF34D399)],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isLevelUp
                                                  ? AppColors.secondary
                                                  : const Color(0xFF10B981))
                                              .withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Devam Et butonu
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isLevelUp ? AppColors.secondary : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: (_isLevelUp ? AppColors.secondary : const Color(0xFF10B981))
                            .withValues(alpha: 0.4),
                      ),
                      child: Text(
                        _isLevelUp ? 'HARİKA!' : 'DEVAM ET',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SEVIYE BADGE WIDGET
// ─────────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final int level;
  final bool highlight;

  const _LevelBadge({required this.level, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final Color color = highlight ? AppColors.secondary : Colors.white24;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: highlight ? color : Colors.white30,
          width: highlight ? 3.0 : 1.5,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            color: highlight ? Colors.white : AppColors.textSecondaryDark,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PARTICLE HELPER CLASSES & PAINTER
// ─────────────────────────────────────────────────────────────────

class _Particle {
  final double dx;
  final double dy;
  final double size;
  final Color color;

  const _Particle({
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      final double curX = center.dx + (p.dx * progress);
      final double curY = center.dy + (p.dy * progress);
      final double opacity = (1.0 - progress).clamp(0.0, 1.0);
      if (opacity <= 0.0) continue;

      paint.color = p.color.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(curX, curY),
        p.size * (1.0 - (progress * 0.4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ─────────────────────────────────────────────────────────────────
// HELPER FUNCTION: Dialog'u göstermek için
// ─────────────────────────────────────────────────────────────────

/// XP ilerleme dialog'unu gösterir. 
/// [onDismissed] dialog kapatıldığında çağrılır (navigasyon için kullanılır).
Future<void> showXpProgressDialog({
  required BuildContext context,
  required int previousLevel,
  required int previousTotalXp,
  required int newLevel,
  required int newTotalXp,
  required int xpGained,
  VoidCallback? onDismissed,
}) async {
  if (xpGained < 0) {
    // XP negatif ise direkt navigasyona geç
    onDismissed?.call();
    return;
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => XpProgressDialog(
      previousLevel: previousLevel,
      previousTotalXp: previousTotalXp,
      newLevel: newLevel,
      newTotalXp: newTotalXp,
      xpGained: xpGained,
    ),
  );

  onDismissed?.call();
}
