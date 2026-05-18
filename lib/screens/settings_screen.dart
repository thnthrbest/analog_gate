import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../services/app_monitor_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  bool _isSavingName = false;

  Future<void> _updateAvatar() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 800,
      imageQuality: 80,
    );
    
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    final profileService = ref.read(profileServiceProvider);
    await profileService.uploadAvatar(File(pickedFile.path));
    
    // Refresh profile state
    ref.invalidate(profileProvider);
    setState(() => _isUploading = false);
  }

  Future<void> _updateUsername(String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Edit Username', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.border)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      setState(() => _isSavingName = true);
      await ref.read(profileServiceProvider).updateUsername(newName);
      ref.invalidate(profileProvider);
      setState(() => _isSavingName = false);
    }
  }

  Future<void> _requestPermissions() async {
    await AppMonitorService().requestPermissions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Requested app blocking permissions')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar Section
              Center(
                child: GestureDetector(
                  onTap: _updateAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface,
                          border: Border.all(color: AppTheme.border, width: 1),
                          image: profile.avatarUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(profile.avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: profile.avatarUrl == null
                            ? const Icon(Icons.person_rounded, size: 60, color: AppTheme.textMuted)
                            : null,
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: CircularProgressIndicator(color: AppTheme.accent),
                        ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.background, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 18, color: AppTheme.background),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This photo is used by AI to verify it is really you doing the missions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              
              const SizedBox(height: 40),

              // Username Section
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Username', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                subtitle: Text(
                  profile.username ?? 'Tap to set username',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w500),
                ),
                trailing: _isSavingName 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.edit_rounded, color: AppTheme.accent, size: 20),
                onTap: () => _updateUsername(profile.username ?? ''),
              ),
              
              const Divider(color: AppTheme.border, height: 40),

              // System Permissions Section
              const Text('System Permissions', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.security_rounded, color: AppTheme.textSecondary),
                title: const Text('App Blocking Permissions', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: const Text('Grant usage and overlay access to block apps.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                onTap: _requestPermissions,
              ),

              const Divider(color: AppTheme.border, height: 40),

              // Logout
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  ref.read(authServiceProvider).signOut();
                  Navigator.pop(context); // Go back to avoid building unauthenticated states here
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
