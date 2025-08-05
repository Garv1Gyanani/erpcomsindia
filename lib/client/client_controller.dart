import 'package:get/get.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class Employee {
  final String name;
  final String email;
  final String phone;
  final String employeeId;
  final String gender;
  final String status;

  Employee({
    required this.name,
    required this.email,
    required this.phone,
    required this.employeeId,
    required this.gender,
    required this.status,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      employeeId: json['employee_id'] ?? '',
      gender: json['gender'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class EmployeeGroup {
  final String role;
  final List<Employee> employees;

  EmployeeGroup({
    required this.role,
    required this.employees,
  });
}

class ClientDashboardController extends GetxController {
  final ApiService _apiService = getIt<ApiService>();
  final StorageService _storageService = getIt<StorageService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<EmployeeGroup> employeeGroups = <EmployeeGroup>[].obs;
  final RxInt totalEmployees = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
  }

  // Fetch employees from API
  Future<void> fetchEmployees() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Get token from storage
      final token = await _storageService.getToken();
      
      if (token == null || token.isEmpty) {
        errorMessage.value = 'Authentication token not found';
        isLoading.value = false;
        return;
      }

      print('Fetching employees with token: ${token.substring(0, 15)}...');

      // Call API to get employees
      final response = await _apiService.getClientEmployees(token);

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }

      final Map<String, dynamic> responseData = response.data;
      print('Employee fetch response: ${responseData['message']}');

      if (responseData['status'] == true && responseData['data'] != null) {
        final data = responseData['data'] as Map<String, dynamic>;
        
        // Parse employee data
        List<EmployeeGroup> groups = [];
        int totalCount = 0;

        data.forEach((department, departmentData) {
          if (departmentData is Map<String, dynamic>) {
            departmentData.forEach((role, roleEmployees) {
              if (roleEmployees is List) {
                List<Employee> employees = roleEmployees
                    .map((emp) => Employee.fromJson(emp as Map<String, dynamic>))
                    .toList();
                
                if (employees.isNotEmpty) {
                  groups.add(EmployeeGroup(
                    role: '$department - $role',
                    employees: employees,
                  ));
                  totalCount += employees.length;
                }
              }
            });
          }
        });

        employeeGroups.value = groups;
        totalEmployees.value = totalCount;
        
        print('Loaded ${groups.length} employee groups with total ${totalCount} employees');
      } else {
        errorMessage.value = responseData['message'] ?? 'Failed to fetch employees';
      }
    } catch (e) {
      print('Error fetching employees: $e');
      errorMessage.value = 'Failed to fetch employees. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh employee data
  Future<void> refreshEmployees() async {
    await fetchEmployees();
  }

  // Get employee by ID
  Employee? getEmployeeById(String employeeId) {
    for (final group in employeeGroups) {
      for (final employee in group.employees) {
        if (employee.employeeId == employeeId) {
          return employee;
        }
      }
    }
    return null;
  }

  // Search employees by name
  List<Employee> searchEmployees(String query) {
    if (query.isEmpty) return [];
    
    List<Employee> results = [];
    final lowerQuery = query.toLowerCase();
    
    for (final group in employeeGroups) {
      for (final employee in group.employees) {
        if (employee.name.toLowerCase().contains(lowerQuery) ||
            employee.employeeId.toLowerCase().contains(lowerQuery)) {
          results.add(employee);
        }
      }
    }
    
    return results;
  }

  // Get employees by status
  List<Employee> getEmployeesByStatus(String status) {
    List<Employee> results = [];
    
    for (final group in employeeGroups) {
      for (final employee in group.employees) {
        if (employee.status.toLowerCase() == status.toLowerCase()) {
          results.add(employee);
        }
      }
    }
    
    return results;
  }
}