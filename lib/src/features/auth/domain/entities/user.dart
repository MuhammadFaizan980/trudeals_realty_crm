enum UserRole {
  superAdmin('super'),
  sales('sales'),
  support('support');

  final String key;
  const UserRole(this.key);

  static UserRole fromKey(String key) {
    return UserRole.values.firstWhere((e) => e.key == key, orElse: () => UserRole.sales);
  }
}

class User {
  final String id;
  final String name;
  final UserRole role;
  final String dept;
  final String? phone;
  final String? email;
  final String? emailSig;
  final String? smsSig;
  final bool isActive;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.role,
    required this.dept,
    this.phone,
    this.email,
    this.emailSig,
    this.smsSig,
    this.isActive = true,
    this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          role == other.role &&
          dept == other.dept &&
          phone == other.phone &&
          email == other.email &&
          emailSig == other.emailSig &&
          smsSig == other.smsSig &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      role.hashCode ^
      dept.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      emailSig.hashCode ^
      smsSig.hashCode ^
      isActive.hashCode;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id']).toString(),
      name: json['name'] as String,
      role: UserRole.fromKey(json['role'] as String),
      dept: json['dept'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      emailSig: json['emailSig'] as String?,
      smsSig: json['smsSig'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role.key,
      'dept': dept,
      'phone': phone,
      'email': email,
      'emailSig': emailSig,
      'smsSig': smsSig,
      'isActive': isActive,
    };
  }
}
