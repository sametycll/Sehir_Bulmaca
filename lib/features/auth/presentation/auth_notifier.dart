import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isGuest;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    required this.isGuest,
  });

  factory AuthState.initial() => AuthState(
        status: AuthStatus.initial,
        user: null,
        errorMessage: null,
        isGuest: false,
      );

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isGuest,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    _checkCurrentUser();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _checkCurrentUser() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Determine if they are a guest based on email structure
      final isGuest = currentUser.email != null &&
          currentUser.email!.endsWith('@sehirbulmaca.anon');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: currentUser,
        isGuest: isGuest,
      );
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        isGuest: false,
      );
    }
  }

  /// Guest Login using Persistent Device ID
  Future<void> signInAsGuest() async {
    state = state.copyWith(status: AuthStatus.authenticating);
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
        // Kullanıcı bulunamadıysa veya kimlik bilgisi geçersizse yeni kayıt oluştur.
        // Firebase SDK sürümüne göre farklı hata kodları dönebilir.
        const registrableErrors = {
          'user-not-found',
          'invalid-credential',
          'wrong-password',
          'INVALID_LOGIN_CREDENTIALS',
          'user-disabled', // Silinmiş hesap → yeni oluştur
        };
        if (registrableErrors.contains(e.code)) {
          // Kullanıcı yoksa kayıt oluştur
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final user = userCredential.user;
      final prefs = await SharedPreferences.getInstance();
      final lastNickname = prefs.getString('guest_nickname') ?? 'Misafir';

      if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(lastNickname);
        await user.reload();
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: _auth.currentUser,
        isGuest: true,
      );
    } catch (e) {
      debugPrint('[AuthNotifier] signInAsGuest HATA: ${e.runtimeType} | $e');
      String userMessage = 'Anonim giriş başarısız oldu.';
      if (e is FirebaseAuthException) {
        debugPrint('[AuthNotifier] Firebase kod: ${e.code}');
        switch (e.code) {
          case 'operation-not-allowed':
            userMessage =
                'E-posta/şifre girişi Firebase\'de etkinleştirilmemiş. Lütfen yöneticiyle iletişime geçin.';
            break;
          case 'too-many-requests':
            userMessage = 'Çok fazla istek gönderildi. Lütfen bir süre bekleyin.';
            break;
          case 'network-request-failed':
            userMessage = 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
            break;
          default:
            userMessage = 'Misafir girişi başarısız: ${e.code}';
        }
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userMessage,
      );
    }
  }

  /// Google Authentication
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return; // User cancelled the flow
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: userCredential.user,
        isGuest: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Google ile giriş başarısız: $e',
      );
    }
  }

  /// Update display name for Guest and update local cache
  Future<void> updateGuestNickname(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guest_nickname', name);
    
    final user = _auth.currentUser;
    if (user != null && state.isGuest) {
      await user.updateDisplayName(name);
      await user.reload();
      state = state.copyWith(user: _auth.currentUser);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      await _auth.signOut();
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
        }
      } catch (_) {}
      state = AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        isGuest: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Çıkış yapılırken hata oluştu: $e',
      );
    }
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

    // 1. Try to read from Keychain/Secure Storage (survives uninstall on iOS)
    try {
      final storedId = await secureStorage.read(key: 'persistent_device_id');
      if (storedId != null && storedId.isNotEmpty) {
        return storedId;
      }
    } catch (_) {}

    // 2. Try to read from SharedPreferences
    final sharedId = prefs.getString('persistent_device_id');
    if (sharedId != null && sharedId.isNotEmpty) {
      try {
        await secureStorage.write(key: 'persistent_device_id', value: sharedId);
      } catch (_) {}
      return sharedId;
    }

    // 3. Derive unique ID from device hardware properties
    String? derivedId;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Build ID is unique per device/factory image and remains constant
        derivedId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        derivedId = iosInfo.identifierForVendor;
      }
    } catch (_) {}

    // 4. Fallback to random UUID if derivation fails
    final finalId = derivedId ?? const Uuid().v4();

    // 5. Store persistency
    try {
      await secureStorage.write(key: 'persistent_device_id', value: finalId);
    } catch (_) {}
    await prefs.setString('persistent_device_id', finalId);

    return finalId;
  }
}
