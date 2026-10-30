import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'photo_verification_service.dart';

/// Sends the photo to the verify-photo Edge Function. The server checks it and
/// records the mission only when the photo passes, so the app holds no API key.
class PhotoVerifierService {
  Future<VerificationResult> verify({
    required String imagePath,
    required String missionId,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final res = await Supabase.instance.client.functions.invoke(
        'verify-photo',
        body: {'missionId': missionId, 'imageBase64': base64Encode(bytes)},
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final verified = data['verified'] == true;
      return VerificationResult(
        success: verified,
        matchedLabel: verified ? data['label'] as String? : null,
        detectedLabels: const [],
        message: verified
            ? 'Verification Successful! ✓'
            : (data['message'] as String? ?? 'Photo did not match.'),
      );
    } catch (e) {
      print('=== VERIFY-PHOTO ERROR === $e');
      return const VerificationResult(
        success: false,
        matchedLabel: null,
        detectedLabels: [],
        message: 'Verification failed. Check your connection and try again.',
      );
    }
  }
}
