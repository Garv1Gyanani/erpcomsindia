import 'dart:io';

class FamilyMember {
  final String name;
  final String relation;
  final String occupation;
  final String dob;

  FamilyMember({
    required this.name,
    required this.relation,
    required this.occupation,
    required this.dob,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relation': relation,
      'occupation': occupation,
      'dob': dob,
    };
  }
}

class Education {
  final String degree;
  final String university;
  final String specialization;
  final String fromYear;
  final String toYear;
  final String percentage;

  Education({
    required this.degree,
    required this.university,
    required this.specialization,
    required this.fromYear,
    required this.toYear,
    required this.percentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'university': university,
      'specialization': specialization,
      'from_year': fromYear,
      'to_year': toYear,
      'percentage': percentage,
    };
  }
}

class EPFNominee {
  final String name;
  final String address;
  final String relationship;
  final String dob;
  final String share;
  final String guardian;

  EPFNominee({
    required this.name,
    required this.address,
    required this.relationship,
    required this.dob,
    required this.share,
    required this.guardian,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'relationship': relationship,
      'dob': dob,
      'share': share,
      'guardian': guardian,
    };
  }
}

class EPSNominee {
  final String name;
  final String age;
  final String relationship;

  EPSNominee({
    required this.name,
    required this.age,
    required this.relationship,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'relationship': relationship,
    };
  }
}

class ESICFamily {
  final String name;
  final String dob;
  final String relation;
  final String residing;
  final String residence;

  ESICFamily({
    required this.name,
    required this.dob,
    required this.relation,
    required this.residing,
    required this.residence,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dob': dob,
      'relation': relation,
      'residing': residing,
      'residence': residence,
    };
  }
}

class EmployeeRequestModel {
  final String empName;
  final String gender;
  final String dateOfBirth;
  final String hireDate;
  final String maritalStatus;
  final String bloodGroup;
  final String religion;
  final List<FamilyMember> familyMembers;
  final String departmentId;
  final String designationId;
  final String siteId;
  final String location;
  final String joiningMode;
  final String punchingCode;
  final String emergencyContact;
  final String contactPersonName;
  final String emergencyContactRelation;
  final String email;
  final String phone;
  final List<String> presentAddress;
  final List<String> permanentAddress;
  final List<Education> education;
  final String aadhar;
  final String pan;
  final String bankName;
  final String bankAccount;
  final String ifscCode;
  final String remarks;
  final List<EPFNominee> epf;
  final List<EPSNominee> eps;
  final String witness1Name;
  final String witness2Name;
  final String insuranceNo;
  final String branchOffice;
  final String dispensary;
  final List<ESICFamily> family;
  final String pfMember;
  final String pensionMember;
  final String uanNumber;
  final String previousPfNumber;
  final String exitDate;
  final String schemeCertificate;
  final String ppo;
  final String internationalWorker;
  final String countryOrigin;
  final String passportNumber;
  final String passportValidFrom;
  final String passportValidTo;

  // File fields
  final File? aadharFront;
  final File? aadharBack;
  final File? panFile;
  final File? bankDocument;
  final File? employeeImage;
  final File? signatureThumb;
  final File? witness1Signature;
  final File? witness2Signature;

  EmployeeRequestModel({
    required this.empName,
    required this.gender,
    required this.dateOfBirth,
    required this.hireDate,
    required this.maritalStatus,
    required this.bloodGroup,
    required this.religion,
    required this.familyMembers,
    required this.departmentId,
    required this.designationId,
    required this.siteId,
    required this.location,
    required this.joiningMode,
    required this.punchingCode,
    required this.emergencyContact,
    required this.contactPersonName,
    required this.emergencyContactRelation,
    required this.email,
    required this.phone,
    required this.presentAddress,
    required this.permanentAddress,
    required this.education,
    required this.aadhar,
    required this.pan,
    required this.bankName,
    required this.bankAccount,
    required this.ifscCode,
    required this.remarks,
    required this.epf,
    required this.eps,
    required this.witness1Name,
    required this.witness2Name,
    required this.insuranceNo,
    required this.branchOffice,
    required this.dispensary,
    required this.family,
    required this.pfMember,
    required this.pensionMember,
    required this.uanNumber,
    required this.previousPfNumber,
    required this.exitDate,
    required this.schemeCertificate,
    required this.ppo,
    required this.internationalWorker,
    required this.countryOrigin,
    required this.passportNumber,
    required this.passportValidFrom,
    required this.passportValidTo,
    this.aadharFront,
    this.aadharBack,
    this.panFile,
    this.bankDocument,
    this.employeeImage,
    this.signatureThumb,
    this.witness1Signature,
    this.witness2Signature,
  });

  Map<String, dynamic> toJson() {
    return {
      'emp_name': empName,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'hire_date': hireDate,
      'marital_status': maritalStatus,
      'blood_group': bloodGroup,
      'religion': religion,
      'family_members': familyMembers.map((e) => e.toJson()).toList(),
      'department_id': departmentId,
      'designation_id': designationId,
      'site_id': siteId,
      'location': location,
      'joining_mode': joiningMode,
      'punching_code': punchingCode,
      'emergency_contact': emergencyContact,
      'contact_person_name': contactPersonName,
      'emergency_contact_relation': emergencyContactRelation,
      'email': email,
      'phone': phone,
      'present_address': presentAddress,
      'permanent_address': permanentAddress,
      'education': education.map((e) => e.toJson()).toList(),
      'aadhar': aadhar,
      'pan': pan,
      'bank_name': bankName,
      'bank_account': bankAccount,
      'ifsc_code': ifscCode,
      'remarks': remarks,
      'epf': epf.map((e) => e.toJson()).toList(),
      'eps': eps.map((e) => e.toJson()).toList(),
      'witness1_name': witness1Name,
      'witness2_name': witness2Name,
      'insurance_no': insuranceNo,
      'branch_office': branchOffice,
      'dispensary': dispensary,
      'family': family.map((e) => e.toJson()).toList(),
      'pf_member': pfMember,
      'pension_member': pensionMember,
      'uan_number': uanNumber,
      'previous_pf_number': previousPfNumber,
      'exit_date': exitDate,
      'scheme_certificate': schemeCertificate,
      'ppo': ppo,
      'international_worker': internationalWorker,
      'country_origin': countryOrigin,
      'passport_number': passportNumber,
      'passport_valid_from': passportValidFrom,
      'passport_valid_to': passportValidTo,
    };
  }
}

class EmployeeResponseModel {
  final String status;
  final String message;

  EmployeeResponseModel({
    required this.status,
    required this.message,
  });

  factory EmployeeResponseModel.fromJson(Map<String, dynamic> json) {
    return EmployeeResponseModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
