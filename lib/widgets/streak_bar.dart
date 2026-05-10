import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StreakBar extends StatelessWidget {
  final int streak;
  final List<bool> weekHistory;

  const StreakBar({
    super.key,
    required this.streak,
    required this.weekHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          // ── Streak number ─────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: AppTheme.amber,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const Text(
                'day streak',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ── Day dots ──────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: List.generate(7, (i) {
                  final isToday = i == 6;
                  final done    = weekHistory[i];

                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppTheme.accent
                            : AppTheme.surfaceHigh,
                        border: Border.all(
                          color: isToday && !done
                              ? AppTheme.accent.withOpacity(0.5)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mon – Sun',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}