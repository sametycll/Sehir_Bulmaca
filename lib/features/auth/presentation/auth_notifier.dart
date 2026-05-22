import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';
import '../data/repositories/auth_repository_impl.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
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
    AppUser? user,
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

final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    ref.watch(googleSignInProvider),
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial()) {
    _listenToAuthState();
  }

  void _listenToAuthState() {
    _authRepository.onAuthStateChanged.listen((appUser) {
      if (appUser != null) {
        final isGuest = appUser.email != null &&
            appUser.email!.endsWith('@sehirbulmaca.anon');
        state = AuthState(
          status: AuthStatus.authenticated,
          user: appUser,
          isGuest: isGuest,
        );
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          user: null,
          isGuest: false,
        );
      }
    }, onError: (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: error.toString(),
      );
    });
  }

  /// Guest Login using Persistent Device ID
  Future<void> signInAsGuest() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final user = await _authRepository.signInAsGuest();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isGuest: true,
      );
    } catch (e) {
      debugPrint('[AuthNotifier] signInAsGuest HATA: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getReadableError(e),
      );
    }
  }

  /// Google Authentication
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final user = await _authRepository.signInWithGoogle();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isGuest: false,
      );
    } catch (e) {
      debugPrint('[AuthNotifier] signInWithGoogle HATA: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getReadableError(e),
      );
    }
  }

  /// Update display name for Guest and update local cache
  Future<void> updateGuestNickname(String name) async {
    try {
      await _authRepository.updateGuestNickname(name);
      if (state.user != null) {
        state = state.copyWith(user: _authRepository.currentUser);
      }
    } catch (e) {
      debugPrint('[AuthNotifier] updateGuestNickname HATA: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'İsim güncellenirken hata oluştu: $e',
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      await _authRepository.signOut();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        isGuest: false,
      );
    } catch (e) {
      debugPrint('[AuthNotifier] signOut HATA: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Çıkış yapılırken hata oluştu: $e',
      );
    }
  }

  String _getReadableError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'sign-in-cancelled':
          return 'Giriş işlemi iptal edildi.';
        case 'operation-not-allowed':
          return 'E-posta/şifre girişi Firebase\'de etkinleştirilmemiş.';
        case 'too-many-requests':
          return 'Çok fazla istek gönderildi. Lütfen bir süre bekleyin.';
        case 'network-request-failed':
          return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
        default:
          return 'Giriş başarısız: ${e.message ?? e.code}';
      }
    }
    return 'Bir hata oluştu: $e';
  }
}
