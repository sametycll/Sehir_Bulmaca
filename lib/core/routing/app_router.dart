import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/game/presentation/screens/game_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/auth/presentation/login_screen.dart';

class FirebaseAuthListenable extends ChangeNotifier {
  FirebaseAuthListenable() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      notifyListeners();
    });
  }
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    refreshListenable: FirebaseAuthListenable(),
    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';
      
      if (!loggedIn) {
        return '/login';
      }
      if (loggedIn && loggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
}
