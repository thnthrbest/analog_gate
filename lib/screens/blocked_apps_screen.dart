import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class BlockedAppsScreen extends StatefulWidget {
  const BlockedAppsScreen({super.key});

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen> {
  final List<Map<String, String>> _popularApps = [
    {
      'name': 'YouTube',
      'package': 'com.google.android.youtube',
      'icon': 'play_circle_outline',
    },
    {
      'name': 'TikTok',
      'package': 'com.zhiliaoapp.musically',
      'icon': 'music_note',
    },
    {
      'name': 'Instagram',
      'package': 'com.instagram.android',
      'icon': 'camera_alt',
    },
    {
      'name': 'Facebook',
      'package': 'com.facebook.katana',
      'icon': 'facebook',
    },
    {
      'name': 'X (Twitter)',
      'package': 'com.twitter.android',
      'icon': 'close',
    },
    {
      'name': 'Reddit',
      'package': 'com.reddit.frontpage',
      'icon': 'reddit',
    },
    {
      'name': 'Netflix',
      'package': 'com.netflix.mediaclient',
      'icon': 'movie',
    },
  ];

  List<String> _blockedPackages = [];
  final TextEditingController _customController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadBlockedPackages();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadBlockedPackages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _blockedPackages = prefs.getStringList('blocked_packages') ?? [];
    });
  }

  Future<void> _togglePackage(String package, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (value) {
        if (!_blockedPackages.contains(package)) {
          _blockedPackages.add(package);
        }
      } else {
        _blockedPackages.remove(package);
      }
    });
    await prefs.setStringList('blocked_packages', _blockedPackages);
  }

  Future<void> _addCustomPackage() async {
    if (_formKey.currentState!.validate()) {
      final package = _customController.text.trim();
      if (!_blockedPackages.contains(package)) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _blockedPackages.add(package);
        });
        await prefs.setStringList('blocked_packages', _blockedPackages);
        _customController.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added custom package: $package'),
            backgroundColor: AppTheme.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Package already exists in the block list.'),
            backgroundColor: AppTheme.pink,
          ),
        );
      }
    }
  }

  Future<void> _removeCustomPackage(String package) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _blockedPackages.remove(package);
    });
    await prefs.setStringList('blocked_packages', _blockedPackages);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed: $package'),
        backgroundColor: AppTheme.border,
      ),
    );
  }

  IconData _mapIcon(String? iconName) {
    switch (iconName) {
      case 'play_circle_outline':
        return Icons.play_circle_outline_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'camera_alt':
        return Icons.camera_alt_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'reddit':
        return Icons.reddit_rounded;
      case 'movie':
        return Icons.movie_filter_rounded;
      default:
        return Icons.app_blocking_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate popular apps from custom package names in current blocklist
    final popularPackageNames = _popularApps.map((a) => a['package']!).toList();
    final customBlockedPackages = _blockedPackages.where((p) => !popularPackageNames.contains(p)).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Blocked Apps'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select the apps you want to restrict. When they are used, your active mission timer will count down and request completion once reached.',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Popular Apps Header
            const Text(
              'Popular Distractions',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Popular Apps List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _popularApps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final app = _popularApps[index];
                final name = app['name']!;
                final package = app['package']!;
                final isBlocked = _blockedPackages.contains(package);

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isBlocked ? AppTheme.accent.withOpacity(0.5) : AppTheme.border,
                      width: isBlocked ? 1.0 : 0.5,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor: AppTheme.textSecondary,
                    ),
                    child: CheckboxListTile(
                      activeColor: AppTheme.accent,
                      checkColor: AppTheme.background,
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        package,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isBlocked ? AppTheme.accentDim : AppTheme.surfaceHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _mapIcon(app['icon']),
                          color: isBlocked ? AppTheme.accent : AppTheme.textSecondary,
                          size: 24,
                        ),
                      ),
                      value: isBlocked,
                      onChanged: (bool? val) {
                        if (val != null) {
                          _togglePackage(package, val);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Custom Apps Header
            const Text(
              'Add Custom App Package',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Custom Apps Input Form
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g., com.tencent.ig',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.accent, width: 1.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a package name';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)+$').hasMatch(value.trim())) {
                          return 'Invalid package name format';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _addCustomPackage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.background,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add_rounded, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            if (customBlockedPackages.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Custom Blocked Packages',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: customBlockedPackages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final package = customBlockedPackages[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.code_rounded, color: AppTheme.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            package,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.pink, size: 20),
                          onPressed: () => _removeCustomPackage(package),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
