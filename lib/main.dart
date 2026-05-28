import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/progress_service.dart';
import 'services/gemini_verification_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/login_screen.dart';
import 'screens/overlay_screen.dart';
import 'screens/permission_screen.dart';
import 'providers/auth_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // optional, but keep existing
import 'package:permission_handler/permission_handler.dart';
import 'services/app_monitor_service.dart';
import 'services/notification_service.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayScreen(),
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set dark system UI overlay
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Supabase URL: Pointing to the new VPS server
  const supabaseUrl = 'http://187.77.157.222:8000';

  // Init Supabase (with timeout so app doesn't hang if Supabase is offline)
  bool supabaseReady = false;
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
    ).timeout(const Duration(seconds: 8));
    supabaseReady = true;
    print('Supabase connected successfully!');
  } catch (e) {
    print('Supabase init failed (offline mode): $e');
  }

  // Init services
  GeminiVerificationService().init();
  await NotificationService().init();
  if (supabaseReady) {
    await ProgressService().init();
  }
  await AppMonitorService().initBackgroundService();

  runApp(ProviderScope(child: AnalogGateApp(supabaseReady: supabaseReady)));
}

class AnalogGateApp extends ConsumerWidget {
  final bool supabaseReady;
  const AnalogGateApp({super.key, this.supabaseReady = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If Supabase is not available, go straight to HomeScreen (offline mode)
    if (!supabaseReady) {
      return MaterialApp(
        title: 'Analog Gate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _RootShell(),
      );
    }

    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Analog Gate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: authState.when(
        data: (state) {
          if (state.session != null) {
            return const _RootShell();
          } else {
            return const LoginScreen();
          }
        },
        loading: () => const Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        ),
        error: (error, _) => const LoginScreen(),
      ),
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _currentIndex = 0;
  bool _permissionsChecked = false;
  bool _showPermissionScreen = false;

  @override
  void initState() {
    super.initState();
    _checkIfPermissionsSeen();
  }


  Future<void> _checkIfPermissionsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check actual active permissions
    final cameraStatus = await Permission.camera.status;
    final notificationStatus = await Permission.notification.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    final overlayStatus = await Permission.systemAlertWindow.status;
    
    final allGranted = cameraStatus.isGranted && 
                       notificationStatus.isGranted && 
                       batteryStatus.isGranted && 
                       overlayStatus.isGranted;

    final seen = prefs.getBool('permissions_seen') ?? false;
    
    if (mounted) {
      setState(() {
        _permissionsChecked = true;
        // Decouple from allGranted: Only show onboarding if they've never completed or skipped it.
        _showPermissionScreen = !seen;
      });
    }
    // Decouple service start: start monitoring if seen is true, even if some custom ROM statuses report false
    if (seen) {
      AppMonitorService().startMonitoring();
    }
  }

  Future<void> _onPermissionsDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_seen', true);
    if (mounted) {
      setState(() => _showPermissionScreen = false);
    }
    AppMonitorService().startMonitoring();
  }

  static const _screens = [
    HomeScreen(),
    ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_permissionsChecked) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    if (_showPermissionScreen) {
      return PermissionScreen(onComplete: _onPermissionsDone);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Progress',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppTheme.accent : AppTheme.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.accent : AppTheme.textMuted,
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}