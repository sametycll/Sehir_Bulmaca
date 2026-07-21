import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehir_bulmaca/features/daily_system/infrastructure/models/daily_mission_model.dart';
import 'package:sehir_bulmaca/features/daily_system/infrastructure/models/daily_streak_model.dart';
import 'package:sehir_bulmaca/features/daily_system/domain/entities/daily_mission.dart';

void main() {
  group('DailyMissionModel Parsing Tests', () {
    test('should parse int values correctly', () {
      final map = {
        'id': 'm1',
        'title': 'Test Mission',
        'description': 'Test Description',
        'type': 'test',
        'targetProgress': 5,
        'currentProgress': 2,
        'xpReward': 200,
        'tier': 'medium',
        'isCompleted': false,
        'isClaimed': false,
      };

      final model = DailyMissionModel.fromMap(map);

      expect(model.id, 'm1');
      expect(model.targetProgress, 5);
      expect(model.currentProgress, 2);
      expect(model.xpReward, 200);
      expect(model.tier, MissionTier.medium);
    });

    test('should parse double values to int correctly (preventing TypeError)', () {
      final map = {
        'id': 'm1',
        'title': 'Test Mission',
        'description': 'Test Description',
        'type': 'test',
        'targetProgress': 5.0,
        'currentProgress': 2.0,
        'xpReward': 200.0,
        'tier': 'easy',
        'isCompleted': false,
        'isClaimed': false,
      };

      final model = DailyMissionModel.fromMap(map);

      expect(model.targetProgress, 5);
      expect(model.currentProgress, 2);
      expect(model.xpReward, 200);
    });

    test('should fall back to defaults on null/missing/invalid values', () {
      final map = {
        'id': 'm1',
        'title': 'Test Mission',
      };

      final model = DailyMissionModel.fromMap(map);

      expect(model.targetProgress, 1);
      expect(model.currentProgress, 0);
      expect(model.xpReward, 100);
    });
  });

  group('DailyStreakModel Parsing Tests', () {
    test('should parse double values to int correctly', () {
      final map = {
        'currentStreak': 3.0,
        'bestStreak': 7.0,
        'missionsResetAt': Timestamp.fromDate(DateTime(2026, 5, 23)),
      };

      final model = DailyStreakModel.fromMap(map);

      expect(model.currentStreak, 3);
      expect(model.bestStreak, 7);
    });
  });
}
