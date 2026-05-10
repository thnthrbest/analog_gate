import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/progress_service.dart';
import '../services/mission_data.dart';
import '../models/models.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _svc = ProgressService();

  @override
  Widget build(BuildContext context) {
    final week        = _svc.weekHistory;
    final completed   = _svc.todayCompleted;
    final allMissions = MissionData.all;
    final doneMissions = allMissions
        .where((m) => completed.contains(m.id))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: const Text(
                  'Progress',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),
            ),

            // ── XP + Streak cards ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: _BigStatCard(
                    label: 'Total XP',
                    value: '${_svc.totalXp}',
                    icon: Icons.bolt_rounded,
                    color: AppTheme.accent,
                    bg: AppTheme.accentDim,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _BigStatCard(
                    label: 'Day streak',
                    value: '${_svc.streakDays}',
                    icon: Icons.local_fire_department_rounded,
                    color: AppTheme.amber,
                    bg: AppTheme.amberDim,
                  )),
                ]).animate().fadeIn(delay: 100.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Weekly calendar ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _WeekCalendar(week: week),
              ).animate().fadeIn(delay: 200.ms),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Level progress bar ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LevelCard(xp: _svc.totalXp),
              ).animate().fadeIn(delay: 300.ms),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Today's completed missions ───────────────────
            if (doneMissions.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: const Text(
                    'COMPLETED TODAY',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      letterSpacing: 0.12,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _CompletedMissionRow(mission: doneMissions[i])
                      .animate()
                      .fadeIn(delay: (350 + i * 60).ms)
                      .slideX(begin: 0.05, end: 0),
                  childCount: doneMissions.length,
                ),
              ),
            ],

            // ── Empty state ──────────────────────────────────
            if (doneMissions.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Icon(Icons.emoji_nature_outlined,
                        color: AppTheme.textMuted, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No missions completed yet today.\nGo outside and earn your scroll time!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 13, height: 1.6),
                    ),
                  ]).animate().fadeIn(delay: 300.ms),
                ),
              ),

            // ── Achievements ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: const Text(
                  'ACHIEVEMENTS',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.12,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AchievementsGrid(
                  xp: _svc.totalXp,
                  streak: _svc.streakDays,
                  completedCount: completed.length,
                ),
              ).animate().fadeIn(delay: 500.ms),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Big stat card ─────────────────────────────────────────────────────────────
class _BigStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _BigStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w500)),
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ]),
    ]),
  );
}

// ── Weekly calendar ───────────────────────────────────────────────────────────
class _WeekCalendar extends StatelessWidget {
  final List<bool> week;
  const _WeekCalendar({required this.week});

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('This week',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final isToday = i == 6;
          final done    = week[i];
          return Column(children: [
            Text(_days[i],
                style: TextStyle(
                    color: isToday ? AppTheme.accent : AppTheme.textMuted,
                    fontSize: 11)),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppTheme.accentDim
                    : (isToday ? AppTheme.surfaceHigh : Colors.transparent),
                border: Border.all(
                  color: done
                      ? AppTheme.accent
                      : (isToday
                          ? AppTheme.accent.withOpacity(0.4)
                          : AppTheme.border),
                  width: isToday ? 1.5 : 0.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: AppTheme.accent, size: 16)
                  : null,
            ),
          ]);
        }),
      ),
    ]),
  );
}

// ── Level / XP progress bar ───────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final int xp;
  const _LevelCard({required this.xp});

  static const _levels = [
    (0,    100,  'Seed',       Icons.spa_rounded),
    (100,  300,  'Sprout',     Icons.eco_rounded),
    (300,  600,  'Sapling',    Icons.park_rounded),
    (600,  1000, 'Tree',       Icons.forest_rounded),
    (1000, 2000, 'Forest',     Icons.nature_rounded),
    (2000, 9999, 'Ancient Oak',Icons.account_tree_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final level = _levels.lastWhere(
      (l) => xp >= l.$1,
      orElse: () => _levels.first,
    );
    final progress = ((xp - level.$1) / (level.$2 - level.$1)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(level.$4, color: AppTheme.accent, size: 20),
          const SizedBox(width: 8),
          Text('Level: ${level.$3}',
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('$xp / ${level.$2} XP',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.border,
            valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${((1 - progress) * (level.$2 - level.$1)).toInt()} XP to next level',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ]),
    );
  }
}

// ── Completed mission row ─────────────────────────────────────────────────────
class _CompletedMissionRow extends StatelessWidget {
  final Mission mission;
  const _CompletedMissionRow({required this.mission});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: mission.iconBg,
            borderRadius: BorderRadius.circular(10)),
        child: Icon(mission.icon, color: mission.iconColor, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mission.title,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Text('+${mission.xp} XP · ${mission.difficultyLabel}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      )),
      const Icon(Icons.check_circle_rounded,
          color: AppTheme.accent, size: 20),
    ]),
  );
}

// ── Achievements grid ─────────────────────────────────────────────────────────
class _AchievementsGrid extends StatelessWidget {
  final int xp;
  final int streak;
  final int completedCount;

  const _AchievementsGrid({
    required this.xp,
    required this.streak,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final badges = [
      _Badge('First Step',   Icons.directions_walk_rounded, completedCount >= 1, AppTheme.accent),
      _Badge('Bookworm',     Icons.menu_book_rounded,       xp >= 50,            AppTheme.amber),
      _Badge('Week Warrior', Icons.local_fire_department_rounded, streak >= 7,   AppTheme.pink),
      _Badge('Century',      Icons.bolt_rounded,            xp >= 100,           AppTheme.purple),
      _Badge('Nature Lover', Icons.park_rounded,            xp >= 200,           AppTheme.green),
      _Badge('Mindful',      Icons.self_improvement_rounded, completedCount >= 10, AppTheme.teal),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: badges.map((b) => _BadgeChip(badge: b)).toList(),
    );
  }
}

class _Badge {
  final String label;
  final IconData icon;
  final bool earned;
  final Color color;
  const _Badge(this.label, this.icon, this.earned, this.color);
}

class _BadgeChip extends StatelessWidget {
  final _Badge badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: const Duration(milliseconds: 300),
    opacity: badge.earned ? 1.0 : 0.35,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badge.earned
            ? badge.color.withOpacity(0.12)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badge.earned ? badge.color.withOpacity(0.5) : AppTheme.border,
          width: 0.5,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(badge.icon,
            color: badge.earned ? badge.color : AppTheme.textMuted,
            size: 14),
        const SizedBox(width: 6),
        Text(badge.label,
            style: TextStyle(
              color: badge.earned ? badge.color : AppTheme.textMuted,
              fontSize: 12,
              fontWeight: badge.earned ? FontWeight.w500 : FontWeight.normal,
            )),
      ]),
    ),
  );
}