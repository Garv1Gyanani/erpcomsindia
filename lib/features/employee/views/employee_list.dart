// lib/features/employee/views/employee_list_page.dart (or your file path)

import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/employee/views/basic_info.dart';
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
  Map<String, dynamic>? _employeesBySite;
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
        Uri.parse('https://erp.comsindia.in/api/employee'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == true &&
            responseData['employees'] != null) {
          setState(() {
            _employeesBySite =
                responseData['employees'] as Map<String, dynamic>;
            _isLoading = false;
          });

          print(
              '✅ Loaded employees for ${_employeesBySite?.length ?? 0} sites');
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Failed to load employees';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        String errorMessage =
            'Failed to load employees. Status: ${response.statusCode}';
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('message')) {
            errorMessage = responseData['message'];
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }

        setState(() {
          _errorMessage = errorMessage;
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
          onPressed: () {
            context.goNamed('team');
          },
        ),
        title: const Text('Sites',
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
                ).then((_) {
                  // Refresh list after adding an employee
                  _refreshEmployees();
                });
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

    if (_employeesBySite == null || _employeesBySite!.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshEmployees,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No sites or employees found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: RefreshIndicator(
        onRefresh: _refreshEmployees,
        child: ListView.builder(
          itemCount: _employeesBySite!.length,
          itemBuilder: (context, index) {
            final siteName = _employeesBySite!.keys.elementAt(index);
            final siteEmployees = _employeesBySite![siteName] as List<dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ExpansionTile(
                title: Text(
                  siteName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  '${siteEmployees.length} employees',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                maintainState: true,
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                childrenPadding: EdgeInsets.zero,
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                children: siteEmployees
                    .map((emp) =>
                        _buildEmployeeNode(emp as Map<String, dynamic>))
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmployeeNode(Map<String, dynamic> employee) {
    final juniors = employee['juniors'];
    bool hasJuniors = false;
    int juniorCount = 0;

    if (juniors is Map<String, dynamic> && juniors.isNotEmpty) {
      hasJuniors = true;
      juniors.forEach((key, value) {
        if (value is List) {
          juniorCount += value.length;
        }
      });
    }

    if (hasJuniors) {
      return ExpansionTile(
        title: _buildEmployeeTile(employee, isParent: true),
        subtitle: Text('$juniorCount Juniors'),
        childrenPadding: const EdgeInsets.only(left: 16.0),
        children: (juniors as Map<String, dynamic>).entries.expand((entry) {
          final juniorList = entry.value as List<dynamic>;
          return juniorList.map((junior) {
            return _buildEmployeeNode(junior as Map<String, dynamic>);
          });
        }).toList(),
      );
    } else {
      return _buildEmployeeTile(employee);
    }
  }

  Widget _buildEmployeeTile(Map<String, dynamic> emp, {bool isParent = false}) {
    final imageUrl = emp['employee_image_path'] != null
        ? 'https://erp.comsindia.in/${emp['employee_image_path']}'
        : null;
    final isSupervisor =
        (emp['roles'] as List<dynamic>?)?.contains('Supervisor') ?? false;

    return ListTile(
      onTap: () async {
        // When navigating to the edit page, we can pass a callback
        // or simply refresh when we pop back.
        final result = await context.push(
          '/employee/edit/${emp['id']}',
          extra: {'name': emp['name']},
        );
        // If the edit page returned 'true' (meaning a successful update), refresh the list.
        if (result == true) {
          _refreshEmployees();
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        onBackgroundImageError: imageUrl != null ? (e, s) {} : null,
        child: imageUrl == null
            ? Text(
                emp['name']?.toString().isNotEmpty == true
                    ? emp['name'][0].toUpperCase()
                    : '?',
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              emp['name'] ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          if (isSupervisor)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Supervisor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Emp ID: ${emp['empId'] ?? 'N/A'}'),
          Text(emp['designation'] ?? 'N/A'),
          Text(emp['department'] ?? 'N/A'),
        ],
      ),
      trailing: isParent
          ? null
          : IconButton(
              icon: Icon(Icons.delete, color: Colors.red[700], size: 20),
              tooltip: 'Delete Employee',
              onPressed: () {
                if (emp['id'] != null) {
                  _deleteEmployee(emp['id'], emp['name']);
                }
              },
            ),
    );
  }

  /// ========================================================================
  /// ========= THIS IS THE CORRECTED DELETE EMPLOYEE METHOD =========
  /// ========================================================================
  void _deleteEmployee(int employeeId, String employeeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete this employee: $employeeName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await _storageService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Not authenticated. Please log in again.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      // Corrected URL to match the curl command: .../delete/{id}
      final url =
          Uri.parse('https://erp.comsindia.in/api/employee/delete/$employeeId');

      final response = await http.delete(
        url,
        headers: {
          // Added 'Accept' header to match curl command
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Employee deleted successfully'),
            backgroundColor: Colors.green,
          ));
          _refreshEmployees(); // Refresh the list to show the change
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? 'Failed to delete employee.'),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        String errorMessage =
            'Error deleting employee. Status code: ${response.statusCode}';
        try {
          final data = json.decode(response.body);
          errorMessage = data['message'] ?? errorMessage;
        } catch (e) {
          // Ignore if response body is not valid JSON
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
