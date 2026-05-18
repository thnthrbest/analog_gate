import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'auth_provider.dart';

final profileServiceProvider = Provider((ref) => ProfileService());

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  // Automatically re-fetch if auth state changes
  final authState = ref.watch(authStateProvider);
  
  if (authState.value == null) {
    return null;
  }
  
  final profileService = ref.read(profileServiceProvider);
  return profileService.getProfile();
});
