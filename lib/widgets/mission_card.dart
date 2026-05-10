import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback onTap;

  const MissionCard({
    super.key,
    required this.mission,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: mission.isCompleted
              ? AppTheme.accentDim.withOpacity(0.4)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: mission.isCompleted
                ? AppTheme.accent.withOpacity(0.35)
                : AppTheme.border,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Icon ───────────────────────────────────────
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: mission.isCompleted
                          ? AppTheme.accentDim
                          : mission.iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      mission.icon,
                      color: mission.isCompleted
                          ? AppTheme.accent
                          : mission.iconColor,
                      size: 22,
                    ),
                  ),
                  if (mission.isCompleted)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppTheme.background,
                          size: 12,
                        ),
                      ).animate().scale(
                            duration: 300.ms,
                            curve: Curves.elasticOut,
                          ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // ── Text ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        color: mission.isCompleted
                            ? AppTheme.accent
                            : AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: mission.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppTheme.accent.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mission.isCompleted
                          ? 'Completed · +${mission.xp} XP'
                          : mission.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Right badge ─────────────────────────────────
              if (!mission.isCompleted)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentDim,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${mission.xp} XP',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.difficultyLabel,
                      style: TextStyle(
                        color: mission.difficultyColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              else
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.accent,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}