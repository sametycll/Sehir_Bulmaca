/// Türkiye'nin 7 coğrafi bölgesine ait il plaka kodları.
/// Kaynak: Türkiye İstatistik Kurumu (TÜİK) resmi bölge sınıflandırması.
class RegionData {
  /// Her bölge modunun id'sine karşılık gelen plaka kodları seti
  static const Map<String, Set<int>> regionPlateCodes = {
    'marmara': {
      10, // Balıkesir (Marmara + Ege sınırında; TÜİK: Marmara)
      11, // Bilecik     
      16, // Bursa
      17, // Çanakkale
      22, // Edirne
      34, // İstanbul
      39, // Kırklareli
      41, // Kocaeli
      54, // Sakarya
      59, // Tekirdağ
      77, // Yalova
    },
    'ege': {
      3,  // Afyonkarahisar
      9,  // Aydın
      20, // Denizli
      35, // İzmir
      43, // Kütahya
      45, // Manisa
      48, // Muğla
      64, // Uşak
    },
    'akdeniz': {
      1,  // Adana
      7,  // Antalya
      15, // Burdur
      31, // Hatay
      32, // Isparta
      33, // Mersin
      46, // Kahramanmaraş   
      80, // Osmaniye
    },
    'ic_anadolu': {
      6,  // Ankara
      18, // Çankırı
      26, // Eskişehir
      38, // Kayseri
      40, // Kırşehir
      42, // Konya
      50, // Nevşehir
      51, // Niğde
      58, // Sivas
      66, // Yozgat
      68, // Aksaray
      70, // Karaman
      71, // Kırıkkale
    },
    'karadeniz': {
      5,  // Amasya
      8,  // Artvin
      14, // Bolu
      19, // Çorum
      28, // Giresun
      29, // Gümüşhane
      37, // Kastamonu
      52, // Ordu
      53, // Rize
      55, // Samsun
      57, // Sinop
      60, // Tokat
      61, // Trabzon
      67, // Zonguldak
      69, // Bayburt
      74, // Bartın
      78, // Karabük
      81, // Düzce      
    },
    'dogu_anadolu': {
      4,  // Ağrı
      12, // Bingöl
      13, // Bitlis
      23, // Elazığ
      24, // Erzincan
      25, // Erzurum
      30, // Hakkari
      36, // Kars
      44, // Malatya
      49, // Muş
      62, // Tunceli
      65, // Van
      75, // Ardahan
      76, // Iğdır
    },
    'guneydogu_anadolu': {
      2,  // Adıyaman
      21, // Diyarbakır
      27, // Gaziantep
      47, // Mardin
      56, // Siirt
      63, // Şanlıurfa
      72, // Batman
      73, // Şırnak
      79, //
    },
  };

  /// Plaka kodundan o ilin bölge id'sini döndürür
  static String? regionForPlate(int plateCode) {
    for (final entry in regionPlateCodes.entries) {
      if (entry.value.contains(plateCode)) return entry.key;
    }
    return null;
  }

  /// Verilen game mode id'sine ait plaka kodlarını döndürür.
  /// Bölgesel mod değilse (allTurkey, timeAttack, blitz) null döner.
  static Set<int>? platesForMode(String modeId) {
    return regionPlateCodes[modeId];
  }
}
