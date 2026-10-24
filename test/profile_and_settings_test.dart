import 'package:flutter_test/flutter_test.dart';
import 'package:smokeguard/data/models/user_profile.dart';
import 'package:smokeguard/data/models/user_settings.dart';
import 'package:smokeguard/data/repositories/profile_repository.dart';
import 'package:smokeguard/data/repositories/settings_repository.dart';
import 'package:smokeguard/features/profile/profile_controller.dart';
import 'package:smokeguard/features/settings/settings_controller.dart';

void main() {
  group('Phase 3 Profile & Settings Unit Tests', () {
    test('SensitivityLevel factors correspond to PEI requirements', () {
      expect(SensitivityLevel.low.factor, equals(0.8));
      expect(SensitivityLevel.medium.factor, equals(1.0));
      expect(SensitivityLevel.high.factor, equals(1.3));
    });

    test('UserProfile defaults and serialization work', () {
      final profile = UserProfile.defaultProfile(id: 'usr_1', email: 'test@smokeguard.app');
      expect(profile.ageGroup, equals('26-40'));
      expect(profile.sensitivityLevel, equals(SensitivityLevel.medium));

      final json = profile.toJson();
      final parsed = UserProfile.fromJson(json);

      expect(parsed.id, equals(profile.id));
      expect(parsed.sensitivityLevel, equals(SensitivityLevel.medium));
    });

    test('UserSettings default settings check', () {
      final s = UserSettings.defaultSettings(userId: 'usr_1');
      expect(s.notificationsEnabled, isTrue);
      expect(s.voiceAlertsEnabled, isTrue);
      expect(s.voiceLanguage, equals('en'));
      expect(s.locationEnabled, isFalse);
    });

    test('ProfileController updateProfile updates state and repository', () async {
      final repo = MockProfileRepository();
      final controller = ProfileController(repo, 'usr_1', 'user@example.com');

      await controller.loadProfile();
      expect(controller.state.profile?.displayName, isNotEmpty);

      final success = await controller.updateProfile(
        displayName: 'Dr. Jane Doe',
        sensitivityLevel: SensitivityLevel.high,
      );

      expect(success, isTrue);
      expect(controller.state.profile?.displayName, equals('Dr. Jane Doe'));
      expect(controller.state.profile?.sensitivityLevel, equals(SensitivityLevel.high));
    });

    test('SettingsController toggles update state', () async {
      final repo = MockSettingsRepository();
      final controller = SettingsController(repo, 'usr_1');
      await controller.loadSettings();

      expect(controller.state.settings.locationEnabled, isFalse);

      await controller.toggleLocation(true);
      expect(controller.state.settings.locationEnabled, isTrue);

      await controller.setVoiceLanguage('hi');
      expect(controller.state.settings.voiceLanguage, equals('hi'));
    });
  });
}
