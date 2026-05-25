import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/mission_data.dart';
import '../services/progress_service.dart';
import '../widgets/streak_bar.dart';
import 'gate_screen.dart';
import 'settings_screen.dart';
import 'blocked_apps_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = ProgressService();
  Timer? _refreshTimer;

  // Local state synced from shared preferences
  String? _activeMissionId;
  int _accumulatedUsageSeconds = 0;
  List<String> _blockedPackages = [];
  bool _testingMode = false;

  @override
  void initState() {
    super.initState();
    _loadState();
    // Refresh the UI state periodically to show progress updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadState();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    
    if (mounted) {
      setState(() {
        _activeMissionId = prefs.getString('active_mission_id') ?? _svc.activeMissionId;
        _accumulatedUsageSeconds = prefs.getInt('accumulated_usage_seconds') ?? 0;
        _blockedPackages = prefs.getStringList('blocked_packages') ?? [];
        _testingMode = prefs.getBool('testing_mode') ?? false;
      });
    }
  }

  Future<void> _resetUsage() async {
    await _svc.resetAccumulatedUsage();
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (e) {
      debugPrint('Error closing overlay: $e');
    }
    await _loadState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset accumulated usage successfully!'),
          backgroundColor: AppTheme.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onCompleteMissionTap(Mission m) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GateScreen(mission: m, lockedApps: const []),
      ),
    );
    _loadState();
  }

  void _onRerollTap() async {
    final success = await _svc.rerollActiveMission();
    if (success) {
      await _loadState();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rerolled active mission successfully! ✓'),
            backgroundColor: AppTheme.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No shorter alternative tasks available!'),
            backgroundColor: AppTheme.pink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    if (_testingMode) {
      return '${seconds}s';
    }
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '${mins}m ${secs}s';
    }
    return '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Find active mission
    final mission = MissionData.all.firstWhere(
      (m) => m.id == _activeMissionId,
      orElse: () => MissionData.all.isNotEmpty ? MissionData.all.first : _fallbackDefaultMission(),
    );

    // 2. Calculate time limit
    int limitSeconds;
    if (_testingMode) {
      limitSeconds = switch (mission.difficulty) {
        MissionDifficulty.easy => 15,
        MissionDifficulty.medium => 30,
        MissionDifficulty.hard => 45,
      };
    } else {
      limitSeconds = switch (mission.difficulty) {
        MissionDifficulty.easy => 10 * 60,
        MissionDifficulty.medium => 20 * 60,
        MissionDifficulty.hard => 30 * 60,
      };
    }

    final double progress = (limitSeconds > 0) 
        ? (_accumulatedUsageSeconds / limitSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accent,
          backgroundColor: AppTheme.surface,
          onRefresh: _loadState,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good ${_greeting()}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          const Text('Analog Gate',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5)),
                        ],
                      ),
                      Row(
                        children: [
                          _XpBadge(xp: _svc.totalXp),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.settings_rounded, color: AppTheme.textSecondary, size: 22),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                              _loadState();
                            },
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),
              ),

              // Streak Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreakBar(
                    streak: _svc.streakDays,
                    weekHistory: _svc.weekHistory,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Blocked App Status card & Progress Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'BLOCKED APPS USAGE',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (_testingMode)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _resetUsage,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentDim,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 0.5),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.refresh_rounded, color: AppTheme.accent, size: 10),
                                          SizedBox(width: 4),
                                          Text(
                                            'Reset',
                                            style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.pinkDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.pink.withOpacity(0.3), width: 0.5),
                                    ),
                                    child: const Text(
                                      '⚡ Testing Mode',
                                      style: TextStyle(color: AppTheme.pink, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatDuration(_accumulatedUsageSeconds),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Limit: ${_formatDuration(limitSeconds)}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Premium styled progress bar
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceHigh,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                  height: 10,
                                  width: constraints.maxWidth * progress,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: progress >= 1.0
                                          ? [AppTheme.pink, AppTheme.pink]
                                          : [AppTheme.accent, AppTheme.accent.withOpacity(0.7)],
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (progress >= 1.0 ? AppTheme.pink : AppTheme.accent).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                        const SizedBox(height: 16),
                        if (_blockedPackages.isEmpty)
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BlockedAppsScreen()),
                              );
                              _loadState();
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppTheme.amber, size: 16),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'No apps selected to block. Tap here to set up.',
                                    style: TextStyle(
                                      color: AppTheme.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            'Restricting: ${_blockedPackages.map((p) => p.split('.').last).join(', ')}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Active Mission Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE GATE MISSION',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Card highlighting the active mission
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: mission.difficultyColor.withOpacity(0.5), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: mission.difficultyColor.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: mission.iconBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    mission.icon,
                                    color: mission.iconColor,
                                    size: 32,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: mission.difficultyColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: mission.difficultyColor.withOpacity(0.3), width: 0.5),
                                      ),
                                      child: Text(
                                        mission.difficultyLabel,
                                        style: TextStyle(
                                          color: mission.difficultyColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${mission.xp} XP',
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              mission.title,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mission.description,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Verification Info
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.camera_alt_outlined, color: AppTheme.textSecondary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      mission.photoPrompt,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 54,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            mission.difficultyColor,
                                            mission.difficultyColor.withOpacity(0.8),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: mission.difficultyColor.withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () => _onCompleteMissionTap(mission),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.bolt_rounded, color: AppTheme.background, size: 20),
                                            SizedBox(width: 4),
                                            Text(
                                              'Complete',
                                              style: TextStyle(
                                                color: AppTheme.background,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 54,
                                    child: OutlinedButton(
                                      onPressed: _onRerollTap,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textSecondary,
                                        side: const BorderSide(color: AppTheme.border, width: 0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.refresh_rounded, size: 18),
                                          SizedBox(width: 4),
                                          Text(
                                            'Reroll',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  Mission _fallbackDefaultMission() {
    return Mission(
      id: 'walk_outside',
      title: 'Take a short walk',
      description: 'Step outside for at least 5 minutes. Breathe.',
      photoPrompt: 'Take a photo of outdoors — sky, street, park, anything outside.',
      difficulty: MissionDifficulty.easy,
      category: MissionCategory.outdoor,
      xp: 30,
      duration: 5,
      aiLabels: ['sky', 'outdoor', 'nature', 'tree', 'plant', 'grass', 'road', 'building', 'street'],
      icon: Icons.directions_walk_rounded,
      iconColor: AppTheme.accent,
      iconBg: AppTheme.accentDim,
    );
  }
}

class _XpBadge extends StatelessWidget {
  final int xp;
  const _XpBadge({required this.xp});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.accentDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 16),
          const SizedBox(width: 4),
          Text('$xp XP',
              style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      );
}