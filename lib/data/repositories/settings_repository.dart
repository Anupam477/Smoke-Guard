import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;

import '../../core/errors/failures.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/user_settings.dart';
import '../../features/settings/demo_mode_provider.dart';

abstract class ISettingsRepository {
  Future<UserSettings> getSettings(String userId);
  Future<void> saveSettings(UserSettings settings);
}

class SupabaseSettingsRepository implements ISettingsRepository {
  final sp.SupabaseClient _client;

  SupabaseSettingsRepository(this._client);

  @override
  Future<UserSettings> getSettings(String userId) async {
    try {
      final res = await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) {
        return UserSettings.defaultSettings(userId: userId);
      }
      return UserSettings.fromJson(res);
    } catch (e) {
      throw AppFailure('Failed to load user settings: $e');
    }
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    try {
      await _client.from('user_settings').upsert(settings.toJson());
    } catch (e) {
      throw AppFailure('Failed to save settings: $e');
    }
  }
}

class MockSettingsRepository implements ISettingsRepository {
  final Map<String, UserSettings> _settings = {};

  @override
  Future<UserSettings> getSettings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_settings.containsKey(userId)) {
      return _settings[userId]!;
    }
    return UserSettings.defaultSettings(userId: userId);
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _settings[settings.userId] = settings;
    debugPrint('[MockSettingsRepository] Settings saved for user ${settings.userId}');
  }
}

final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  final isDemoMode = ref.watch(demoModeProvider);

  if (isDemoMode || !SupabaseService.isInitialized) {
    return MockSettingsRepository();
  } else {
    return SupabaseSettingsRepository(SupabaseService.client);
  }
});
