import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_colors.dart';
import 'auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Backdrop rotation animation (ultra slow)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 80),
    )..repeat();

    // Fade-in animation for UI contents
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show error snackbar if error state occurs
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF06090E), // Derin uzay siyahı
              Color(0xFF0F172A), // Slate lacivert
            ],
          ),
        ),
        child: Stack(
          children: [
            // 1. Slow Rotating Compass backdrop
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: LoginBackdropPainter(
                      rotation: _rotationController.value * 2 * math.pi,
                    ),
                  );
                },
              ),
            ),

            // 2. Main Login Card
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Logo Icon
                          Container(
                            padding: const EdgeInsets.all(20),
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
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.explore_rounded,
                              size: 56,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Heading
                          const Text(
                            'TÜRKİYE',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          const Text(
                            'ŞEHİR BULMACA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Keşfetmeye başlamak için oturum açın.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 36),

                          if (authState.status == AuthStatus.authenticating) ...[
                            const Center(
                              child: Column(
                                children: [
                                  SpinKitDoubleBounce(
                                    color: AppColors.primary,
                                    size: 50.0,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Giriş Yapılıyor, Lütfen Bekleyin...',
                                    style: TextStyle(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Neon Guest Login Button
                            _buildLoginButton(
                              onPressed: () =>
                                  ref.read(authProvider.notifier).signInAsGuest(),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00ADB5),
                                  Color(0xFF00838A),
                                ],
                              ),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15)),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_outline_rounded,
                                      color: Colors.white, size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    'Anonim Giriş (Misafir Olarak Oyna)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Google Login Button
                            _buildLoginButton(
                              onPressed: () =>
                                  ref.read(authProvider.notifier).signInWithGoogle(),
                              color: Colors.white,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                                    height: 20,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.g_mobiledata_rounded,
                                            color: Colors.black, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Google ile Giriş Yap',
                                    style: TextStyle(
                                      color: Color(0xFF1F262E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                          // Information text
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.04),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Anonim Giriş seçeneğinde, bu telefona özel kalıcı bir kimlik oluşturulur. Uygulama silinse dahi skorlarınız korunur.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondaryDark
                                          .withValues(alpha: 0.7),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildLoginButton({
    required VoidCallback onPressed,
    Gradient? gradient,
    Color? color,
    BoxBorder? border,
    required Widget child,
  }) {
    double scale = 1.0;
    return StatefulBuilder(builder: (context, setBtnState) {
      return GestureDetector(
        onTapDown: (_) => setBtnState(() => scale = 0.96),
        onTapCancel: () => setBtnState(() => scale = 1.0),
        onTapUp: (_) {
          setBtnState(() => scale = 1.0);
          onPressed();
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: gradient,
              color: color,
              border: border,
              boxShadow: gradient != null
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00ADB5).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
            ),
            child: Center(child: child),
          ),
        ),
      );
    });
  }
}

class LoginBackdropPainter extends CustomPainter {
  final double rotation;

  final Paint circlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = AppColors.primary.withValues(alpha: 0.035)
    ..strokeWidth = 1.0;

  final Paint linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = AppColors.primary.withValues(alpha: 0.02)
    ..strokeWidth = 1.0;

  LoginBackdropPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxRadius = math.min(size.width, size.height) * 0.5;

    // Outer polar grid
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, maxRadius * (i / 5.0), circlePaint);
    }

    // Compass dial rotation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final start = Offset(math.cos(angle) * (maxRadius * 0.2),
          math.sin(angle) * (maxRadius * 0.2));
      final end =
          Offset(math.cos(angle) * maxRadius, math.sin(angle) * maxRadius);
      canvas.drawLine(start, end, linePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LoginBackdropPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}
