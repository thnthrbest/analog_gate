import 'dart:async';
import 'dart:ui';
import 'package:app_usage/app_usage.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'mission_data.dart';
import '../models/models.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  if (service is AndroidServiceInstance) {
    // Promote the service to a foreground service immediately to prevent OS from suspending/killing it
    service.setAsForegroundService();

    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Run the monitoring loop in the background isolate
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    await AppMonitorService()._checkUsageAndBlock();
  });
}

class AppMonitorService {
  static final AppMonitorService _i = AppMonitorService._();
  factory AppMonitorService() => _i;
  AppMonitorService._();

  bool _isMonitoring = false;
  DateTime? _lastCheckTime;
  String? _lastActiveForegroundApp;

  Future<void> requestPermissions() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  Future<void> initBackgroundService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'analog_gate_progress',
        initialNotificationTitle: 'Analog Gate',
        initialNotificationContent: 'Monitoring screen time',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
    );
  }

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    final service = FlutterBackgroundService();
    service.startService();
    
    print('🔍 App Monitor background service started!');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    NotificationService().cancelProgressNotification();
    print('App Monitor background service stopped.');
  }

  String _formatDuration(int seconds, bool testingMode) {
    if (testingMode) {
      return '${seconds}s';
    }
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '${mins}m ${secs}s';
    }
    return '${secs}s';
  }

  Future<void> _checkUsageAndBlock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Force reload to get latest values from other processes
      
      // 1. Get blocked packages
      final List<String> blockedPackages = prefs.getStringList('blocked_packages') ?? [];
      if (blockedPackages.isEmpty) {
        await NotificationService().cancelProgressNotification();
        return;
      }

      // 2. Get active mission limit
      final String? activeMissionId = prefs.getString('active_mission_id');
      if (activeMissionId == null || activeMissionId.isEmpty) {
        await NotificationService().cancelProgressNotification();
        return;
      }

      // Find the mission from MissionData
      final mission = MissionData.all.firstWhere(
        (m) => m.id == activeMissionId,
        orElse: () => MissionData.all.first,
      );
      final difficulty = mission.difficulty;

      // 3. Get testing mode
      final bool testingMode = prefs.getBool('testing_mode') ?? false;

      // Calculate time limit in seconds
      int limitSeconds;
      if (testingMode) {
        limitSeconds = switch (difficulty) {
          MissionDifficulty.easy => 15,
          MissionDifficulty.medium => 30,
          MissionDifficulty.hard => 45,
        };
      } else {
        limitSeconds = switch (difficulty) {
          MissionDifficulty.easy => 10 * 60,
          MissionDifficulty.medium => 20 * 60,
          MissionDifficulty.hard => 30 * 60,
        };
      }

      int currentAccumulated = prefs.getInt('accumulated_usage_seconds') ?? 0;
      bool alreadyExceeded = currentAccumulated >= limitSeconds;

      // 4. Check usage and active foreground app
      final now = DateTime.now();
      
      // Determine if a blocked app is active using real-time UsageEvents!
      bool isAnyBlockedAppActive = false;
      try {
        final eventStart = now.subtract(const Duration(seconds: 15));
        final List<EventUsageInfo> events = await UsageStats.queryEvents(eventStart, now);
        
        String? detectedApp;
        if (events.isNotEmpty) {
          // Sort events chronologically by timestamp
          events.sort((a, b) => int.parse(a.timeStamp!).compareTo(int.parse(b.timeStamp!)));
          
          // Traverse backwards from latest to oldest
          for (int i = events.length - 1; i >= 0; i--) {
            final e = events[i];
            if (e.packageName == null) continue;
            
            if (e.eventType == '1') { // MOVE_TO_FOREGROUND / RESUMED
              detectedApp = e.packageName;
              break;
            } else if (e.eventType == '2') { // MOVE_TO_BACKGROUND / PAUSED
              // If the latest event is putting the current app to background, we clear it
              if (_lastActiveForegroundApp == e.packageName) {
                _lastActiveForegroundApp = null;
              }
            }
          }
        }
        
        if (detectedApp != null) {
          _lastActiveForegroundApp = detectedApp;
        } else {
          // Fallback: If no event in the last 15s, query usage stats for the last 30s
          final statsStart = now.subtract(const Duration(seconds: 30));
          final List<UsageInfo> stats = await UsageStats.queryUsageStats(statsStart, now);
          if (stats.isNotEmpty) {
            stats.sort((a, b) {
              final aTime = int.tryParse(a.lastTimeUsed ?? '0') ?? 0;
              final bTime = int.tryParse(b.lastTimeUsed ?? '0') ?? 0;
              return bTime.compareTo(aTime);
            });
            final latest = stats.first;
            final latestTime = int.tryParse(latest.lastTimeUsed ?? '0') ?? 0;
            // If the latest app was used within the last 12 seconds
            if (now.millisecondsSinceEpoch - latestTime < 12000) {
              _lastActiveForegroundApp = latest.packageName;
            }
          }
        }
        
        if (_lastActiveForegroundApp != null) {
          print('📱 DETECTED FOREGROUND APP: $_lastActiveForegroundApp');
        }
      } catch (e) {
        print('⚠️ Failed to query real-time events/stats: $e');
      }

      // Evaluate the currently active app context
      if (_lastActiveForegroundApp != null) {
        final pkg = _lastActiveForegroundApp!;
        final isSelf = pkg == 'com.example.analog_gate';
        final isSystem = pkg == 'com.android.systemui' || pkg == 'com.android.settings';
        final isLauncher = pkg.contains('launcher') || pkg.contains('trebuchet') || pkg.contains('sec.android.app.launcher') || pkg.contains('home') || pkg == 'android';
        
        if (!isSelf && !isSystem && !isLauncher) {
          isAnyBlockedAppActive = _isPackageBlocked(pkg, blockedPackages);
          if (isAnyBlockedAppActive) {
            print('📱 REALTIME CONFIRMED: User is actively in blocked app: $pkg');
          }
        }
      }

      int elapsedSeconds = 5;
      if (_lastCheckTime != null) {
        elapsedSeconds = now.difference(_lastCheckTime!).inSeconds;
        if (elapsedSeconds > 15) elapsedSeconds = 5;
      }
      _lastCheckTime = now;

      // Query historical totals to perform background sync when needed
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month, endDate.day);
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startDate, endDate);

      // Calculate TRUE accumulated time from Android UsageStats
      int currentTotalUsage = 0;
      for (var info in infoList) {
        if (blockedPackages.contains(info.packageName)) {
          currentTotalUsage += info.usage.inSeconds;
        }
      }

      int? baseline = prefs.getInt('baseline_usage_seconds');
      if (baseline == null) {
        baseline = currentTotalUsage - currentAccumulated;
        await prefs.setInt('baseline_usage_seconds', baseline);
      }

      int trueAccumulated = currentTotalUsage - baseline;
      if (trueAccumulated < 0) trueAccumulated = 0;

      // Hybrid real-time tracking logic:
      if (isAnyBlockedAppActive) {
        currentAccumulated += elapsedSeconds; // Smooth real-time increment
      }

      // Sync manual counter with true OS-reported usage
      if (trueAccumulated > currentAccumulated) {
        // We missed time (e.g., service was killed). Sync up immediately!
        currentAccumulated = trueAccumulated;
      } else if (!isAnyBlockedAppActive && (currentAccumulated - trueAccumulated > 15)) {
        // We over-counted (e.g., screen was locked while app was open). Sync down!
        currentAccumulated = trueAccumulated;
      }

      await prefs.setInt('accumulated_usage_seconds', currentAccumulated);

      if (isAnyBlockedAppActive) {
        print('⏳ Accumulated usage: ${currentAccumulated}s / ${limitSeconds}s limit');

        // Check if exceeded limit
        if (currentAccumulated >= limitSeconds) {
          print('🚫 LIMIT EXCEEDED! Triggering overlay blocking.');
          await _showBlockOverlay("Active Mission: ${mission.title}");
          
          if (!alreadyExceeded) {
            // First time exceeding! Send notification
            await NotificationService().showLimitExceededNotification(
              missionTitle: mission.title,
            );
          }
        }
      } else {
        // If the user is no longer in a blocked app (e.g., they pressed Home),
        // we should automatically hide the overlay so they can use their phone!
        try {
          if (await FlutterOverlayWindow.isActive()) {
            await FlutterOverlayWindow.closeOverlay();
            print('✅ User exited blocked app. Hiding overlay.');
          }
        } catch (e) {
          // Ignore
        }
      }

      // Update progress bar notification
      if (currentAccumulated < limitSeconds) {
        final timeUsedStr = _formatDuration(currentAccumulated, testingMode);
        final timeLimitStr = _formatDuration(limitSeconds, testingMode);
        await NotificationService().showProgressNotification(
          title: '⏳ Track Screen Time: ${mission.title}',
          body: '$timeUsedStr / $timeLimitStr used',
          progress: currentAccumulated,
          maxProgress: limitSeconds,
        );
      } else {
        await NotificationService().cancelProgressNotification();
      }
    } catch (e) {
      print('⚠️ Usage check failed: $e');
    }
  }

  Future<void> _showBlockOverlay(String reason) async {
    try {
      final bool isActive = await FlutterOverlayWindow.isActive();
      if (!isActive) {
        if (await FlutterOverlayWindow.isPermissionGranted()) {
          await FlutterOverlayWindow.showOverlay(
            enableDrag: false,
            flag: OverlayFlag.defaultFlag,
            alignment: OverlayAlignment.center,
            visibility: NotificationVisibility.visibilityPublic,
            positionGravity: PositionGravity.auto,
            height: WindowSize.fullCover,
            width: WindowSize.matchParent,
          );
        } else {
          print('⚠️ Overlay permission not granted. Cannot show block overlay.');
        }
      }
    } catch (e) {
      // Android 14+ throws ForegroundServiceStartNotAllowedException when
      // the app is in the background and doesn't hold the required permission.
      // We catch this so the app does not crash — the overlay simply won't show.
      print('⚠️ Could not show overlay (background restriction): $e');
    }
  }

  bool _isPackageBlocked(String packageName, List<String> blockedPackages) {
    for (var blocked in blockedPackages) {
      if (blocked == packageName) return true;
      
      // YouTube variant mapping
      if (blocked == 'com.google.android.youtube') {
        if (packageName == 'com.google.android.youtube' ||
            packageName == 'com.google.android.apps.youtube.lite' ||
            packageName == 'com.vanced.android.youtube' ||
            packageName == 'app.revanced.android.youtube') {
          return true;
        }
      }
      
      // TikTok variant mapping
      if (blocked == 'com.zhiliaoapp.musically' || blocked == 'com.ss.android.ugc.trill') {
        if (packageName == 'com.zhiliaoapp.musically' ||
            packageName == 'com.ss.android.ugc.aweme' ||
            packageName == 'com.zhiliaoapp.musically.go' ||
            packageName == 'com.ss.android.ugc.aweme.lite' ||
            packageName == 'com.ss.android.ugc.trill' ||
            packageName == 'com.ss.android.ugc.trill.lite') {
          return true;
        }
      }
    }
    return false;
  }
}
