import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../../../core/services/storage_service.dart';

class AttendanceController extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<ShiftData> _shifts = [];
  List<AttendanceEmployeeData> _employees = [];
  Map<String, List<AttendanceEmployee>> _attendanceView = {};
  Map<String, AttendanceStatus> _attendanceStatus = {};
  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedShiftId;
  int? _selectedSiteId;

  // Getters
  List<ShiftData> get shifts => _shifts;
  List<AttendanceEmployeeData> get employees => _employees;
  Map<String, List<AttendanceEmployee>> get attendanceView => _attendanceView;
  Map<String, AttendanceStatus> get attendanceStatus => _attendanceStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get selectedShiftId => _selectedShiftId;
  int? get selectedSiteId => _selectedSiteId;

  // **NEW METHOD**: Clear all cached data when switching users
  void clearAllData() {
    _shifts.clear();
    _employees.clear();
    _attendanceView.clear();
    _attendanceStatus.clear();
    _selectedShiftId = null;
    _selectedSiteId = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Set selected shift
  void setSelectedShift(int? shiftId) {
    _selectedShiftId = shiftId;
    notifyListeners();
  }

  // Set selected site
  void setSelectedSite(int? siteId) {
    _selectedSiteId = siteId;
    notifyListeners();
  }

  // Fetch all shifts
  Future<void> fetchShifts() async {
    try {
      setState(true, null);

      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        setState(false, 'Authentication token not found. Please login again.');
        return;
      }

      final response = await http.get(
        Uri.parse('https://erp.comsindia.in/api/shift/index'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final shiftResponse = ShiftResponseModel.fromJson(responseData);

        if (shiftResponse.status) {
          _shifts = shiftResponse.data;
          setState(false, null);
        } else {
          setState(false, shiftResponse.message);
        }
      } else {
        setState(
            false, 'Failed to load shifts. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(
          false, 'Network error. Please check your connection and try again.');
    }
  }

  // Fetch employees by shift
  Future<void> fetchEmployeesByShift(int shiftId) async {
    try {
      print('Fetching employees for shift ID: $shiftId');

      setState(true, null);
      _employees.clear(); // Clear previous list
      _attendanceStatus.clear(); // Clear previous statuses

      final token = await _storageService.getToken();
      print('Retrieved token: $token');

      if (token == null || token.isEmpty) {
        print('Token not found or empty');
        setState(false, 'Authentication token not found. Please login again.');
        return;
      }

      final url =
          'https://erp.comsindia.in/api/attendance/TeamMembersBy/shift/$shiftId';
      print('Making request to URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Decoded response: $responseData');

        final employeeResponse =
            AttendanceEmployeeResponse.fromJson(responseData);
        print('Parsed employee response: ${employeeResponse.toString()}');

        if (employeeResponse.status) {
          _employees = employeeResponse.data;
          _attendanceStatus = employeeResponse.attendanceStatus;

          print('Loaded ${_employees.length} employees');
          print('Initial attendance statuses: $_attendanceStatus');

          for (var employee in _employees) {
            if (employee.isWeekend) {
              print(
                  'Employee ${employee.userId} has a weekend. Setting status to Weekend.');
              _attendanceStatus[employee.userId.toString()] = AttendanceStatus(
                userId: employee.userId,
                status: 'Weekend',
                punchIn: null,
                punchOut: null,
              );
            }
          }

          print('Final attendance statuses: $_attendanceStatus');
          setState(false, null);
        } else {
          print(
              'Server returned unsuccessful status: ${employeeResponse.message}');
          setState(false, employeeResponse.message);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        setState(
            false, 'Failed to load employees. Status: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('Exception occurred: $e');
      print('Stacktrace: $stacktrace');
      setState(
          false, 'Network error. Please check your connection and try again.');
    }
  }

  // Helper method to set loading state and error
  void setState(bool loading, String? error) {
    _isLoading = loading;
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Punch In employees
  Future<bool> punchInEmployees(
      List<int> userIds, int siteId, int shiftId) async {
    try {
      setState(true, null);

      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        setState(false, 'Authentication token not found. Please login again.');
        return false;
      }

      Map<String, String> formData = {
        'site_id': siteId.toString(),
        'shift_id': shiftId.toString(),
      };

      for (int i = 0; i < userIds.length; i++) {
        formData['user_ids[$i]'] = userIds[i].toString();
      }

      final response = await http.post(
        Uri.parse('https://erp.comsindia.in/api/attendance/punchIn'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: formData,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final punchResponse = PunchResponse.fromJson(responseData);

        if (punchResponse.status) {
          setState(false, null);
          return true;
        } else {
          setState(false, punchResponse.message);
          return false;
        }
      } else {
        setState(false, 'Failed to punch in. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      setState(false,
          'Network error during punch in. Please check your connection and try again.');
      return false;
    }
  }

  // Punch Out employees
  Future<bool> punchOutEmployees(List<int> userIds,
      [String remarks = '']) async {
    try {
      setState(true, null);

      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        setState(false, 'Authentication token not found. Please login again.');
        return false;
      }

      Map<String, String> formData = {
        'remarks': remarks,
      };

      for (int i = 0; i < userIds.length; i++) {
        formData['user_ids[$i]'] = userIds[i].toString();
      }

      final response = await http.post(
        Uri.parse('https://erp.comsindia.in/api/attendance/punchOut'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: formData,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final punchResponse = PunchResponse.fromJson(responseData);

        if (punchResponse.status) {
          setState(false, null);
          return true;
        } else {
          setState(false, punchResponse.message);
          return false;
        }
      } else {
        setState(false, 'Failed to punch out. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      setState(
          false, 'Network error. Please check your connection and try again.');
      return false;
    }
  }

  // Fetch attendance view
  Future<void> fetchAttendanceView(
      List<int> userIds, int siteId, int shiftId) async {
    try {
      print('Fetching attendance view...');
      print('Site ID: $siteId, Shift ID: $shiftId, User IDs: $userIds');

      setState(true, null);

      // **IMPORTANT**: Clear previous attendance view data before fetching new data
      _attendanceView.clear();

      final token = await _storageService.getToken();
      print('Retrieved token: $token');

      if (token == null || token.isEmpty) {
        print('Error: Token is null or empty');
        setState(false, 'Authentication token not found. Please login again.');
        return;
      }

      var request = http.Request(
        'GET',
        Uri.parse('https://erp.comsindia.in/api/attendance/view'),
      );

      final Map<String, String> bodyFields = {
        'site_id': siteId.toString(),
        'shift_id': shiftId.toString(),
        ...{
          for (var i = 0; i < userIds.length; i++)
            'user_ids[$i]': userIds[i].toString()
        }
      };

      print('Request body: ${json.encode(bodyFields)}');

      request.body = json.encode(bodyFields);
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      print('Sending request to: ${request.url}');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Decoded response: $responseData');

        final attendanceResponse =
            AttendanceViewResponse.fromJson(responseData);
        print('Parsed AttendanceViewResponse: ${attendanceResponse.message}');

        if (attendanceResponse.status) {
          _attendanceView = attendanceResponse.employees;
          print('Attendance view loaded: ${_attendanceView.length} sites');
          setState(false, null);
        } else {
          print(
              'API returned status=false with message: ${attendanceResponse.message}');
          setState(false, attendanceResponse.message);
        }
      } else {
        print('Failed to fetch. Status code: ${response.statusCode}');
        setState(false,
            'Failed to load attendance view. Status: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('Exception caught: $e');
      print('Stacktrace: $stacktrace');
      setState(
          false, 'Network error. Please check your connection and try again.');
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    if (_selectedShiftId != null) {
      await fetchEmployeesByShift(_selectedShiftId!);
    } else if (_shifts.isEmpty) {
      await fetchShifts();
    }
  }

  // Get selected employees from current list
  List<AttendanceEmployeeData> getSelectedEmployees(List<int> userIds) {
    return _employees.where((emp) => userIds.contains(emp.userId)).toList();
  }

  // Fetch detailed attendance records for a specific user
  Future<List<AttendanceDetail>> fetchUserAttendanceDetails(int userId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await http.get(
        Uri.parse('https://erp.comsindia.in/api/attendance/view/$userId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final attendanceResponse = AttendanceDetailResponse.fromJson(jsonData);

        if (attendanceResponse.status) {
          return attendanceResponse.data;
        } else {
          throw Exception(attendanceResponse.message);
        }
      } else {
        throw Exception(
            'Failed to fetch attendance details. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching attendance details: $e');
    }
  }

  // Get all user IDs from current employees list
  List<int> getAllUserIds() {
    return _employees.map((emp) => emp.userId).toList();
  }

  // Check if employee is on duty
  bool isEmployeeOnDuty(int userId) {
    final status = _attendanceStatus[userId.toString()];
    return status?.isOnDuty ?? false;
  }

  // Check if it's a weekend for the employee
  bool isEmployeeOnWeekend(int userId) {
    final status = _attendanceStatus[userId.toString()];
    return status?.isWeekend ?? false;
  }

  // Get attendance status for an employee
  AttendanceStatus? getEmployeeAttendanceStatus(int userId) {
    return _attendanceStatus[userId.toString()];
  }

  // Get employees that are on duty
  List<AttendanceEmployeeData> getOnDutyEmployees() {
    return _employees.where((emp) => isEmployeeOnDuty(emp.userId)).toList();
  }

  // Get employees that are not on duty (can be punched in)
  List<AttendanceEmployeeData> getAvailableForPunchInEmployees() {
    return _employees.where((emp) {
      return !isEmployeeOnDuty(emp.userId) && !isEmployeeOnWeekend(emp.userId);
    }).toList();
  }
}