import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../game/infrastructure/services/audio_service.dart';
import '../providers/level_up_queue_provider.dart';

/// Seviye atlandığında tüm ekranı kaplayan, neon parlamalı ve patlama
/// (particle burst) efektli premium seviye atlama penceresi.
class LevelUpOverlayWidget extends StatefulWidget {
  final LevelUpDetails details;
  final VoidCallback onFinished;

  const LevelUpOverlayWidget({
    super.key,
    required this.details,
    required this.onFinished,
  });

  @override
  State<LevelUpOverlayWidget> createState() => _LevelUpOverlayWidgetState();
}

class _LevelUpOverlayWidgetState extends State<LevelUpOverlayWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _progressBarAnimation;
  late final AnimationController _particleController;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    
    // Giriş kart animasyon yöneticisi
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Uzun süreli daha akıcı doldurma için 1200ms yaptık
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _progressBarAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    );

    // Particle patlama animasyon yöneticisi
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Rastgele patlayacak partikülleri üret
    _generateParticles();

    // Animasyonları başlat
    _controller.forward();
    _particleController.forward();

    // Haptic feedback (titreşim) tetikle
    _triggerHaptics();

    // Seviye atlama sesini oynat
    AudioService.playSuccess();
  }

  void _generateParticles() {
    final random = math.Random();
    _particles = List.generate(40, (_) {
      final double angle = random.nextDouble() * 2 * math.pi;
      // Dışarı doğru hız/mesafe katsayısı
      final double velocity = 150.0 + random.nextDouble() * 200.0;
      final double size = 4.0 + random.nextDouble() * 8.0;
      
      // Neon renk seçenekleri: Turuncu, Sarı, Turkuaz, Pembe
      final colors = [
        AppColors.secondary,
        const Color(0xFFFFD700), // Altın sarısı
        AppColors.primary,
        const Color(0xFFFF1493), // Neon pembe
      ];
      final color = colors[random.nextInt(colors.length)];

      return _Particle(
        dx: math.cos(angle) * velocity,
        dy: math.sin(angle) * velocity,
        size: size,
        color: color,
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
    _controller.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Arka Planı Bulanıklaştır (BackdropFilter)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),

          // 2. Partikül Patlaması (Burayı arka plana yerleştiriyoruz)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              );
            },
          ),

          // 3. Seviye Atlama Ana Kartı
          ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1524),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.2),
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
                      // Üst Taç / Yıldız İkonu
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.secondary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tebrikler Metni
                      Text(
                        'SEVİYE ATLADIN!',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                          shadows: [
                            Shadow(
                              color: AppColors.secondary.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Büyük Seviye Gösterimi (Örn: 4 -> 5)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LevelBadge(level: widget.details.fromLevel),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white60,
                              size: 28,
                            ),
                          ),
                          _LevelBadge(level: widget.details.toLevel, highlight: true),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Kazanılan Unvan
                      Text(
                        'KAZANILAN UNVAN',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.details.titleGained,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // XP Bar Dolum Animasyonu
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'SEVİYE TAMAMLANDI',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _progressBarAnimation,
                                  builder: (context, child) {
                                    final percentage = (_progressBarAnimation.value * 100).toInt();
                                    return Text(
                                      '%$percentage',
                                      style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                // Arka plan
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                // Doldurulan bar
                                AnimatedBuilder(
                                  animation: _progressBarAnimation,
                                  builder: (context, child) {
                                    return FractionallySizedBox(
                                      widthFactor: _progressBarAnimation.value,
                                      child: Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppColors.secondary,
                                              Color(0xFFFFD700), // Gold transition
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.secondary.withValues(alpha: 0.5),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Tamam Butonu
                      ElevatedButton(
                        onPressed: () {
                          // Kapatma sesi veya haptic eklenebilir
                          HapticFeedback.lightImpact();
                          widget.onFinished();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.secondary.withValues(alpha: 0.4),
                        ),
                        child: const Text(
                          'HARİKA!',
                          style: TextStyle(
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
          ),
        ],
      ),
    );
  }
}

/// Seviye dairesini gösteren küçük widget.
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
        color: highlight ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
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
      // Zamanla dışarı doğru kayan pozisyon
      final double curX = center.dx + (p.dx * progress);
      final double curY = center.dy + (p.dy * progress);
      
      // Sönümlenerek yok olma saydamlığı (Interval ile sonda hızlı sönme)
      final double opacity = (1.0 - progress).clamp(0.0, 1.0);
      
      if (opacity <= 0.0) continue;

      paint.color = p.color.withValues(alpha: opacity);
      
      // Dairesel partikül çiz
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
// ENTRY POINT FUNCTION FOR OVERLAY
// ─────────────────────────────────────────────────────────────────

/// Seviye atlama popup'ını ekrana basan yardımcı global fonksiyon.
OverlayEntry createLevelUpOverlayEntry({
  required LevelUpDetails details,
  required VoidCallback onFinished,
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => LevelUpOverlayWidget(
      details: details,
      onFinished: () {
        entry.remove();
        onFinished();
      },
    ),
  );
  return entry;
}
