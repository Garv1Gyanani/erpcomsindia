class AuthModel {
  final bool status;
  final String message;
  final String? token;
  final String? tokenType;
  final int? expiresIn;
  final UserModel? user;
  final List<String>? roles;

  AuthModel({
    required this.status,
    required this.message,
    this.token,
    this.tokenType,
    this.expiresIn,
    this.user,
    this.roles,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      roles: json['roles'] != null
          ? (json['roles'] is List
              ? List<String>.from(json['roles']
                  .map((role) => role is String ? role : (role['name'] ?? '')))
              : null)
          : null,
    );
  }
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? emailVerifiedAt;
  final String? createdAt;
  final String? updatedAt;
  final List<RoleModel> roles; // Changed to List<RoleModel>

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.roles = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Extract roles from the new structure
    List<RoleModel> rolesList = [];
    if (json['roles'] != null && json['roles'] is List) {
      rolesList = (json['roles'] as List).map((role) {
        if (role is Map<String, dynamic>) {
          return RoleModel.fromJson(role);
        }
        return RoleModel(id: 0, name: '', guardName: '');
      }).toList();
    }

    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      roles: rolesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'roles': roles.map((role) => role.toJson()).toList(),
    };
  }

  List<String> get roleNames => roles.map((role) => role.name).toList();
}

// New RoleModel class to handle the role structure
class RoleModel {
  final int id;
  final String name;
  final String guardName;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? pivot;

  RoleModel({
    required this.id,
    required this.name,
    required this.guardName,
    this.createdAt,
    this.updatedAt,
    this.pivot,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      guardName: json['guard_name'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      pivot: json['pivot'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'guard_name': guardName,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'pivot': pivot,
    };
  }
}
