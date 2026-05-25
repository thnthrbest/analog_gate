import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../theme/app_theme.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  bool _testingMode = false;

  @override
  void initState() {
    super.initState();
    _checkTestingMode();
  }

  Future<void> _checkTestingMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _testingMode = prefs.getBool('testing_mode') ?? false;
    });
  }

  Future<void> _bypassForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accumulated_usage_seconds', 0);
    await prefs.remove('baseline_usage_seconds'); // Reset baseline for testing bypass too!
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppTheme.accent, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Time Limit Reached!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You must complete a mission in Analog Gate to unlock this app again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () async {
                  try {
                    const intent = AndroidIntent(
                      action: 'android.intent.action.MAIN',
                      package: 'com.example.analog_gate',
                      componentName: 'com.example.analog_gate.MainActivity',
                      category: 'android.intent.category.LAUNCHER',
                      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                    );
                    await intent.launch();
                  } catch (e) {
                    print('Could not launch app: $e');
                  }
                  
                  // Add a short delay to ensure the system processes the intent
                  // before we kill the overlay context.
                  await Future.delayed(const Duration(milliseconds: 500));
                  await FlutterOverlayWindow.closeOverlay();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go to Analog Gate',
                  style: TextStyle(
                    color: AppTheme.background,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_testingMode) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _bypassForTesting,
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.pink),
                  label: const Text(
                    'Bypass (Testing Only)',
                    style: TextStyle(color: AppTheme.pink, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.pink, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
