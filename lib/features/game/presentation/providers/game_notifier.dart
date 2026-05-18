import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../domain/entities/city_entity.dart';
import '../../infrastructure/services/audio_service.dart';
import 'game_state.dart';

final gameProvider = NotifierProvider.autoDispose<GameNotifier, GameState>(() {
  return GameNotifier();
});

class GameNotifier extends AutoDisposeNotifier<GameState> {
  Timer? _timer;

  @override
  GameState build() {
    // Notifier dispose edildiğinde timer'ı da iptal et
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const GameState();
  }

  void initGame(List<CityEntity> cities) {
    final cityMap = {for (var city in cities) city.normalizedName: city};
    state = state.copyWith(
      allCities: cityMap,
      foundCities: [],
      elapsedTime: 0,
      isRunning: true,
      isFinished: false,
      comboCount: 0,
      lastFoundCityName: '',
      lastCorrectGuessTime: null,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isRunning && !state.isFinished) {
        state = state.copyWith(elapsedTime: state.elapsedTime + 1);
      }
    });
  }

  void onInputChanged(String input) {
    if (!state.isRunning || state.isFinished) return;

    final normalizedInput = input.normalizeCityName;
    
    if (state.allCities.containsKey(normalizedInput)) {
      final city = state.allCities[normalizedInput]!;
      
      if (!state.foundCities.any((c) => c.id == city.id)) {
        _markCityAsFound(city);
      }
    }
  }

  void _markCityAsFound(CityEntity city) {
    final now = DateTime.now();
    final updatedCity = city.copyWith(isFound: true, foundAt: now);
    final newFoundCities = [...state.foundCities, updatedCity];
    
    // Combo hesaplama (4 saniye aralığında bulunursa combo katlanır)
    int newCombo = 1;
    if (state.lastCorrectGuessTime != null) {
      final diff = now.difference(state.lastCorrectGuessTime!);
      if (diff.inSeconds <= 4) {
        newCombo = state.comboCount + 1;
      }
    }

    // Ses çalma tetikleyicisi
    if (newCombo >= 2) {
      AudioService.playCombo(newCombo);
    } else {
      AudioService.playCorrect();
    }
    
    state = state.copyWith(
      foundCities: newFoundCities,
      comboCount: newCombo,
      lastFoundCityName: city.name,
      lastCorrectGuessTime: now,
    );

    if (newFoundCities.length == state.allCities.length) {
      AudioService.playSuccess();
      _finishGame();
    }
  }

  void manualFinishGame() {
    _finishGame();
  }

  void _finishGame() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, isFinished: true);
  }
}
