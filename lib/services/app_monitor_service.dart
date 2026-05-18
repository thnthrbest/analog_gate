import 'dart:async';
import 'dart:math';
import 'package:app_usage/app_usage.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class AppMonitorService {
  static final AppMonitorService _i = AppMonitorService._();
  factory AppMonitorService() => _i;
  AppMonitorService._();

  Timer? _timer;
  bool _isMonitoring = false;

  // The packages we want to block (e.g., YouTube, TikTok)
  final List<String> _targetPackages = [
    'com.google.android.youtube',
    'com.zhiliaoapp.musically', // TikTok
  ];

  // --- Medical & Screen-Addiction Parameters ---
  final bool _testingMode = true; // ⚡ TESTING: Triggers after 10 seconds!

  // 1. Daily accumulated usage limit (in minutes)
  final int _dailyMaxLimitMinutes = 30;

  // 2. 20-20-20 Eye Strain Rule (Continuous SECONDS in test mode)
  int get _continuousEyeLimitSeconds => _testingMode ? 10 : 20 * 60;

  // 3. Posture Fatigue Break
  int get _continuousPostureLimitSeconds => _testingMode ? 30 : 45 * 60;

  // 4. Dopamine Habit Loop Breaker
  int get _habitBreakerTriggerSeconds => _testingMode ? 8 : 15 * 60;
  final double _randomTriggerChance = 1.0; // 100% in test mode for guaranteed trigger

  // Trackers for continuous usage (in seconds)
  final Map<String, int> _continuousSeconds = {};
  final Map<String, int> _lastUsageMinutes = {};

  Future<void> requestPermissions() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    // Poll every 5 seconds for fast detection in test mode
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkUsageAndBlock();
    });
    
    // Also check immediately on start
    _checkUsageAndBlock();
    print('🔍 App Monitor started! Watching: $_targetPackages');
  }

  void stopMonitoring() {
    _timer?.cancel();
    _isMonitoring = false;
    print('App Monitor stopped.');
  }

  Future<void> _checkUsageAndBlock() async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startDate, endDate);

      for (var info in infoList) {
        final pkg = info.packageName;
        if (!_targetPackages.contains(pkg)) continue;

        final currentDailyUsageSeconds = info.usage.inSeconds;
        final lastUsage = _lastUsageMinutes[pkg] ?? 0;

        // Determine if the app was actively used since last poll
        if (currentDailyUsageSeconds > lastUsage) {
          // App is actively being used
          _continuousSeconds[pkg] = (_continuousSeconds[pkg] ?? 0) + 5;
          _lastUsageMinutes[pkg] = currentDailyUsageSeconds;
          print('📱 $pkg active for ${_continuousSeconds[pkg]}s (trigger at ${_continuousEyeLimitSeconds}s)');
        } else {
          // App not in use, reset continuous timer
          if ((_continuousSeconds[pkg] ?? 0) > 0) {
            print('📱 $pkg went to background, resetting timer');
          }
          _continuousSeconds[pkg] = 0;
        }

        final continuousSec = _continuousSeconds[pkg] ?? 0;

        // Check blocking criteria:
        bool shouldBlock = false;
        String reason = "";

        // 1. Daily accumulated usage limit
        if (currentDailyUsageSeconds >= _dailyMaxLimitMinutes * 60) {
          shouldBlock = true;
          reason = "Daily limit of $_dailyMaxLimitMinutes mins reached!";
        }
        // 2. 20-20-20 Rule (Eye Strain) — triggers at 10s in test mode
        else if (continuousSec >= _continuousEyeLimitSeconds) {
          shouldBlock = true;
          reason = "Eye strain warning! Follow the 20-20-20 rule.";
        }
        // 3. Posture Fatigue Stretch
        else if (continuousSec >= _continuousPostureLimitSeconds) {
          shouldBlock = true;
          reason = "Screen fatigue! Take a posture correction stretch.";
        }
        // 4. Dopamine Habit Loop Breaker
        else if (continuousSec >= _habitBreakerTriggerSeconds) {
          final randomValue = Random().nextDouble();
          if (randomValue < _randomTriggerChance) {
            shouldBlock = true;
            reason = "Mindless scrolling detected! Break the habit loop.";
          }
        }

        if (shouldBlock) {
          print('🚫 BLOCKING $pkg: $reason');
          _continuousSeconds[pkg] = 0; // Reset so it doesn't instantly re-trigger
          await _showBlockOverlay(reason);
          break;
        }
      }
    } catch (e) {
      print('⚠️ Usage check failed: $e');
    }
  }

  Future<void> _showBlockOverlay(String reason) async {
    final bool isActive = await FlutterOverlayWindow.isActive();
    if (!isActive) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
      );
    }
  }
}
