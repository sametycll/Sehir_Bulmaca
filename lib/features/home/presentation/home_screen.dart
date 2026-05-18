import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _floatController;
  late final Path _starPath; // Önbelleğe alınmış vektör yıldız yolu

  @override
  void initState() {
    super.initState();
    // Arka plan harita/pusula dönme animasyonu (Son derece yavaş, 60 saniyede bir tur)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // Logo havada asılı durma ve nefes alma animasyonu (4 saniyede bir tur)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // FPS Sorununu Önlemek İçin: Pusula Rüzgar Yıldızı yolunu tam bir kez (1.0 referans yarıçapında)
    // initState içinde çiziyoruz. paint() döngüsünde sıfırdan hesaplanmaz, GPU donanım düzeyinde ölçeklenir!
    _starPath = _buildCompassStarPath();
  }

  Path _buildCompassStarPath() {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final double angle = i * math.pi / 4;
      final double innerAngle = angle + math.pi / 8;
      
      final outerPoint = Offset(math.cos(angle) * 0.8, math.sin(angle) * 0.8);
      final innerPoint = Offset(math.cos(innerAngle) * 0.22, math.sin(innerAngle) * 0.22);
      
      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    path.close();
    return path;
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // FPS Düşüşlerini Engellemek İçin: Arka plan degradeyi normal Flutter Container'ı ile
        // çizerek işletim sisteminin raster katmanında önbelleğe alınmasını (cache) sağlıyoruz.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF070B11), // Derin koyu siyah
              Color(0xFF0F172A), // Modern slate lacivert
            ],
          ),
        ),
        child: Stack(
          children: [
            // 1. Dinamik, Animasyonlu Coğrafi Pusula Arka Planı (Optimize Edilmiş Canvas)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_rotationController, _floatController]),
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CompassBackdropPainter(
                        rotation: _rotationController.value * 2 * math.pi,
                        pulse: math.sin(_floatController.value * 2 * math.pi),
                        starPath: _starPath,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Ana Menü İçerikleri
            SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Floating Logo (Havada asılı duran pusula logosu)
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          final double floatOffset = 10.0 * math.sin(_floatController.value * 2 * math.pi);
                          return Transform.translate(
                            offset: Offset(0, floatOffset),
                            child: Column(
                              children: [
                                // Parlayan Dairesel Logo Kabuğu
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.map_rounded,
                                    size: 72,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Başlıklar
                                const Text(
                                  'TÜRKİYE',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 10,
                                    color: AppColors.textPrimaryDark,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(0, 4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ŞEHİR BULMACA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 4,
                                    color: AppColors.primary.withValues(alpha: 0.85),
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black38,
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const Spacer(),

                      // 3. Premium Butonlar Grubu
                      Column(
                        children: [
                          // Oyuna Başla (Neon Gradientli)
                          PremiumMenuButton(
                            onPressed: () => context.push('/game'),
                            isPrimary: true,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'OYUNA BAŞLA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Liderlik Tablosu (Glassmorphic)
                          PremiumMenuButton(
                            onPressed: () => context.push('/leaderboard'),
                            isPrimary: false,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.emoji_events_outlined, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'LİDERLİK TABLOSU',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nasıl Oynanır? Butonu
                          TextButton(
                            onPressed: () => _showHowToPlayDialog(context),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                            ),
                            child: const Text(
                              'NASIL OYNANIR?',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nasıl Oynanır Cam Efektli Bilgi Paneli Modalı
  void _showHowToPlayDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Nasıl Oynanır',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: const Color(0xFA1F262E), // Şık, opak koyu cam rengi (FPS Kaybını Tamamen Önler!)
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Nasıl Oynanır?',
                        style: TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // İçerik Listesi
                  _buildTutorialStep(
                    '1',
                    'Şehir İsmini Yazın',
                    'Giriş alanına Türkiye\'nin illerinden birini yazıp Enter\'a basın.',
                  ),
                  const SizedBox(height: 14),
                  _buildTutorialStep(
                    '2',
                    'Haritada Keşfedin',
                    'Doğru tahmin ettiğiniz il, haritada anında zümrüt yeşili olarak parlar ve kamera oraya yumuşakça odaklanır.',
                  ),
                  const SizedBox(height: 14),
                  _buildTutorialStep(
                    '3',
                    'Hızlı Olun, Kombo Yapın! 🔥',
                    '4 saniye içinde ardı ardına şehir bulursanız kombo çarpanı başlar ve fazladan puan serisi kazanırsınız.',
                  ),
                  const SizedBox(height: 14),
                  _buildTutorialStep(
                    '4',
                    'Skoru Sırala',
                    'Süre bitmeden veya pes edip oyunu bayrak ikonuyla bitirdiğinizde skorunuzu local liderlik tablosuna kaydedin!',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Kapatma Butonu
                  PremiumMenuButton(
                    onPressed: () => Navigator.of(context).pop(),
                    isPrimary: true,
                    child: const Text(
                      'ANLADIM, BAŞLAYALIM!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secondAnim, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildTutorialStep(String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  color: AppColors.textSecondaryDark.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Lüks Buton Efekti (Dokunulduğunda küçülüp esneyen basma hissi)
class PremiumMenuButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isPrimary;

  const PremiumMenuButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isPrimary = true,
  });

  @override
  State<PremiumMenuButton> createState() => _PremiumMenuButtonState();
}

class _PremiumMenuButtonState extends State<PremiumMenuButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95), // Basıldığında hafif yaylanarak küçülme
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isPrimary
                ? const LinearGradient(
                    colors: [
                      Color(0xFF00ADB5), // Parlak turkuaz
                      Color(0xFF00838A), // Koyu tonu
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isPrimary ? null : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: widget.isPrimary 
                  ? Colors.white.withValues(alpha: 0.15) 
                  : AppColors.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF00ADB5).withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ]
                : null,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

// Matematiksel ve Sanatsal Coğrafi Pusula Arka Plan Çizici (120 FPS Optimize)
class CompassBackdropPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final Path starPath; // Önbelleklenmiş referans yıldız yolu

  // FPS Kaybını engellemek için boyama fırçalarını (Paint) bir kere oluşturup önbellekliliyoruz
  final Paint circlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = AppColors.primary.withValues(alpha: 0.05)
    ..strokeWidth = 1.0;

  final Paint axisPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = AppColors.primary.withValues(alpha: 0.04)
    ..strokeWidth = 1.2;

  final Paint starFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = AppColors.primary.withValues(alpha: 0.015);

  final Paint starBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = AppColors.primary.withValues(alpha: 0.04)
    ..strokeWidth = 0.8;

  CompassBackdropPainter({
    required this.rotation,
    required this.pulse,
    required this.starPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final maxRadius = math.min(size.width, size.height) * 0.42;

    // 1. Eş Merkezli Coğrafi Polar Çemberler (Önbellekli Paint ile son derece hızlı)
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4.0), circlePaint);
    }

    // 2. Dönmekte Olan Pusula Rüzgarları
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Eksen çizgileri (Önbellekli Paint)
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final end = Offset(math.cos(angle) * maxRadius, math.sin(angle) * maxRadius);
      canvas.drawLine(Offset.zero, end, axisPaint);
    }

    // 8 Köşeli Coğrafi Rüzgar Yıldızı (Önbellekli Path'i donanım hızlandırmalı ölçekliyoruz!)
    canvas.scale(maxRadius);
    canvas.drawPath(starPath, starFillPaint);
    canvas.drawPath(starPath, starBorderPaint);

    canvas.restore();

    // 3. Merkezde Parıldayan Dinamik Radial Glow (Atmosferik Işık)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.12 + 0.03 * pulse),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.95));

    canvas.drawCircle(center, maxRadius * 1.1, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CompassBackdropPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.pulse != pulse;
  }
}
