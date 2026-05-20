import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../data/sources/city_data.dart';
import '../../domain/entities/city_entity.dart';
import '../../infrastructure/data_sources/region_data.dart';
import '../providers/game_notifier.dart';
import '../providers/game_state.dart';
import 'package:sehir_bulmaca/features/leaderboard/presentation/providers/leaderboard_provider.dart';
import 'package:sehir_bulmaca/features/leaderboard/domain/entities/game_mode.dart';
import 'package:sehir_bulmaca/features/auth/presentation/auth_notifier.dart';
import '../widgets/game_input_field.dart';
import '../widgets/turkiye_map_widget.dart';



class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startNewGame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mode = ref.read(playGameModeProvider);

      // Bölgesel mod ise sadece o bölgenin il plaka kodlarını kullan
      List<Map<String, dynamic>> rawList = CityRawData.cities;
      if (mode.isRegional) {
        final regionPlates = RegionData.platesForMode(mode.id);
        if (regionPlates != null && regionPlates.isNotEmpty) {
          rawList = CityRawData.cities
              .where((c) => regionPlates.contains(c['plateCode'] as int))
              .toList();
        }
      }

      final normalizedCities = rawList.map((c) => CityEntity(
        id: c['id'] as String,
        name: c['name'] as String,
        normalizedName: (c['name'] as String).normalizeCityName,
        plateCode: c['plateCode'] as int,
      )).toList();

      ref.read(gameProvider.notifier).initGame(normalizedCities, mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Oyun bittiğinde tetiklenecek olan dinleyici
    ref.listen<GameState>(gameProvider, (previous, next) {
      if (next.isFinished && !(previous?.isFinished ?? false)) {
        _showGameOverDialog(context, next);
      }
    });

    // Doğru tahmin yapıldığında ve kombo olduğunda premium Overlay bildirimlerini tetikler
    ref.listen<int>(gameProvider.select((s) => s.foundCities.length), (previous, next) {
      final current = ref.read(gameProvider);
      if (next > (previous ?? 0)) {
        final cityName = current.lastFoundCityName;
        final combo = current.comboCount;
        if (cityName.isNotEmpty) {
          _showFloatingNotification(context, cityName, combo);
        }
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmation(context);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('ŞEHİR BUL'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryDark),
            tooltip: 'Geri Dön',
            onPressed: () => _showExitConfirmation(context),
          ),
          actions: [
            if (gameState.isRunning && !gameState.isFinished)
              IconButton(
                icon: const Icon(Icons.flag_rounded, color: AppColors.error, size: 28),
                tooltip: 'Oyunu Bitir',
                onPressed: () => _showFinishConfirmation(context),
              ),
            const SizedBox(width: 12),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF020617),
              ],
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  _buildStatPanel(context, gameState, isKeyboardOpen),
                  
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: isKeyboardOpen ? 2.0 : 8.0,
                      ),
                      child: const TurkiyeMapWidget(),
                    ),
                  ),
                  
                  const GameInputField(),
                ],
              ),
              if (gameState.gameMode == GameMode.timeAttack || gameState.gameMode == GameMode.blitzChallenge)
                if (gameState.remainingTime <= 10 && gameState.isRunning && !gameState.isFinished)
                  const Positioned.fill(
                    child: PulsingNeonBorder(),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPanel(BuildContext context, GameState gameState, bool isKeyboardOpen) {
    final String formattedTime;
    final bool isTimed = gameState.gameMode == GameMode.timeAttack || gameState.gameMode == GameMode.blitzChallenge;
    
    if (isTimed) {
      formattedTime = '${gameState.remainingTime} sn';
    } else {
      final minutes = (gameState.elapsedTime / 60).floor();
      final remainingSeconds = gameState.elapsedTime % 60;
      formattedTime = '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    // Süreli modlarda kalan 10 saniyede zaman göstergesini kırmızı renkte göster
    final timeColor = (isTimed && gameState.remainingTime <= 10) ? AppColors.error : AppColors.secondary;

    if (isKeyboardOpen) {
      // Klavye açıkken dikey yer kazanmak için tek satırlık aşırı minimal tasarım
      return Container(
        margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCompactStat('BULUNAN', '${gameState.foundCities.length}', const Color(0xFF10B981)),
            _buildCompactStat(isTimed ? 'KALAN SÜRE' : 'SÜRE', formattedTime, timeColor, isMonospace: true),
            _buildCompactStat('KALAN İL', '${gameState.remainingCount}', AppColors.textSecondaryDark),
          ],
        ),
      );
    }

    // Normal (Klavye kapalıyken) Premium Tasarım
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('BULUNAN', '${gameState.foundCities.length}', const Color(0xFF10B981)),
              _buildStatItem(isTimed ? 'KALAN SÜRE' : 'SÜRE', formattedTime, timeColor, isMonospace: true),
              _buildStatItem('KALAN İL', '${gameState.remainingCount}', AppColors.textSecondaryDark),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: gameState.progress,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: const Color(0xFF10B981), // Emerald green progress
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String value, Color color, {bool isMonospace = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: AppColors.textSecondaryDark,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: isMonospace ? 'monospace' : null,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, {bool isMonospace = false}) {
    return Column(
      children: [
        Text(
          label, 
          style: const TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5, 
            color: AppColors.textSecondaryDark
          )
        ),
        const SizedBox(height: 6),
        Text(
          value, 
          style: TextStyle(
            fontSize: 28, 
            fontWeight: FontWeight.w900, 
            fontFamily: isMonospace ? 'monospace' : null,
            color: color
          )
        ),
      ],
    );
  }

  void _showFloatingNotification(BuildContext context, String cityName, int combo) {
    final overlayState = Overlay.of(context);
    final double cityOffsetX = combo >= 2 ? -65.0 : 0.0;
    
    // 1. Şehir ismi bildirimi
    late OverlayEntry cityEntry;
    cityEntry = OverlayEntry(
      builder: (context) => FloatingNotificationWidget(
        text: '+$cityName',
        color: const Color(0xFF10B981),
        offsetX: cityOffsetX,
        offsetY: 0.0,
        onFinished: () {
          cityEntry.remove();
        },
      ),
    );
    
    // 2. Combo bildirimi
    OverlayEntry? comboEntry;
    if (combo >= 2) {
      comboEntry = OverlayEntry(
        builder: (context) => FloatingNotificationWidget(
          text: 'KOMBO x$combo 🔥',
          color: const Color(0xFFFF8C00),
          offsetX: 65.0,
          offsetY: -15.0, // Hafifçe yukarıda
          isCombo: true,
          onFinished: () {
            comboEntry?.remove();
          },
        ),
      );
    }

    // Bir sonraki karede ekrana ekle ki hata oluşmasın
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlayState.insert(cityEntry);
      if (comboEntry != null) {
        overlayState.insert(comboEntry);
      }
    });
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Oyundan Çık'),
          content: const Text('Mevcut oyun ilerlemeniz kaybolacaktır. Çıkmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              child: const Text('VAZGEÇ', style: TextStyle(color: AppColors.textSecondaryDark)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('ÇIK', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/');
              },
            ),
          ],
        );
      },
    );
  }

  void _showFinishConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Row(
            children: [
              Icon(Icons.flag_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Oyunu Sonlandır'),
            ],
          ),
          content: const Text(
            'Oyunu bitirmek istediğinize emin misiniz? Bulamadığınız tüm şehirler yanlış sayılacaktır.',
            style: TextStyle(color: AppColors.textPrimaryDark),
          ),
          actions: [
            TextButton(
              child: const Text('VAZGEÇ', style: TextStyle(color: AppColors.textSecondaryDark)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('OYUNU BİTİR', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(gameProvider.notifier).manualFinishGame();
              },
            ),
          ],
        );
      },
    );
  }

  void _showGameOverDialog(BuildContext context, GameState finalState) {
    final authState = ref.read(authProvider);
    final initialName = authState.user?.displayName ?? '';
    final nameController = TextEditingController(text: initialName);
    
    final int score = finalState.foundCities.length;
    final int elapsedTime = finalState.elapsedTime;
    final int maxScore = finalState.gameMode.maxScore;
    final bool allFound = score == maxScore;
    bool isSaving = false;

    // Süre biçimlendirme
    final String formattedTime;
    if (finalState.gameMode == GameMode.timeAttack || finalState.gameMode == GameMode.blitzChallenge) {
      formattedTime = '$elapsedTime sn';
    } else {
      final minutes = (elapsedTime / 60).floor();
      final remainingSeconds = elapsedTime % 60;
      formattedTime = '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final name = nameController.text.trim();
            final bool isButtonEnabled = name.isNotEmpty;

            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: allFound 
                      ? const Color(0xFF10B981).withValues(alpha: 0.3) 
                      : AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              title: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (allFound ? const Color(0xFF10B981) : AppColors.primary).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        allFound ? Icons.emoji_events_rounded : Icons.sports_score_rounded,
                        color: allFound ? const Color(0xFF10B981) : AppColors.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      allFound ? 'Tebrikler!' : 'Oyun Bitti!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: allFound ? const Color(0xFF10B981) : AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      allFound 
                          ? 'Mükemmel! ${finalState.gameMode.title} kapsamındaki tüm şehirleri başarıyla buldunuz!'
                          : 'Oyunu tamamladınız! Performansınız oldukça başarılı.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    
                    // İstatistik Kartları
                    Row(
                      children: [
                        Expanded(
                          child: _buildResultCard(
                            'DOĞRU ŞEHİR',
                            '$score / $maxScore',
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildResultCard(
                            finalState.gameMode == GameMode.timeAttack || finalState.gameMode == GameMode.blitzChallenge
                                ? 'TOPLAM SÜRE'
                                : 'GEÇEN SÜRE',
                            formattedTime,
                            AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // İsim Giriş Alanı
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Liderlik Tablosuna Kaydolun:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      onChanged: (val) => setState(() {}),
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Adınızı yazın...',
                        hintStyle: TextStyle(color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsOverflowButtonSpacing: 8,
              actions: [
                ElevatedButton(
                  onPressed: (isButtonEnabled && !isSaving)
                      ? () async {
                          setState(() {
                            isSaving = true;
                          });
                          
                          try {
                            // Misafir ismi güncelleniyor
                            if (authState.isGuest) {
                              await ref.read(authProvider.notifier).updateGuestNickname(name);
                            }

                            // Doğru mod ile skoru kaydet
                            await ref.read(leaderboardNotifierProvider.notifier).submitScore(
                              name: name,
                              mode: finalState.gameMode,
                              score: score,
                              elapsedTime: elapsedTime,
                            );

                            final submitState = ref.read(leaderboardNotifierProvider);
                            if (submitState.hasError) {
                              throw submitState.error ?? Exception('Bilinmeyen bir hata oluştu.');
                            }

                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close dialog
                              context.go('/leaderboard'); // Go to leaderboard
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() {
                                isSaving = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $e'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 8),
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    disabledBackgroundColor: AppColors.surfaceDark.withValues(alpha: 0.5),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('SKORU KAYDET VE SIRALAMAYI GÖR'),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startNewGame();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('TEKRAR OYNA'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('ANA SAYFA'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildResultCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondaryDark,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Son 10 Saniyede Ekran Çerçevesinde Pulsing Neon Kırmızı Çizgi Çizen Animasyonlu Widget
class PulsingNeonBorder extends StatefulWidget {
  const PulsingNeonBorder({super.key});

  @override
  State<PulsingNeonBorder> createState() => _PulsingNeonBorderState();
}

class _PulsingNeonBorderState extends State<PulsingNeonBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _glowAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.35 + (_glowAnimation.value * 0.65)),
                width: 3.0 + (_glowAnimation.value * 3.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.25 + (_glowAnimation.value * 0.5)),
                  blurRadius: 15.0 + (_glowAnimation.value * 15.0),
                  spreadRadius: 1.0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tamamen Bağımsız, Donmayan ve Sönümlenen Vektör Animasyonlu Bildirim Widget'ı
/// Standart Flutter Overlay sistemi sayesinde hizalama ve clipping sınırlarına takılmaz!
class FloatingNotificationWidget extends StatefulWidget {
  final String text;
  final Color color;
  final double offsetX;
  final double offsetY;
  final bool isCombo;
  final VoidCallback onFinished;

  const FloatingNotificationWidget({
    super.key,
    required this.text,
    required this.color,
    required this.offsetX,
    required this.offsetY,
    this.isCombo = false,
    required this.onFinished,
  });

  @override
  State<FloatingNotificationWidget> createState() => _FloatingNotificationWidgetState();
}

class _FloatingNotificationWidgetState extends State<FloatingNotificationWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _yAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Dikey süzülüş ivmesi (EaseOut sayesinde başta hızlı sonra sönümlü yavaş)
    _yAnimation = Tween<double>(begin: 0.0, end: -150.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Saydamlık eğrisi (Girişte hızlı belirir, ortada sabit kalır, sonda erir)
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    // Pulse/Büyüme animasyon eğrisi (Girişte tatlı bir pop yapar)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60),
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
    final size = MediaQuery.of(context).size;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    
    // Klavye durumuna göre dikey konum hesaplama
    final double baseHeight = isKeyboardOpen ? size.height * 0.35 : size.height * 0.65;
    final double xPos = size.width / 2 + widget.offsetX;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: xPos - 150,
          top: baseHeight + widget.offsetY + _yAnimation.value,
          width: 300,
          child: IgnorePointer(
            child: Material(
              type: MaterialType.transparency,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: widget.color.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: widget.isCombo ? 24 : 20,
                          fontWeight: FontWeight.w900,
                          color: widget.color,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              offset: const Offset(0.0, 2.0),
                              blurRadius: 4.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
