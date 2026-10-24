class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String? displayName;
  final bool isDemoUser;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.displayName,
    this.isDemoUser = false,
    required this.createdAt,
  });

  factory UserModel.demo() {
    return UserModel(
      id: 'demo-user-uuid-12345',
      email: 'demo@smokeguard.app',
      displayName: 'Demo User',
      isDemoUser: true,
      createdAt: DateTime.now(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      displayName: json['display_name'] as String?,
      isDemoUser: json['is_demo'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'display_name': displayName,
      'is_demo': isDemoUser,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
