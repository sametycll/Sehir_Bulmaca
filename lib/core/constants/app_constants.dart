class AppConstants {
  static const String appName = 'Türkiye Şehir Bulma';
  
  // Game Config
  static const int totalCities = 81;
  static const Duration gameTimerInterval = Duration(seconds: 1);
  
  // Firebase Collections
  static const String leaderboardCollection = 'leaderboard';
  static const String usersCollection = 'users';

  // Animation Durations
  static const Duration splashDuration = Duration(milliseconds: 2000);
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);

  // Map Colors
  static const int defaultCityColor = 0xFFFFFFFF; // Beyaz
  static const int discoveredCityColor = 0xFF4CAF50; // Canlı Yeşil
}
