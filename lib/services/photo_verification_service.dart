import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class PhotoVerificationService {
  static final PhotoVerificationService _i = PhotoVerificationService._();
  factory PhotoVerificationService() => _i;
  PhotoVerificationService._();

  late final ImageLabeler _labeler;

  void init() {
    _labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.55));
  }

  Future<VerificationResult> verify({
    required String imagePath,
    required List<String> requiredLabels,
  }) async {
    try {
      final labels = await _labeler.processImage(InputImage.fromFilePath(imagePath));

      final detected = labels
          .where((l) => l.confidence > 0.55)
          .map((l) => l.label.toLowerCase())
          .toList();

      String? matched;
      for (final req in requiredLabels) {
        for (final det in detected) {
          if (det.contains(req.toLowerCase()) || req.toLowerCase().contains(det)) {
            matched = req;
            break;
          }
        }
        if (matched != null) break;
      }

      final topLabels = labels
          .where((l) => l.confidence > 0.55)
          .take(5)
          .map((l) => '${l.label} (${(l.confidence * 100).toStringAsFixed(0)}%)')
          .toList();

      return VerificationResult(
        success: matched != null,
        matchedLabel: matched,
        detectedLabels: topLabels,
        message: matched != null
            ? '${_cap(matched!)} detected ✓'
            : 'Photo doesn\'t match the mission. Try a clearer photo.',
      );
    } catch (_) {
      return const VerificationResult(
        success: false,
        matchedLabel: null,
        detectedLabels: [],
        message: 'Verification failed. Please try again.',
      );
    }
  }

  String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  void dispose() => _labeler.close();
}

class VerificationResult {
  final bool         success;
  final String?      matchedLabel;
  final List<String> detectedLabels;
  final String       message;

  const VerificationResult({
    required this.success,
    required this.matchedLabel,
    required this.detectedLabels,
    required this.message,
  });
}