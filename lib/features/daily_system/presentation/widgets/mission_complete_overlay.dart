import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_mission.dart';
import '../providers/daily_notifier.dart';
import '../../../game/infrastructure/services/audio_service.dart';

/// Görev tamamlandığında ekranın üzerinde beliren konfeti animasyonlu overlay (pop-up) servisi.
class MissionCompleteOverlayService {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// Sıradaki tamamlanmış görevi kuyruktan çekip gösterir.
  static void checkAndShowNext(BuildContext context, WidgetRef ref) {
    if (_isShowing) return;

    final queueNotifier = ref.read(completedMissionsQueueProvider.notifier);
    final completedMissions = ref.read(completedMissionsQueueProvider);

    if (completedMissions.isEmpty) return;

    final mission = queueNotifier.dequeue();
    if (mission != null) {
      _showOverlay(context, ref, mission);
    }
  }

  static void _showOverlay(BuildContext context, WidgetRef ref, DailyMission mission) {
    _isShowing = true;
    final overlayState = Overlay.of(context);

    // Başarı sesi çal
    AudioService.playCorrect();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _MissionCompleteWidget(
          mission: mission,
          onDismiss: () {
            _dismiss();
            // Bir sonraki görevi kontrol et (kuyrukta bekleyen varsa sırayla göster)
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                checkAndShowNext(context, ref);
              }
            });
          },
        );
      },
    );

    overlayState.insert(_overlayEntry!);
  }

  static void _dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }
}

class _MissionCompleteWidget extends StatefulWidget {
  final DailyMission mission;
  final VoidCallback onDismiss;

  const _MissionCompleteWidget({
    required this.mission,
    required this.onDismiss,
  });

  @override
  State<_MissionCompleteWidget> createState() => _MissionCompleteWidgetState();
}

class _MissionCompleteWidgetState extends State<_MissionCompleteWidget>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Konfeti animasyon controller
  late AnimationController _confettiController;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Kart animasyonu
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeIn,
    );

    // Konfeti animasyonu
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        _updateParticles();
      });

    // Konfeti parçacıklarını oluştur
    for (int i = 0; i < 80; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble() * 400, // Ekran genişliği varsayımı
        y: -_random.nextDouble() * 200,
        color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        size: _random.nextDouble() * 8 + 6,
        speedX: (_random.nextDouble() - 0.5) * 4,
        speedY: _random.nextDouble() * 5 + 3,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      ));
    }

    _cardController.forward();
    _confettiController.forward();

    // 4 saniye sonra otomatik kapanma (kullanıcı kapatmazsa)
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _close();
      }
    });
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      final size = MediaQuery.of(context).size;
      for (final p in _particles) {
        p.x = (p.x + p.speedX).clamp(0.0, size.width);
        p.y += p.speedY;
        p.rotation += p.rotationSpeed;
        
        // Ekrandan çıkınca yukarıda yeniden konumlandır (döngüsel konfeti efekti)
        if (p.y > size.height) {
          p.y = -20;
          p.x = _random.nextDouble() * size.width;
        }
      }
    });
  }

  void _close() {
    _cardController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Nadirliğe göre renk belirleme
    Color tierColor = Colors.green;
    switch (widget.mission.tier) {
      case MissionTier.easy:
        tierColor = Colors.greenAccent;
        break;
      case MissionTier.medium:
        tierColor = Colors.blueAccent;
        break;
      case MissionTier.hard:
        tierColor = Colors.orangeAccent;
        break;
      case MissionTier.legendary:
        tierColor = Colors.purpleAccent;
        break;
    }

    return Material(
      color: Colors.black54, // Yarı saydam arka plan
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Konfeti Çizimi (IgnorePointer ile sarmalanarak dokunma olaylarını engeller)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(particles: _particles),
                ),
              ),
            ),
  
            // Merkezdeki Görev Tamamlama Kartı
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: size.width * 0.85,
                    constraints: const BoxConstraints(maxHeight: 380),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E1E38), // Koyu arka plan
                          const Color(0xFF151528).withOpacity(0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: tierColor.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Başarı Tacı İkonu
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: tierColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: tierColor,
                            size: 52,
                          ),
                        ),
                        const SizedBox(height: 16),
  
                        const Text(
                          'GÖREV TAMAMLANDI!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
  
                        // Görev Başlığı
                        Text(
                          widget.mission.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
  
                        // Görev Açıklaması
                        Text(
                          widget.mission.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
  
                        // Ödül Bölümü
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '+${widget.mission.xpReward} XP',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
  
                        // Kapatma / Devam Et Butonu
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _close,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tierColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'HARİKA!',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
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
      ),
    );
  }
}

/// Konfeti parçacığı modeli.
class _ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double speedX;
  final double speedY;
  double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// Konfetiyi ekrana çizdiren CustomPainter.
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      paint.color = p.color;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation * pi / 180);

      // Farklı şekillerde konfeti çizebiliriz (kare, dikdörtgen, daire)
      if (p.size % 2 == 0) {
        // Dikdörtgen konfeti
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      } else {
        // Daire konfeti
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
