import 'package:freezed_annotation/freezed_annotation.dart';

part 'city_entity.freezed.dart';

@freezed
class CityEntity with _$CityEntity {
  const factory CityEntity({
    required String id,
    required String name,
    required String normalizedName, // Arama/Karşılaştırma için
    required int plateCode,
    @Default(false) bool isFound,
    DateTime? foundAt,
  }) = _CityEntity;
}
