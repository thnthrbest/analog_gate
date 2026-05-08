import 'package:flutter/material.dart';

enum MissionDifficulty { easy, medium, hard }
enum MissionCategory  { outdoor, reading, movement, creativity, mindfulness }

// ── Mission ──────────────────────────────────────────────────────────────────
class Mission {
  final String           id;
  final String           title;
  final String           description;
  final String           photoPrompt;
  final MissionDifficulty difficulty;
  final MissionCategory  category;
  final int              xp;
  final List<String>     aiLabels;   // ML Kit labels that count as valid proof
  final IconData         icon;
  final Color            iconColor;
  final Color            iconBg;
  bool                   isCompleted;
  String?                photoPath;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.photoPrompt,
    required this.difficulty,
    required this.category,
    required this.xp,
    required this.aiLabels,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isCompleted = false,
    this.photoPath,
  });

  String get difficultyLabel => switch (difficulty) {
    MissionDifficulty.easy   => 'Easy',
    MissionDifficulty.medium => 'Medium',
    MissionDifficulty.hard   => 'Hard',
  };

  Color get difficultyColor => switch (difficulty) {
    MissionDifficulty.easy   => const Color(0xFF639922),
    MissionDifficulty.medium => const Color(0xFFEF9F27),
    MissionDifficulty.hard   => const Color(0xFFD4537E),
  };
}

// ── Locked App ───────────────────────────────────────────────────────────────
class LockedApp {
  final String       id;
  final String       name;
  final String       packageName;
  final IconData     icon;
  final Color        iconColor;
  final Color        iconBg;
  final List<String> requiredMissionIds;
  final int          sessionMinutes;
  bool               isUnlockedToday;
  DateTime?          unlockedAt;

  LockedApp({
    required this.id,
    required this.name,
    required this.packageName,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.requiredMissionIds,
    this.sessionMinutes = 30,
    this.isUnlockedToday = false,
    this.unlockedAt,
  });

  bool get isSessionExpired {
    if (!isUnlockedToday || unlockedAt == null) return false;
    return DateTime.now().difference(unlockedAt!).inMinutes >= sessionMinutes;
  }

  int get minutesRemaining {
    if (!isUnlockedToday || unlockedAt == null) return 0;
    final elapsed = DateTime.now().difference(unlockedAt!).inMinutes;
    return (sessionMinutes - elapsed).clamp(0, sessionMinutes);
  }
}