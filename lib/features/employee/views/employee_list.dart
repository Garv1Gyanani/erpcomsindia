import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/employee/views/basic_info.dart';
import 'package:coms_india/features/employee/views/employee_details.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final StorageService _storageService = StorageService();
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await _storageService.getToken();
      print('🔍 Retrieved token: ${token?.substring(0, 20)}...');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // Make API call
      final response = await http.get(
        Uri.parse('https://erp.comsindia.in/api/employee/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 API Response Status: ${response.statusCode}');
      print('🔍 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle different response structures
        List<dynamic> employeeList = [];
        if (responseData is Map<String, dynamic>) {
          // If response has a data field
          if (responseData.containsKey('data')) {
            employeeList = responseData['data'] as List<dynamic>;
          }
          // If response has employees field
          else if (responseData.containsKey('employees')) {
            employeeList = responseData['employees'] as List<dynamic>;
          }
          // If response is directly an array wrapped in an object
          else if (responseData.containsKey('result')) {
            employeeList = responseData['result'] as List<dynamic>;
          }
        } else if (responseData is List) {
          // If response is directly an array
          employeeList = responseData;
        }

        setState(() {
          _employees =
              employeeList.map((emp) => _processEmployeeData(emp)).toList();
          _isLoading = false;
        });

        print('✅ Loaded ${_employees.length} employees');
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load employees. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching employees: $e');
      setState(() {
        _errorMessage =
            'Network error. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _processEmployeeData(dynamic employeeData) {
    // Process and normalize employee data from API
    final emp = employeeData as Map<String, dynamic>;

    // Extract user data
    final user = emp['user'] as Map<String, dynamic>? ?? {};
    final department = emp['department'] as Map<String, dynamic>? ?? {};
    final designation = emp['designation'] as Map<String, dynamic>? ?? {};

    // Extract basic info
    final name = user['name'] ?? 'Unknown';
    final employeeId = emp['employee_id'] ?? 'N/A';
    final departmentName = department['department_name'] ?? 'N/A';
    final designationName = designation['designation_name'] ?? 'N/A';

    // Extract employee image path
    final imagePath = emp['employee_image_path'] as String?;
    String? imageUrl;
    if (imagePath != null && imagePath.isNotEmpty) {
      imageUrl = 'https://erp.comsindia.in/$imagePath';
    }

    // Extract roles
    final roles = user['roles'] as List<dynamic>? ?? [];
    String roleText = 'No Role';
    Color roleColor = Colors.grey;

    if (roles.isNotEmpty) {
      final roleNames = roles.map((role) => role['name'] as String).toList();
      roleText = roleNames.join(', ');

      // Determine role color based on role type
      final firstRole = roleNames.first.toLowerCase();
      if (firstRole.contains('admin') || firstRole.contains('manager')) {
        roleColor = Colors.red;
      } else if (firstRole.contains('supervisor')) {
        roleColor = Colors.orange;
      } else if (firstRole.contains('employee') ||
          firstRole.contains('worker')) {
        roleColor = Colors.green;
      } else {
        roleColor = Colors.blue;
      }
    }

    // Extract site info
    final empAssignSite =
        user['emp_assign_site'] as Map<String, dynamic>? ?? {};
    final site = empAssignSite['site'] as Map<String, dynamic>? ?? {};
    final siteName = site['site_name'] ?? 'N/A';

    return {
      'name': name,
      'id': employeeId,
      'department': departmentName,
      'designation': designationName,
      'role': roleText,
      'color': roleColor,
      'site': siteName,
      'image_url': imageUrl,
      'user_id': user['id'],
      'department_id': emp['department_id'],
      'designation_id': emp['designation_id'],
      'roles_list': roles,
      'original_data': emp, // Keep original data for reference
    };
  }

  Future<void> _refreshEmployees() async {
    await _fetchEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.goNamed("home")),
        title: const Text('Employee List',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshEmployees,
            tooltip: 'Refresh',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEmployeePage(),
                  ),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, color: Colors.white),
                  Text(
                    'Add Employee',
                    style: TextStyle(fontSize: 8, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading employees...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshEmployees,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_employees.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No employees found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshEmployees,
      child: ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final emp = _employees[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: emp['image_url'] != null
                  ? CircleAvatar(
                      backgroundColor: emp['color'] ?? Colors.blue,
                      backgroundImage: NetworkImage(emp['image_url']),
                      onBackgroundImageError: (exception, stackTrace) {
                        print('Error loading employee image: $exception');
                      },
                    )
                  : CircleAvatar(
                      backgroundColor: emp['color'] ?? Colors.blue,
                      child: Text(
                        emp['name']?.toString().isNotEmpty == true
                            ? emp['name'][0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
              title: Text(
                emp['name'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (emp['id']?.toString().isNotEmpty == true &&
                      emp['id'] != 'N/A')
                    Text(
                      'ID: ${emp['id']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (emp['designation']?.toString().isNotEmpty == true)
                    Text(
                      '${emp['designation']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (emp['site']?.toString().isNotEmpty == true &&
                      emp['site'] != 'N/A')
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Site: ${emp['site']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: emp['color'] ?? Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emp['role'] ?? 'No Role',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[700], size: 20),
                    tooltip: 'Delete Employee',
                    onPressed: () {
                      if (emp['user_id'] != null) {
                        _deleteEmployee(emp['user_id']);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Cannot delete employee: User ID is missing.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              onTap: () {
                // Navigate to employee details page
                _navigateToEmployeeDetails(emp);
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToEmployeeDetails(Map<String, dynamic> employee) {
    final userId = employee['user_id'];
    final employeeName = employee['name'] ?? 'Unknown Employee';

    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmployeeDetailsPage(
            userId: userId,
            employeeName: employeeName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found for this employee'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee['name'] ?? 'Employee Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Employee ID', employee['id']),
              _buildDetailRow('Department', employee['department']),
              _buildDetailRow('Designation', employee['designation']),
              _buildDetailRow('Role', employee['role']),
              if (employee['site']?.toString().isNotEmpty == true &&
                  employee['site'] != 'N/A')
                _buildDetailRow('Site', employee['site']),
              // if (employee['user_id'] != null)
              //   _buildDetailRow('User ID', employee['user_id']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmployee(int userId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error. Please login again.')),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('https://erp.comsindia.in/api/employee/delete/$userId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success
        setState(() {
          _employees.removeWhere((emp) => emp['user_id'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Error
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Failed to delete employee.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
