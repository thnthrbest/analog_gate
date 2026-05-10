import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── Base URL ────────────────────────────────────────────────
  // Android emulator → 10.0.2.2 แทน localhost
  // iOS simulator    → localhost
  // Device จริง      → IP ของเครื่อง dev เช่น 192.168.1.x
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://localhost:8000/api/v1';
  }

  static final ApiService _i = ApiService._();
  factory ApiService() => _i;
  ApiService._();

  final _client = http.Client();

  // ── Headers ─────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Device ID (ใช้เป็น user identifier) ─────────────────────
  Future<String> get deviceId async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      id = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('device_id', id);
    }
    return id;
  }

  // ── Register / get user ──────────────────────────────────────
  Future<void> registerUser() async {
    final id = await deviceId;
    await _post('/users', {'device_id': id});
  }

  // ── Get progress ─────────────────────────────────────────────
  Future<ProgressData> getProgress() async {
    final id   = await deviceId;
    final json = await _get('/progress/$id');
    return ProgressData.fromJson(json);
  }

  // ── Complete mission ─────────────────────────────────────────
  Future<CompleteMissionResult> completeMission({
    required String missionKey,
    bool verified = false,
  }) async {
    final id   = await deviceId;
    final json = await _post('/missions/complete', {
      'device_id':   id,
      'mission_key': missionKey,
      'verified':    verified,
    });
    return CompleteMissionResult.fromJson(json);
  }

  // ── Unlock app ───────────────────────────────────────────────
  Future<UnlockAppResult> unlockApp(String appId) async {
    final id   = await deviceId;
    final json = await _post('/apps/unlock', {
      'device_id': id,
      'app_id':    appId,
    });
    return UnlockAppResult.fromJson(json);
  }

  // ── HTTP helpers ─────────────────────────────────────────────
  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _client
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    return _handleResponse(res);
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(
        statusCode: res.statusCode,
        message: json['detail']?.toString() ?? 'Unknown error',
      );
    }
    return json;
  }
}

// ── Response models ───────────────────────────────────────────
class ProgressData {
  final int        totalXp;
  final int        streak;
  final List<String> todayCompleted;
  final List<String> todayUnlockedApps;
  final List<bool>   weekHistory;

  const ProgressData({
    required this.totalXp,
    required this.streak,
    required this.todayCompleted,
    required this.todayUnlockedApps,
    required this.weekHistory,
  });

  factory ProgressData.fromJson(Map<String, dynamic> j) => ProgressData(
    totalXp           : j['total_xp'] as int,
    streak            : j['streak'] as int,
    todayCompleted    : List<String>.from(j['today_completed'] ?? []),
    todayUnlockedApps : List<String>.from(j['today_unlocked_apps'] ?? []),
    weekHistory       : List<bool>.from(j['week_history'] ?? []),
  );
}

class CompleteMissionResult {
  final bool   success;
  final int    xpEarned;
  final int    totalXp;
  final int    streak;
  final String message;

  const CompleteMissionResult({
    required this.success,
    required this.xpEarned,
    required this.totalXp,
    required this.streak,
    required this.message,
  });

  factory CompleteMissionResult.fromJson(Map<String, dynamic> j) =>
      CompleteMissionResult(
        success  : j['success'] as bool,
        xpEarned : j['xp_earned'] as int,
        totalXp  : j['total_xp'] as int,
        streak   : j['streak'] as int,
        message  : j['message'] as String,
      );
}

class UnlockAppResult {
  final bool      success;
  final DateTime? expiresAt;
  final String    message;

  const UnlockAppResult({
    required this.success,
    required this.expiresAt,
    required this.message,
  });

  factory UnlockAppResult.fromJson(Map<String, dynamic> j) => UnlockAppResult(
    success  : j['success'] as bool,
    expiresAt: j['expires_at'] != null
        ? DateTime.parse(j['expires_at'] as String)
        : null,
    message  : j['message'] as String,
  );
}

class ApiException implements Exception {
  final int    statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}