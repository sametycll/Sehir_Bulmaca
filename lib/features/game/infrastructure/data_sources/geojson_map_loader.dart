import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/services.dart';

class ProvinceMapData {
  final String id;
  final String name;
  final int plateCode;
  final Path originalPath;
  final Rect bounds;

  ProvinceMapData({
    required this.id,
    required this.name,
    required this.plateCode,
    required this.originalPath,
    required this.bounds,
  });
}

class ParsedMapData {
  final List<ProvinceMapData> provinces;
  final Rect boundingBox;
  final Path combinedTurkeyPath; // Premium tek parçalı gölge ve sınır efektleri için birleşik harita yolu

  ParsedMapData({
    required this.provinces,
    required this.boundingBox,
    required this.combinedTurkeyPath,
  });
}

class GeoJsonMapLoader {
  // Web Mercator Projeksiyon Formülleri
  static double _projectX(double longitude) {
    return longitude * math.pi / 180.0;
  }

  static double _projectY(double latitude) {
    final latRad = latitude * math.pi / 180.0;
    // Kuzey yönü yukarıda olduğundan, daha büyük enlemlerin (kuzey) ekranda daha küçük Y değerlerine karşılık gelmesi amacıyla log(tan) değerini negatif yapıyoruz.
    return -math.log(math.tan(math.pi / 4.0 + latRad / 2.0));
  }

  static Future<ParsedMapData> loadAndParse() async {
    final jsonString = await rootBundle.loadString('assets/maps/tr.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final features = data['features'] as List<dynamic>;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    final List<ProvinceMapData> provinces = [];

    // simplemaps'teki İngilizce/hatalı il adlarını doğru Türkçe yazılışlarıyla eşleştiren sözlük.
    const Map<int, String> plateToCityName = {
      1: 'Adana', 2: 'Adıyaman', 3: 'Afyonkarahisar', 4: 'Ağrı', 5: 'Amasya',
      6: 'Ankara', 7: 'Antalya', 8: 'Artvin', 9: 'Aydın', 10: 'Balıkesir',
      11: 'Bilecik', 12: 'Bingöl', 13: 'Bitlis', 14: 'Bolu', 15: 'Burdur',
      16: 'Bursa', 17: 'Çanakkale', 18: 'Çankırı', 19: 'Çorum', 20: 'Denizli',
      21: 'Diyarbakır', 22: 'Edirne', 23: 'Elazığ', 24: 'Erzincan', 25: 'Erzurum',
      26: 'Eskişehir', 27: 'Gaziantep', 28: 'Giresun', 29: 'Gümüşhane', 30: 'Hakkari',
      31: 'Hatay', 32: 'Isparta', 33: 'Mersin', 34: 'İstanbul', 35: 'İzmir',
      36: 'Kars', 37: 'Kastamonu', 38: 'Kayseri', 39: 'Kırklareli', 40: 'Kırşehir',
      41: 'Kocaeli', 42: 'Konya', 43: 'Kütahya', 44: 'Malatya', 45: 'Manisa',
      46: 'Kahramanmaraş', 47: 'Mardin', 48: 'Muğla', 49: 'Muş', 50: 'Nevşehir',
      51: 'Niğde', 52: 'Ordu', 53: 'Rize', 54: 'Sakarya', 55: 'Samsun',
      56: 'Siirt', 57: 'Sinop', 58: 'Sivas', 59: 'Tekirdağ', 60: 'Tokat',
      61: 'Trabzon', 62: 'Tunceli', 63: 'Şanlıurfa', 64: 'Uşak', 65: 'Van',
      66: 'Yozgat', 67: 'Zonguldak', 68: 'Aksaray', 69: 'Bayburt', 70: 'Karaman',
      71: 'Kırıkkale', 72: 'Batman', 73: 'Şırnak', 74: 'Bartın', 75: 'Ardahan',
      76: 'Iğdır', 77: 'Yalova', 78: 'Karabük', 79: 'Kilis', 80: 'Osmaniye',
      81: 'Düzce',
    };

    for (final feature in features) {
      final properties = feature['properties'] as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      
      final String id = properties['id'] as String;
      final String rawName = properties['name'] as String;
      
      // SimpleMaps id değerinden plaka kodunu çıkar (örn. TR75 -> 75, TR08 -> 8)
      final String numberPart = id.replaceAll(RegExp(r'[^0-9]'), '');
      final int plateCode = int.tryParse(numberPart) ?? 0;

      // Varsa düzeltilmiş Türkçe il adını kullan, yoksa ham adı kullan
      final String name = plateToCityName[plateCode] ?? rawName;

      final String geometryType = geometry['type'] as String;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      final path = Path();
      double provMinX = double.infinity;
      double provMaxX = -double.infinity;
      double provMinY = double.infinity;
      double provMaxY = -double.infinity;

      void updateBounds(double x, double y) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;

        if (x < provMinX) provMinX = x;
        if (x > provMaxX) provMaxX = x;
        if (y < provMinY) provMinY = y;
        if (y > provMaxY) provMaxY = y;
      }

      Path buildRingPath(List<dynamic> ring) {
        final ringPath = Path();
        if (ring.isEmpty) return ringPath;

        final first = ring[0] as List<dynamic>;
        final firstX = _projectX((first[0] as num).toDouble());
        final firstY = _projectY((first[1] as num).toDouble());
        ringPath.moveTo(firstX, firstY);
        updateBounds(firstX, firstY);

        for (int i = 1; i < ring.length; i++) {
          final pt = ring[i] as List<dynamic>;
          final x = _projectX((pt[0] as num).toDouble());
          final y = _projectY((pt[1] as num).toDouble());
          ringPath.lineTo(x, y);
          updateBounds(x, y);
        }
        ringPath.close();
        return ringPath;
      }

      if (geometryType == 'Polygon') {
        for (final ring in coordinates) {
          final ringPath = buildRingPath(ring as List<dynamic>);
          path.addPath(ringPath, Offset.zero);
        }
      } else if (geometryType == 'MultiPolygon') {
        for (final polygon in coordinates) {
          for (final ring in polygon as List<dynamic>) {
            final ringPath = buildRingPath(ring as List<dynamic>);
            path.addPath(ringPath, Offset.zero);
          }
        }
      }

      provinces.add(
        ProvinceMapData(
          id: id,
          name: name,
          plateCode: plateCode,
          originalPath: path,
          bounds: Rect.fromLTRB(provMinX, provMinY, provMaxX, provMaxY),
        ),
      );
    }

    final combinedTurkeyPath = Path();
    for (final province in provinces) {
      combinedTurkeyPath.addPath(province.originalPath, Offset.zero);
    }

    return ParsedMapData(
      provinces: provinces,
      boundingBox: Rect.fromLTRB(minX, minY, maxX, maxY),
      combinedTurkeyPath: combinedTurkeyPath,
    );
  }
}
