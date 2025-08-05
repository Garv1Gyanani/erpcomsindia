import 'dart:math' as Math;
import 'package:coms_india/features/attendance/controllers/attendance_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final ApiService _apiService = getIt<ApiService>();
  final StorageService storageService = getIt<StorageService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxString token = ''.obs;
  final RxString loginAs = ''.obs; // Track login type: 'client' or 'employee'

  @override
  void onInit() {
    super.onInit();
    // No need for 'await' here, it can run in the background
    checkLoginStatus();
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
            errorMessage.value = messageMap['mobile'][0];
          }
        }
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      print('Error requesting OTP: $e');
      if (e.toString().contains('The selected mobile is invalid')) {
        errorMessage.value = 'The selected mobile is invalid';
      }
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
        final userLoginAs =
            responseData['login_as'] as String?; // Get login type

        if (authToken != null && responseData['user'] != null) {
          // Save to memory FIRST
          token.value = authToken;
          loginAs.value = userLoginAs ?? '';

          // Parse user data
          final userData = responseData['user'] as Map<String, dynamic>;
          final user = UserModel.fromJson(userData);
          currentUser.value = user;

          // Save to storage including login type
          await storageService.saveAuthData(
            authToken,
            user,
            tokenType: responseData['token_type'] ?? 'Bearer',
            expiresIn: responseData['expires_in'] ?? 3600,
            loginAs: userLoginAs, // Save login type
          );

          isLoading.value = false;

          // Navigate based on login type
          if (context.mounted) {
            if (userLoginAs == 'client') {
              context.go('/client-dashboard');
            } else {
              context.go('/team');
            }
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

  Future<void> logout(BuildContext context) async {
    try {
      print('Starting logout process...');

      // IMMEDIATELY clear memory variables FIRST - before any async operations
      print('Clearing user data from memory IMMEDIATELY');
      token.value = '';
      currentUser.value = null;
      errorMessage.value = '';
      loginAs.value = '';

      // Clear attendance controller if it exists
      try {
        if (Get.isRegistered<AttendanceController>()) {
          final attendanceController = Get.find<AttendanceController>();
          attendanceController.clearAllData();
          print('✅ AttendanceController data cleared');
        } else {
          print('ℹ️ AttendanceController not registered, skipping clear');
        }
      } catch (e) {
        print('⚠️ Error clearing AttendanceController (non-critical): $e');
      }

      // Clear data from storage
      print('Clearing user data from storage');
      await storageService.clearAll();

      // Refresh the router to trigger redirect logic
      if (context.mounted) {
        GoRouter.of(context).refresh();
      }
    } catch (e) {
      print('Error during logout: $e');

      // As a fallback, force clear memory and try to refresh router again
      token.value = '';
      currentUser.value = null;
      errorMessage.value = '';
      loginAs.value = '';
      update();

      if (context.mounted) {
        GoRouter.of(context).refresh();
      }
    }
  }

  // Check if user is already logged in
  Future<bool> checkLoginStatus() async {
    print('Checking login status...');
    try {
      // Load token from storage
      final savedToken = await storageService.getToken();

      if (savedToken == null || savedToken.isEmpty) {
        print('No valid token found. User is not logged in.');
        await _clearAllUserData(); // Clean up any partial data
        return false;
      }

      print(
          'Found saved token: ${savedToken.substring(0, Math.min(15, savedToken.length))}...');

      // Load user and login type from storage
      final savedUser = await storageService.getUser();
      final savedLoginAs = await storageService.getLoginType();

      if (savedUser != null && savedLoginAs != null) {
        // ========== THIS IS THE FIX ==========
        // Populate ALL relevant controller state variables from storage
        token.value = savedToken;
        loginAs.value = savedLoginAs;
        currentUser.value = savedUser;
        // ===================================

        print(
            '✅ User loaded from storage: ${savedUser.name}, roles: ${savedUser.roles}, login_as: ${loginAs.value}');
        return true; // User is logged in and state is consistent
      } else {
        print(
            '⚠️ No saved user/loginAs found despite having a token. Clearing all data.');
        await _clearAllUserData();
        return false;
      }
    } catch (e) {
      print('❌ Error checking login status: $e');
      // Try to clean up any corrupted state
      await _clearAllUserData();
      return false;
    }
  }

  // Helper method to clear all user data from memory and storage
  Future<void> _clearAllUserData() async {
    try {
      await storageService.clearAll();
      token.value = '';
      currentUser.value = null;
      loginAs.value = '';
      errorMessage.value = '';
      update(); // Force update GetX observers
      print('✅ All user data cleared from state and storage.');
    } catch (e) {
      print('❌ Error clearing all user data: $e');
      // Force clear memory even if storage fails
      token.value = '';
      currentUser.value = null;
      loginAs.value = '';
      errorMessage.value = '';
    }
  }

  // Check if user is a client
  bool isClient() {
    return loginAs.value == 'client';
  }

  // Check if user has a specific role
  bool hasRole(String role) {
    return currentUser.value?.roles.any((userRole) => userRole.name == role) ??
        false;
  }

  // Get user's primary role (first in the list)
  String? getPrimaryRole() {
    if (currentUser.value == null || currentUser.value!.roles.isEmpty)
      return null;
    return currentUser.value!.roles.first.name;
  }

  // Get user display name
  String getUserName() {
    return currentUser.value?.name ?? 'User';
  }

  // Get user initials for avatar
  String getUserInitials() {
    final name = getUserName();
    if (name.isEmpty || name == 'User') return 'U';
    return name.trim()[0].toUpperCase();
  }
}
