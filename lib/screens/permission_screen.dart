import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/app_monitor_service.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const PermissionScreen({super.key, required this.onComplete});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _cameraGranted = false;
  bool _overlayGranted = false;
  bool _usageGranted = false; // We can't check this programmatically, user confirms manually

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    bool overlayStatus = false;
    try {
      overlayStatus = await _checkOverlayPermission();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _cameraGranted = cameraStatus.isGranted;
        _overlayGranted = overlayStatus;
      });
    }
  }

  Future<bool> _checkOverlayPermission() async {
    try {
      final result = await Permission.systemAlertWindow.status;
      return result.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    setState(() => _cameraGranted = status.isGranted);
  }

  Future<void> _requestOverlay() async {
    await AppMonitorService().requestPermissions();
    // Check again after user returns
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  Future<void> _requestUsageAccess() async {
    // Open Usage Access settings page
    await openAppSettings();
    // We assume user granted it if they clicked
    setState(() => _usageGranted = true);
  }

  bool get _allGranted => _cameraGranted && _overlayGranted && _usageGranted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Header
              const Icon(Icons.shield_rounded, color: AppTheme.accent, size: 48)
                  .animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),
              const SizedBox(height: 20),
              const Text(
                'App Permissions',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              const Text(
                'Analog Gate needs these permissions to block apps and verify your missions with the camera.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),

              // Permission Cards
              Expanded(
                child: ListView(
                  children: [
                    _PermissionCard(
                      icon: Icons.camera_alt_rounded,
                      iconColor: AppTheme.green,
                      title: 'Camera Access',
                      description: 'Required to take photos for mission verification with Gemini AI.',
                      isGranted: _cameraGranted,
                      onRequest: _requestCamera,
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    _PermissionCard(
                      icon: Icons.layers_rounded,
                      iconColor: AppTheme.amber,
                      title: 'Display Over Other Apps',
                      description: 'Required to show the blocking overlay when your screen time limit is reached.',
                      isGranted: _overlayGranted,
                      onRequest: _requestOverlay,
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    _PermissionCard(
                      icon: Icons.bar_chart_rounded,
                      iconColor: AppTheme.purple,
                      title: 'Usage Access',
                      description: 'Required to track how long you use YouTube, TikTok, etc. Go to Settings → Apps → Special Access → Usage Access.',
                      isGranted: _usageGranted,
                      onRequest: _requestUsageAccess,
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                  ],
                ),
              ),

              // Bottom Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onComplete, // Always allow proceeding
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allGranted ? AppTheme.accent : AppTheme.surfaceHigh,
                    foregroundColor: _allGranted ? AppTheme.background : AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: _allGranted ? AppTheme.accent : AppTheme.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    _allGranted ? 'All Set! Continue →' : 'Skip for Now →',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 8),
              if (!_allGranted)
                const Text(
                  'You can grant permissions later in Settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onRequest;

  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted ? AppTheme.green.withOpacity(0.4) : AppTheme.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                )),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Status / Button
          if (isGranted)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.greenDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppTheme.green, size: 18),
            )
          else
            TextButton(
              onPressed: onRequest,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.accentDim,
                foregroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Grant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
