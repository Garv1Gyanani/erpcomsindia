import 'package:coms_india/features/auth/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart'; // Added for Color
import 'package:http/http.dart' as http; // Import http
import 'dart:convert'; // Import json
import 'package:coms_india/core/services/storage_service.dart'; // Import storage service

class AttendanceDetailResponse {
  final bool status;
  final String message;
  final List<AttendanceDetail> data;

  AttendanceDetailResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AttendanceDetailResponse.fromJson(Map<String, dynamic> json) {
    final bool status = json['status'] ?? false;
    final String message = json['message'] ?? '';
    final List<AttendanceDetail> data = [];

    // Only try to parse data if it exists and is a list
    if (json['data'] != null && json['data'] is List) {
      data.addAll((json['data'] as List<dynamic>)
          .map((e) => AttendanceDetail.fromJson(e as Map<String, dynamic>))
          .toList());
    }

    // If status is false, throw an exception with the API message
    if (!status) {
      throw Exception(message);
    }

    return AttendanceDetailResponse(
      status: status,
      message: message,
      data: data,
    );
  }
}

class AttendanceDetail {
  final int id;
  final int userId;
  final int siteId;
  final int shiftId;
  final DateTime? punchIn;
  final DateTime? punchOut;
  final bool isWeekend;
  final String? totalWorkHours;
  final String? overtimeHours;
  final int? lateByMinutes;
  final int? leftEarlyByMinutes;
  final String? status;
  final int markedBy;
  final String? remarks;
  final UserModel user;

  AttendanceDetail({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.shiftId,
    this.punchIn,
    this.punchOut,
    required this.isWeekend,
    this.totalWorkHours,
    this.overtimeHours,
    this.lateByMinutes,
    this.leftEarlyByMinutes,
    this.status,
    required this.markedBy,
    this.remarks,
    required this.user,
  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceDetail(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      shiftId: json['shift_id'] ?? 0,
      punchIn:
          json['punch_in'] != null ? DateTime.parse(json['punch_in']) : null,
      punchOut:
          json['punch_out'] != null ? DateTime.parse(json['punch_out']) : null,
      isWeekend: (json['is_weekend'] ?? 0) == 1,
      totalWorkHours: json['total_work_hours'],
      overtimeHours: json['overtime_hours'],
      lateByMinutes: json['late_by_minutes'],
      leftEarlyByMinutes: json['left_early_by_minutes'],
      status: json['status'],
      markedBy: json['marked_by'] ?? 0,
      remarks: json['remarks'],
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  String get formattedPunchInDate {
    if (punchIn == null) return 'N/A';
    return DateFormat('dd MMM, yyyy').format(punchIn!);
  }

  String get formattedPunchInTime {
    if (punchIn == null) return 'N/A';
    final istTime = punchIn!.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('h:mm a').format(istTime);
  }

  String get formattedPunchOutTime {
    if (punchOut == null) return 'N/A';
    final istTime =
        punchOut!.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('h:mm a').format(istTime);
  }
}

class ShiftResponseModel {
  final bool status;
  final String message;
  final List<ShiftData> data;

  ShiftResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ShiftResponseModel.fromJson(Map<String, dynamic> json) {
    return ShiftResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)
              ?.map((e) => ShiftData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ShiftData {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final int durationHours;
  final bool isOvertimeAllowed;
  final bool isActive;

  ShiftData({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.isOvertimeAllowed,
    required this.isActive,
  });

  factory ShiftData.fromJson(Map<String, dynamic> json) {
    return ShiftData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      durationHours: json['duration_hours'] ?? 0,
      isOvertimeAllowed: (json['is_overtime_allowed'] ?? 0) == 1,
      isActive: (json['is_active'] ?? 0) == 1,
    );
  }

  // Format time to AM/PM format
  String formattedTimeRange() {
    return '${formatTimeToAMPM(startTime)} - ${formatTimeToAMPM(endTime)}';
  }

  String formatTimeToAMPM(String time24) {
    try {
      final parsedTime = DateFormat('HH:mm:ss').parse(time24);
      return DateFormat('h:mm a').format(parsedTime);
    } catch (e) {
      return time24;
    }
  }
}

class AttendanceEmployeeResponse {
  final bool status;
  final String message;
  final List<AttendanceEmployeeData> data;
  final Map<String, AttendanceStatus> attendanceStatus;

  AttendanceEmployeeResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.attendanceStatus,
  });

  factory AttendanceEmployeeResponse.fromJson(Map<String, dynamic> json) {
    // Parse attendance status
    final Map<String, AttendanceStatus> attendanceStatus = {};
    final dynamic attendanceStatusData = json['Attendance_status'];

    if (attendanceStatusData is List<dynamic>) {
      // Case 1: Attendance_status is a list
      for (var item in attendanceStatusData) {
        if (item is Map<String, dynamic>) {
          final userId = item['user_id']?.toString();
          if (userId != null) {
            attendanceStatus[userId] = AttendanceStatus.fromJson(item);
          }
        }
      }
    } else if (attendanceStatusData is Map<String, dynamic>) {
      // Case 2: Attendance_status is a map (handle as before)
      attendanceStatusData.forEach((userId, statusData) {
        if (statusData is Map<String, dynamic>) {
          attendanceStatus[userId] = AttendanceStatus.fromJson(statusData);
        }
      });
    } else {
      // Case 3: Attendance_status is null or something else unexpected
      print(
          "Warning: Unexpected type for Attendance_status: ${attendanceStatusData.runtimeType}");
      // You might want to log an error or handle this differently
    }

    return AttendanceEmployeeResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)
              ?.map((e) =>
                  AttendanceEmployeeData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attendanceStatus: attendanceStatus,
    );
  }
}

class AttendanceStatus {
  final int userId;
  final DateTime? punchIn;
  final DateTime? punchOut;
  final String status;

  AttendanceStatus({
    required this.userId,
    this.punchIn,
    this.punchOut,
    required this.status,
  });

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    return AttendanceStatus(
      userId: json['user_id'] ?? 0,
      punchIn:
          json['punch_in'] != null ? DateTime.parse(json['punch_in']) : null,
      punchOut:
          json['punch_out'] != null ? DateTime.parse(json['punch_out']) : null,
      status: json['status'] ?? '',
    );
  }

  // Helper methods
  bool get isOnDuty => status.toLowerCase() == 'on_duty';
  bool get isOffDuty =>
      status.toLowerCase() == 'absent' || status.toLowerCase() == 'off_duty';
  bool get isAbsent => status.toLowerCase() == 'absent';

  bool get isWeekend => status.toLowerCase() == 'weekend';

  String get formattedStatus {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String get punchInTime {
    if (punchIn == null) return 'N/A';
    final istTime = punchIn!.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('h:mm a').format(istTime);
  }

  String get punchOutTime {
    if (punchOut == null) return 'N/A';
    final istTime =
        punchOut!.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('h:mm a').format(istTime);
  }
}

class AttendanceEmployeeData {
  final int id;
  final int userId;
  final int siteId;
  final int shiftId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserData user;
  final SiteData site;
  final bool isWeekend;

  AttendanceEmployeeData({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.shiftId,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.site,
    required this.isWeekend,
  });

  factory AttendanceEmployeeData.fromJson(Map<String, dynamic> json) {
    return AttendanceEmployeeData(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      shiftId: json['shift_id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      user: UserData.fromJson(json['user'] ?? {}),
      site: SiteData.fromJson(json['site'] ?? {}),
      isWeekend: json['isWeekend'] ?? false,
    );
  }
}

class SiteData {
  final int id;
  final String siteName;
  final String weekendStatus;
  final String weekendDay;

  SiteData({
    required this.id,
    required this.siteName,
    required this.weekendStatus,
    required this.weekendDay,
  });

  factory SiteData.fromJson(Map<String, dynamic> json) {
    return SiteData(
      id: json['id'] ?? 0,
      siteName: json['site_name'] ?? '',
      weekendStatus: json['weekendStatus'] ?? '',
      weekendDay: json['weekendDay'] ?? '',
    );
  }
}

class UserData {
  final int id;
  final String name;
  final String email;
  final String phone;
  final EmployeeData? employee;
  final String? employeeImage;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.employee,
    this.employeeImage,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      employee: json['employee'] != null
          ? EmployeeData.fromJson(json['employee'])
          : null,
      employeeImage: json['employee_image'],
    );
  }
}

class EmployeeData {
  final int userId;
  final String? employeeImagePath;

  EmployeeData({
    required this.userId,
    this.employeeImagePath,
  });

  factory EmployeeData.fromJson(Map<String, dynamic> json) {
    return EmployeeData(
      userId: json['user_id'] ?? 0,
      employeeImagePath: json['employee_image_path'],
    );
  }
}

class PunchResponse {
  final bool status;
  final String message;
  final PunchData data;

  PunchResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PunchResponse.fromJson(Map<String, dynamic> json) {
    return PunchResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: PunchData.fromJson(json['data'] ?? {}),
    );
  }
}

class PunchData {
  final List<String> punched;
  final List<String> skippedAlreadyPunchedIn;
  final List<String>? punchedOut;
  final List<String>? skipped;

  PunchData({
    required this.punched,
    required this.skippedAlreadyPunchedIn,
    this.punchedOut,
    this.skipped,
  });

  factory PunchData.fromJson(Map<String, dynamic> json) {
    return PunchData(
      punched: List<String>.from(json['punched'] ?? []),
      skippedAlreadyPunchedIn:
          List<String>.from(json['skipped_already_punched_in'] ?? []),
      punchedOut: json['punched_out'] != null
          ? List<String>.from(json['punched_out'])
          : null,
      skipped:
          json['skipped'] != null ? List<String>.from(json['skipped']) : null,
    );
  }
}

class AttendanceViewResponse {
  final bool status;
  final String message;
  final Map<String, List<AttendanceEmployee>> employees;

  AttendanceViewResponse({
    required this.status,
    required this.message,
    required this.employees,
  });

  factory AttendanceViewResponse.fromJson(Map<String, dynamic> json) {
    final employeesData = json['employees'] as Map<String, dynamic>? ?? {};
    final Map<String, List<AttendanceEmployee>> employees = {};

    employeesData.forEach((siteName, employeeList) {
      if (employeeList is List) {
        employees[siteName] = employeeList
            .map((e) => AttendanceEmployee.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint(
            "Expected list for site '$siteName', but got ${employeeList.runtimeType}");
      }
    });

    return AttendanceViewResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      employees: employees,
    );
  }
}

class AttendanceEmployee {
  final int id;
  final String name;
  final String empId;
  final List<dynamic> roles;
  final String department;
  final String designation;
  final String site;
  final String? employeeImagePath;
  final AttendanceRecord? attendance;
  final Map<String, List<AttendanceEmployee>> juniors;

  AttendanceEmployee({
    required this.id,
    required this.name,
    required this.empId,
    required this.roles,
    required this.department,
    required this.designation,
    required this.site,
    this.employeeImagePath,
    this.attendance,
    required this.juniors,
  });

  factory AttendanceEmployee.fromJson(Map<String, dynamic> json) {
    // Parse juniors correctly as Map<String, List<AttendanceEmployee>>
    final Map<String, List<AttendanceEmployee>> parsedJuniors = {};
    final juniorsData = json['juniors'];

    if (juniorsData is Map<String, dynamic>) {
      juniorsData.forEach((site, juniorList) {
        if (juniorList is List) {
          parsedJuniors[site] = juniorList
              .map(
                  (e) => AttendanceEmployee.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      });
    }

    return AttendanceEmployee(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      empId: json['empId'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      site: json['site'] ?? '',
      employeeImagePath: json['employee_image_path'] ?? '',
      attendance: json['attendance'] != null
          ? AttendanceRecord.fromJson(
              json['attendance'] as Map<String, dynamic>)
          : null,
      juniors: parsedJuniors,
    );
  }

  // Helper methods
  bool get isOnDuty => attendance != null && attendance!.status == 'on_duty';
  bool get isOffDuty =>
      attendance != null &&
      (attendance!.status == 'absent' || attendance!.status == 'off_duty') &&
      attendance!.punchOut != null;
  bool get isAbsent => attendance != null && attendance!.status == 'absent';
  bool get hasAttendanceToday => attendance != null;

  String get currentStatus {
    if (!hasAttendanceToday) return 'Not Punched In';

    final latestAttendance = attendance!;
    // Return the exact status from backend, properly formatted
    return latestAttendance.status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Color get statusColor {
    if (!hasAttendanceToday) return Colors.grey;

    final latestAttendance = attendance!;
    switch (latestAttendance.status.toLowerCase()) {
      case 'on_duty':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'off_duty':
      case 'half_day':
        return Colors.orange;
      case 'present':
        return Colors.blue;
      case 'late':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

class AttendanceRecord {
  final DateTime? punchIn;
  final DateTime? punchOut;
  final String status;
  final String? totalWorkHours;
  final String overtimeHours;
  final int lateBy;

  AttendanceRecord({
    this.punchIn,
    this.punchOut,
    required this.status,
    this.totalWorkHours,
    required this.overtimeHours,
    required this.lateBy,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      punchIn:
          json['punch_in'] != null ? DateTime.parse(json['punch_in']) : null,
      punchOut:
          json['punch_out'] != null ? DateTime.parse(json['punch_out']) : null,
      status: json['status'] ?? '',
      totalWorkHours: json['total_work_hours']?.toString(),
      overtimeHours: json['overtime_hours']?.toString() ?? '0.00',
      lateBy: json['late_by_minutes'] ?? 0,
    );
  }

  // Helper methods
  String get punchInTime {
    if (punchIn == null) return 'N/A';
    final istTime = punchIn!.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('h:mm a').format(istTime);
  }

  String get punchOutTime {
    if (punchOut == null) return 'N/A';
    final istTime =
        punchOut!.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('h:mm a').format(istTime);
  }

  String get lateByText {
    if (lateBy <= 0) return 'On time';
    final hours = lateBy ~/ 60;
    final minutes = lateBy % 60;
    if (hours > 0) {
      return 'Late by ${hours}h ${minutes}m';
    } else {
      return 'Late by ${minutes}m';
    }
  }
}
