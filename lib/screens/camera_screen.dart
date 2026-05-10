import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  final String photoPrompt;
  const CameraScreen({super.key, required this.photoPrompt});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isReady = false;
  bool _isTaking = false;
  int _camIndex = 0;
  FlashMode _flash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    await _startController(_cameras[_camIndex]);
  }

  Future<void> _startController(CameraDescription cam) async {
    final ctrl = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = ctrl;
    await ctrl.initialize();
    await ctrl.setFlashMode(_flash);
    if (mounted) setState(() => _isReady = true);
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _isReady = false);
    _camIndex = (_camIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await _startController(_cameras[_camIndex]);
  }

  Future<void> _toggleFlash() async {
    final next = _flash == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller?.setFlashMode(next);
    setState(() => _flash = next);
  }

  Future<void> _takePhoto() async {
    if (_isTaking || _controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isTaking = true);
    try {
      final file = await _controller!.takePicture();
      if (mounted) Navigator.pop(context, file.path);
    } catch (e) {
      setState(() => _isTaking = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startController(_cameras[_camIndex]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ───────────────────────────────
          if (_isReady && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accent,
                strokeWidth: 2,
              ),
            ),

          // ── Corner guides ────────────────────────────────
          if (_isReady) const _CornerGuides(),

          // ── Top bar ──────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(
                      icon: Icons.close,
                      onTap: () => Navigator.pop(context, null),
                    ),
                    _CircleButton(
                      icon: _flash == FlashMode.off
                          ? Icons.flash_off_rounded
                          : Icons.flash_on_rounded,
                      onTap: _toggleFlash,
                      active: _flash != FlashMode.off,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── Prompt label ─────────────────────────────────
          Positioned(
            left: 16, right: 16,
            bottom: 160,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accent.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.photoPrompt,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 12),
                  ),
                ),
              ]),
            ).animate().fadeIn(delay: 200.ms),
          ),

          // ── Bottom controls ──────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Flip camera
                    _CircleButton(
                      icon: Icons.flip_camera_ios_rounded,
                      onTap: _flipCamera,
                      size: 48,
                    ),

                    // Shutter
                    GestureDetector(
                      onTap: _takePhoto,
                      child: AnimatedContainer(
                        duration: 150.ms,
                        width: _isTaking ? 68 : 72,
                        height: _isTaking ? 68 : 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isTaking
                              ? AppTheme.accent.withOpacity(0.8)
                              : AppTheme.accent,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isTaking
                              ? Icons.hourglass_top_rounded
                              : Icons.camera_alt_rounded,
                          color: AppTheme.background,
                          size: 30,
                        ),
                      ),
                    ),

                    // Placeholder to balance layout
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ).animate().slideY(begin: 0.3, end: 0, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}

// ── Corner guides overlay ────────────────────────────────────────────────────
class _CornerGuides extends StatelessWidget {
  const _CornerGuides();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CornerPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 48.0;
    const len    = 24.0;

    // top-left
    canvas.drawLine(Offset(margin, margin + len), Offset(margin, margin), paint);
    canvas.drawLine(Offset(margin, margin), Offset(margin + len, margin), paint);
    // top-right
    canvas.drawLine(Offset(size.width - margin - len, margin),
        Offset(size.width - margin, margin), paint);
    canvas.drawLine(Offset(size.width - margin, margin),
        Offset(size.width - margin, margin + len), paint);
    // bottom-left
    canvas.drawLine(Offset(margin, size.height - margin - len),
        Offset(margin, size.height - margin), paint);
    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(margin + len, size.height - margin), paint);
    // bottom-right
    canvas.drawLine(Offset(size.width - margin - len, size.height - margin),
        Offset(size.width - margin, size.height - margin), paint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin - len),
        Offset(size.width - margin, size.height - margin), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Small circle button ──────────────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool active;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppTheme.accent.withOpacity(0.25)
            : Colors.black.withOpacity(0.45),
        border: Border.all(
          color: active ? AppTheme.accent : Colors.white24,
          width: 0.5,
        ),
      ),
      child: Icon(
        icon,
        color: active ? AppTheme.accent : Colors.white,
        size: size * 0.45,
      ),
    ),
  );
}