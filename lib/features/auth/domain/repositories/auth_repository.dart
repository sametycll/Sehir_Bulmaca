import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Stream to listen to active user session changes
  Stream<AppUser?> get onAuthStateChanged;

  /// Retrieves the currently authenticated user profile
  AppUser? get currentUser;

  /// Signs in with Google credentials and synchronizes the profile to Firestore
  Future<AppUser> signInWithGoogle();

  /// Signs in using persistent device ID and synchronizes the profile to Firestore
  Future<AppUser> signInAsGuest();

  /// Updates a guest's nickname in Firebase Auth and updates Firestore
  Future<void> updateGuestNickname(String nickname);

  /// Standard log out flow
  Future<void> signOut();
}
