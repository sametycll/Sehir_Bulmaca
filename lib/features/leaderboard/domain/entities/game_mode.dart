enum GameMode {
  allTurkey,
  marmara,
  ege,
  timeAttack,
}

extension GameModeExtension on GameMode {
  String get id {
    switch (this) {
      case GameMode.allTurkey:
        return 'all_turkey';
      case GameMode.marmara:
        return 'marmara';
      case GameMode.ege:
        return 'ege';
      case GameMode.timeAttack:
        return 'time_attack';
    }
  }

  String get title {
    switch (this) {
      case GameMode.allTurkey:
        return 'Tüm Türkiye (81 İl)';
      case GameMode.marmara:
        return 'Marmara Bölgesi';
      case GameMode.ege:
        return 'Ege Bölgesi';
      case GameMode.timeAttack:
        return 'Zamanlı Mod 🔥';
    }
  }

  int get maxScore {
    switch (this) {
      case GameMode.allTurkey:
        return 81;
      case GameMode.marmara:
        return 11; // 11 cities in Marmara
      case GameMode.ege:
        return 8;  // 8 cities in Ege
      case GameMode.timeAttack:
        return 81;
    }
  }

  static GameMode fromId(String id) {
    return GameMode.values.firstWhere(
      (element) => element.id == id,
      orElse: () => GameMode.allTurkey,
    );
  }
}
