import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env_config.dart';

class SupabaseService {
  SupabaseService._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Avoid throwing fatal exception if placeholders are used in early demo/dev setup
    if (EnvConfig.supabaseUrl.contains('placeholder') ||
        EnvConfig.supabaseAnonKey.contains('placeholder')) {
      debugPrint('[SupabaseService] Using placeholder credentials. Supabase cloud features will run in mock mode.');
      return;
    }

    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Initialized successfully.');
    } catch (e) {
      debugPrint('[SupabaseService] Initialization warning/error: $e');
    }
  }

  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError('Supabase is not initialized. Call SupabaseService.initialize() first.');
    }
    return Supabase.instance.client;
  }
}
