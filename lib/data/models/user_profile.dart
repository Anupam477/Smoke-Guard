enum SensitivityLevel {
  low,
  medium,
  high;

  double get factor {
    switch (this) {
      case SensitivityLevel.low:
        return 0.8;
      case SensitivityLevel.medium:
        return 1.0;
      case SensitivityLevel.high:
        return 1.3;
    }
  }

  String get displayName {
    switch (this) {
      case SensitivityLevel.low:
        return 'Low Sensitivity (x0.8)';
      case SensitivityLevel.medium:
        return 'Medium Sensitivity (Standard x1.0)';
      case SensitivityLevel.high:
        return 'High Sensitivity (Sensitized x1.3)';
    }
  }
}

class UserProfile {
  final String id;
  final String email;
  final String? phone;
  final String displayName;
  final String ageGroup; // 'Under 18', '18-25', '26-40', '41-60', '60+'
  final SensitivityLevel sensitivityLevel;
  final List<String> healthPreferences; // e.g. ['Asthma', 'Allergies']
  final String preferredLanguage; // 'en' or 'hi'
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasAsthma => healthPreferences.any((h) => h.toLowerCase().contains('asthma'));
  bool get hasCopd => healthPreferences.any((h) => h.toLowerCase().contains('copd'));
  bool get isPregnant => healthPreferences.any((h) => h.toLowerCase().contains('pregnant'));
  bool get isSmoker => healthPreferences.any((h) => h.toLowerCase().contains('smoker'));

  const UserProfile({
    required this.id,
    required this.email,
    this.phone,
    required this.displayName,
    this.ageGroup = '26-40',
    this.sensitivityLevel = SensitivityLevel.medium,
    this.healthPreferences = const [],
    this.preferredLanguage = 'en',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.defaultProfile({required String id, required String email}) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      email: email,
      displayName: email.contains('@') ? email.split('@').first : 'User',
      ageGroup: '26-40',
      sensitivityLevel: SensitivityLevel.medium,
      healthPreferences: const [],
      preferredLanguage: 'en',
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      displayName: json['display_name'] as String? ?? 'User',
      ageGroup: json['age_group'] as String? ?? '26-40',
      sensitivityLevel: SensitivityLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['sensitivity_level'] as String? ?? 'medium').toLowerCase(),
        orElse: () => SensitivityLevel.medium,
      ),
      healthPreferences: (json['health_preferences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'display_name': displayName,
      'age_group': ageGroup,
      'sensitivity_level': sensitivityLevel.name,
      'health_preferences': healthPreferences,
      'preferred_language': preferredLanguage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? email,
    String? phone,
    String? displayName,
    String? ageGroup,
    SensitivityLevel? sensitivityLevel,
    List<String>? healthPreferences,
    String? preferredLanguage,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      ageGroup: ageGroup ?? this.ageGroup,
      sensitivityLevel: sensitivityLevel ?? this.sensitivityLevel,
      healthPreferences: healthPreferences ?? this.healthPreferences,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
