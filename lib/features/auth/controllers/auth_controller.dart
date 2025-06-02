import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final ApiService _apiService = getIt<ApiService>();
  final StorageService _storageService = getIt<StorageService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxString token = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  // Check if user is already logged in
  Future<bool> checkLoginStatus() async {
    print('Checking login status...');
    try {
      // Load token
      final savedToken = await _storageService.getToken();

      if (savedToken != null && savedToken.isNotEmpty) {
        token.value = savedToken;
        print(
            'Found saved token: ${savedToken.substring(0, Math.min(15, savedToken.length))}...');

        // Load user from storage
        final savedUser = await _storageService.getUser();
        if (savedUser != null) {
          currentUser.value = savedUser;
          print(
              'User loaded from storage: ${savedUser.name}, roles: ${savedUser.roles}');
          return true; // User is logged in
        } else {
          print('No saved user found despite having token');
          // Token exists but no user data, clear token
          await _storageService.clearAll();
          token.value = '';
        }
      } else {
        print('No saved token found, user is not logged in');
      }

      return false; // User is not logged in
    } catch (e) {
      print('Error checking login status: $e');
      // Try to clean up any corrupted state
      try {
        await _storageService.clearAll();
        token.value = '';
        currentUser.value = null;
      } catch (_) {
        // Ignore cleanup errors
      }
      return false;
    }
  }

  // Request OTP for mobile number
  Future<bool> requestOtp(String mobile) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      print('Requesting OTP for mobile: $mobile');
      final response = await _apiService.verifyMobile(mobile);

      if (response.data is! Map<String, dynamic>) {
        throw Exception(
            'Invalid response format: Expected Map<String, dynamic>');
      }

      final Map<String, dynamic> responseData = response.data;
      print('OTP request response: ${responseData['message']}');

      if (responseData['status'] == true) {
        isLoading.value = false;
        return true;
      } else {
        // Handle error message from API
        if (responseData['message'] is Map) {
          // If message is a map (validation errors)
          final messageMap = responseData['message'] as Map;
          if (messageMap.containsKey('mobile')) {
            errorMessage.value =
                messageMap['mobile'][0] ?? 'Invalid mobile number';
          } else {
            errorMessage.value = 'Invalid mobile number';
          }
        } else {
          // If message is a string
          errorMessage.value =
              responseData['message']?.toString() ?? 'Failed to send OTP';
        }
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      print('Error requesting OTP: $e');
      errorMessage.value = 'Failed to send OTP. Please try again.';
      isLoading.value = false;
      return false;
    }
  }

  // Verify OTP and login
  Future<bool> verifyOtpAndLogin(
      String mobile, String otp, BuildContext context) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      print('Verifying OTP for mobile: $mobile');
      final response = await _apiService.verifyOtp(mobile, otp);

      if (response.data is! Map<String, dynamic>) {
        throw Exception(
            'Invalid response format: Expected Map<String, dynamic>');
      }

      final Map<String, dynamic> responseData = response.data;
      print('OTP verification response: ${responseData['message']}');

      if (responseData['status'] == true) {
        // Get token
        final authToken = responseData['token'] as String?;
        if (authToken != null && responseData['user'] != null) {
          // Save token
          token.value = authToken;

          // Parse user data
          final userData = responseData['user'] as Map<String, dynamic>;
          final user = UserModel.fromJson(userData);

          // Process roles
          List<String> roles = [];
          if (userData['roles'] != null && userData['roles'] is List) {
            final userRoles = userData['roles'] as List;
            roles = userRoles
                .map((role) {
                  if (role is String) return role;
                  if (role is Map && role['name'] != null)
                    return role['name'].toString();
                  return '';
                })
                .where((role) => role.isNotEmpty)
                .toList();
          }

          // Update user roles
          if (roles.isNotEmpty) {
            user.roles.clear();
            user.roles.addAll(roles);
          }

          // Save to memory
          currentUser.value = user;

          // Save to storage
          await _storageService.saveAuthData(
            authToken,
            user,
            tokenType: responseData['token_type'] ?? 'Bearer',
            expiresIn: responseData['expires_in'] ?? 3600,
          );

          isLoading.value = false;

          // Navigate to home
          if (context.mounted) {
            context.go('/home');
          }

          return true;
        } else {
          errorMessage.value =
              'Authentication failed: Missing token or user data';
        }
      } else {
        errorMessage.value =
            responseData['message'] ?? 'OTP verification failed';
      }

      isLoading.value = false;
      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      errorMessage.value = 'Failed to verify OTP. Please try again.';
      isLoading.value = false;
      return false;
    }
  }

  // Logout user
  Future<void> logout(BuildContext context) async {
    isLoading.value = true;

    try {
      print('Starting logout process...');

      // Get the token from current value
      final currentToken = token.value;

      if (currentToken.isNotEmpty) {
        try {
          print(
              'Calling logout API with token: ${currentToken.substring(0, Math.min(15, currentToken.length))}...');

          // Call the logout API
          final response = await _apiService.logout(currentToken);

          if (response.statusCode == 200) {
            print('Logout API call successful: ${response.data['message']}');
          } else {
            print('Logout API returned non-200 status: ${response.statusCode}');
          }
        } catch (e) {
          print('Error calling logout API: $e');
          // Continue with local logout even if API call fails
        }
      } else {
        print('No token available for logout');
      }

      // Clear data from memory
      print('Clearing user data from memory');
      token.value = '';
      currentUser.value = null;
      errorMessage.value = '';

      // Clear data from storage
      print('Clearing user data from storage');
      final clearResult = await _storageService.clearAll();
      print('Storage cleared: $clearResult');

      isLoading.value = false;

      // Navigate to login screen
      print('Navigating to login screen');
      if (context.mounted) {
        try {
          context.go('/login');
          print('Navigation to login successful');
        } catch (e) {
          print('Error navigating with GoRouter: $e');
          if (context.mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      }
    } catch (e) {
      print('Error during logout: $e');
      isLoading.value = false;
      if (context.mounted) {
        context.go('/login');
      }
      rethrow;
    }
  }

  // Check if user has a specific role
  bool hasRole(String role) {
    final user = currentUser.value;
    if (user == null) return false;
    return user.roles.contains(role);
  }

  // Get user's primary role (first in the list)
  String? getPrimaryRole() {
    final user = currentUser.value;
    if (user == null || user.roles.isEmpty) return null;
    return user.roles.first;
  }

  // Get user display name
  String getUserName() {
    final user = currentUser.value;
    if (user == null) return 'User';
    return user.name;
  }

  // Get user initials for avatar
  String getUserInitials() {
    final name = getUserName();
    if (name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }
}
