import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

/// ProgressService ใหม่ — sync ข้อมูลกับ backend
/// ถ้า API ล้มเหลวจะ fallback ไปใช้ local cache
class ProgressService {
  static final ProgressService _i = ProgressService._();
  factory ProgressService() => _i;
  ProgressService._();

  final _api = ApiService();
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
    await _syncFromApi();
  }

  Future<void> _syncFromApi() async {
    try {
      await _api.registerUser();
      final data = await _api.getProgress();
      _totalXp           = data.totalXp;
      _streak            = data.streak;
      _todayCompleted    = data.todayCompleted;
      _todayUnlockedApps = data.todayUnlockedApps;
      _weekHistory       = data.weekHistory;
      _saveToCache();
    } catch (_) {}
  }

  Future<bool> completeMission(String missionKey, int xp) async {
    if (!_todayCompleted.contains(missionKey)) {
      _todayCompleted = [..._todayCompleted, missionKey];
      _totalXp += xp;
    }
    _saveToCache();
    try {
      final result = await _api.completeMission(
        missionKey: missionKey,
        verified: true,
      );
      _totalXp = result.totalXp;
      _streak  = result.streak;
      _saveToCache();
      return result.success;
    } catch (_) {
      return true;
    }
  }

  Future<void> unlockApp(String appId) async {
    if (!_todayUnlockedApps.contains(appId)) {
      _todayUnlockedApps = [..._todayUnlockedApps, appId];
    }
    _saveToCache();
    try {
      await _api.unlockApp(appId);
    } catch (_) {}
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