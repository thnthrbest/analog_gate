import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/user_profile.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  // Cache path for the downloaded avatar so Gemini can use it
  String? _cachedAvatarPath;
  String? get cachedAvatarPath => _cachedAvatarPath;

  /// Fetch the current user's profile from the database
  Future<UserProfile?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        // If profile doesn't exist yet, return a default one
        return UserProfile(id: user.id);
      }

      final profile = UserProfile.fromJson(data);
      
      // If there's an avatar, cache it locally in the background for Gemini
      if (profile.avatarUrl != null) {
        _cacheAvatar(profile.avatarUrl!);
      }

      return profile;
    } catch (e) {
      print('Error fetching profile: $e');
      return UserProfile(id: user.id);
    }
  }

  /// Update username
  Future<void> updateUsername(String newUsername) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').upsert({
      'id': user.id,
      'username': newUsername,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Upload a new avatar and save to profile
  Future<String?> uploadAvatar(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final fileExt = p.extension(imageFile.path);
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}$fileExt';

      // 1. Upload to Supabase Storage
      await _client.storage.from('avatars').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // 2. Get public URL
      final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);

      // 3. Update the profiles table
      await _client.from('profiles').upsert({
        'id': user.id,
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // 4. Update local cache
      _cachedAvatarPath = imageFile.path;

      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  /// Downloads the avatar to a temporary local file so Gemini can read it
  Future<void> _cacheAvatar(String publicUrl) async {
    try {
      // Create a local temp file
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, 'cached_avatar.jpg'));

      // If the URL has changed, download it (basic cache logic)
      final uri = Uri.parse(publicUrl);
      final response = await _client.storage
          .from('avatars')
          .download(uri.pathSegments.last); // Extract filename from URL

      await file.writeAsBytes(response);
      _cachedAvatarPath = file.path;
      print('Avatar cached successfully at: ${file.path}');
    } catch (e) {
      print('Failed to cache avatar: $e');
    }
  }
}
