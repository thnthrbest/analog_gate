import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Create the required notification channels explicitly so they are
    // available immediately when starting the background foreground service.
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidImplementation != null) {
      // 1. Progress tracking channel (Low importance for foreground service)
      const AndroidNotificationChannel progressChannel = AndroidNotificationChannel(
        'analog_gate_progress',
        'Screen Time Progress',
        description: 'Real-time screen time progress for active mission',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );
      await androidImplementation.createNotificationChannel(progressChannel);

      // 2. Limit alerts channel (High importance for screen block notification)
      const AndroidNotificationChannel limitChannel = AndroidNotificationChannel(
        'analog_gate_limit',
        'App Limit Exceeded',
        description: 'Notifications shown when app usage limits are exceeded',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidImplementation.createNotificationChannel(limitChannel);
    }
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> showLimitExceededNotification({required String missionTitle}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'analog_gate_limit',
      'App Limit Exceeded',
      channelDescription: 'Notifications shown when app usage limits are exceeded',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      999, // Unique ID
      '⏳ Screen Time Limit Reached!',
      'Complete active mission "$missionTitle" to unlock your apps.',
      platformChannelSpecifics,
    );
  }

  Future<void> showProgressNotification({
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'analog_gate_progress',
      'Screen Time Progress',
      channelDescription: 'Real-time screen time progress for active mission',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      ongoing: true,
      onlyAlertOnce: true,
      showWhen: false,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      888, // Unique ID for progress tracking
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> cancelProgressNotification() async {
    await _localNotificationsPlugin.cancel(888);
  }
}
