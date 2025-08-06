class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? phone;
  final int roleId;
  final String roleName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phone,
    required this.roleId,
    required this.roleName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Alias for fullName to match API response
  String get name => fullName;

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle role_name - it might come directly or from nested role object
    String roleName;
    if (json['role_name'] != null) {
      roleName = json['role_name'] as String;
    } else if (json['role'] != null && json['role']['name'] != null) {
      roleName = json['role']['name'] as String;
    } else {
      roleName = 'Unknown'; // fallback
    }

    return User(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      roleId: (json['role_id'] as num).toInt(),
      roleName: roleName,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role_id': roleId,
      'role_name': roleName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? phone,
    int? roleId,
    String? roleName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, fullName: $fullName, roleName: $roleName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class LoginResponse {
  final String token;
  final User user;

  const LoginResponse({
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String? phone;
  final int roleId;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
    required this.roleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'role_id': roleId,
    };
  }
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'new_password': newPassword,
    };
  }
}
