
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
             ? List<String>.from(json['roles'].map((role) => 
                 role is String ? role : (role['name'] ?? '')))
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
  final EmployeeModel? employee;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.employee,
    this.roles = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Extract roles from the complex structure
    List<String> rolesList = [];
    if (json['roles'] != null) {
      if (json['roles'] is List) {
        rolesList = (json['roles'] as List).map((role) {
          if (role is String) {
            return role;
          } else if (role is Map) {
            return role['name'] as String? ?? '';
          }
          return '';
        }).toList();
      }
    }

    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      employee: json['employee'] != null
          ? EmployeeModel.fromJson(json['employee'])
          : null,
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
      'employee': employee?.toJson(),
      'roles': roles,
    };
  }
}

// employee_model.dart
class EmployeeModel {
  final int id;
  final int userId;
  final String name;
  final String employeeId;
  final String? gender;
  final String? dateOfBirth;
  final String? hireDate;
  final String? maritalStatus;
  final String? bloodGroup;
  final String? fatherHusbandName;
  final String? motherName;
  final String? spouseName;
  final String? childName1;
  final String? childName2;
  final int? departmentId;
  final int? designationId;
  final String? location;
  final String? emergencyContact;
  final String? emergencyContactRelation;
  final String? presentAddress;
  final String? permanentAddress;
  final String? aadhar;
  final String? pan;
  final String? bankName;
  final String? bankAccount;
  final String? ifscCode;
  final String? employeeImage;
  final String? createdAt;
  final String? updatedAt;

  EmployeeModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.employeeId,
    this.gender,
    this.dateOfBirth,
    this.hireDate,
    this.maritalStatus,
    this.bloodGroup,
    this.fatherHusbandName,
    this.motherName,
    this.spouseName,
    this.childName1,
    this.childName2,
    this.departmentId,
    this.designationId,
    this.location,
    this.emergencyContact,
    this.emergencyContactRelation,
    this.presentAddress,
    this.permanentAddress,
    this.aadhar,
    this.pan,
    this.bankName,
    this.bankAccount,
    this.ifscCode,
    this.employeeImage,
    this.createdAt,
    this.updatedAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      employeeId: json['employee_id'] ?? '',
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      hireDate: json['hire_date'],
      maritalStatus: json['marital_status'],
      bloodGroup: json['blood_group'],
      fatherHusbandName: json['father_husband_name'],
      motherName: json['mother_name'],
      spouseName: json['spouse_name'],
      childName1: json['child_name_1'],
      childName2: json['child_name_2'],
      departmentId: json['department_id'],
      designationId: json['designation_id'],
      location: json['location'],
      emergencyContact: json['emergency_contact'],
      emergencyContactRelation: json['emergency_contact_relation'],
      presentAddress: json['present_address'],
      permanentAddress: json['permanent_address'],
      aadhar: json['aadhar'],
      pan: json['pan'],
      bankName: json['bank_name'],
      bankAccount: json['bank_account'],
      ifscCode: json['ifsc_code'],
      employeeImage: json['employee_image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'employee_id': employeeId,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'hire_date': hireDate,
      'marital_status': maritalStatus,
      'blood_group': bloodGroup,
      'father_husband_name': fatherHusbandName,
      'mother_name': motherName,
      'spouse_name': spouseName,
      'child_name_1': childName1,
      'child_name_2': childName2,
      'department_id': departmentId,
      'designation_id': designationId,
      'location': location,
      'emergency_contact': emergencyContact,
      'emergency_contact_relation': emergencyContactRelation,
      'present_address': presentAddress,
      'permanent_address': permanentAddress,
      'aadhar': aadhar,
      'pan': pan,
      'bank_name': bankName,
      'bank_account': bankAccount,
      'ifsc_code': ifscCode,
      'employee_image': employeeImage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// role_model.dart
class RoleModel {
  final int id;
  final String name;
  final String guardName;
  final String? createdAt;
  final String? updatedAt;

  RoleModel({
    required this.id,
    required this.name,
    required this.guardName,
    this.createdAt,
    this.updatedAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      guardName: json['guard_name'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'guard_name': guardName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}