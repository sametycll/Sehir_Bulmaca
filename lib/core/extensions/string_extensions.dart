extension StringNormalization on String {
  /// Türkçe karakterleri normalize eder ve küçük harfe çevirir.
  /// Karşılaştırmalarda "case-insensitive" ve "accent-insensitive" benzeri bir davranış sağlar.
  String get normalizeCityName {
    return trim()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }
}
