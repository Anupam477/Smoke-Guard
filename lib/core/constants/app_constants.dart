class AppConstants {
  AppConstants._();

  static const String appName = 'SmokeGuard';

  // BLE UUIDs
  static const String bleServiceUuid = '00005247-0000-1000-8000-00805f9b34fb';
  static const String bleDataCharUuid = '00005248-0000-1000-8000-00805f9b34fb';
  static const String bleBatteryCharUuid = '00002a19-0000-1000-8000-00805f9b34fb';

  // Storage Keys
  static const String keyDemoMode = 'smokeguard_demo_mode';
  static const String keyThemeMode = 'smokeguard_theme_mode';
  static const String keyLanguage = 'smokeguard_language';
  static const String keyOnboardingComplete = 'smokeguard_onboarding_complete';
  static const String keyUserSensitivity = 'smokeguard_user_sensitivity';

  // PEI Calculation Weight Defaults
  static const double peiWeightPossible = 1.0;
  static const double peiWeightModerate = 2.0;
  static const double peiWeightHigh = 4.0;

  static const double sensitivityLowFactor = 0.8;
  static const double sensitivityMediumFactor = 1.0;
  static const double sensitivityHighFactor = 1.3;

  // Timers & Delays
  static const int calibrationDurationSeconds = 60;
  static const int sensorSyncIntervalSeconds = 30;
}
