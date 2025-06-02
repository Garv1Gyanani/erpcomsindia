import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/task/model/task_model.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:coms_india/core/services/api_service.dart';
import 'package:coms_india/core/di/service_locator.dart';

class TaskStatusController extends GetxController {
  final ApiService _apiService = getIt<ApiService>();
  final StorageService _storageService = getIt<StorageService>();
  // Observable variables
  final _taskStatus = Rxn<TaskStatusModel>();
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _currentUserId = ''.obs;

  // Getters
  TaskStatusModel? get taskStatus => _taskStatus.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get currentUserId => _currentUserId.value;

  // Observable getters for UI binding
  RxBool get hasError => (_errorMessage.value.isNotEmpty).obs;
  RxBool get hasData => (_taskStatus.value != null).obs;

  // Progress calculations
  double get progressPercentage => taskStatus?.progressPercentage ?? 0.0;
  bool get isAllCompleted => taskStatus?.isAllCompleted ?? false;

  @override
  void onInit() {
    super.onInit();
    fetchTaskStatus();
  }

  // Set current user ID
  void setUserId(String userId) {
    _currentUserId.value = userId;
  }

  // Fetch task status for specific user
  Future<void> fetchTaskStatus() async {
   
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final response = await _apiService.getTaskStatus();

      if (response.statusCode == 200 && response.data != null) {
        _taskStatus.value = TaskStatusModel.fromJson(response.data);
        print('Task Status loaded successfully: ${_taskStatus.value}');
      } else {
        throw Exception(
            'Failed to load task status. Status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMsg = 'Network error occurred';

      if (e.response != null) {
        if (e.response?.data is Map<String, dynamic>) {
          final errorData = e.response?.data as Map<String, dynamic>;
          errorMsg = errorData['message'] ?? 'Server error occurred';
        } else {
          errorMsg = 'Server returned status: ${e.response?.statusCode}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Request timeout. Please try again.';
      }

      _errorMessage.value = errorMsg;
      print('Error fetching task status: $errorMsg');
    } catch (e) {
      _errorMessage.value = 'An unexpected error occurred: ${e.toString()}';
      print('Unexpected error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Refresh task status
  Future<void> refreshTaskStatus() async {
    if (_currentUserId.value.isNotEmpty) {
      await fetchTaskStatus();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  // Reset all data
  void reset() {
    _taskStatus.value = null;
    _isLoading.value = false;
    _errorMessage.value = '';
    _currentUserId.value = '';
  }
}
