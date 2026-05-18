import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../providers/game_notifier.dart';
import '../../infrastructure/services/audio_service.dart';

class GameInputField extends ConsumerStatefulWidget {
  const GameInputField({super.key});

  @override
  ConsumerState<GameInputField> createState() => _GameInputFieldState();
}

class _GameInputFieldState extends ConsumerState<GameInputField> with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _shakeController;
  bool _isWrong = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });

    // Yanlış tahminde shake animasyonunu yönlendiren kontrolcü
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeController.addListener(() {
      setState(() {});
    });
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
        setState(() {
          _isWrong = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleInput(String value) {
    ref.read(gameProvider.notifier).onInputChanged(value);
    setState(() {}); // Clear butonunun görünürlüğü için
  }

  void _handleSubmitted(String value) {
    if (value.trim().isEmpty) return;
    
    final normalized = value.trim().normalizeCityName;
    final gameState = ref.read(gameProvider);
    
    // Tahminin doğruluğunu kontrol et
    if (gameState.allCities.containsKey(normalized)) {
      final city = gameState.allCities[normalized]!;
      if (gameState.foundCities.any((c) => c.id == city.id)) {
        // Zaten bulunmuş! Shake ve kırmızı glow tetikle
        _triggerWrongGuess();
      } else {
        // Doğru tahmin! Notifier bunu zaten yakalayacaktır
        ref.read(gameProvider.notifier).onInputChanged(value);
      }
    } else {
      // Yanlış tahmin! Shake ve kırmızı glow tetikle
      _triggerWrongGuess();
    }
  }

  void _triggerWrongGuess() {
    setState(() {
      _isWrong = true;
    });
    _shakeController.forward(from: 0.0);
    AudioService.playWrong();
  }

  @override
  Widget build(BuildContext context) {
    // Bulunan şehir sayısını dinle, eğer arttıysa inputu temizle
    ref.listen<int>(gameProvider.select((s) => s.foundCities.length), (previous, next) {
      if (next > (previous ?? 0)) {
        _controller.clear();
      }
    });

    // Damped harmonic shake offset formülü (0 -> 1 arasında sönümlenen sinüs dalgası)
    final double shakeOffset = math.sin(_shakeController.value * 4 * math.pi) * 8.0 * (1.0 - _shakeController.value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Transform.translate(
        offset: Offset(shakeOffset, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: _isWrong 
                ? Colors.red.withValues(alpha: 0.08) 
                : (_isFocused ? AppColors.primary.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _isWrong 
                  ? Colors.red.withValues(alpha: 0.8) 
                  : (_isFocused ? AppColors.primary : Colors.white.withValues(alpha: 0.15)),
              width: 2.0,
            ),
            boxShadow: [
              if (_isWrong)
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              else if (_isFocused)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _isWrong ? Icons.error_outline_rounded : Icons.search_rounded,
                color: _isWrong ? Colors.red : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _handleInput,
                  onSubmitted: _handleSubmitted,
                  autofocus: true,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Şehir ismini yazın ve Enter\'a basın...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondaryDark.withValues(alpha: 0.4),
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 1.0,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondaryDark),
                  onPressed: () {
                    setState(() {
                      _controller.clear();
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
