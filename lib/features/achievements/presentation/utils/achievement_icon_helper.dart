import 'package:flutter/material.dart';

IconData getAchievementIcon(int codePoint) {
  switch (codePoint) {
    case 0xe574:
      return Icons.explore_rounded;
    case 0xef14:
      return Icons.bolt_rounded;
    case 0xf08b:
      return Icons.speed_rounded;
    case 0xef55:
      return Icons.emoji_events_rounded;
    case 0xf04b:
      return Icons.leaderboard_rounded;
    case 0xeec6:
      return Icons.local_fire_department_rounded;
    case 0xef50:
      return Icons.star_rounded;
    case 0xe2b7:
      return Icons.forest_rounded;
    case 0xe7d4:
      return Icons.water_rounded;
    default:
      return Icons.emoji_events_rounded;
  }
}
