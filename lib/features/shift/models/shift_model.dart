// Static data models - API integration will be added later when API is available
class ShiftModel {
  final int id;
  final String shiftName;
  final String startTime;
  final String endTime;
  final String siteDetails;
  final List<String> workingDays;
  final bool isActive;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ShiftModel({
    required this.id,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.siteDetails,
    required this.workingDays,
    required this.isActive,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  // JSON methods for static data - will be updated when API is available
  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] ?? 0,
      shiftName: json['shiftName'] ?? json['shift_name'] ?? '',
      startTime: json['startTime'] ?? json['start_time'] ?? '',
      endTime: json['endTime'] ?? json['end_time'] ?? '',
      siteDetails: json['siteDetails'] ?? json['site_details'] ?? '',
      workingDays:
          List<String>.from(json['workingDays'] ?? json['working_days'] ?? []),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : (json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'])
              : null),
    );
  }

  // Factory method specifically for API response format
  factory ShiftModel.fromApiJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['shift_id'] ?? 0,
      shiftName: json['shift_name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      siteDetails: '', // Will be set from site context
      workingDays: [], // API doesn't provide working days in this format
      isActive: (json['is_active'] ?? 1) == 1,
      isDefault: (json['is_default'] ?? 0) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shiftName': shiftName, // API will use 'shift_name'
      'startTime': startTime, // API will use 'start_time'
      'endTime': endTime, // API will use 'end_time'
      'siteDetails': siteDetails, // API will use 'site_details'
      'workingDays': workingDays, // API will use 'working_days'
      'isActive': isActive, // API will use 'is_active'
      'createdAt': createdAt?.toIso8601String(), // API will use 'created_at'
      'updatedAt': updatedAt?.toIso8601String(), // API will use 'updated_at'
    };
  }

  // Calculate shift duration in hours
  double get duration {
    try {
      final start = _timeToDouble(startTime);
      final end = _timeToDouble(endTime);

      if (end > start) {
        return end - start;
      } else {
        // Handle overnight shifts
        return (24 - start) + end;
      }
    } catch (e) {
      return 0.0;
    }
  }

  // Check if shift is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    final currentTime = now.hour + (now.minute / 60);
    final start = _timeToDouble(startTime);
    final end = _timeToDouble(endTime);

    if (end > start) {
      // Same day shift
      return currentTime >= start && currentTime <= end;
    } else {
      // Overnight shift
      return currentTime >= start || currentTime <= end;
    }
  }

  // Format time range in AM/PM format
  String get formattedTimeRange {
    return '${_formatTimeToAMPM(startTime)} - ${_formatTimeToAMPM(endTime)}';
  }

  // Helper method to format individual time to AM/PM
  String _formatTimeToAMPM(String time24) {
    try {
      // Handle both HH:mm and HH:mm:ss formats
      String timeWithoutSeconds = time24;
      if (time24.contains(':')) {
        final parts = time24.split(':');
        if (parts.length >= 2) {
          // Take only hours and minutes, ignore seconds
          timeWithoutSeconds = '${parts[0]}:${parts[1]}';
        }
      }

      final parts = timeWithoutSeconds.split(':');
      if (parts.length != 2) return time24;

      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return time24; // Return original if invalid
      }

      String period = hour >= 12 ? 'PM' : 'AM';

      // Convert to 12-hour format
      if (hour == 0) {
        hour = 12; // 12 AM
      } else if (hour > 12) {
        hour = hour - 12; // PM hours
      }

      // Format with leading zero for minutes
      String minuteStr = minute.toString().padLeft(2, '0');

      return '$hour:$minuteStr $period';
    } catch (e) {
      return time24; // Return original if parsing fails
    }
  }

  // Helper method to convert time string to double
  double _timeToDouble(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return hour + (minute / 60);
    }
    return 0.0;
  }

  @override
  String toString() {
    return 'ShiftModel(id: $id, shiftName: $shiftName, startTime: $startTime, endTime: $endTime, isActive: $isActive)';
  }
}

class ShiftCreateModel {
  final String shiftName;
  final String startTime;
  final String endTime;
  final String siteDetails;
  final List<String> workingDays;
  final bool isActive;

  ShiftCreateModel({
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    this.siteDetails = '',
    required this.workingDays,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'shiftName': shiftName, // API will use 'shift_name'
      'startTime': startTime, // API will use 'start_time'
      'endTime': endTime, // API will use 'end_time'
      'siteDetails': siteDetails, // API will use 'site_details'
      'workingDays': workingDays, // API will use 'working_days'
      'isActive': isActive, // API will use 'is_active'
    };
  }
}

class ShiftResponseModel {
  final String status;
  final String message;
  final List<ShiftModel>? shifts;
  final ShiftModel? shift;

  ShiftResponseModel({
    required this.status,
    required this.message,
    this.shifts,
    this.shift,
  });

  factory ShiftResponseModel.fromJson(Map<String, dynamic> json) {
    return ShiftResponseModel(
      status: json['status'] ?? 'success',
      message: json['message'] ?? '',
      shifts: json['shifts'] != null
          ? (json['shifts'] as List)
              .map((shift) => ShiftModel.fromJson(shift))
              .toList()
          : null,
      shift: json['shift'] != null ? ShiftModel.fromJson(json['shift']) : null,
    );
  }
}

// New models for site shift API response
class SiteShiftModel {
  final int siteId;
  final String siteName;
  final List<ShiftModel> shifts;

  SiteShiftModel({
    required this.siteId,
    required this.siteName,
    required this.shifts,
  });

  factory SiteShiftModel.fromJson(Map<String, dynamic> json) {
    return SiteShiftModel(
      siteId: json['site_id'] ?? 0,
      siteName: json['site_name'] ?? '',
      shifts: json['shifts'] != null
          ? (json['shifts'] as List)
              .map((shift) => ShiftModel.fromApiJson(shift))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'site_id': siteId,
      'site_name': siteName,
      'shifts': shifts.map((shift) => shift.toJson()).toList(),
    };
  }
}

class SiteShiftResponseModel {
  final bool status;
  final String message;
  final List<SiteShiftModel> data;

  SiteShiftResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SiteShiftResponseModel.fromJson(Map<String, dynamic> json) {
    return SiteShiftResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((site) => SiteShiftModel.fromJson(site))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((site) => site.toJson()).toList(),
    };
  }

  // Helper method to get all shifts from all sites
  List<ShiftModel> getAllShifts() {
    List<ShiftModel> allShifts = [];
    for (var site in data) {
      for (var shift in site.shifts) {
        // Add site name to shift details for context
        final updatedShift = ShiftModel(
          id: shift.id,
          shiftName: shift.shiftName,
          startTime: shift.startTime,
          endTime: shift.endTime,
          siteDetails: '${site.siteName} - ${shift.siteDetails}'.trim(),
          workingDays: shift.workingDays,
          isActive: shift.isActive,
          isDefault: shift.isDefault,
          createdAt: shift.createdAt,
          updatedAt: shift.updatedAt,
        );
        allShifts.add(updatedShift);
      }
    }
    return allShifts;
  }
}

// New models for assigned sites API
class AssignedSiteModel {
  final int id;
  final int userId;
  final int siteId;
  final String siteName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AssignedSiteModel({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.siteName,
    this.createdAt,
    this.updatedAt,
  });

  factory AssignedSiteModel.fromJson(Map<String, dynamic> json) {
    return AssignedSiteModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      siteName: json['site']?['site_name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'site_id': siteId,
      'site_name': siteName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class AssignedSitesResponseModel {
  final List<AssignedSiteModel> sites;

  AssignedSitesResponseModel({
    required this.sites,
  });

  factory AssignedSitesResponseModel.fromJson(Map<String, dynamic> json) {
    return AssignedSitesResponseModel(
      sites: json['user'] != null
          ? (json['user'] as List)
              .map((site) => AssignedSiteModel.fromJson(site))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': sites.map((site) => site.toJson()).toList(),
    };
  }

  // Helper method to get site names
  List<String> getSiteNames() {
    return sites.map((site) => site.siteName).toList();
  }
}

// New models for all shifts API
class AllShiftModel {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final double durationHours;
  final bool isOvertimeAllowed;
  final bool isActive;

  AllShiftModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.isOvertimeAllowed,
    required this.isActive,
  });

  factory AllShiftModel.fromJson(Map<String, dynamic> json) {
    return AllShiftModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      durationHours: (json['duration_hours'] ?? 0).toDouble(),
      isOvertimeAllowed: (json['is_overtime_allowed'] ?? 0) == 1,
      isActive: (json['is_active'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'duration_hours': durationHours,
      'is_overtime_allowed': isOvertimeAllowed ? 1 : 0,
      'is_active': isActive ? 1 : 0,
    };
  }

  // Convert to ShiftModel for UI compatibility
  ShiftModel toShiftModel() {
    return ShiftModel(
      id: id,
      shiftName: name,
      startTime: startTime,
      endTime: endTime,
      siteDetails: '',
      workingDays: [],
      isActive: isActive,
    );
  }

  // Calculate shift duration in hours (for display)
  double get duration => durationHours;
}

class AllShiftsResponseModel {
  final bool status;
  final String message;
  final List<AllShiftModel> data;

  AllShiftsResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AllShiftsResponseModel.fromJson(Map<String, dynamic> json) {
    return AllShiftsResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((shift) => AllShiftModel.fromJson(shift))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((shift) => shift.toJson()).toList(),
    };
  }

  // Helper method to convert to ShiftModel list for UI
  List<ShiftModel> toShiftModels() {
    return data.map((shift) => shift.toShiftModel()).toList();
  }
}

// Model for create shift response
class CreateShiftResponseModel {
  final bool status;
  final String message;
  final AllShiftModel? data;

  CreateShiftResponseModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory CreateShiftResponseModel.fromJson(Map<String, dynamic> json) {
    return CreateShiftResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AllShiftModel.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

// Model for assign shifts response
class AssignShiftsResponseModel {
  final bool status;
  final String message;
  final List<dynamic> data;

  AssignShiftsResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AssignShiftsResponseModel.fromJson(Map<String, dynamic> json) {
    return AssignShiftsResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data,
    };
  }
}
