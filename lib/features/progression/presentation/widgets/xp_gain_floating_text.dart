import 'package:flutter/material.dart';
import '../../../../core/routing/app_router.dart';
import '../providers/progression_provider.dart';

/// Ekranın ortasından yukarı süzülen, donmayan ve sönümlenen XP kazanım bildirim widget'ı.
/// Klavye clipping'i (klavyenin yazıyı kapatması) sorununu otomatik algılar ve yukarı kaydırır.
class XpGainFloatingText extends StatefulWidget {
  final String text;
  final Color color;
  final double offsetX;
  final double offsetY;
  final VoidCallback onFinished;

  const XpGainFloatingText({
    super.key,
    required this.text,
    required this.color,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    required this.onFinished,
  });

  @override
  State<XpGainFloatingText> createState() => _XpGainFloatingTextState();
}

class _XpGainFloatingTextState extends State<XpGainFloatingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _yAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Yukarı süzülüş ivmesi (easeOutCubic)
    _yAnimation = Tween<double>(begin: 0.0, end: -180.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Saydamlık eğrisi
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(_controller);

    // Tatlı bir büyüme/pop animasyonu
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 1.25), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 65),
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
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Klavye açıksa yazıyı yukarı kaydırıp clipping'i önle
    final double baseHeight = isKeyboardOpen ? size.height * 0.32 : size.height * 0.58;
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFA0B0F19), // Koyu premium cam arka planı
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: widget.color.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                          const BoxShadow(
                            color: Colors.black38,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        widget.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: widget.color,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
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

/// [XpFloatingOverlayService] implementasyonu.
/// Notifier veya servislerden doğrudan tetiklenerek en üst katmanda uçan yazı gösterir.
class XpFloatingOverlayServiceImpl {
  static void registerService() {
    XpFloatingOverlayService.register((xp, isBonus) {
      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context == null) return;

      final overlayState = Overlay.of(context);
      late OverlayEntry entry;

      final String text = isBonus ? '+$xp BONUS XP 🔥' : '+$xp XP';
      final Color color = isBonus ? const Color(0xFFFF8C00) : const Color(0xFF10B981);

      // Üst üste yığılmaları önlemek için rastgele ufak yatay offset
      final double randomOffset = (xp % 3 == 0)
          ? -30.0
          : (xp % 2 == 0)
              ? 30.0
              : 0.0;

      entry = OverlayEntry(
        builder: (context) => XpGainFloatingText(
          text: text,
          color: color,
          offsetX: randomOffset,
          onFinished: () {
            entry.remove();
          },
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          overlayState.insert(entry);
        }
      });
    });
  }
}
