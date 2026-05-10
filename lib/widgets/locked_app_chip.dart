import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class LockedAppChip extends StatelessWidget {
  final LockedApp app;
  final List<Mission> missions;
  final VoidCallback onTap;

  const LockedAppChip({
    super.key,
    required this.app,
    required this.missions,
    required this.onTap,
  });

  /// How many required missions are done today
  int _doneCount() => missions
      .where((m) => app.requiredMissionIds.contains(m.id) && m.isCompleted)
      .length;

  int get _total => app.requiredMissionIds.length;

  @override
  Widget build(BuildContext context) {
    final done      = _doneCount();
    final unlocked  = app.isUnlockedToday && !app.isSessionExpired;
    final expired   = app.isUnlockedToday && app.isSessionExpired;
    final progress  = _total == 0 ? 1.0 : done / _total;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked ? AppTheme.accentDim : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? AppTheme.accent.withOpacity(0.5)
                : expired
                    ? AppTheme.border
                    : AppTheme.border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App icon + lock/unlock indicator ────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: app.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(app.icon, color: app.iconColor, size: 20),
                ),
                _StatusIcon(unlocked: unlocked, expired: expired),
              ],
            ),

            const SizedBox(height: 10),

            // ── App name ─────────────────────────────────────
            Text(
              app.name,
              style: TextStyle(
                color: unlocked ? AppTheme.accent : AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // ── Progress bar ──────────────────────────────────
            if (!unlocked && !expired) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation(
                    progress >= 1.0 ? AppTheme.accent : app.iconColor,
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$done / $_total missions',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],

            // ── Session timer (unlocked) ──────────────────────
            if (unlocked) ...[
              Row(children: [
                const Icon(Icons.timer_outlined,
                    color: AppTheme.accent, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${app.minutesRemaining}m left',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                  ),
                ),
              ]),
            ],

            // ── Expired state ─────────────────────────────────
            if (expired)
              const Text(
                'Session ended',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final bool unlocked;
  final bool expired;

  const _StatusIcon({required this.unlocked, required this.expired});

  @override
  Widget build(BuildContext context) {
    if (unlocked) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppTheme.accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_open_rounded,
          color: AppTheme.background,
          size: 13,
        ),
      );
    }

    if (expired) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: const Icon(
          Icons.timer_off_outlined,
          color: AppTheme.textMuted,
          size: 13,
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: const Icon(
        Icons.lock_rounded,
        color: AppTheme.textSecondary,
        size: 13,
      ),
    );
  }
}