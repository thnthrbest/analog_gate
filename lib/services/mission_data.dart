import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MissionData {
  static final List<Mission> all = [
    // ── Outdoor ──────────────────────────────────────────────
    Mission(
      id: 'walk_outside',
      title: 'Take a short walk',
      description: 'Step outside for at least 5 minutes. Breathe.',
      photoPrompt: 'Take a photo of outdoors — sky, street, park, anything outside.',
      difficulty: MissionDifficulty.easy,
      category: MissionCategory.outdoor,
      xp: 30,
      aiLabels: ['sky','outdoor','nature','tree','plant','grass','road','building','street'],
      icon: Icons.directions_walk_rounded,
      iconColor: AppTheme.accent,
      iconBg: AppTheme.accentDim,
    ),
    Mission(
      id: 'find_tree',
      title: 'Find a tree or plant',
      description: 'Locate something green growing in the real world.',
      photoPrompt: 'Photo of a tree, shrub, flower, or any plant.',
      difficulty: MissionDifficulty.easy,
      category: MissionCategory.outdoor,
      xp: 20,
      aiLabels: ['tree','plant','flower','grass','vegetation','leaf','garden','forest'],
      icon: Icons.park_rounded,
      iconColor: AppTheme.green,
      iconBg: AppTheme.greenDim,
    ),
    Mission(
      id: 'sky_photo',
      title: 'Look up at the sky',
      description: 'Notice clouds, color, or light. Then photograph it.',
      photoPrompt: 'A photo showing the sky — clouds, sun, stars, or just blue.',
      difficulty: MissionDifficulty.easy,
      category: MissionCategory.outdoor,
      xp: 20,
      aiLabels: ['sky','cloud','atmosphere','daytime','sunset','sunrise','blue sky'],
      icon: Icons.wb_sunny_rounded,
      iconColor: AppTheme.amber,
      iconBg: AppTheme.amberDim,
    ),
    Mission(
      id: 'basketball',
      title: 'Play basketball',
      description: 'Shoot some hoops — at least 10 shots.',
      photoPrompt: 'A basketball, hoop, or court in the photo.',
      difficulty: MissionDifficulty.medium,
      category: MissionCategory.movement,
      xp: 50,
      aiLabels: ['basketball','sport','ball','court','hoop','sports equipment'],
      icon: Icons.sports_basketball_rounded,
      iconColor: AppTheme.amber,
      iconBg: AppTheme.amberDim,
    ),
    // ── Reading ───────────────────────────────────────────────
    Mission(
      id: 'open_book',
      title: 'Open a physical book',
      description: 'Real pages. Not a PDF. Spend at least 5 minutes.',
      photoPrompt: 'A photo of an open physical book showing the pages.',
      difficulty: MissionDifficulty.medium,
      category: MissionCategory.reading,
      xp: 50,
      aiLabels: ['book','text','publication','paper','library','paperback'],
      icon: Icons.menu_book_rounded,
      iconColor: AppTheme.amber,
      iconBg: AppTheme.amberDim,
    ),
    Mission(
      id: 'newspaper',
      title: 'Read a physical newspaper',
      description: 'Ink on paper. Notice how slow and satisfying it is.',
      photoPrompt: 'Photo of a printed newspaper or magazine.',
      difficulty: MissionDifficulty.medium,
      category: MissionCategory.reading,
      xp: 40,
      aiLabels: ['newspaper','magazine','publication','text','paper','news'],
      icon: Icons.article_rounded,
      iconColor: AppTheme.teal,
      iconBg: AppTheme.tealDim,
    ),
    // ── Creativity ────────────────────────────────────────────
    Mission(
      id: 'draw_something',
      title: 'Draw or doodle something',
      description: 'Pen and paper. No eraser required. 5 minutes.',
      photoPrompt: 'Photo of your drawing or doodle on paper.',
      difficulty: MissionDifficulty.medium,
      category: MissionCategory.creativity,
      xp: 40,
      aiLabels: ['drawing','sketch','art','paper','pen','pencil','handwriting'],
      icon: Icons.draw_rounded,
      iconColor: AppTheme.pink,
      iconBg: AppTheme.pinkDim,
    ),
    Mission(
      id: 'write_journal',
      title: 'Write 3 sentences in a journal',
      description: 'Handwritten. Any 3 sentences about your day or thoughts.',
      photoPrompt: 'Photo of your handwritten journal or notebook.',
      difficulty: MissionDifficulty.medium,
      category: MissionCategory.creativity,
      xp: 45,
      aiLabels: ['handwriting','notebook','paper','text','writing','journal'],
      icon: Icons.edit_note_rounded,
      iconColor: AppTheme.purple,
      iconBg: AppTheme.purpleDim,
    ),
    // ── Mindfulness ───────────────────────────────────────────
    Mission(
      id: 'make_tea',
      title: 'Make a cup of tea or coffee',
      description: 'The slow way. No instant. Notice the process.',
      photoPrompt: 'Photo of your cup of tea or coffee.',
      difficulty: MissionDifficulty.easy,
      category: MissionCategory.mindfulness,
      xp: 25,
      aiLabels: ['cup','coffee','tea','drink','mug','beverage'],
      icon: Icons.coffee_rounded,
      iconColor: AppTheme.amber,
      iconBg: AppTheme.amberDim,
    ),
    Mission(
      id: 'stretching',
      title: 'Do 5 minutes of stretching',
      description: 'Stand up, reach, breathe. Your body will thank you.',
      photoPrompt: 'Photo of your space — mat, floor, or open area.',
      difficulty: MissionDifficulty.easy,
      category: MissionCategory.movement,
      xp: 30,
      aiLabels: ['floor','mat','room','indoor','yoga mat','carpet'],
      icon: Icons.self_improvement_rounded,
      iconColor: AppTheme.teal,
      iconBg: AppTheme.tealDim,
    ),
  ];

  /// Pick 3 missions for today — deterministic by date so they don't change mid-day.
  static List<Mission> todaysMissions() {
    final seed = DateTime.now().day + DateTime.now().month * 31;
    final pool  = List<Mission>.from(all);
    for (int i = pool.length - 1; i > 0; i--) {
      final j = (seed * (i + 7)) % (i + 1);
      final t = pool[i]; pool[i] = pool[j]; pool[j] = t;
    }
    // Return fresh copies so completion state is per-session
    return pool.take(3).map((m) => Mission(
      id: m.id, title: m.title, description: m.description,
      photoPrompt: m.photoPrompt, difficulty: m.difficulty,
      category: m.category, xp: m.xp, aiLabels: m.aiLabels,
      icon: m.icon, iconColor: m.iconColor, iconBg: m.iconBg,
    )).toList();
  }
}

class AppData {
  static List<LockedApp> defaultApps = [
    LockedApp(
      id: 'instagram',
      name: 'Instagram Reels',
      packageName: 'com.instagram.android',
      icon: Icons.camera_alt_rounded,
      iconColor: AppTheme.purple,
      iconBg: AppTheme.purpleDim,
      requiredMissionIds: ['walk_outside', 'find_tree', 'sky_photo'],
      sessionMinutes: 30,
    ),
    LockedApp(
      id: 'youtube',
      name: 'YouTube Shorts',
      packageName: 'com.google.android.youtube',
      icon: Icons.play_circle_outline_rounded,
      iconColor: AppTheme.green,
      iconBg: AppTheme.greenDim,
      requiredMissionIds: ['open_book', 'newspaper'],
      sessionMinutes: 30,
    ),
    LockedApp(
      id: 'tiktok',
      name: 'TikTok',
      packageName: 'com.zhiliaoapp.musically',
      icon: Icons.music_note_rounded,
      iconColor: AppTheme.pink,
      iconBg: AppTheme.pinkDim,
      requiredMissionIds: ['basketball', 'stretching'],
      sessionMinutes: 20,
    ),
  ];
}