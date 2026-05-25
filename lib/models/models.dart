import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
  final int              duration;   // duration in minutes
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
    required this.duration,
    required this.aiLabels,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isCompleted = false,
    this.photoPath,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    final iconName = json['icon_name'] as String? ?? 'walk';
    final colorName = json['color_name'] as String? ?? 'accent';

    return Mission(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      photoPrompt: json['photo_prompt'] as String,
      difficulty: MissionDifficulty.values.firstWhere(
        (e) => e.name == (json['difficulty'] as String?),
        orElse: () => MissionDifficulty.easy,
      ),
      category: MissionCategory.values.firstWhere(
        (e) => e.name == (json['category'] as String?),
        orElse: () => MissionCategory.mindfulness,
      ),
      xp: json['xp'] as int? ?? 10,
      duration: json['duration'] as int? ?? 10,
      aiLabels: List<String>.from(json['ai_labels'] ?? []),
      icon: _mapIcon(iconName),
      iconColor: _mapColor(colorName, dim: false),
      iconBg: _mapColor(colorName, dim: true),
    );
  }

  static IconData _mapIcon(String name) {
    switch (name) {
      case 'walk': return Icons.directions_walk_rounded;
      case 'tree': return Icons.park_rounded;
      case 'sun': return Icons.wb_sunny_rounded;
      case 'basketball': return Icons.sports_basketball_rounded;
      case 'book': return Icons.menu_book_rounded;
      case 'article': return Icons.article_rounded;
      case 'draw': return Icons.draw_rounded;
      case 'edit': return Icons.edit_note_rounded;
      case 'coffee': return Icons.coffee_rounded;
      case 'stretch': return Icons.self_improvement_rounded;
      case 'eye': return Icons.remove_red_eye_rounded;
      case 'water': return Icons.local_drink_rounded;
      case 'wrist': return Icons.pan_tool_rounded;
      default: return Icons.task_alt_rounded;
    }
  }

  static Color _mapColor(String name, {required bool dim}) {
    switch (name) {
      case 'accent': return dim ? AppTheme.accentDim : AppTheme.accent;
      case 'green': return dim ? AppTheme.greenDim : AppTheme.green;
      case 'amber': return dim ? AppTheme.amberDim : AppTheme.amber;
      case 'teal': return dim ? AppTheme.tealDim : AppTheme.teal;
      case 'pink': return dim ? AppTheme.pinkDim : AppTheme.pink;
      case 'purple': return dim ? AppTheme.purpleDim : AppTheme.purple;
      default: return dim ? AppTheme.accentDim : AppTheme.accent;
    }
  }

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