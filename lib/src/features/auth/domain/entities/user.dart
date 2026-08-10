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
  final String password;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.role,
    required this.dept,
    this.phone,
    this.email,
    this.emailSig,
    this.smsSig,
    required this.password,
    this.isActive = true,
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
          password == other.password &&
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
      password.hashCode ^
      isActive.hashCode;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      role: UserRole.fromKey(json['role'] as String),
      dept: json['dept'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      emailSig: json['emailSig'] as String?,
      smsSig: json['smsSig'] as String?,
      password: json['password'] as String? ?? 'demo',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.key,
      'dept': dept,
      'phone': phone,
      'email': email,
      'emailSig': emailSig,
      'smsSig': smsSig,
      'password': password,
      'isActive': isActive,
    };
  }
}
