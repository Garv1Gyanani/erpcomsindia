import 'package:dio/dio.dart';
import '../utils/constants.dart';

class ApiService {
  late final Dio _dio;

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

      final response = await _dio.post(ApiConstants.verifyOtp, data: formData);
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
      final response = await _dio.post('/api/logout');
      print('Logout response: ${response.data}');

      return response;
    } catch (e) {
      print('API Logout error: ${e.toString()}');
      rethrow;
    }
  }
}
