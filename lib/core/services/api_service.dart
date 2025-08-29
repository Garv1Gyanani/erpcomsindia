import 'dart:convert';

import 'package:coms_india/features/employee/models/employee.dart';
import 'package:coms_india/features/shift/models/site_shift_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants.dart';
import '../di/service_locator.dart';
import 'storage_service.dart';
import 'package:http/http.dart' as http;

class ApiService {
  late final Dio _dio;
  final StorageService _storageService = getIt<StorageService>();

  ApiService() {
    _initDio();
  }

  Dio get dio => _dio;

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging for debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    // Add interceptor to add auth token to requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip adding token for login/verify endpoints
        if (options.path.contains('/verify-mobile') ||
            options.path.contains('/verify-otp')) {
          return handler.next(options);
        }

        // Get token from storage
        final token = await _storageService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, ErrorInterceptorHandler handler) {
        // Handle error response
        if (e.response?.data is Map<String, dynamic>) {
          final errorData = e.response?.data as Map<String, dynamic>;
          if (errorData['message'] is Map) {
            // If message is a map (validation errors)
            final messageMap = errorData['message'] as Map;
            if (messageMap.containsKey('mobile')) {
              // Create a new DioException with the custom message
              final newError = DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                error: messageMap['mobile'][0] ?? 'Invalid mobile number',
                type: e.type,
              );
              return handler.reject(newError);
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  List<Site> siteListFromJson(String str) =>
      List<Site>.from(json.decode(str)['data'].map((x) => Site.fromJson(x)));

  final String _baseUrl = 'https://erp.comsindia.in/api';

  Future<List<Site>> fetchSitesAndShifts(String token) async {
    // ... (previous code is unchanged)
    final url = Uri.parse('$_baseUrl/weekend/site/list');

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        return siteListFromJson(response.body);
      } else {
        throw Exception(
            'Failed to load site list. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching sites: $e');
    }
  }

  // --- NEW METHOD ---
  Future<List<Employee>> fetchEmployeesForShift(
      String token, int siteId, int shiftId) async {
    final url = Uri.parse('$_baseUrl/weekend/site/$siteId/shift/$shiftId');

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Use the new model helper to parse the response
        return employeeListFromJson(response.body);
      } else {
        throw Exception(
            'Failed to load employee list. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching employees: $e');
    }
  }

  Future<void> assignWeekends({
    required String token,
    required int siteId,
    required List<Employee> employees,
  }) async {
    final url = Uri.parse('$_baseUrl/weekend/emp/assign');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    for (final employee in employees) {
      if (employee.selectedDays.isEmpty) {
        debugPrint('Skipping ${employee.name} — no selected days.');
        continue;
      }

      debugPrint(
          'Preparing request for ${employee.name} (ID: ${employee.userId})');

      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      request.fields['site_id'] = siteId.toString();
      request.fields['user_id'] = employee.userId.toString();

      List<String> daysList = employee.selectedDays.toList();
      for (int i = 0; i < daysList.length; i++) {
        request.fields['days[$i]'] = daysList[i];
      }

      // Print full request fields for debugging
      debugPrint('Request fields for ${employee.name}: ${request.fields}');

      try {
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        debugPrint('Response for ${employee.name}: '
            'Status ${response.statusCode}, Body: $responseBody');

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception(
            '❌ Failed to assign weekend for ${employee.name}. '
            'Status: ${response.statusCode}, Body: $responseBody',
          );
        } else {
          debugPrint('✅ Weekend assigned successfully for ${employee.name}');
        }
      } catch (e) {
        debugPrint('🚨 Exception for ${employee.name}: $e');
        throw Exception(
          'An error occurred while submitting for ${employee.name}: $e',
        );
      }
    }

    debugPrint('All weekend assignments completed.');
  }

  Future<List<SiteGroup>> fetchWeekendList(String token) async {
    final url = Uri.parse('$_baseUrl/weekend/emp/list');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    };
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return siteGroupListFromJson(response.body);
    } else {
      throw Exception(
          'Failed to load weekend list. Status: ${response.statusCode}');
    }
  }

  // Verify mobile number and request OTP
  Future<Response> verifyMobile(String mobile) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.verifyMobile}?mobile=$mobile',
      );
      print('Verify Mobile Response: ${response.data}');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getClientEmployees(String token) async {
    try {
      print(
          'Getting client employees with token: ${token.substring(0, 15)}...');

      final response = await _dio.get(
        '$_baseUrl/client/emp',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('Client employees response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Error getting client employees: $e');
      rethrow;
    }
  }

  // Verify OTP and login
  Future<Response> verifyOtp(String mobile, String otp) async {
    try {
      final formData = FormData.fromMap({
        'mobile': mobile,
        'otp': otp,
      });

      final response = await _dio.post(
        ApiConstants.verifyOtp,
        data: formData,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> logout(String token, BuildContext context) async {
    try {
      // Set the authorization header with the token
      _dio.options.headers['Authorization'] = 'Bearer $token';

      print('Sending logout request with headers: ${_dio.options.headers}');

      // Make the request to the logout endpoint
      final response = await _dio.post(
        ApiConstants.logout,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      print('Logout response: ${response.data}');
      context.goNamed('login');
      return response;
    } catch (e) {
      print('API Logout error: ${e.toString()}');
      rethrow;
    }
  }

  // Get user profile data
  Future<Response> getUserProfile() async {
    try {
      final response = await _dio.get(
        ApiConstants.profile,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      return response;
    } catch (e) {
      print('API Profile error: ${e.toString()}');
      rethrow;
    }
  }

  Future<Response> getTaskStatus() async {
    final authData = await _storageService.getAllAuthData();
    final userData = authData['user']['id'] ?? '';

    print('User ID ================= $userData');
    try {
      final response = await _dio.get(
        '${ApiConstants.taskStatus}/$userData',
      );
      print('Task Status Response: ${response.data}');
      return response;
    } catch (e) {
      print('API Task Status error: ${e.toString()}');
      rethrow;
    }
  }

  // Create employee with multipart form data
  Future<Response> createEmployee(FormData formData) async {
    try {
      print(
          '🌐 DEBUG: About to make API call to ${ApiConstants.createEmployee}');
      print('🌐 DEBUG: FormData fields count: ${formData.fields.length}');
      print('🌐 DEBUG: FormData files count: ${formData.files.length}');

      final response = await _dio.post(
        ApiConstants.createEmployee,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('🎉 DEBUG: API call completed successfully!');
      print('🎉 DEBUG: Response status: ${response.statusCode}');
      print('🎉 DEBUG: Response data: ${response.data}');
      return response;
    } catch (e) {
      print('❌ DEBUG: API Create Employee error occurred');
      print('❌ DEBUG: Error details: ${e.toString()}');
      print('❌ DEBUG: Error type: ${e.runtimeType}');

      if (e is DioException) {
        print('❌ DEBUG: DioException occurred: ${e.message}');
        print('❌ DEBUG: Response status: ${e.response?.statusCode}');
        print('❌ DEBUG: Response data: ${e.response?.data}');

        // Handle specific API validation errors
        if (e.response?.statusCode == 422 && e.response?.data != null) {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic> &&
              responseData['message'] is Map) {
            final validationErrors =
                responseData['message'] as Map<String, dynamic>;
            throw Exception('API Error: ${validationErrors.toString()}');
          }
        }
      }
      rethrow;
    }
  }

  // Get departments list
  Future<Response> getDepartments() async {
    try {
      print('🏢 DEBUG: Fetching departments...');
      final response = await _dio.get(
        ApiConstants.departments,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      print('🏢 DEBUG: Departments response: ${response.data}');
      return response;
    } catch (e) {
      print('❌ DEBUG: API Get Departments error: ${e.toString()}');
      rethrow;
    }
  }

  // Get sites list
  Future<Response> getSites() async {
    try {
      print('🏗️ DEBUG: Fetching sites...');
      final response = await _dio.get(
        ApiConstants.sites,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      print('🏗️ DEBUG: Sites response: ${response.data}');
      return response;
    } catch (e) {
      print('❌ DEBUG: API Get Sites error: ${e.toString()}');
      rethrow;
    }
  }

  // Get locations list
  Future<Response> getLocations() async {
    try {
      print('📍 DEBUG: Fetching locations...');
      final response = await _dio.get(
        ApiConstants.locations,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      print('📍 DEBUG: Locations response: ${response.data}');
      return response;
    } catch (e) {
      print('❌ DEBUG: API Get Locations error: ${e.toString()}');
      rethrow;
    }
  }

  // Get site shifts list
  Future<Response> getSiteShifts() async {
    try {
      print('🕐 DEBUG: Fetching site shifts...');
      final response = await _dio.get(
        ApiConstants.siteShifts,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      print('🕐 DEBUG: Site shifts response: ${response.data}');
      return response;
    } catch (e) {
      print('❌ DEBUG: API Get Site Shifts error: ${e.toString()}');
      rethrow;
    }
  }

  // Get assigned sites for current user
  Future<Response> getAssignedSites() async {
    try {
      print('🏢 DEBUG: Fetching assigned sites...');
      final response = await _dio.get(
        ApiConstants.assignedSites,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      print('🏢 DEBUG: Assigned sites response: ${response.data}');
      return response;
    } catch (e) {
      print('❌ DEBUG: API Get Assigned Sites error: ${e.toString()}');
      rethrow;
    }
  }

  // Get all available shifts
  Future<Response> getAllShifts() async {
    try {
      print('⏰ DEBUG: Fetching all shifts...');
      final response = await _dio.get(
        ApiConstants.allShifts,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      print('⏰ DEBUG: All shifts response: ${response.data}');
      return response;
    } catch (e) {
      print('❌ DEBUG: API Get All Shifts error: ${e.toString()}');
      rethrow;
    }
  }

  // Create new shift
  Future<Response> createNewShift(
      String name, String startTime, String endTime) async {
    try {
      print('➕ DEBUG: Creating new shift...');
      final formData = FormData.fromMap({
        'name': name,
        'start_time': startTime,
        'end_time': endTime,
      });

      final response = await _dio.post(
        ApiConstants.createShift,
        data: formData,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      print('➕ DEBUG: Create shift response: ${response.data}');
      return response;
    } catch (e) {
      print('❌ DEBUG: API Create Shift error: ${e.toString()}');
      rethrow;
    }
  }

  // Assign shifts to site
  Future<Response> assignShiftsToSite(
      int siteId, List<int> shiftIds, int defaultShiftId) async {
    try {
      print('🔄 DEBUG: Assigning shifts to site...');
      final requestData = {
        'site_id': siteId,
        'shift_ids': shiftIds,
        'default_shift_id': defaultShiftId,
      };

      final response = await _dio.post(
        ApiConstants.assignShifts,
        data: requestData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      print('🔄 DEBUG: Assign shifts response: ${response.data}');
      return response;
    } catch (e) {
      print('❌ DEBUG: API Assign Shifts error: ${e.toString()}');
      rethrow;
    }
  }
}
