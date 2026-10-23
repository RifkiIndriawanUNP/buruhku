enum UserRole { client, agent }

class User {
  final String id;
  final String phone;
  final String fullName;
  final String? photoUrl;
  final String? defaultAddress;
  final Set<UserRole> roles;
  final bool isAgentVerified;
  final DateTime createdAt;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  User({
    required this.id,
    required this.phone,
    required this.fullName,
    this.photoUrl,
    this.defaultAddress,
    required this.roles,
    this.isAgentVerified = false,
    required this.createdAt,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  User copyWith({
    String? fullName,
    String? photoUrl,
    String? defaultAddress,
    Set<UserRole>? roles,
    bool? isAgentVerified,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) =>
      User(
        id: id,
        phone: phone,
        fullName: fullName ?? this.fullName,
        photoUrl: photoUrl ?? this.photoUrl,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        roles: roles ?? this.roles,
        isAgentVerified: isAgentVerified ?? this.isAgentVerified,
        createdAt: createdAt,
        emergencyContactName:
            emergencyContactName ?? this.emergencyContactName,
        emergencyContactPhone:
            emergencyContactPhone ?? this.emergencyContactPhone,
      );
}