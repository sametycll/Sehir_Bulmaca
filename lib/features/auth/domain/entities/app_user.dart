class AppUser {
  final String uid;
  final String displayName;
  final String shortTag;
  final String leaderboardName;
  final String? photoUrl;
  final DateTime createdAt;
  final String? email;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.shortTag,
    required this.leaderboardName,
    this.photoUrl,
    required this.createdAt,
    this.email,
  });

  /// Getter for backwards compatibility with existing views calling photoURL
  String? get photoURL => photoUrl;
}
