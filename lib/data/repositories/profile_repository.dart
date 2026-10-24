import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;

import '../../core/errors/failures.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/user_profile.dart';
import '../../features/settings/demo_mode_provider.dart';

abstract class IProfileRepository {
  Future<UserProfile?> getProfile(String userId);
  Future<void> saveProfile(UserProfile profile);
}

class SupabaseProfileRepository implements IProfileRepository {
  final sp.SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return null;
      return UserProfile.fromJson(res);
    } catch (e) {
      throw AppFailure('Failed to fetch profile: $e');
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    try {
      await _client.from('profiles').upsert(profile.toJson());
    } catch (e) {
      throw AppFailure('Failed to save profile: $e');
    }
  }
}

class MockProfileRepository implements IProfileRepository {
  final Map<String, UserProfile> _profiles = {};

  @override
  Future<UserProfile?> getProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_profiles.containsKey(userId)) {
      return _profiles[userId];
    }
    return UserProfile.defaultProfile(id: userId, email: 'demo@smokeguard.app');
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profiles[profile.id] = profile;
    debugPrint('[MockProfileRepository] Profile updated for ${profile.displayName}');
  }
}

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final isDemoMode = ref.watch(demoModeProvider);

  if (isDemoMode || !SupabaseService.isInitialized) {
    return MockProfileRepository();
  } else {
    return SupabaseProfileRepository(SupabaseService.client);
  }
});
