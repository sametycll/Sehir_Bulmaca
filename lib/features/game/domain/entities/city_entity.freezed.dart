// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'city_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CityEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get normalizedName =>
      throw _privateConstructorUsedError; // Arama/Karşılaştırma için
  int get plateCode => throw _privateConstructorUsedError;
  bool get isFound => throw _privateConstructorUsedError;
  DateTime? get foundAt => throw _privateConstructorUsedError;

  /// Create a copy of CityEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CityEntityCopyWith<CityEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CityEntityCopyWith<$Res> {
  factory $CityEntityCopyWith(
    CityEntity value,
    $Res Function(CityEntity) then,
  ) = _$CityEntityCopyWithImpl<$Res, CityEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    String normalizedName,
    int plateCode,
    bool isFound,
    DateTime? foundAt,
  });
}

/// @nodoc
class _$CityEntityCopyWithImpl<$Res, $Val extends CityEntity>
    implements $CityEntityCopyWith<$Res> {
  _$CityEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CityEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? normalizedName = null,
    Object? plateCode = null,
    Object? isFound = null,
    Object? foundAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            normalizedName: null == normalizedName
                ? _value.normalizedName
                : normalizedName // ignore: cast_nullable_to_non_nullable
                      as String,
            plateCode: null == plateCode
                ? _value.plateCode
                : plateCode // ignore: cast_nullable_to_non_nullable
                      as int,
            isFound: null == isFound
                ? _value.isFound
                : isFound // ignore: cast_nullable_to_non_nullable
                      as bool,
            foundAt: freezed == foundAt
                ? _value.foundAt
                : foundAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CityEntityImplCopyWith<$Res>
    implements $CityEntityCopyWith<$Res> {
  factory _$$CityEntityImplCopyWith(
    _$CityEntityImpl value,
    $Res Function(_$CityEntityImpl) then,
  ) = __$$CityEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String normalizedName,
    int plateCode,
    bool isFound,
    DateTime? foundAt,
  });
}

/// @nodoc
class __$$CityEntityImplCopyWithImpl<$Res>
    extends _$CityEntityCopyWithImpl<$Res, _$CityEntityImpl>
    implements _$$CityEntityImplCopyWith<$Res> {
  __$$CityEntityImplCopyWithImpl(
    _$CityEntityImpl _value,
    $Res Function(_$CityEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CityEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? normalizedName = null,
    Object? plateCode = null,
    Object? isFound = null,
    Object? foundAt = freezed,
  }) {
    return _then(
      _$CityEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        normalizedName: null == normalizedName
            ? _value.normalizedName
            : normalizedName // ignore: cast_nullable_to_non_nullable
                  as String,
        plateCode: null == plateCode
            ? _value.plateCode
            : plateCode // ignore: cast_nullable_to_non_nullable
                  as int,
        isFound: null == isFound
            ? _value.isFound
            : isFound // ignore: cast_nullable_to_non_nullable
                  as bool,
        foundAt: freezed == foundAt
            ? _value.foundAt
            : foundAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$CityEntityImpl implements _CityEntity {
  const _$CityEntityImpl({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.plateCode,
    this.isFound = false,
    this.foundAt,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String normalizedName;
  // Arama/Karşılaştırma için
  @override
  final int plateCode;
  @override
  @JsonKey()
  final bool isFound;
  @override
  final DateTime? foundAt;

  @override
  String toString() {
    return 'CityEntity(id: $id, name: $name, normalizedName: $normalizedName, plateCode: $plateCode, isFound: $isFound, foundAt: $foundAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CityEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.normalizedName, normalizedName) ||
                other.normalizedName == normalizedName) &&
            (identical(other.plateCode, plateCode) ||
                other.plateCode == plateCode) &&
            (identical(other.isFound, isFound) || other.isFound == isFound) &&
            (identical(other.foundAt, foundAt) || other.foundAt == foundAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    normalizedName,
    plateCode,
    isFound,
    foundAt,
  );

  /// Create a copy of CityEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CityEntityImplCopyWith<_$CityEntityImpl> get copyWith =>
      __$$CityEntityImplCopyWithImpl<_$CityEntityImpl>(this, _$identity);
}

abstract class _CityEntity implements CityEntity {
  const factory _CityEntity({
    required final String id,
    required final String name,
    required final String normalizedName,
    required final int plateCode,
    final bool isFound,
    final DateTime? foundAt,
  }) = _$CityEntityImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get normalizedName; // Arama/Karşılaştırma için
  @override
  int get plateCode;
  @override
  bool get isFound;
  @override
  DateTime? get foundAt;

  /// Create a copy of CityEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CityEntityImplCopyWith<_$CityEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
