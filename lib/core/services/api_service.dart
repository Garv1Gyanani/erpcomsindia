import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../di/service_locator.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;
  final StorageService _storageService = getIt<StorageService>();

  ApiService() {
    _initDio();
  }

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

  // Verify mobile number and request OTP
  Future<Response> verifyMobile(String mobile) async {
    try {
      final response = await _dio.get(
        ApiConstants.verifyMobile,
        queryParameters: {'mobile': mobile},
        options: Options(
          headers: {
            'Authorization':
                'Bearer eyJhbGciOiJIUzI1NiJ9.e30.ulmAWxLxCwNUPwLLzm1ylKEGFK6U2qfisp3b_kMYMrU'
          },
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

  Future<Response> logout(String token) async {
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

  // Get employee details
  Future<Response> getEmployeeDetails(int userId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.employeeDetails}$userId',
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );
      print('Employee Details Response: ${response.data}');
      return response;
    } catch (e) {
      print('API Employee Details error: ${e.toString()}');
      rethrow;
    }
  }
}
