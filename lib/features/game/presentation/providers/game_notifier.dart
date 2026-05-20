import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../domain/entities/city_entity.dart';
import '../../../leaderboard/domain/entities/game_mode.dart';
import '../../infrastructure/services/audio_service.dart';
import 'game_state.dart';

final playGameModeProvider = StateProvider<GameMode>((ref) => GameMode.allTurkey);

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

  void initGame(List<CityEntity> cities, GameMode mode) {
    final cityMap = {for (var city in cities) city.normalizedName: city};
    
    int initialRemainingTime = 0;
    if (mode.isTimedMode) {
      initialRemainingTime = 60;
    }

    state = state.copyWith(
      allCities: cityMap,
      foundCities: [],
      elapsedTime: 0,
      isRunning: true,
      isFinished: false,
      comboCount: 0,
      lastFoundCityName: '',
      lastCorrectGuessTime: null,
      gameMode: mode,
      remainingTime: initialRemainingTime,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isRunning && !state.isFinished) {
        if (state.gameMode.isTimedMode) {
          final newRemainingTime = state.remainingTime - 1;
          
          if (newRemainingTime <= 0) {
            state = state.copyWith(
              remainingTime: 0,
              elapsedTime: state.elapsedTime + 1,
            );
            _finishGame();
          } else {
            state = state.copyWith(
              remainingTime: newRemainingTime,
              elapsedTime: state.elapsedTime + 1,
            );
            
            // Son 10 saniyede kalp atışı sesi
            if (newRemainingTime <= 10) {
              AudioService.playHeartbeat();
            }
          }
        } else {
          state = state.copyWith(elapsedTime: state.elapsedTime + 1);
        }
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
    
    // Zamana Karşı modunda kalan süreye ek saniye eklenir (Blitz modunda eklenmez)
    int newRemainingTime = state.remainingTime;
    if (state.gameMode == GameMode.timeAttack) {
      final addedSeconds = newCombo * 3;
      newRemainingTime = (state.remainingTime + addedSeconds).clamp(0, 99);
    }

    state = state.copyWith(
      foundCities: newFoundCities,
      comboCount: newCombo,
      lastFoundCityName: city.name,
      lastCorrectGuessTime: now,
      remainingTime: newRemainingTime,
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
