import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'photo_verification_service.dart';

class GeminiVerificationService {
  static final GeminiVerificationService _i = GeminiVerificationService._();
  factory GeminiVerificationService() => _i;
  GeminiVerificationService._();

  // TODO: Replace with actual Gemini API Key (get from Google AI Studio)
  static const _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY',
  );

  late final GenerativeModel _model;

  void init() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
  }

  /// Verifies the object and (optionally) the face in the image using Gemini.
  Future<VerificationResult> verifyWithAI({
    required String imagePath,
    String? profileImagePath, // The saved face of the user
    required String requiredObject,
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      return const VerificationResult(
        success: false,
        matchedLabel: null,
        detectedLabels: [],
        message: 'Developer Error: Please add Gemini API Key.',
      );
    }

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      
      List<DataPart> imageParts = [
        DataPart('image/jpeg', imageBytes),
      ];

      String prompt = 'Analyze this image. Does it clearly show a "$requiredObject"? ';

      // If we have a profile picture, we ask Gemini to do a face match
      if (profileImagePath != null) {
        final profileBytes = await File(profileImagePath).readAsBytes();
        imageParts.insert(0, DataPart('image/jpeg', profileBytes));
        prompt = 'I have provided two images. Image 1 is the profile photo. Image 2 is the new photo. '
                 '1. Are the people in both photos the same person? '
                 '2. Does Image 2 clearly show a "$requiredObject"? '
                 'Reply exactly with YES if BOTH conditions are met, otherwise reply with a short explanation of why it failed.';
      } else {
        prompt += 'Reply exactly with YES if it does, otherwise reply with a short explanation of why it failed.';
      }

      final content = [
        Content.multi([...imageParts, TextPart(prompt)])
      ];

      final response = await _model.generateContent(content);
      final text = response.text?.trim().toUpperCase() ?? '';

      if (text.startsWith('YES')) {
        return VerificationResult(
          success: true,
          matchedLabel: requiredObject,
          detectedLabels: [requiredObject],
          message: 'Verification Successful! ✓',
        );
      } else {
        return VerificationResult(
          success: false,
          matchedLabel: null,
          detectedLabels: [],
          message: response.text?.trim() ?? 'AI rejected the image.',
        );
      }
    } catch (e, stackTrace) {
      print('=== GEMINI ERROR ===');
      print(e);
      print(stackTrace);
      return VerificationResult(
        success: false,
        matchedLabel: null,
        detectedLabels: [],
        message: 'AI Error: Could not connect to Gemini. $e',
      );
    }
  }
}
