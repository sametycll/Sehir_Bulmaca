import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sehir_bulmaca/features/daily_system/presentation/screens/daily_missions_screen.dart';
import 'package:sehir_bulmaca/features/daily_system/presentation/providers/daily_notifier.dart';
import 'package:sehir_bulmaca/features/daily_system/domain/entities/daily_streak.dart';
import 'package:sehir_bulmaca/features/daily_system/domain/entities/daily_mission.dart';
import 'package:sehir_bulmaca/features/daily_system/domain/repositories/daily_repository.dart';
import 'package:sehir_bulmaca/features/auth/presentation/auth_notifier.dart';
import 'package:sehir_bulmaca/features/auth/domain/entities/app_user.dart';
import 'package:sehir_bulmaca/features/auth/domain/repositories/auth_repository.dart';

import 'package:sehir_bulmaca/features/daily_system/presentation/providers/reset_timer_provider.dart';

void main() {
  testWidgets('DailyMissionsScreen Layout Test', (WidgetTester tester) async {
    // Mock user and daily state
    final mockUser = AppUser(
      uid: 'test_uid',
      displayName: 'Test Oyuncu',
      email: 'test@sehirbulmaca.com',
      shortTag: '1234',
      leaderboardName: 'Test Oyuncu #1234',
      photoUrl: null,
      createdAt: DateTime.now(),
    );

    final mockStreak = DailyStreak(
      currentStreak: 3,
      bestStreak: 5,
      missionsResetAt: DateTime.now().add(const Duration(hours: 12)),
      lastActiveDate: DateTime.now(),
    );

    final mockMissions = [
      DailyMission(
        id: 'mission_1',
        title: 'İlk Görev',
        description: '3 şehir tahmin et',
        targetProgress: 3,
        currentProgress: 1,
        xpReward: 100,
        tier: MissionTier.easy,
        type: 'guess_city',
        isCompleted: false,
        isClaimed: false,
      )
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository(mockUser)),
          dailyRepositoryProvider.overrideWithValue(FakeDailyRepository(mockStreak, mockMissions)),
          resetTimerProvider.overrideWith((ref) => Stream.value('12:34:56')),
        ],
        child: const MaterialApp(
          home: DailyMissionsScreen(),
        ),
      ),
    );

    // Frame'i tetikle (sonsuz alev animasyonu nedeniyle pumpAndSettle yerine pump kullanıyoruz)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Ekranın yüklendiğini doğrula
    expect(find.text('GÜNLÜK MERKEZ'), findsOneWidget);
    expect(find.text('3 GÜNLÜK SERİ'), findsOneWidget);
    expect(find.text('İlk Görev'), findsOneWidget);
  });
}

class FakeAuthRepository implements AuthRepository {
  final AppUser _user;
  FakeAuthRepository(this._user);

  @override
  Stream<AppUser?> get onAuthStateChanged => Stream.value(_user);

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInAsGuest() async => _user;

  @override
  Future<AppUser> signInWithGoogle() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateGuestNickname(String nickname) async {}
}

class FakeDailyRepository implements DailyRepository {
  final DailyStreak _streak;
  final List<DailyMission> _missions;

  FakeDailyRepository(this._streak, this._missions);

  @override
  Future<List<DailyMission>> getDailyMissions(String userId) async => _missions;

  @override
  Future<DailyStreak?> getDailyStreak(String userId) async => _streak;

  @override
  Future<void> saveDailyData(String userId, DailyStreak streak, List<DailyMission> missions) async {}

  @override
  Future<void> saveDailyMissions(String userId, List<DailyMission> missions) async {}

  @override
  Future<void> saveDailyStreak(String userId, DailyStreak streak) async {}
}


