import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/mission_data.dart';
import '../services/progress_service.dart';
import '../widgets/mission_card.dart';
import '../widgets/locked_app_chip.dart';
import '../widgets/streak_bar.dart';
import 'gate_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Mission>   _missions;
  late List<LockedApp> _apps;
  final _svc = ProgressService();

  @override
  void initState() {
    super.initState();
    _missions = MissionData.todaysMissions();
    _apps     = AppData.defaultApps;
    _syncState();
  }

  void _syncState() {
    for (final m in _missions) {
      m.isCompleted = _svc.isMissionDone(m.id);
    }
    for (final a in _apps) {
      a.isUnlockedToday = _svc.isAppUnlocked(a.id);
    }
  }

  void _onMissionTap(Mission m) async {
    if (m.isCompleted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GateScreen(mission: m, lockedApps: _apps)),
    );
    setState(_syncState);
  }

  void _onAppTap(LockedApp app) async {
    // Find any incomplete mission that can unlock this app
    final needed = _missions.where(
      (m) => app.requiredMissionIds.contains(m.id) && !m.isCompleted,
    ).toList();

    if (app.isUnlockedToday) {
      _showUnlockedDialog(app);
      return;
    }

    if (needed.isEmpty) {
      // All required missions done — unlock!
      await _svc.unlockApp(app.id);
      setState(() {
        app.isUnlockedToday = true;
        app.unlockedAt = DateTime.now();
      });
      _showUnlockedDialog(app);
    } else {
      // Send to gate with the first needed mission
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GateScreen(mission: needed.first, lockedApps: _apps),
        ),
      );
      setState(_syncState);
    }
  }

  void _showUnlockedDialog(LockedApp app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(app.icon, color: app.iconColor, size: 22),
          const SizedBox(width: 8),
          Text(app.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        ]),
        content: Text(
          app.isSessionExpired
              ? 'Your ${app.sessionMinutes}-min session has ended. Complete another mission to unlock again tomorrow.'
              : 'Unlocked! You have ${app.minutesRemaining} minutes left in your session. Enjoy mindfully 🌿',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _missions.where((m) => m.isCompleted).length;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Good ${_greeting()}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const Text('Your gates',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 24,
                              fontWeight: FontWeight.w500)),
                    ]),
                    _XpBadge(xp: _svc.totalXp),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),
            ),

            // ── Streak bar ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreakBar(
                  streak: _svc.streakDays,
                  weekHistory: _svc.weekHistory,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            ),

            // ── Progress indicator ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today\'s missions',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11,
                            letterSpacing: 0.1)),
                    Text('$completedCount / ${_missions.length} done',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ),

            // ── Missions ─────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => MissionCard(
                  mission: _missions[i],
                  onTap: () => _onMissionTap(_missions[i]),
                ).animate().fadeIn(delay: (150 + i * 80).ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                childCount: _missions.length,
              ),
            ),

            // ── Locked apps ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: const Text('LOCKED APPS',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.12)),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _apps.map((a) => LockedAppChip(
                    app: a,
                    missions: _missions,
                    onTap: () => _onAppTap(a),
                  )).toList(),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
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