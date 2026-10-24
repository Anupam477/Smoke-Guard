import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/env_config.dart';
import '../../core/constants/app_constants.dart';

class DemoModeNotifier extends StateNotifier<bool> {
  DemoModeNotifier() : super(EnvConfig.defaultDemoMode) {
    _loadDemoModeState();
  }

  Future<void> _loadDemoModeState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.getBool(AppConstants.keyDemoMode);
    if (savedState != null) {
      state = savedState;
    }
  }

  Future<void> toggleDemoMode(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyDemoMode, enabled);
  }
}

final demoModeProvider = StateNotifierProvider<DemoModeNotifier, bool>((ref) {
  return DemoModeNotifier();
});
