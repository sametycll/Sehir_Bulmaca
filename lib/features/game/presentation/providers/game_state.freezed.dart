// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GameState {
  Map<String, CityEntity> get allCities =>
      throw _privateConstructorUsedError; // Key: normalizedName
  List<CityEntity> get foundCities => throw _privateConstructorUsedError;
  int get elapsedTime => throw _privateConstructorUsedError;
  bool get isRunning => throw _privateConstructorUsedError;
  bool get isFinished => throw _privateConstructorUsedError;
  String get currentInput => throw _privateConstructorUsedError;
  int get comboCount => throw _privateConstructorUsedError;
  String get lastFoundCityName => throw _privateConstructorUsedError;
  DateTime? get lastCorrectGuessTime => throw _privateConstructorUsedError;
  GameMode get gameMode => throw _privateConstructorUsedError;
  int get remainingTime => throw _privateConstructorUsedError;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call({
    Map<String, CityEntity> allCities,
    List<CityEntity> foundCities,
    int elapsedTime,
    bool isRunning,
    bool isFinished,
    String currentInput,
    int comboCount,
    String lastFoundCityName,
    DateTime? lastCorrectGuessTime,
    GameMode gameMode,
    int remainingTime,
  });
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allCities = null,
    Object? foundCities = null,
    Object? elapsedTime = null,
    Object? isRunning = null,
    Object? isFinished = null,
    Object? currentInput = null,
    Object? comboCount = null,
    Object? lastFoundCityName = null,
    Object? lastCorrectGuessTime = freezed,
    Object? gameMode = null,
    Object? remainingTime = null,
  }) {
    return _then(
      _value.copyWith(
            allCities: null == allCities
                ? _value.allCities
                : allCities // ignore: cast_nullable_to_non_nullable
                      as Map<String, CityEntity>,
            foundCities: null == foundCities
                ? _value.foundCities
                : foundCities // ignore: cast_nullable_to_non_nullable
                      as List<CityEntity>,
            elapsedTime: null == elapsedTime
                ? _value.elapsedTime
                : elapsedTime // ignore: cast_nullable_to_non_nullable
                      as int,
            isRunning: null == isRunning
                ? _value.isRunning
                : isRunning // ignore: cast_nullable_to_non_nullable
                      as bool,
            isFinished: null == isFinished
                ? _value.isFinished
                : isFinished // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentInput: null == currentInput
                ? _value.currentInput
                : currentInput // ignore: cast_nullable_to_non_nullable
                      as String,
            comboCount: null == comboCount
                ? _value.comboCount
                : comboCount // ignore: cast_nullable_to_non_nullable
                      as int,
            lastFoundCityName: null == lastFoundCityName
                ? _value.lastFoundCityName
                : lastFoundCityName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastCorrectGuessTime: freezed == lastCorrectGuessTime
                ? _value.lastCorrectGuessTime
                : lastCorrectGuessTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            gameMode: null == gameMode
                ? _value.gameMode
                : gameMode // ignore: cast_nullable_to_non_nullable
                      as GameMode,
            remainingTime: null == remainingTime
                ? _value.remainingTime
                : remainingTime // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
    _$GameStateImpl value,
    $Res Function(_$GameStateImpl) then,
  ) = __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Map<String, CityEntity> allCities,
    List<CityEntity> foundCities,
    int elapsedTime,
    bool isRunning,
    bool isFinished,
    String currentInput,
    int comboCount,
    String lastFoundCityName,
    DateTime? lastCorrectGuessTime,
    GameMode gameMode,
    int remainingTime,
  });
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
    _$GameStateImpl _value,
    $Res Function(_$GameStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allCities = null,
    Object? foundCities = null,
    Object? elapsedTime = null,
    Object? isRunning = null,
    Object? isFinished = null,
    Object? currentInput = null,
    Object? comboCount = null,
    Object? lastFoundCityName = null,
    Object? lastCorrectGuessTime = freezed,
    Object? gameMode = null,
    Object? remainingTime = null,
  }) {
    return _then(
      _$GameStateImpl(
        allCities: null == allCities
            ? _value._allCities
            : allCities // ignore: cast_nullable_to_non_nullable
                  as Map<String, CityEntity>,
        foundCities: null == foundCities
            ? _value._foundCities
            : foundCities // ignore: cast_nullable_to_non_nullable
                  as List<CityEntity>,
        elapsedTime: null == elapsedTime
            ? _value.elapsedTime
            : elapsedTime // ignore: cast_nullable_to_non_nullable
                  as int,
        isRunning: null == isRunning
            ? _value.isRunning
            : isRunning // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFinished: null == isFinished
            ? _value.isFinished
            : isFinished // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentInput: null == currentInput
            ? _value.currentInput
            : currentInput // ignore: cast_nullable_to_non_nullable
                  as String,
        comboCount: null == comboCount
            ? _value.comboCount
            : comboCount // ignore: cast_nullable_to_non_nullable
                  as int,
        lastFoundCityName: null == lastFoundCityName
            ? _value.lastFoundCityName
            : lastFoundCityName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastCorrectGuessTime: freezed == lastCorrectGuessTime
            ? _value.lastCorrectGuessTime
            : lastCorrectGuessTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        gameMode: null == gameMode
            ? _value.gameMode
            : gameMode // ignore: cast_nullable_to_non_nullable
                  as GameMode,
        remainingTime: null == remainingTime
            ? _value.remainingTime
            : remainingTime // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$GameStateImpl extends _GameState {
  const _$GameStateImpl({
    final Map<String, CityEntity> allCities = const {},
    final List<CityEntity> foundCities = const [],
    this.elapsedTime = 0,
    this.isRunning = false,
    this.isFinished = false,
    this.currentInput = '',
    this.comboCount = 0,
    this.lastFoundCityName = '',
    this.lastCorrectGuessTime,
    this.gameMode = GameMode.allTurkey,
    this.remainingTime = 0,
  }) : _allCities = allCities,
       _foundCities = foundCities,
       super._();

  final Map<String, CityEntity> _allCities;
  @override
  @JsonKey()
  Map<String, CityEntity> get allCities {
    if (_allCities is EqualUnmodifiableMapView) return _allCities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_allCities);
  }

  // Key: normalizedName
  final List<CityEntity> _foundCities;
  // Key: normalizedName
  @override
  @JsonKey()
  List<CityEntity> get foundCities {
    if (_foundCities is EqualUnmodifiableListView) return _foundCities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_foundCities);
  }

  @override
  @JsonKey()
  final int elapsedTime;
  @override
  @JsonKey()
  final bool isRunning;
  @override
  @JsonKey()
  final bool isFinished;
  @override
  @JsonKey()
  final String currentInput;
  @override
  @JsonKey()
  final int comboCount;
  @override
  @JsonKey()
  final String lastFoundCityName;
  @override
  final DateTime? lastCorrectGuessTime;
  @override
  @JsonKey()
  final GameMode gameMode;
  @override
  @JsonKey()
  final int remainingTime;

  @override
  String toString() {
    return 'GameState(allCities: $allCities, foundCities: $foundCities, elapsedTime: $elapsedTime, isRunning: $isRunning, isFinished: $isFinished, currentInput: $currentInput, comboCount: $comboCount, lastFoundCityName: $lastFoundCityName, lastCorrectGuessTime: $lastCorrectGuessTime, gameMode: $gameMode, remainingTime: $remainingTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            const DeepCollectionEquality().equals(
              other._allCities,
              _allCities,
            ) &&
            const DeepCollectionEquality().equals(
              other._foundCities,
              _foundCities,
            ) &&
            (identical(other.elapsedTime, elapsedTime) ||
                other.elapsedTime == elapsedTime) &&
            (identical(other.isRunning, isRunning) ||
                other.isRunning == isRunning) &&
            (identical(other.isFinished, isFinished) ||
                other.isFinished == isFinished) &&
            (identical(other.currentInput, currentInput) ||
                other.currentInput == currentInput) &&
            (identical(other.comboCount, comboCount) ||
                other.comboCount == comboCount) &&
            (identical(other.lastFoundCityName, lastFoundCityName) ||
                other.lastFoundCityName == lastFoundCityName) &&
            (identical(other.lastCorrectGuessTime, lastCorrectGuessTime) ||
                other.lastCorrectGuessTime == lastCorrectGuessTime) &&
            (identical(other.gameMode, gameMode) ||
                other.gameMode == gameMode) &&
            (identical(other.remainingTime, remainingTime) ||
                other.remainingTime == remainingTime));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_allCities),
    const DeepCollectionEquality().hash(_foundCities),
    elapsedTime,
    isRunning,
    isFinished,
    currentInput,
    comboCount,
    lastFoundCityName,
    lastCorrectGuessTime,
    gameMode,
    remainingTime,
  );

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);
}

abstract class _GameState extends GameState {
  const factory _GameState({
    final Map<String, CityEntity> allCities,
    final List<CityEntity> foundCities,
    final int elapsedTime,
    final bool isRunning,
    final bool isFinished,
    final String currentInput,
    final int comboCount,
    final String lastFoundCityName,
    final DateTime? lastCorrectGuessTime,
    final GameMode gameMode,
    final int remainingTime,
  }) = _$GameStateImpl;
  const _GameState._() : super._();

  @override
  Map<String, CityEntity> get allCities; // Key: normalizedName
  @override
  List<CityEntity> get foundCities;
  @override
  int get elapsedTime;
  @override
  bool get isRunning;
  @override
  bool get isFinished;
  @override
  String get currentInput;
  @override
  int get comboCount;
  @override
  String get lastFoundCityName;
  @override
  DateTime? get lastCorrectGuessTime;
  @override
  GameMode get gameMode;
  @override
  int get remainingTime;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
