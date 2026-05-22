import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/helpers/tag_generator.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AppUser? _cachedUser;

  AuthRepositoryImpl(this._auth, this._firestore, this._googleSignIn);

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _cachedUser = null;
        return null;
      }
      final user = await _fetchOrUpdateProfile(firebaseUser);
      _cachedUser = user;
      return user;
    });
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Google Sign-In was cancelled by the user.',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Firebase User was null after Google credential sign-in.',
        );
      }

      final appUser = await _fetchOrUpdateProfile(firebaseUser);
      _cachedUser = appUser;
      return appUser;
    } catch (e) {
      debugPrint('[AuthRepositoryImpl] signInWithGoogle error: $e');
      rethrow;
    }
  }

  @override
  Future<AppUser> signInAsGuest() async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      final email = '$deviceId@sehirbulmaca.anon';
      final password = '${deviceId}_secure_pass';

      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        const registrableErrors = {
          'user-not-found',
          'invalid-credential',
          'wrong-password',
          'INVALID_LOGIN_CREDENTIALS',
          'user-disabled',
        };
        if (registrableErrors.contains(e.code)) {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Firebase User was null after guest sign-in.',
        );
      }

      // Sync nickname if set locally in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastNickname = prefs.getString('guest_nickname') ?? 'Misafir';

      if (firebaseUser.displayName == null || firebaseUser.displayName!.isEmpty) {
        await firebaseUser.updateDisplayName(lastNickname);
        await firebaseUser.reload();
      }

      final appUser = await _fetchOrUpdateProfile(_auth.currentUser ?? firebaseUser);
      _cachedUser = appUser;
      return appUser;
    } catch (e) {
      debugPrint('[AuthRepositoryImpl] signInAsGuest error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateGuestNickname(String nickname) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guest_nickname', nickname);

      await firebaseUser.updateDisplayName(nickname);
      await firebaseUser.reload();

      final docRef = _firestore.collection('users').doc(firebaseUser.uid);
      final docSnap = await docRef.get();
      if (docSnap.exists && docSnap.data() != null) {
        final existingUser = AppUserModel.fromMap(docSnap.data()!);
        final updatedLeaderboardName = '$nickname #${existingUser.shortTag}';
        
        final updatedUser = AppUserModel(
          uid: existingUser.uid,
          displayName: nickname,
          shortTag: existingUser.shortTag,
          leaderboardName: updatedLeaderboardName,
          photoUrl: existingUser.photoUrl,
          createdAt: existingUser.createdAt,
          email: existingUser.email,
        );
        
        await docRef.set(updatedUser.toMap(), SetOptions(merge: true));
        _cachedUser = updatedUser;
      }
    } catch (e) {
      debugPrint('[AuthRepositoryImpl] updateGuestNickname error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
      _cachedUser = null;
    } catch (e) {
      debugPrint('[AuthRepositoryImpl] signOut error: $e');
      rethrow;
    }
  }

  /// Helper to fetch existing profile or construct and save a new one.
  Future<AppUser> _fetchOrUpdateProfile(User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    try {
      final docSnap = await docRef.get(const GetOptions(source: Source.serverAndCache));
      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        final existingUser = AppUserModel.fromMap(data);

        // Check if display name or photo URL has changed on Firebase side and we need to update/merge them
        final hasPhotoChanged = firebaseUser.photoURL != null && firebaseUser.photoURL != existingUser.photoUrl;
        final hasDisplayNameChanged = firebaseUser.displayName != null && 
            firebaseUser.displayName!.isNotEmpty && 
            firebaseUser.displayName != existingUser.displayName;

        if (hasPhotoChanged || hasDisplayNameChanged) {
          final updatedDisplayName = hasDisplayNameChanged ? firebaseUser.displayName! : existingUser.displayName;
          final updatedLeaderboardName = '$updatedDisplayName #${existingUser.shortTag}';
          final updatedUser = AppUserModel(
            uid: existingUser.uid,
            displayName: updatedDisplayName,
            shortTag: existingUser.shortTag,
            leaderboardName: updatedLeaderboardName,
            photoUrl: firebaseUser.photoURL ?? existingUser.photoUrl,
            createdAt: existingUser.createdAt,
            email: firebaseUser.email ?? existingUser.email,
          );
          await docRef.set(updatedUser.toMap(), SetOptions(merge: true));
          return updatedUser;
        }
        return existingUser;
      }
    } catch (e) {
      debugPrint('[AuthRepositoryImpl] fetchProfile offline/cache read issue: $e');
    }

    // New User profile creation
    final String tag = TagGenerator.generateDeterministicTag(firebaseUser.uid);
    final isGuest = firebaseUser.email?.endsWith('@sehirbulmaca.anon') == true;
    final String displayName = firebaseUser.displayName ?? (isGuest ? 'Misafir' : 'Oyuncu');
    final String leaderboardName = '$displayName #$tag';

    final newUser = AppUserModel(
      uid: firebaseUser.uid,
      displayName: displayName,
      shortTag: tag,
      leaderboardName: leaderboardName,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      email: firebaseUser.email,
    );

    try {
      await docRef.set(newUser.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AuthRepositoryImpl] set profile error (cache fallback will handle): $e');
    }
    return newUser;
  }

  /// Generates or retrieves a unique persistent device ID
  Future<String> _getOrCreateDeviceId() async {
    const secureStorage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      final webId = prefs.getString('persistent_device_id');
      if (webId != null && webId.isNotEmpty) {
        return webId;
      }
      final newWebId = const Uuid().v4();
      await prefs.setString('persistent_device_id', newWebId);
      return newWebId;
    }

    try {
      final storedId = await secureStorage.read(key: 'persistent_device_id');
      if (storedId != null && storedId.isNotEmpty) {
        return storedId;
      }
    } catch (_) {}

    final sharedId = prefs.getString('persistent_device_id');
    if (sharedId != null && sharedId.isNotEmpty) {
      try {
        await secureStorage.write(key: 'persistent_device_id', value: sharedId);
      } catch (_) {}
      return sharedId;
    }

    String? derivedId;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        derivedId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        derivedId = iosInfo.identifierForVendor;
      }
    } catch (_) {}

    final finalId = derivedId ?? const Uuid().v4();

    try {
      await secureStorage.write(key: 'persistent_device_id', value: finalId);
    } catch (_) {}
    await prefs.setString('persistent_device_id', finalId);

    return finalId;
  }
}
