import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/shift/models/shift_model.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:coms_india/core/services/api_service.dart';
import 'package:coms_india/core/di/service_locator.dart';

enum ShiftStatus {
  initial,
  loading,
  success,
  error,
}

// Shift controller with API integration
class ShiftController extends GetxController {
  final ApiService _apiService = getIt<ApiService>();
  final StorageService _storageService = getIt<StorageService>();

  // Observable variables
  final _shifts = <ShiftModel>[].obs;
  final _siteShifts = <SiteShiftModel>[].obs;
  final _assignedSites = <AssignedSiteModel>[].obs;
  final _allShifts = <AllShiftModel>[].obs;
  final _status = ShiftStatus.initial.obs;
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _selectedShift = Rxn<ShiftModel>();

  // Getters
  List<ShiftModel> get shifts => _shifts.toList();
  List<SiteShiftModel> get siteShifts => _siteShifts.toList();
  List<AssignedSiteModel> get assignedSites => _assignedSites.toList();
  List<AllShiftModel> get allShifts => _allShifts.toList();
  ShiftStatus get status => _status.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  ShiftModel? get selectedShift => _selectedShift.value;

  // Observable getters for UI binding
  RxBool get hasError => (_errorMessage.value.isNotEmpty).obs;
  RxBool get hasData => (_shifts.isNotEmpty).obs;
  RxBool get hasShifts => (_shifts.isNotEmpty).obs;

  // Get active shifts only
  List<ShiftModel> get activeShifts =>
      _shifts.where((shift) => shift.isActive).toList();

  // Get currently active shift
  ShiftModel? get currentlyActiveShift =>
      _shifts.firstWhereOrNull((shift) => shift.isCurrentlyActive);

  @override
  void onInit() {
    super.onInit();
    // Only fetch if we don't have data already
    if (_shifts.isEmpty) {
      fetchShifts();
    }
  }

  void _setStatus(ShiftStatus status) {
    _status.value = status;
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String message) {
    _errorMessage.value = message;
    _setStatus(ShiftStatus.error);
  }

  void _setSuccess() {
    _errorMessage.value = '';
    _setStatus(ShiftStatus.success);
  }

  // Fetch all shifts from API
  Future<void> fetchShifts() async {
    try {
      _setLoading(true);
      _errorMessage.value = '';
      _setStatus(ShiftStatus.loading);

      final response = await _apiService.getSiteShifts();

      if (response.statusCode == 200 && response.data != null) {
        final siteShiftResponse =
            SiteShiftResponseModel.fromJson(response.data);

        if (siteShiftResponse.status) {
          _siteShifts.assignAll(siteShiftResponse.data);
          _shifts.assignAll(siteShiftResponse.getAllShifts());
          _setSuccess();
          print(
              '🕐 Site shifts loaded successfully: ${_siteShifts.length} sites, ${_shifts.length} total shifts');
        } else {
          throw Exception(siteShiftResponse.message);
        }
      } else {
        throw Exception(
            'Failed to load site shifts. Status: ${response.statusCode}');
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
      _setError(errorMsg);
      print('❌ Error fetching site shifts: $errorMsg');
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      print('❌ Unexpected error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get site names from the API data (for backward compatibility)
  List<String> get availableSites {
    return _siteShifts.map((site) => site.siteName).toList();
  }

  // Get assigned site names for current user (for assign shift page)
  List<String> get assignedSiteNames {
    return _assignedSites.map((site) => site.siteName).toList();
  }

  // Get all available shifts as ShiftModel (for assign shift page)
  List<ShiftModel> get availableShiftsForAssign {
    return _allShifts.map((shift) => shift.toShiftModel()).toList();
  }

  // Get shifts for a specific site
  List<ShiftModel> getShiftsForSite(String siteName) {
    final site = _siteShifts.firstWhereOrNull((s) => s.siteName == siteName);
    return site?.shifts ?? [];
  }

  // Get shifts for a specific site by ID
  List<ShiftModel> getShiftsForSiteById(int siteId) {
    final site = _siteShifts.firstWhereOrNull((s) => s.siteId == siteId);
    return site?.shifts ?? [];
  }

  // Get site ID by name
  int? getSiteIdByName(String siteName) {
    final site = _siteShifts.firstWhereOrNull((s) => s.siteName == siteName);
    return site?.siteId;
  }

  // Get default shift for a specific site
  ShiftModel? getDefaultShiftForSite(String siteName) {
    final shifts = getShiftsForSite(siteName);
    return shifts.firstWhereOrNull((shift) => shift.isDefault);
  }

  // Get all shifts that could be assigned to a site (including newly created ones)
  List<ShiftModel> getAvailableShiftsForSite(String siteName) {
    // Get existing shifts for the site
    final existingShifts = getShiftsForSite(siteName);

    // Get all available shifts that could be assigned
    final allAvailableShifts = availableShiftsForAssign;

    // Combine existing and available shifts, removing duplicates
    final allShifts = <ShiftModel>[];
    final seenIds = <int>{};

    // Add existing shifts first
    for (final shift in existingShifts) {
      if (!seenIds.contains(shift.id)) {
        allShifts.add(shift);
        seenIds.add(shift.id);
      }
    }

    // Add available shifts that aren't already in the list
    for (final shift in allAvailableShifts) {
      if (!seenIds.contains(shift.id)) {
        allShifts.add(shift);
        seenIds.add(shift.id);
      }
    }

    return allShifts;
  }

  // Fetch assigned sites for current user
  Future<void> fetchAssignedSites() async {
    try {
      _setLoading(true);
      _errorMessage.value = '';

      final response = await _apiService.getAssignedSites();

      if (response.statusCode == 200 && response.data != null) {
        final assignedSitesResponse =
            AssignedSitesResponseModel.fromJson(response.data);
        _assignedSites.assignAll(assignedSitesResponse.sites);
        print(
            '🏢 Assigned sites loaded successfully: ${_assignedSites.length} sites');
      } else {
        throw Exception(
            'Failed to load assigned sites. Status: ${response.statusCode}');
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
      _setError(errorMsg);
      print('❌ Error fetching assigned sites: $errorMsg');
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      print('❌ Unexpected error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all available shifts
  Future<void> fetchAllShifts() async {
    try {
      _setLoading(true);
      _errorMessage.value = '';

      final response = await _apiService.getAllShifts();

      if (response.statusCode == 200 && response.data != null) {
        final allShiftsResponse =
            AllShiftsResponseModel.fromJson(response.data);

        if (allShiftsResponse.status) {
          _allShifts.assignAll(allShiftsResponse.data);
          print(
              '⏰ All shifts loaded successfully: ${_allShifts.length} shifts');
        } else {
          throw Exception(allShiftsResponse.message);
        }
      } else {
        throw Exception(
            'Failed to load all shifts. Status: ${response.statusCode}');
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
      _setError(errorMsg);
      print('❌ Error fetching all shifts: $errorMsg');
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      print('❌ Unexpected error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch data for assign shift page (sites + shifts)
  Future<void> fetchAssignShiftData() async {
    try {
      _setLoading(true);
      _errorMessage.value = '';
      _setStatus(ShiftStatus.loading);

      // Fetch both assigned sites and all shifts in parallel
      await Future.wait([
        fetchAssignedSites(),
        fetchAllShifts(),
      ]);

      _setSuccess();
      print('📋 Assign shift data loaded successfully');
    } catch (e) {
      _setError('Failed to load assign shift data: ${e.toString()}');
      print('❌ Error loading assign shift data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new shift
  Future<bool> createNewShift(
      String name, String startTime, String endTime) async {
    try {
      _setLoading(true);
      _errorMessage.value = '';

      final response =
          await _apiService.createNewShift(name, startTime, endTime);

      if (response.statusCode == 200 && response.data != null) {
        final createShiftResponse =
            CreateShiftResponseModel.fromJson(response.data);

        if (createShiftResponse.status && createShiftResponse.data != null) {
          // Add the new shift to our local list
          _allShifts.add(createShiftResponse.data!);
          _setSuccess();
          print(
              '➕ Shift created successfully: ${createShiftResponse.data!.name}');
          return true;
        } else {
          throw Exception(createShiftResponse.message);
        }
      } else {
        String apiErrorMsg =
            'Failed to create shift. Status: ${response.statusCode}';
        if (response.data != null && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['message'] != null && data['message'] is String) {
            apiErrorMsg = data['message'];
          }
        }
        _setError(apiErrorMsg);
        print('❌ Error creating shift: ' + apiErrorMsg);
        return false;
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
      _setError(errorMsg);
      print('❌ Error creating shift: $errorMsg');
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      print('❌ Unexpected error creating shift: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Assign shifts to site
  Future<bool> assignShiftsToSite(
      String siteName, List<int> shiftIds, int defaultShiftId) async {
    try {
      _setLoading(true);
      _errorMessage.value = '';

      // Find the site ID from assigned sites
      final site =
          _assignedSites.firstWhereOrNull((s) => s.siteName == siteName);
      if (site == null) {
        throw Exception('Site not found: $siteName');
      }

      final response = await _apiService.assignShiftsToSite(
          site.siteId, shiftIds, defaultShiftId);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final assignShiftsResponse =
            AssignShiftsResponseModel.fromJson(response.data);

        if (assignShiftsResponse.status) {
          _setSuccess();
          print('🔄 Shifts assigned successfully to $siteName');
          return true;
        } else {
          throw Exception(assignShiftsResponse.message);
        }
      } else {
        throw Exception(
            'Failed to assign shifts. Status: ${response.statusCode}');
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
      _setError(errorMsg);
      print('❌ Error assigning shifts: $errorMsg');
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      print('❌ Unexpected error assigning shifts: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create new shift
  Future<bool> createShift(ShiftCreateModel shiftData) async {
    try {
      _setLoading(true);
      _errorMessage.value = '';

      final response = await _apiService.createNewShift(
        shiftData.shiftName,
        shiftData.startTime,
        shiftData.endTime,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final createShiftResponse =
            CreateShiftResponseModel.fromJson(response.data);

        if (createShiftResponse.status && createShiftResponse.data != null) {
          // Add the new shift to our local list
          _allShifts.add(createShiftResponse.data!);
          _setSuccess();
          print(
              '➕ Shift created successfully: ${createShiftResponse.data!.name}');
          return true;
        } else {
          throw Exception(createShiftResponse.message);
        }
      } else {
        String apiErrorMsg =
            'Failed to create shift. Status: ${response.statusCode}';
        if (response.data != null && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['message'] != null && data['message'] is String) {
            apiErrorMsg = data['message'];
          }
        }
        _setError(apiErrorMsg);
        print('❌ Error creating shift: ' + apiErrorMsg);
        return false;
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
      _setError(errorMsg);
      print('❌ Error creating shift: $errorMsg');
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      print('❌ Unexpected error creating shift: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update shift
  Future<bool> updateShift(int shiftId, ShiftCreateModel shiftData) async {
    try {
      _setLoading(true);
      _errorMessage.value = '';

      // For now, we'll use the create shift API since update API might not be available
      // In a real implementation, you would call an update endpoint
      final response = await _apiService.createNewShift(
        shiftData.shiftName,
        shiftData.startTime,
        shiftData.endTime,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final createShiftResponse =
            CreateShiftResponseModel.fromJson(response.data);

        if (createShiftResponse.status && createShiftResponse.data != null) {
          // Update the shift in our local list
          final index = _allShifts.indexWhere((shift) => shift.id == shiftId);
          if (index != -1) {
            _allShifts[index] = createShiftResponse.data!;
          } else {
            _allShifts.add(createShiftResponse.data!);
          }
          _setSuccess();
          print(
              '✏️ Shift updated successfully: ${createShiftResponse.data!.name}');
          return true;
        } else {
          throw Exception(createShiftResponse.message);
        }
      } else {
        String apiErrorMsg =
            'Failed to update shift. Status: ${response.statusCode}';
        if (response.data != null && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['message'] != null && data['message'] is String) {
            apiErrorMsg = data['message'];
          }
        }
        _setError(apiErrorMsg);
        print('❌ Error updating shift: ' + apiErrorMsg);
        return false;
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
      _setError(errorMsg);
      print('❌ Error updating shift: $errorMsg');
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      print('❌ Unexpected error updating shift: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete shift
  Future<bool> deleteShift(int shiftId) async {
    try {
      _setLoading(true);
      _errorMessage.value = '';

      // TODO: Implement delete shift API when endpoint is available
      // For now, we'll remove from local list only
      final initialLength = _allShifts.length;
      _allShifts.removeWhere((shift) => shift.id == shiftId);
      final removed = initialLength - _allShifts.length;

      if (removed > 0) {
        _setSuccess();
        print('🗑️ Shift removed from local list: ID $shiftId');
        return true;
      } else {
        _setError('Shift not found');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      print('❌ Unexpected error deleting shift: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Select a shift
  void selectShift(ShiftModel shift) {
    _selectedShift.value = shift;
  }

  // Clear selection
  void clearSelection() {
    _selectedShift.value = null;
  }

  // Refresh shifts list
  Future<void> refreshShifts() async {
    await fetchShifts();
  }

  // Refresh assign shift data (sites + shifts)
  Future<void> refreshAssignShiftData() async {
    await fetchAssignShiftData();
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
    if (_status.value == ShiftStatus.error) {
      _status.value = ShiftStatus.initial;
    }
  }

  // Reset controller
  void reset() {
    _shifts.clear();
    _siteShifts.clear();
    _assignedSites.clear();
    _allShifts.clear();
    _status.value = ShiftStatus.initial;
    _isLoading.value = false;
    _errorMessage.value = '';
    _selectedShift.value = null;
  }

  // Get shifts by working day
  List<ShiftModel> getShiftsByDay(String day) {
    return _shifts
        .where((shift) => shift.workingDays.contains(day) && shift.isActive)
        .toList();
  }

  // Search shifts
  List<ShiftModel> searchShifts(String query) {
    if (query.isEmpty) return _shifts.toList();

    return _shifts
        .where((shift) =>
            shift.shiftName.toLowerCase().contains(query.toLowerCase()) ||
            shift.siteDetails.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
