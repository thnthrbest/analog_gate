import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MissionData {
  // Static cache of all missions. Defaults to hardcoded offline fallback list.
  static List<Mission> all = _fallbackList;

  /// Fetches missions from Supabase and updates the cache.
  static Future<void> loadFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('missions').select();
      
      if (response.isNotEmpty) {
        final List<Mission> loadedMissions = response
            .map<Mission>((json) => Mission.fromJson(json))
            .toList();
        
        all = loadedMissions;
        print('Successfully loaded ${all.length} missions from Supabase!');
      }
    } catch (e) {
      print('Failed to load missions from Supabase, using fallback: $e');
    }
  }

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

  // ── Hardcoded Offline Fallback List ───────────────────────────
  static final List<Mission> _fallbackList = [
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
  ];
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
      requiredMissionIds: ['open_book', 'eye_break_20'],
      sessionMinutes: 30,
    ),
    LockedApp(
      id: 'tiktok',
      name: 'TikTok',
      packageName: 'com.zhiliaoapp.musically',
      icon: Icons.music_note_rounded,
      iconColor: AppTheme.pink,
      iconBg: AppTheme.pinkDim,
      requiredMissionIds: ['basketball', 'posture_stretch'],
      sessionMinutes: 20,
    ),
  ];
}