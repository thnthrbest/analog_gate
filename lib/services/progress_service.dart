import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProgressService {
  static final ProgressService _i = ProgressService._();
  factory ProgressService() => _i;
  ProgressService._();

  late SharedPreferences _p;

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    await _checkStreak();
  }

  // ── Keys ────────────────────────────────────────────────────
  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }
  String get _completedKey => 'completed_$_today';
  String get _unlockedKey  => 'unlocked_$_today';

  // ── Getters ─────────────────────────────────────────────────
  int get totalXp    => _p.getInt('total_xp') ?? 0;
  int get streakDays => _p.getInt('streak') ?? 0;

  List<String> get todayCompleted {
    final s = _p.getString(_completedKey);
    return s == null ? [] : List<String>.from(jsonDecode(s));
  }

  List<String> get todayUnlocked {
    final s = _p.getString(_unlockedKey);
    return s == null ? [] : List<String>.from(jsonDecode(s));
  }

  bool isMissionDone(String id)  => todayCompleted.contains(id);
  bool isAppUnlocked(String id)  => todayUnlocked.contains(id);

  // ── Mutations ────────────────────────────────────────────────
  Future<void> completeMission(String id, int xp) async {
    final list = todayCompleted;
    if (list.contains(id)) return;
    list.add(id);
    await _p.setString(_completedKey, jsonEncode(list));
    await _p.setInt('total_xp', totalXp + xp);
    await _p.setString('last_date', _today);

    // First completion of the day → bump streak
    if (list.length == 1) await _p.setInt('streak', streakDays + 1);
  }

  Future<void> unlockApp(String id) async {
    final list = todayUnlocked;
    if (list.contains(id)) return;
    list.add(id);
    await _p.setString(_unlockedKey, jsonEncode(list));
  }

  Future<bool> spendXp(int amount) async {
    if (totalXp < amount) return false;
    await _p.setInt('total_xp', totalXp - amount);
    return true;
  }

  /// Reset streak if the user missed a day.
  Future<void> _checkStreak() async {
    final last = _p.getString('last_date');
    if (last == null) return;
    final diff = DateTime.now().difference(DateTime.parse(last)).inDays;
    if (diff > 1) await _p.setInt('streak', 0);
  }

  /// Last 7 days — true = had at least 1 mission that day.
  List<bool> get weekHistory => List.generate(7, (i) {
    final d = DateTime.now().subtract(Duration(days: 6 - i));
    final key = 'completed_${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    final s = _p.getString(key);
    return s != null && (jsonDecode(s) as List).isNotEmpty;
  });
}