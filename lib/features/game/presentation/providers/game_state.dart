import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/city_entity.dart';

part 'game_state.freezed.dart';

@freezed
class GameState with _$GameState {
  const factory GameState({
    @Default({}) Map<String, CityEntity> allCities, // Key: normalizedName
    @Default([]) List<CityEntity> foundCities,
    @Default(0) int elapsedTime,
    @Default(false) bool isRunning,
    @Default(false) bool isFinished,
    @Default('') String currentInput,
    @Default(0) int comboCount,
    @Default('') String lastFoundCityName,
    DateTime? lastCorrectGuessTime,
  }) = _GameState;

  const GameState._();

  int get remainingCount => allCities.length - foundCities.length;
  double get progress => allCities.isEmpty ? 0 : foundCities.length / allCities.length;
}
