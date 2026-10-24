import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../auth/auth_controller.dart';

class SettingsState {
  final bool isLoading;
  final UserSettings settings;
  final String? errorMessage;

  const SettingsState({
    this.isLoading = false,
    required this.settings,
    this.errorMessage,
  });

  SettingsState copyWith({
    bool? isLoading,
    UserSettings? settings,
    String? errorMessage,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  final ISettingsRepository _repository;
  final String? _userId;

  SettingsController(this._repository, this._userId)
      : super(SettingsState(
          settings: UserSettings.defaultSettings(userId: _userId ?? 'default'),
        )) {
    if (_userId != null) {
      loadSettings();
    }
  }

  Future<void> loadSettings() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final s = await _repository.getSettings(_userId!);
      state = state.copyWith(isLoading: false, settings: s);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleNotifications(bool val) async {
    final updated = state.settings.copyWith(notificationsEnabled: val);
    state = state.copyWith(settings: updated);
    await _repository.saveSettings(updated);
  }

  Future<void> toggleVoiceAlerts(bool val) async {
    final updated = state.settings.copyWith(voiceAlertsEnabled: val);
    state = state.copyWith(settings: updated);
    await _repository.saveSettings(updated);
  }

  Future<void> setVoiceLanguage(String lang) async {
    final updated = state.settings.copyWith(voiceLanguage: lang);
    state = state.copyWith(settings: updated);
    await _repository.saveSettings(updated);
  }

  Future<void> toggleSmartwatch(bool val) async {
    final updated = state.settings.copyWith(smartwatchAlertsEnabled: val);
    state = state.copyWith(settings: updated);
    await _repository.saveSettings(updated);
  }

  Future<void> toggleCloudSync(bool val) async {
    final updated = state.settings.copyWith(cloudSyncEnabled: val);
    state = state.copyWith(settings: updated);
    await _repository.saveSettings(updated);
  }

  Future<void> toggleLocation(bool val) async {
    final updated = state.settings.copyWith(locationEnabled: val);
    state = state.copyWith(settings: updated);
    await _repository.saveSettings(updated);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  return SettingsController(repo, user?.id);
});
