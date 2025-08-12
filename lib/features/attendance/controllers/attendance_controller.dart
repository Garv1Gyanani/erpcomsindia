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
  int? _selectedSiteId; // ADDED: To store the dynamic site ID
  PunchResponse? punchResponse;

  // Getters
  List<ShiftData> get shifts => _shifts;
  List<AttendanceEmployeeData> get employees => _employees;
  Map<String, List<AttendanceEmployee>> get attendanceView => _attendanceView;
  Map<String, AttendanceStatus> get attendanceStatus => _attendanceStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get selectedShiftId => _selectedShiftId;
  int? get selectedSiteId => _selectedSiteId; // ADDED: Getter for the site ID

  // NEW METHOD: Clear all cached data when switching users
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
        Uri.parse('https://erp.comsindia.in/api/site/shift/index'),
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
      _selectedSiteId = null; // Reset site ID on new fetch

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
        print('Parsed employee response: $employeeResponse');

        if (employeeResponse.status) {
          _employees = employeeResponse.data;
          _attendanceStatus = employeeResponse.attendanceStatus;

          // Capture the site ID from the first employee in the list
          if (_employees.isNotEmpty) {
            _selectedSiteId = _employees.first.siteId;
            print('>>>> Associated Site ID captured: $_selectedSiteId <<<<');
          } else {
            print('No employees found for this shift. Site ID is null.');
          }

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
    List<int> userIds,
    int siteId,
    int shiftId,
  ) async {
    try {
      print('=== PUNCH IN DEBUG START ===');
      print('Input parameters:');
      print('  userIds: $userIds');
      print('  siteId: $siteId');
      print('  shiftId: $shiftId');
      print('  userIds length: ${userIds.length}');

      setState(true, null);

      // Token validation
      print('\n--- Token Validation ---');
      final token = await _storageService.getToken();
      print('Token retrieved: ${token != null ? "Yes" : "No"}');

      if (token == null || token.isEmpty) {
        print('ERROR: Token is null or empty');
        setState(false, 'Authentication token not found. Please login again.');
        return false;
      }

      print('Token length: ${token.length}');
      print('Token preview: ${token.substring(0, 20)}...');

      // Prepare form data
      print('\n--- Form Data Preparation ---');
      Map<String, String> formData = {
        'site_id': siteId.toString(),
        'shift_id': shiftId.toString(),
      };

      for (int i = 0; i < userIds.length; i++) {
        formData['user_ids[$i]'] = userIds[i].toString();
        print('  user_ids[$i]: ${userIds[i]}');
      }

      // API Request
      print('\n--- API Request ---');
      final url = 'https://erp.comsindia.in/api/attendance/punchIn';
      print('URL: $url');
      final requestStartTime = DateTime.now();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: formData,
      );

      final requestEndTime = DateTime.now();
      print(
          'Request Duration: ${requestEndTime.difference(requestStartTime).inMilliseconds}ms');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('JSON Parsed Successfully');

        final punchResponse = PunchResponse.fromJson(responseData);
        print(
            'PunchResponse Parsed: ${punchResponse.status} | ${punchResponse.message}');

        this.punchResponse = punchResponse;

        if (punchResponse.status) {
          final punchedList = punchResponse.data?.punched ?? [];
          final skippedList = punchResponse.data?.skipped ?? [];

          if (punchedList.isNotEmpty) {
            print('--- SUCCESS ---');
            print('Employees punched in: ${punchedList.join(", ")}');
            setState(false, null);
            return true;
          } else if (skippedList != null && skippedList.isNotEmpty) {
            print('--- SKIPPED ---');
            String skippedReasons =
                skippedList.map((e) => '${e.empName}: ${e.reason}').join('\n');
            print(skippedReasons);
            setState(false, '$skippedReasons');
            return false;
          } else {
            print('--- NO ACTION ---');
            setState(false, 'No employees were punched in or skipped.');
            return false;
          }
        } else {
          print('--- API STATUS FALSE ---');
          setState(false, punchResponse.message);
          return false;
        }
      } else {
        print('--- HTTP ERROR ---');
        try {
          final errorData = json.decode(response.body);
          final message = errorData['message'] ?? 'Unknown server error.';
          setState(false, 'Server error: $message');
        } catch (e) {
          setState(false, 'Failed to punch in. Status: ${response.statusCode}');
        }
        return false;
      }
    } catch (e, stack) {
      print('--- EXCEPTION ---');
      print('Error: $e');
      print('Stack trace: $stack');
      setState(false, 'Unexpected error occurred while punching in.');
      return false;
    }
  }

  // Punch Out employees
  Future<bool> punchOutEmployees(List<int> userIds,
      [String remarks = '']) async {
    try {
      print('=== PUNCH OUT DEBUG START ===');
      print('Input parameters:');
      print('  userIds: $userIds');
      print('  remarks: $remarks');
      print('  userIds length: ${userIds.length}');

      setState(true, null);

      // Token validation
      print('\n--- Token Validation ---');
      final token = await _storageService.getToken();
      print('Token retrieved: ${token != null ? "Yes" : "No"}');

      if (token == null || token.isEmpty) {
        print('ERROR: Token is null or empty');
        setState(false, 'Authentication token not found. Please login again.');
        return false;
      }

      print('Token length: ${token.length}');
      print('Token preview: ${token.substring(0, 20)}...');

      // Prepare form data
      print('\n--- Form Data Preparation ---');
      Map<String, String> formData = {
        'remarks': remarks,
      };

      for (int i = 0; i < userIds.length; i++) {
        formData['user_ids[$i]'] = userIds[i].toString();
        print('  user_ids[$i]: ${userIds[i]}');
      }

      // API Request
      print('\n--- API Request ---');
      final url = 'https://erp.comsindia.in/api/attendance/punchOut';
      print('URL: $url');
      final requestStartTime = DateTime.now();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: formData,
      );

      final requestEndTime = DateTime.now();
      print(
          'Request Duration: ${requestEndTime.difference(requestStartTime).inMilliseconds}ms');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('JSON Parsed Successfully');

        final punchResponse = PunchResponse.fromJson(responseData);
        print(
            'PunchResponse Parsed: ${punchResponse.status} | ${punchResponse.message}');

        this.punchResponse = punchResponse;

        if (punchResponse.status) {
          final punchedList = punchResponse.data?.punchedOut ?? [];
          final skippedList = punchResponse.data?.skipped ?? [];

          if (punchedList != null && punchedList.isNotEmpty) {
            print('--- SUCCESS ---');
            print('Employees punched out: ${punchedList.join(", ")}');
            setState(false, null);
            return true;
          } else if (skippedList != null && skippedList.isNotEmpty) {
            print('--- SKIPPED ---');
            String skippedReasons =
                skippedList.map((e) => '${e.empName}: ${e.reason}').join('\n');
            print(skippedReasons);
            setState(false, '$skippedReasons');
            return false;
          } else {
            print('--- NO ACTION ---');
            setState(false, 'No employees were punched out or skipped.');
            return false;
          }
        } else {
          print('--- API STATUS FALSE ---');
          setState(false, punchResponse.message);
          return false;
        }
      } else {
        print('--- HTTP ERROR ---');
        try {
          final errorData = json.decode(response.body);
          final message = errorData['message'] ?? 'Unknown server error.';
          setState(false, 'Server error: $message');
        } catch (e) {
          setState(
              false, 'Failed to punch out. Status: ${response.statusCode}');
        }
        return false;
      }
    } catch (e, stack) {
      print('--- EXCEPTION ---');
      print('Error: $e');
      print('Stack trace: $stack');
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
