import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../leaderboard/domain/entities/game_mode.dart';
import '../../game/presentation/providers/game_notifier.dart';
import '../../progression/presentation/providers/progression_provider.dart';
import '../../progression/domain/services/level_calculator.dart';
import '../../progression/presentation/widgets/xp_bar_widget.dart';
import '../../daily_system/presentation/providers/daily_notifier.dart';
import '../../daily_system/presentation/widgets/mission_complete_overlay.dart';
import '../../daily_system/domain/entities/daily_mission.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _floatController;
  late final Path _starPath;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _starPath = _buildCompassStarPath();
  }

  Path _buildCompassStarPath() {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final double angle = i * math.pi / 4;
      final double innerAngle = angle + math.pi / 8;
      final outerPoint = Offset(math.cos(angle) * 0.8, math.sin(angle) * 0.8);
      final innerPoint =
          Offset(math.cos(innerAngle) * 0.22, math.sin(innerAngle) * 0.22);
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
    // Tamamlanan günlük görevlerin overlay olarak gösterilmesini dinle
    ref.listen<List<DailyMission>>(completedMissionsQueueProvider, (previous, next) {
      if (next.isNotEmpty) {
        MissionCompleteOverlayService.checkAndShowNext(context, ref);
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF070B11),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 1. Animasyonlu Coğrafi Pusula Arka Planı
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation:
                      Listenable.merge([_rotationController, _floatController]),
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CompassBackdropPainter(
                        rotation: _rotationController.value * 2 * math.pi,
                        pulse:
                            math.sin(_floatController.value * 2 * math.pi),
                        starPath: _starPath,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Premium Profil Chip (Sağ Üst)
            Positioned(
              top: 0,
              right: 16,
              child: SafeArea(
                child: Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authProvider);
                    if (authState.status == AuthStatus.authenticating ||
                        authState.user == null) {
                      return const SizedBox.shrink();
                    }
                    final user = authState.user!;
                    final isGuest = authState.isGuest;
                    final displayName = user.displayName;
                    final photoUrl = user.photoURL;
                    final uid = user.uid;
                    final shortTag = user.shortTag;

                    return GestureDetector(
                      onTap: () => _showProfileDialog(
                          context, ref, displayName, user.email ?? '',
                          photoUrl, isGuest, uid, shortTag),
                      child: _ProfileChip(
                        displayName: displayName,
                        shortTag: shortTag,
                        photoUrl: photoUrl,
                        isGuest: isGuest,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 3. Ana Menü İçerikleri
            SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Floating Logo
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          final double floatOffset =
                              10.0 * math.sin(_floatController.value * 2 * math.pi);
                          return Transform.translate(
                            offset: Offset(0, floatOffset),
                            child: Column(
                              children: [
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

                      // Butonlar
                      Column(
                        children: [
                          PremiumMenuButton(
                            onPressed: () =>
                                _showGameModeSelectionSheet(context, ref),
                            isPrimary: true,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 24),
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

                          PremiumMenuButton(
                            onPressed: () => context.push('/leaderboard'),
                            isPrimary: false,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.emoji_events_outlined,
                                    color: AppColors.primary, size: 20),
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

                          PremiumMenuButton(
                            onPressed: () => context.push('/achievements'),
                            isPrimary: false,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.military_tech_rounded,
                                    color: AppColors.secondary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'BAŞARIMLAR',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          PremiumMenuButton(
                            onPressed: () => context.push('/daily'),
                            isPrimary: false,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wb_sunny_rounded,
                                    color: Colors.amber, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'GÜNLÜK GÖREVLER',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () => _showHowToPlayDialog(context),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  AppColors.textSecondaryDark.withValues(alpha: 0.7),
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

  // ─── Nasıl Oynanır ───
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
              color: const Color(0xFA1F262E),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.help_outline_rounded,
                            color: AppColors.primary, size: 24),
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
                  _buildTutorialStep('1', 'Şehir İsmini Yazın',
                      'Giriş alanına Türkiye\'nin illerinden birini yazıp Enter\'a basın.'),
                  const SizedBox(height: 14),
                  _buildTutorialStep('2', 'Haritada Keşfedin',
                      'Doğru tahmin ettiğiniz il, haritada anında zümrüt yeşili olarak parlar.'),
                  const SizedBox(height: 14),
                  _buildTutorialStep('3', 'Hızlı Olun, Kombo Yapın! 🔥',
                      '4 saniye içinde ardı ardına şehir bulursanız kombo çarpanı başlar.'),
                  const SizedBox(height: 14),
                  _buildTutorialStep('4', 'Skoru Sırala',
                      'Oyunu bitirdiğinizde skorunuzu liderlik tablosuna kaydedin!'),
                  const SizedBox(height: 24),
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

  // ─── Profil Dialog ───
  void _showProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String name,
    String email,
    String? photoUrl,
    bool isGuest,
    String uid,
    String shortTag,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2130),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isGuest
                              ? [
                                  const Color(0xFF6C757D),
                                  const Color(0xFF495057),
                                ]
                              : [
                                  AppColors.primary,
                                  const Color(0xFF007A80),
                                ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Icon(
                                isGuest
                                    ? Icons.person_outline_rounded
                                    : Icons.person_rounded,
                                size: 42,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isGuest
                            ? const Color(0xFF4A5568)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF1A2130), width: 2),
                      ),
                      child: Text(
                        isGuest ? 'Misafir' : 'Google',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // İsim
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (shortTag.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        '#$shortTag',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isGuest ? 'Misafir Hesap' : email,
                  style: TextStyle(
                    color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // Seviye ve XP İlerlemesi
                Consumer(
                  builder: (context, ref, child) {
                    final progressAsync = ref.watch(progressionProvider);
                    return progressAsync.when(
                      data: (progress) {
                        final title = LevelCalculator.getTitle(progress.level);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.secondary.withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.workspace_premium_rounded,
                                        color: AppColors.secondary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'SEVİYE ${progress.level}',
                                        style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: AppColors.textPrimaryDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            XpBarWidget(
                              currentXp: progress.currentXp,
                              xpToNextLevel: progress.xpToNextLevel,
                              height: 8,
                              showText: true,
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Toplam: ${progress.totalXp} XP',
                                style: TextStyle(
                                  color: AppColors.textSecondaryDark.withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            PremiumMenuButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.push('/progression');
                              },
                              isPrimary: false,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.query_stats_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'DETAYLI İLERLEME',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      error: (err, stack) => const SizedBox.shrink(),
                    );
                  },
                ),

                // Kullanıcı ID Kartı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KULLANICI ID',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              uid,
                              style: TextStyle(
                                color: AppColors.primary.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: uid));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Kullanıcı ID kopyalandı!'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.copy_rounded,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Divider(
                    color: Colors.white.withValues(alpha: 0.08), height: 1),
                const SizedBox(height: 16),

                // Çıkış Butonu
                GestureDetector(
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ref.read(authProvider.notifier).signOut();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'OTURUMU KAPAT',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Oyun Modu Seçimi ───
  void _showGameModeSelectionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'OYUN MODUNU SEÇİN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Şehirleri nasıl bulmak istersiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Mod listesi - scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Klasik Modlar ──
                      _SectionLabel(label: '⚔️  KLASİK MODLAR'),
                      const SizedBox(height: 10),
                      _buildModeTile(context, ref,
                          mode: GameMode.allTurkey,
                          icon: Icons.map_outlined,
                          color: AppColors.primary),
                      const SizedBox(height: 10),
                      _buildModeTile(context, ref,
                          mode: GameMode.timeAttack,
                          icon: Icons.flash_on_rounded,
                          color: Colors.amber),
                      const SizedBox(height: 10),
                      _buildModeTile(context, ref,
                          mode: GameMode.blitzChallenge,
                          icon: Icons.timer_outlined,
                          color: Colors.redAccent),

                      const SizedBox(height: 20),

                      // ── Bölgesel Modlar ──
                      _SectionLabel(label: '🗺️  BÖLGESEL MODLAR'),
                      const SizedBox(height: 10),
                      _buildModeTile(context, ref,
                          mode: GameMode.marmara,
                          icon: Icons.water_rounded,
                          color: const Color(0xFF4FC3F7)),
                      const SizedBox(height: 10),
                      _buildModeTile(context, ref,
                          mode: GameMode.ege,
                          icon: Icons.beach_access_rounded,
                          color: const Color(0xFF26C6DA)),
                      const SizedBox(height: 10),
                      _buildModeTile(context, ref,
                          mode: GameMode.akdeniz,
                          icon: Icons.wb_sunny_rounded,
                          color: const Color(0xFFFF8A65)),
                      const SizedBox(height: 10),
                      _buildModeTile(context, ref,
                          mode: GameMode.icAnadolu,
                          icon: Icons.landscape_rounded,
                          color: const Color(0xFFA5D6A7)),
                      const SizedBox(height: 10),
                      _buildModeTile(context, ref,
                          mode: GameMode.karadeniz,
                          icon: Icons.forest_rounded,
                          color: const Color(0xFF80CBC4)),
                      const SizedBox(height: 10),
                      _buildModeTile(context, ref,
                          mode: GameMode.doguAnadolu,
                          icon: Icons.terrain_rounded,
                          color: const Color(0xFFCE93D8)),
                      const SizedBox(height: 10),
                      _buildModeTile(context, ref,
                          mode: GameMode.guneydoguAnadolu,
                          icon: Icons.filter_drama_rounded,
                          color: const Color(0xFFFFCC02)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeTile(
    BuildContext context,
    WidgetRef ref, {
    required GameMode mode,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        ref.read(playGameModeProvider.notifier).state = mode;
        Navigator.of(context).pop();
        context.push('/game');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.title,
                    style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mode.subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondaryDark.withValues(alpha: 0.65),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.25), size: 13),
          ],
        ),
      ),
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
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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

// ─── Premium Profil Chip ───
class _ProfileChip extends StatefulWidget {
  final String displayName;
  final String? shortTag;
  final String? photoUrl;
  final bool isGuest;

  const _ProfileChip({
    required this.displayName,
    this.shortTag,
    this.photoUrl,
    required this.isGuest,
  });

  @override
  State<_ProfileChip> createState() => _ProfileChipState();
}

class _ProfileChipState extends State<_ProfileChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color chipColor =
        widget.isGuest ? const Color(0xFF6C757D) : AppColors.primary;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final glowOpacity = 0.08 + 0.07 * _pulseAnim.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: widget.isGuest
                  ? [
                      const Color(0xFF4A5568).withValues(alpha: 0.25),
                      const Color(0xFF2D3748).withValues(alpha: 0.25),
                    ]
                  : [
                      AppColors.primary.withValues(alpha: 0.15),
                      const Color(0xFF007A80).withValues(alpha: 0.1),
                    ],
            ),
            border: Border.all(
              color: chipColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: chipColor.withValues(alpha: glowOpacity),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        chipColor,
                        chipColor.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: chipColor.withValues(alpha: 0.15),
                    backgroundImage: widget.photoUrl != null
                        ? NetworkImage(widget.photoUrl!)
                        : null,
                    child: widget.photoUrl == null
                        ? Icon(
                            widget.isGuest
                                ? Icons.person_outline_rounded
                                : Icons.person_rounded,
                            size: 15,
                            color: chipColor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.shortTag != null && widget.shortTag!.isNotEmpty) ...[
                          const SizedBox(width: 3),
                          Text(
                            '#${widget.shortTag}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      widget.isGuest ? 'Misafir' : 'Google',
                      style: TextStyle(
                        color: chipColor.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Bölüm Başlığı ───
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondaryDark.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

// ─── Premium Buton ───
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
      onTapDown: (_) => setState(() => _scale = 0.95),
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
                      Color(0xFF00ADB5),
                      Color(0xFF00838A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isPrimary
                ? null
                : Colors.white.withValues(alpha: 0.04),
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

// ─── Pusula Arka Plan Çizici ───
class CompassBackdropPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final Path starPath;

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

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4.0), circlePaint);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final end = Offset(
          math.cos(angle) * maxRadius, math.sin(angle) * maxRadius);
      canvas.drawLine(Offset.zero, end, axisPaint);
    }

    canvas.scale(maxRadius);
    canvas.drawPath(starPath, starFillPaint);
    canvas.drawPath(starPath, starBorderPaint);
    canvas.restore();

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.12 + 0.03 * pulse),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(
          Rect.fromCircle(center: center, radius: maxRadius * 0.95));

    canvas.drawCircle(center, maxRadius * 1.1, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CompassBackdropPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.pulse != pulse;
  }
}
