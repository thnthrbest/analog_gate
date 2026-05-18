import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'mission_data.dart';

class ProgressService {
  static final ProgressService _i = ProgressService._();
  factory ProgressService() => _i;
  ProgressService._();

  final _supabase = Supabase.instance.client;
  late SharedPreferences _prefs;

  int          _totalXp            = 0;
  int          _streak             = 0;
  List<String> _todayCompleted     = [];
  List<String> _todayUnlockedApps  = [];
  List<bool>   _weekHistory        = List.filled(7, false);

  int          get totalXp        => _totalXp;
  int          get streakDays     => _streak;
  List<String> get todayCompleted => _todayCompleted;
  List<String> get todayUnlocked  => _todayUnlockedApps;
  List<bool>   get weekHistory    => _weekHistory;

  bool isMissionDone(String id) => _todayCompleted.contains(id);
  bool isAppUnlocked(String id) => _todayUnlockedApps.contains(id);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromCache();
    
    // Non-blocking Supabase sync with timeout — app starts even if DB is unreachable
    try {
      await MissionData.loadFromSupabase().timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Mission load skipped (offline): $e');
    }
    try {
      await _syncFromSupabase().timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Progress sync skipped (offline): $e');
    }
  }

  Future<void> _syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (data == null) return;

      final profile = UserProfile.fromJson(data);
      
      _handleStreakLogic(profile);
      
      _totalXp = profile.totalXp;
      _todayCompleted = profile.todayCompleted;
      _todayUnlockedApps = profile.todayUnlocked;
      
      _saveToCache();
    } catch (e) {
      print('Sync Error: $e');
    }
  }

  void _handleStreakLogic(UserProfile profile) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    _streak = profile.currentStreak;
    _weekHistory = profile.weekHistory;

    if (profile.lastActiveDate != null) {
      final lastActive = DateTime(profile.lastActiveDate!.year, profile.lastActiveDate!.month, profile.lastActiveDate!.day);
      final difference = today.difference(lastActive).inDays;

      if (difference == 1) {
        // Logged in consecutive day! Streak maintained (it will increase when they complete a mission)
      } else if (difference > 1) {
        // Streak broken
        _streak = 0;
        _weekHistory = List.filled(7, false);
      } else if (difference == 0) {
        // Already active today, do nothing to streak
      }
    }
  }

  Future<bool> completeMission(String missionKey, int xp) async {
    if (_todayCompleted.contains(missionKey)) return true; // Already done

    _todayCompleted = [..._todayCompleted, missionKey];
    _totalXp += xp;
    
    // Update streak history for today
    final dayOfWeek = DateTime.now().weekday % 7; // Sunday=0, Monday=1...
    _weekHistory[dayOfWeek] = true;
    
    // Check if it's their first mission today to increment streak
    if (_todayCompleted.length == 1) {
      _streak += 1;
    }

    _saveToCache();
    await _saveToSupabase();
    return true;
  }

  Future<void> unlockApp(String appId) async {
    if (!_todayUnlockedApps.contains(appId)) {
      _todayUnlockedApps = [..._todayUnlockedApps, appId];
      _saveToCache();
      await _saveToSupabase();
    }
  }

  Future<void> _saveToSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'total_xp': _totalXp,
        'current_streak': _streak,
        'last_active_date': "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}",
        'today_completed': _todayCompleted,
        'today_unlocked': _todayUnlockedApps,
        'week_history': _weekHistory,
        'updated_at': now.toUtc().toIso8601String(),
      });
    } catch (e) {
      print('Save Error: $e');
    }
  }

  void _loadFromCache() {
    _totalXp = _prefs.getInt('xp') ?? 0;
    _streak  = _prefs.getInt('streak') ?? 0;
    final c = _prefs.getString('completed_$_todayKey');
    final u = _prefs.getString('unlocked_$_todayKey');
    final w = _prefs.getString('week_history');
    
    _todayCompleted    = c != null ? List<String>.from(jsonDecode(c)) : [];
    _todayUnlockedApps = u != null ? List<String>.from(jsonDecode(u)) : [];
    _weekHistory       = w != null ? List<bool>.from(jsonDecode(w)) : List.filled(7, false);
  }

  void _saveToCache() {
    _prefs.setInt('xp', _totalXp);
    _prefs.setInt('streak', _streak);
    _prefs.setString('completed_$_todayKey', jsonEncode(_todayCompleted));
    _prefs.setString('unlocked_$_todayKey',  jsonEncode(_todayUnlockedApps));
    _prefs.setString('week_history',         jsonEncode(_weekHistory));
  }

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }
}