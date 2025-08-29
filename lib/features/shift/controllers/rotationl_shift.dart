import 'package:coms_india/core/constants/app_colors.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/shift/views/site_shifts_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RotationalShiftPage extends StatefulWidget {
  const RotationalShiftPage({Key? key}) : super(key: key);

  @override
  State<RotationalShiftPage> createState() => _RotationalShiftPageState();
}

class _RotationalShiftPageState extends State<RotationalShiftPage> {
  bool isLoading = true;
  bool isLoadingEmployees = false;
  bool isSaving = false;
  String? errorMessage;

  // Data models
  List<SiteData> sites = [];
  SiteData? selectedSite;
  ShiftData? selectedShift;
  List<Employee> employees = [];

  // Track employee shift assignments - only one shift per employee
  Map<int, int?> employeeShiftAssignments = {};

  // Storage service for auth token
  String? authToken;
  final StorageService _storageService = StorageService();

  // API configuration
  final String apiUrl = 'https://erp.comsindia.in/api/site/shift/index';
  final String _baseUrl = 'https://erp.comsindia.in/api';

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    await _loadAuthToken();
    if (authToken != null) {
      await fetchShiftData();
    } else {
      setState(() {
        errorMessage = 'Authentication token not found. Please login again.';
        isLoading = false;
      });
    }
  }

  Future<void> _loadAuthToken() async {
    try {
      final authData = await _storageService.getAllAuthData();
      final userData = authData['user'];
      authToken = authData['token'];
    } catch (e) {
      print('Error loading auth token: $e');
      authToken = null;
    }
  }

  Future<void> fetchShiftData() async {
    if (authToken == null) {
      setState(() {
        errorMessage = 'Authentication token not available';
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['status'] == true) {
          final List<dynamic> sitesJson = jsonData['data'];
          setState(() {
            sites = sitesJson.map((site) => SiteData.fromJson(site)).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = jsonData['message'] ?? 'Failed to fetch data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

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
        return employeeListFromJson(response.body);
      } else {
        throw Exception(
            'Failed to load employee list. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching employees: $e');
    }
  }

  Future<void> loadEmployeesForShift() async {
    if (selectedSite == null || selectedShift == null) return;

    setState(() {
      isLoadingEmployees = true;
      employees = [];
    });

    try {
      final employeeList = await fetchEmployeesForShift(
        authToken!,
        selectedSite!.siteId,
        selectedShift!.shiftId,
      );

      setState(() {
        employees = employeeList;
        // Initialize shift assignments for each employee
        for (var employee in employees) {
          if (!employeeShiftAssignments.containsKey(employee.userId)) {
            employeeShiftAssignments[employee.userId] = null;
          }
        }
        isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoadingEmployees = false;
      });
    }
  }

  // Get other shifts available at the selected site (excluding current shift)
  List<ShiftData> getOtherShifts() {
    if (selectedSite == null || selectedShift == null) return [];

    return selectedSite!.shifts
        .where((shift) => shift.shiftId != selectedShift!.shiftId)
        .toList();
  }

  // Toggle shift assignment for an employee (only one at a time)
  void toggleShiftAssignment(int employeeId, int shiftId) {
    setState(() {
      if (employeeShiftAssignments[employeeId] == shiftId) {
        // If clicking the same shift, deselect it
        employeeShiftAssignments[employeeId] = null;
      } else {
        // Otherwise, select this shift (replacing any previous selection)
        employeeShiftAssignments[employeeId] = shiftId;
      }
    });
  }

  // Toggle shift assignment for all employees
  void toggleShiftForAllEmployees(int shiftId) {
    setState(() {
      // Count how many employees currently have this shift assigned
      final currentlyAssigned = employeeShiftAssignments.values
          .where((assignedShiftId) => assignedShiftId == shiftId)
          .length;

      if (currentlyAssigned > 0) {
        // If some employees have this shift, remove it from all
        for (var employeeId in employeeShiftAssignments.keys) {
          if (employeeShiftAssignments[employeeId] == shiftId) {
            employeeShiftAssignments[employeeId] = null;
          }
        }
      } else {
        // If no employees have this shift, assign it to all
        for (var employeeId in employeeShiftAssignments.keys) {
          employeeShiftAssignments[employeeId] = shiftId;
        }
      }
    });
  }

  // Check if employee is assigned to a shift
  bool isEmployeeAssignedToShift(int employeeId, int shiftId) {
    return employeeShiftAssignments[employeeId] == shiftId;
  }

  // Get total assignment count
  int getTotalAssignments() {
    return employeeShiftAssignments.values
        .where((shiftId) => shiftId != null)
        .length;
  }

  // Check if there are any active assignments
  bool hasActiveAssignments() {
    return employeeShiftAssignments.values.any((shiftId) => shiftId != null);
  }

  String formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];

      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotational Shifts'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    Expanded(child: _buildContent()),
                    if (employees.isNotEmpty && getOtherShifts().isNotEmpty)
                      _buildBottomSaveSection(),
                  ],
                ),
    );
  }

  Widget _buildBottomSaveSection() {
    final totalAssignments = getTotalAssignments();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (totalAssignments > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  '$totalAssignments assignment(s) selected',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: totalAssignments > 0 && !isSaving
                    ? _saveShiftAssignments
                    : null,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  isSaving ? 'Saving...' : 'Save Assignments',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Save shift assignments using API
  void _saveShiftAssignments() {
    final totalAssignments = getTotalAssignments();

    if (totalAssignments == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No shift assignments to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Save'),
          content: Text('Save $totalAssignments shift assignment(s)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performSaveAssignments();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performSaveAssignments() async {
    if (selectedSite == null || authToken == null) {
      print('Debug: Missing selectedSite or authToken');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final url =
          Uri.parse('https://erp.comsindia.in/api/shift/rotation/store');
      print('Debug: Sending request to $url');

      var request = http.MultipartRequest('POST', url);

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $authToken';

      request.fields['site_id'] = selectedSite!.siteId.toString();
      request.fields['remarks'] =
          'Shift rotation batch - ${DateTime.now().toString()}';

      print('Debug: site_id = ${request.fields['site_id']}');
      print('Debug: remarks = ${request.fields['remarks']}');

      int assignmentIndex = 0;
      for (var entry in employeeShiftAssignments.entries) {
        final userId = entry.key;
        final shiftId = entry.value;

        if (shiftId != null) {
          request.fields['assignments[$assignmentIndex][user_id]'] =
              userId.toString();
          request.fields['assignments[$assignmentIndex][shift_id]'] =
              shiftId.toString();
          print(
              'Debug: Added assignment - user_id: $userId, shift_id: $shiftId');
          assignmentIndex++;
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Debug: Response status code = ${response.statusCode}');
      print('Debug: Response body = $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        print('Debug: Parsed JSON response = $jsonData');

        if (jsonData['status'] == true || jsonData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  jsonData['message'] ?? 'Assignments saved successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          context.push('/site-shifts');
          setState(() {
            employeeShiftAssignments.clear();
            for (var employee in employees) {
              employeeShiftAssignments[employee.userId] = null;
            }
          });
        } else {
          print('Debug: Server returned failure message.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(jsonData['message'] ?? 'Failed to save assignments'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('Debug: Server returned non-200/201 status.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Debug: Exception occurred - $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving assignments: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
      print('Debug: Save process completed. isSaving = $isSaving');
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              await _initializeAndFetchData();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSiteDropdown(),
          const SizedBox(height: 16),
          if (selectedSite != null) ...[
            _buildShiftDropdown(),
            const SizedBox(height: 16),
          ],
          if (selectedShift != null) ...[
            _buildAvailableShiftsHeader(),
            const SizedBox(height: 16),
            _buildEmployeeGrid(),
          ],
        ],
      ),
    );
  }

  Widget _buildSiteDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Site',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<SiteData>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Choose a site',
            prefixIcon: Icon(Icons.location_on),
          ),
          value: selectedSite,
          items: sites.map((site) {
            return DropdownMenuItem<SiteData>(
              value: site,
              child: Text(site.siteName),
            );
          }).toList(),
          onChanged: (SiteData? value) {
            // Prevent site change if there are active assignments
            if (hasActiveAssignments()) {
              _showChangeConfirmationDialog(
                'Change Site',
                'You have unsaved assignments. Changing the site will clear all selections. Continue?',
                () {
                  setState(() {
                    selectedSite = value;
                    selectedShift = null;
                    employees = [];
                    employeeShiftAssignments.clear();
                  });
                },
              );
            } else {
              setState(() {
                selectedSite = value;
                selectedShift = null;
                employees = [];
                employeeShiftAssignments.clear();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildShiftDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Current Shift',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ShiftData>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Choose current shift to view employees',
          ),
          value: selectedShift,
          items: selectedSite!.shifts.map((shift) {
            return DropdownMenuItem<ShiftData>(
              value: shift,
              child: Text(
                '${shift.shiftName} (${formatTime(shift.startTime)} - ${formatTime(shift.endTime)})',
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (ShiftData? value) {
            // Prevent shift change if there are active assignments
            if (hasActiveAssignments()) {
              _showChangeConfirmationDialog(
                'Change Shift',
                'You have unsaved assignments. Changing the shift will clear all selections. Continue?',
                () {
                  setState(() {
                    selectedShift = value;
                    employees = [];
                    employeeShiftAssignments.clear();
                  });
                  if (value != null) {
                    loadEmployeesForShift();
                  }
                },
              );
            } else {
              setState(() {
                selectedShift = value;
              });
              if (value != null) {
                loadEmployeesForShift();
              }
            }
          },
        ),
      ],
    );
  }

  void _showChangeConfirmationDialog(
      String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableShiftsHeader() {
    final otherShifts = getOtherShifts();

    if (otherShifts.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Shifts for Assignment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: otherShifts.map((shift) {
                final assignedCount = employeeShiftAssignments.values
                    .where((shiftId) => shiftId == shift.shiftId)
                    .length;
                final totalEmployees = employees.length;
                final isAllAssigned =
                    assignedCount == totalEmployees && totalEmployees > 0;

                return InkWell(
                  onTap: () => toggleShiftForAllEmployees(shift.shiftId),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAllAssigned ? Colors.green[100] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAllAssigned ? Colors.green : Colors.blue[200]!,
                        width: isAllAssigned ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAllAssigned
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 16,
                          color:
                              isAllAssigned ? Colors.green : Colors.blue[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${shift.shiftName} (${formatTime(shift.startTime)} - ${formatTime(shift.endTime)})', // Display shift name and time
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isAllAssigned
                                ? Colors.green[800]
                                : Colors.blue[800],
                          ),
                        ),
                        if (assignedCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAllAssigned ? Colors.green : Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$assignedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeGrid() {
    if (isLoadingEmployees) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (employees.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No employees found for this shift',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final otherShifts = getOtherShifts();

    if (otherShifts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No other shifts available at ${selectedSite!.siteName}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: employees
          .map((employee) => _buildEmployeeCard(employee, otherShifts))
          .toList(),
    );
  }

  Widget _buildEmployeeCard(Employee employee, List<ShiftData> otherShifts) {
    final assignedShiftId = employeeShiftAssignments[employee.userId];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    employee.name.isNotEmpty
                        ? employee.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        employee.phone,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (assignedShiftId != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Assigned',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Weekend Days
            if (employee.selectedDays.isNotEmpty) ...[
              Wrap(
                spacing: 4.0,
                children: employee.selectedDays
                    .map((day) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getWeekendDayColor(day),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getShortDayName(day),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Shift Assignment Selection (Only one at a time)
            const Text(
              'Assign to one additional shift:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: otherShifts.map((shift) {
                final isAssigned = assignedShiftId == shift.shiftId;

                return InkWell(
                  onTap: () =>
                      toggleShiftAssignment(employee.userId, shift.shiftId),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAssigned ? Colors.blue[100] : Colors.grey[100],
                      border: Border.all(
                        color: isAssigned ? Colors.blue : Colors.grey[300]!,
                        width: isAssigned ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAssigned
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 16,
                          color: isAssigned ? Colors.blue : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${shift.shiftName} (${formatTime(shift.startTime)} - ${formatTime(shift.endTime)})', // Display shift name and time
                          style: TextStyle(
                            color: isAssigned
                                ? Colors.blue[800]
                                : Colors.grey[700],
                            fontWeight: isAssigned
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getWeekendDayColor(String day) {
    switch (day.toLowerCase()) {
      case 'sunday':
      case 'sun':
        return Colors.red[400] ?? Colors.red;
      case 'monday':
      case 'mon':
        return Colors.blue[400] ?? Colors.blue;
      case 'tuesday':
      case 'tue':
        return Colors.green[400] ?? Colors.green;
      case 'wednesday':
      case 'wed':
        return Colors.orange[400] ?? Colors.orange;
      case 'thursday':
      case 'thu':
        return Colors.purple[400] ?? Colors.purple;
      case 'friday':
      case 'fri':
        return Colors.teal[400] ?? Colors.teal;
      case 'saturday':
      case 'sat':
        return Colors.indigo[400] ?? Colors.indigo;
      default:
        return Colors.grey[400] ?? Colors.grey;
    }
  }

  String _getShortDayName(String day) {
    switch (day.toLowerCase()) {
      case 'sunday':
        return 'SUN';
      case 'monday':
        return 'MON';
      case 'tuesday':
        return 'TUE';
      case 'wednesday':
        return 'WED';
      case 'thursday':
        return 'THU';
      case 'friday':
        return 'FRI';
      case 'saturday':
        return 'SAT';
      default:
        return day.length > 3
            ? day.substring(0, 3).toUpperCase()
            : day.toUpperCase();
    }
  }
}

// Data models
class SiteData {
  final int siteId;
  final String siteName;
  final List<ShiftData> shifts;

  SiteData({
    required this.siteId,
    required this.siteName,
    required this.shifts,
  });

  factory SiteData.fromJson(Map<String, dynamic> json) {
    return SiteData(
      siteId: json['site_id'],
      siteName: json['site_name'],
      shifts: (json['shifts'] as List)
          .map((shift) => ShiftData.fromJson(shift))
          .toList(),
    );
  }
}

class ShiftData {
  final int shiftId;
  final String shiftName;
  final String startTime;
  final String endTime;
  final int isDefault;
  final int isActive;

  ShiftData({
    required this.shiftId,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.isDefault,
    required this.isActive,
  });

  factory ShiftData.fromJson(Map<String, dynamic> json) {
    return ShiftData(
      shiftId: json['shift_id'],
      shiftName: json['shift_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      isDefault: json['is_default'],
      isActive: json['is_active'],
    );
  }
}

class Employee {
  final int userId;
  final String name;
  final String phone;
  Set<String> selectedDays;

  Employee({
    required this.userId,
    required this.name,
    required this.phone,
    required List<String> initialWeekendDays,
  }) : selectedDays = Set<String>.from(initialWeekendDays);

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        userId: json["user_id"] ?? 0,
        name: json["name"],
        phone: json["phone"],
        initialWeekendDays:
            List<String>.from(json["weekend_days"].map((x) => x)),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          phone == other.phone;

  @override
  int get hashCode => phone.hashCode;
}

class WeekendEmployee {
  final String name;
  final String phone;
  final List<String> shifts;
  final List<String> weekendDays;

  WeekendEmployee({
    required this.name,
    required this.phone,
    required this.shifts,
    required this.weekendDays,
  });

  factory WeekendEmployee.fromJson(Map<String, dynamic> json) =>
      WeekendEmployee(
        name: json["name"],
        phone: json["phone"],
        shifts: List<String>.from(json["shifts"].map((x) => x)),
        weekendDays: List<String>.from(json["weekend_days"].map((x) => x)),
      );
}

class SiteGroup {
  final String site;
  final List<WeekendEmployee> employees;

  SiteGroup({required this.site, required this.employees});

  factory SiteGroup.fromJson(Map<String, dynamic> json) => SiteGroup(
      site: json["site"],
      employees: List<WeekendEmployee>.from(
          json["employees"].map((x) => WeekendEmployee.fromJson(x))));
}

// Helper functions
List<Employee> employeeListFromJson(String str) {
  final jsonData = json.decode(str);
  return List<Employee>.from(jsonData['data'].map((x) => Employee.fromJson(x)));
}

List<SiteGroup> siteGroupListFromJson(String str) => List<SiteGroup>.from(
    json.decode(str)['data'].map((x) => SiteGroup.fromJson(x)));
