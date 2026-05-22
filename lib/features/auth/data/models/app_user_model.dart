import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  AppUserModel({
    required super.uid,
    required super.displayName,
    required super.shortTag,
    required super.leaderboardName,
    super.photoUrl,
    required super.createdAt,
    super.email,
  });

  /// Convert standard AppUser entity into data-layer AppUserModel
  factory AppUserModel.fromEntity(AppUser user) {
    return AppUserModel(
      uid: user.uid,
      displayName: user.displayName,
      shortTag: user.shortTag,
      leaderboardName: user.leaderboardName,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      email: user.email,
    );
  }

  /// Map representations for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'shortTag': shortTag,
      'leaderboardName': leaderboardName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'email': email,
    };
  }

  /// De-serialize from Firestore document snapshot map
  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedCreatedAt;
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedCreatedAt = rawDate.toDate();
    } else if (rawDate is String) {
      parsedCreatedAt = DateTime.parse(rawDate);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return AppUserModel(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Oyuncu',
      shortTag: map['shortTag'] as String? ?? '0000',
      leaderboardName: map['leaderboardName'] as String? ?? 'Oyuncu',
      photoUrl: map['photoUrl'] as String?,
      createdAt: parsedCreatedAt,
      email: map['email'] as String?,
    );
  }
}
