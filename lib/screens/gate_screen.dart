import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/photo_verification_service.dart';
import '../services/gemini_verification_service.dart';
import '../services/progress_service.dart';
import '../providers/profile_provider.dart';

enum _Step { prompt, verifying, success, failed }

class GateScreen extends ConsumerStatefulWidget {
  final Mission           mission;
  final List<LockedApp>   lockedApps;
  const GateScreen({super.key, required this.mission, required this.lockedApps});
  @override
  ConsumerState<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends ConsumerState<GateScreen> {
  _Step   _step = _Step.prompt;
  String? _photoPath;
  VerificationResult? _result;

  final _verifier  = GeminiVerificationService();
  final _progress  = ProgressService();
  final _picker    = ImagePicker();

  Future<void> _pickPhoto(ImageSource src) async {
    final file = await _picker.pickImage(
      source: src,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (file == null) return;

    setState(() {
      _photoPath = file.path;
      _step = _Step.verifying;
    });

    final profileService = ref.read(profileServiceProvider);
    
    final result = await _verifier.verifyWithAI(
      imagePath: file.path,
      profileImagePath: profileService.cachedAvatarPath, // Pass the face!
      requiredObject: widget.mission.aiLabels.isNotEmpty ? widget.mission.aiLabels.first : widget.mission.title,
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _step = result.success ? _Step.success : _Step.failed;
    });

    if (result.success) {
      await _progress.onActiveMissionCompleted(widget.mission.id, widget.mission.xp);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(widget.mission.title,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
    ),
    body: SafeArea(
      child: AnimatedSwitcher(
        duration: 400.ms,
        child: switch (_step) {
          _Step.prompt    => _PromptView(mission: widget.mission, onPick: _pickPhoto),
          _Step.verifying => _VerifyingView(photoPath: _photoPath!),
          _Step.success   => _SuccessView(
              mission: widget.mission,
              photoPath: _photoPath!,
              result: _result!,
              onDone: () => Navigator.pop(context),
            ),
          _Step.failed    => _FailedView(
              result: _result!,
              onRetry: () => setState(() => _step = _Step.prompt),
            ),
        },
      ),
    ),
  );
}

// ── Prompt view ──────────────────────────────────────────────────────────────
class _PromptView extends StatelessWidget {
  final Mission mission;
  final Function(ImageSource) onPick;
  const _PromptView({required this.mission, required this.onPick});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: mission.iconBg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(mission.icon, color: mission.iconColor, size: 38),
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

        const SizedBox(height: 24),
        Text(mission.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textPrimary,
                fontSize: 22, fontWeight: FontWeight.w500))
            .animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 10),
        Text(mission.description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14))
            .animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 32),

        // Photo prompt card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Row(children: [
            const Icon(Icons.camera_alt_outlined, color: AppTheme.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(mission.photoPrompt,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          ]),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 32),
        _GreenButton(
          icon: Icons.camera_alt_rounded,
          label: 'Take a photo',
          onTap: () => onPick(ImageSource.camera),
        ).animate().fadeIn(delay: 280.ms),

        const SizedBox(height: 12),
        _OutlineButton(
          icon: Icons.photo_library_outlined,
          label: 'Choose from gallery',
          onTap: () => onPick(ImageSource.gallery),
        ).animate().fadeIn(delay: 320.ms),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentDim,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('+${mission.xp} XP · ${mission.difficultyLabel}',
              style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
        ).animate().fadeIn(delay: 360.ms),
      ],
    ),
  );
}

// ── Verifying view ───────────────────────────────────────────────────────────
class _VerifyingView extends StatelessWidget {
  final String photoPath;
  const _VerifyingView({required this.photoPath});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(File(photoPath),
            width: 200, height: 200, fit: BoxFit.cover),
      ),
      const SizedBox(height: 32),
      const CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
      const SizedBox(height: 16),
      const Text('Verifying your photo…',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
    ],
  );
}

// ── Success view ─────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final Mission mission;
  final String photoPath;
  final VerificationResult result;
  final VoidCallback onDone;
  const _SuccessView({
    required this.mission, required this.photoPath,
    required this.result, required this.onDone,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Photo with verified badge
        Stack(alignment: Alignment.bottomRight, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(photoPath),
                width: 200, height: 200, fit: BoxFit.cover),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_rounded, color: AppTheme.background, size: 14),
              const SizedBox(width: 4),
              const Text('AI verified',
                  style: TextStyle(color: AppTheme.background,
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

        const SizedBox(height: 24),
        const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 56)
            .animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),

        const SizedBox(height: 12),
        Text(result.message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        const Text('Mission complete!',
            style: TextStyle(color: AppTheme.textPrimary,
                fontSize: 22, fontWeight: FontWeight.w500))
            .animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 24),

        // Stats row
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _StatBox(label: 'XP earned', value: '+${mission.xp}'),
          const SizedBox(width: 12),
          _StatBox(label: 'Difficulty', value: mission.difficultyLabel),
        ]).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 32),
        _GreenButton(
          icon: Icons.arrow_back_rounded,
          label: 'Back to Home',
          onTap: onDone,
        ).animate().fadeIn(delay: 500.ms),
      ],
    ),
  );
}

// ── Failed view ──────────────────────────────────────────────────────────────
class _FailedView extends StatelessWidget {
  final VerificationResult result;
  final VoidCallback onRetry;
  const _FailedView({required this.result, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cancel_outlined, color: Color(0xFFD4537E), size: 64)
            .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        const Text('Photo not verified',
            style: TextStyle(color: AppTheme.textPrimary,
                fontSize: 20, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(result.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),

        if (result.detectedLabels.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AI detected in your photo:',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 6),
              Text(result.detectedLabels.join(', '),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ),
        ],

        const SizedBox(height: 32),
        _GreenButton(
          icon: Icons.refresh_rounded,
          label: 'Try again',
          onTap: onRetry,
        ),
      ],
    ),
  );
}

// ── Shared small widgets ─────────────────────────────────────────────────────
class _GreenButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GreenButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.background,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textSecondary,
        side: const BorderSide(color: AppTheme.border, width: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15),
      ),
    ),
  );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Column(children: [
      Text(value,
          style: const TextStyle(color: AppTheme.accent,
              fontSize: 20, fontWeight: FontWeight.w500)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
    ]),
  );
}