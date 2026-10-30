import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
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
    // Force immersive mode in overlay window context to hide bottom navigation bar gaps
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.black,
    ));
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
      color: Colors.black, // Fully opaque pitch black background
      child: SizedBox.expand(
        child: Container(
          color: Colors.black,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Glowing Lock Icon Block
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppTheme.accentDim.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentDim,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: AppTheme.accent,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Premium Central Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.border,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Time Limit Reached!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You have reached your daily digital screen limit for this app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14, height: 1.4),
                            children: [
                              TextSpan(
                                text: 'You must complete an active ',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              TextSpan(
                                text: 'Analog Gate Mission',
                                style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: ' in the physical world to unlock access.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Launch App Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
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
                      icon: const Icon(Icons.flash_on_rounded, size: 20),
                      label: const Text('Go to Analog Gate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  
                  // Testing Bypass Option
                  if (_testingMode) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _bypassForTesting,
                        icon: const Icon(Icons.refresh_rounded, color: AppTheme.pink),
                        label: const Text('Bypass (Testing Only)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.pink,
                          side: const BorderSide(color: AppTheme.pink, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
