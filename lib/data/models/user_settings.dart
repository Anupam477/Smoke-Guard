class UserSettings {
  final String userId;
  final bool notificationsEnabled;
  final bool voiceAlertsEnabled;
  final String voiceLanguage; // 'en' or 'hi'
  final String voiceAlertFrequency; // 'low', 'normal', 'high'
  final bool smartwatchAlertsEnabled;
  final bool cloudSyncEnabled;
  final bool locationEnabled;
  final DateTime updatedAt;

  const UserSettings({
    required this.userId,
    this.notificationsEnabled = true,
    this.voiceAlertsEnabled = true,
    this.voiceLanguage = 'en',
    this.voiceAlertFrequency = 'normal',
    this.smartwatchAlertsEnabled = true,
    this.cloudSyncEnabled = true,
    this.locationEnabled = false,
    required this.updatedAt,
  });

  factory UserSettings.defaultSettings({required String userId}) {
    return UserSettings(
      userId: userId,
      notificationsEnabled: true,
      voiceAlertsEnabled: true,
      voiceLanguage: 'en',
      voiceAlertFrequency: 'normal',
      smartwatchAlertsEnabled: true,
      cloudSyncEnabled: true,
      locationEnabled: false,
      updatedAt: DateTime.now(),
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'] as String,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      voiceAlertsEnabled: json['voice_alerts_enabled'] as bool? ?? true,
      voiceLanguage: json['voice_language'] as String? ?? 'en',
      voiceAlertFrequency: json['voice_alert_frequency'] as String? ?? 'normal',
      smartwatchAlertsEnabled: json['smartwatch_alerts_enabled'] as bool? ?? true,
      cloudSyncEnabled: json['cloud_sync_enabled'] as bool? ?? true,
      locationEnabled: json['location_enabled'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'notifications_enabled': notificationsEnabled,
      'voice_alerts_enabled': voiceAlertsEnabled,
      'voice_language': voiceLanguage,
      'voice_alert_frequency': voiceAlertFrequency,
      'smartwatch_alerts_enabled': smartwatchAlertsEnabled,
      'cloud_sync_enabled': cloudSyncEnabled,
      'location_enabled': locationEnabled,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? voiceAlertsEnabled,
    String? voiceLanguage,
    String? voiceAlertFrequency,
    bool? smartwatchAlertsEnabled,
    bool? cloudSyncEnabled,
    bool? locationEnabled,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      voiceAlertsEnabled: voiceAlertsEnabled ?? this.voiceAlertsEnabled,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      voiceAlertFrequency: voiceAlertFrequency ?? this.voiceAlertFrequency,
      smartwatchAlertsEnabled: smartwatchAlertsEnabled ?? this.smartwatchAlertsEnabled,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
