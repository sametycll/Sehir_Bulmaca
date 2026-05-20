enum GameMode {
  allTurkey,
  timeAttack,
  blitzChallenge,
  // --- 7 Coğrafi Bölge ---
  marmara,
  ege,
  akdeniz,
  icAnadolu,
  karadeniz,
  doguAnadolu,
  guneydoguAnadolu,
}

extension GameModeExtension on GameMode {
  String get id {
    switch (this) {
      case GameMode.allTurkey:       return 'all_turkey';
      case GameMode.timeAttack:      return 'time_attack';
      case GameMode.blitzChallenge:  return 'blitz_challenge';
      case GameMode.marmara:         return 'marmara';
      case GameMode.ege:             return 'ege';
      case GameMode.akdeniz:         return 'akdeniz';
      case GameMode.icAnadolu:       return 'ic_anadolu';
      case GameMode.karadeniz:       return 'karadeniz';
      case GameMode.doguAnadolu:     return 'dogu_anadolu';
      case GameMode.guneydoguAnadolu:return 'guneydogu_anadolu';
    }
  }

  String get title {
    switch (this) {
      case GameMode.allTurkey:       return 'Tüm Türkiye (81 İl)';
      case GameMode.timeAttack:      return 'Zamana Karşı ⚡';
      case GameMode.blitzChallenge:  return '60 Saniye Yarışı ⏱️';
      case GameMode.marmara:         return 'Marmara Bölgesi 🗺️';
      case GameMode.ege:             return 'Ege Bölgesi 🗺️';
      case GameMode.akdeniz:         return 'Akdeniz Bölgesi 🗺️';
      case GameMode.icAnadolu:       return 'İç Anadolu Bölgesi 🗺️';
      case GameMode.karadeniz:       return 'Karadeniz Bölgesi 🗺️';
      case GameMode.doguAnadolu:     return 'Doğu Anadolu Bölgesi 🗺️';
      case GameMode.guneydoguAnadolu:return 'Güneydoğu Anadolu Bölgesi 🗺️';
    }
  }

  String get subtitle {
    switch (this) {
      case GameMode.allTurkey:
        return 'Klasik harita modu. Türkiye\'deki tüm 81 ili zamana karşı olmadan bulun.';
      case GameMode.timeAttack:
        return '60 saniye ile başla. Her doğru tahmin +3sn kazandırır, kombolar süreyi katlar!';
      case GameMode.blitzChallenge:
        return 'Süre eklemesi yok. 60 saniye içinde en fazla ili bulup rekor kır!';
      case GameMode.marmara:
        return 'Sadece Marmara Bölgesi\'nin 11 ili. Harita bölgeye odaklanır.';
      case GameMode.ege:
        return 'Sadece Ege Bölgesi\'nin 8 ili. Harita bölgeye odaklanır.';
      case GameMode.akdeniz:
        return 'Sadece Akdeniz Bölgesi\'nin 8 ili. Harita bölgeye odaklanır.';
      case GameMode.icAnadolu:
        return 'Sadece İç Anadolu Bölgesi\'nin 13 ili. Harita bölgeye odaklanır.';
      case GameMode.karadeniz:
        return 'Sadece Karadeniz Bölgesi\'nin 18 ili. Harita bölgeye odaklanır.';
      case GameMode.doguAnadolu:
        return 'Sadece Doğu Anadolu Bölgesi\'nin 14 ili. Harita bölgeye odaklanır.';
      case GameMode.guneydoguAnadolu:
        return 'Sadece Güneydoğu Anadolu Bölgesi\'nin 9 ili. Harita bölgeye odaklanır.';
    }
  }

  int get maxScore {
    switch (this) {
      case GameMode.allTurkey:        return 81;
      case GameMode.timeAttack:       return 81;
      case GameMode.blitzChallenge:   return 81;
      case GameMode.marmara:          return 11;
      case GameMode.ege:              return 8;
      case GameMode.akdeniz:          return 8;
      case GameMode.icAnadolu:        return 13;
      case GameMode.karadeniz:        return 18;
      case GameMode.doguAnadolu:      return 14;
      case GameMode.guneydoguAnadolu: return 9;
    }
  }

  bool get isRegional {
    return this == GameMode.marmara ||
        this == GameMode.ege ||
        this == GameMode.akdeniz ||
        this == GameMode.icAnadolu ||
        this == GameMode.karadeniz ||
        this == GameMode.doguAnadolu ||
        this == GameMode.guneydoguAnadolu;
  }

  bool get isTimedMode {
    return this == GameMode.timeAttack || this == GameMode.blitzChallenge;
  }

  static GameMode fromId(String id) {
    return GameMode.values.firstWhere(
      (element) => element.id == id,
      orElse: () => GameMode.allTurkey,
    );
  }
}
