import 'package:coms_india/core/constants/app_colors.dart';
import 'package:coms_india/core/services/api_service.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/employee/models/employee.dart';
import 'package:coms_india/features/shift/models/site_shift_model.dart';
import 'package:coms_india/features/shift/views/weekendlist.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class WeekendAssignmentPage extends StatefulWidget {
  const WeekendAssignmentPage({super.key});

  @override
  State<WeekendAssignmentPage> createState() => _WeekendAssignmentPageState();
}

class _WeekendAssignmentPageState extends State<WeekendAssignmentPage> {
  // Services
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  // State
  bool _isLoading = true;
  String? _errorMessage;
  String? _authToken;
  bool _isSubmitting = false;

  List<Site> _sites = [];
  Site? _selectedSite;
  Shift? _selectedShift;

  bool _isFetchingEmployees = false;
  String? _employeeFetchError;
  List<Employee> _employees = [];

  // final List<String> _weekDays = [
  //   'Mon',
  //   'Tue',
  //   'Wed',
  //   'Thu',
  //   'Fri',
  //   'Sat',
  //   'Sun'
  // ];
  final Map<String, String> _weekDayMap = {
    'Mon': 'Monday',
    'Tue': 'Tuesday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Fri': 'Friday',
    'Sat': 'Saturday',
    'Sun': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authData = await _storageService.getAllAuthData();
      _authToken = authData['token'];
      if (_authToken == null || _authToken!.isEmpty)
        throw Exception('Auth token not found.');
      final sites = await _apiService.fetchSitesAndShifts(_authToken!);
      setState(() => _sites = sites);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEmployees() async {
    if (_selectedSite == null || _selectedShift == null || _authToken == null)
      return;
    setState(() {
      _isFetchingEmployees = true;
      _employeeFetchError = null;
      _employees = [];
    });
    try {
      final employees = await _apiService.fetchEmployeesForShift(
          _authToken!, _selectedSite!.siteId, _selectedShift!.shiftId);
      setState(() => _employees = employees);
    } catch (e) {
      setState(() => _employeeFetchError = e.toString());
    } finally {
      setState(() => _isFetchingEmployees = false);
    }
  }

  Future<void> _submitWeekendAssignment() async {
    final employeesToUpdate =
        _employees.where((emp) => emp.selectedDays.isNotEmpty).toList();
    if (employeesToUpdate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select days for at least one employee.'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _apiService.assignWeekends(
          token: _authToken!,
          siteId: _selectedSite!.siteId,
          employees: employeesToUpdate);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Assignments submitted successfully!'),
          backgroundColor: Colors.white));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Submission Failed: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Weekend'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red))));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Site Dropdown
          DropdownButtonFormField<Site>(
            value: _selectedSite,
            decoration: const InputDecoration(labelText: 'Select Site'),
            hint: const Text('Choose a site'),
            items: _sites
                .map((site) =>
                    DropdownMenuItem(value: site, child: Text(site.siteName)))
                .toList(),
            onChanged: (Site? newValue) {
              setState(() {
                _selectedSite = newValue;
                _selectedShift = null;
                _employees = [];
                _employeeFetchError = null;
              });
            },
          ),
          const SizedBox(height: 20.0),

          // Shift Dropdown
          DropdownButtonFormField<Shift>(
            value: _selectedShift,
            decoration: InputDecoration(
                labelText: 'Select Shift',
                fillColor:
                    _selectedSite == null ? Colors.grey[200] : Colors.white),
            hint: const Text('Choose a shift'),
            items: _selectedSite?.shifts
                .map((shift) => DropdownMenuItem(
                    value: shift, child: Text(shift.shiftName)))
                .toList(),
            onChanged: _selectedSite == null
                ? null
                : (Shift? newValue) {
                    setState(() => _selectedShift = newValue);
                    if (newValue != null) _fetchEmployees();
                  },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          // Employee List Section
          Expanded(child: _buildEmployeeSection()),
          const SizedBox(height: 10),

          // Submit Button
          ElevatedButton(
            onPressed: (_selectedSite != null &&
                    _employees.isNotEmpty &&
                    !_isSubmitting)
                ? _submitWeekendAssignment
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.teal.withOpacity(0.5),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3))
                : const Text('Submit Assignment'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSection() {
    if (_selectedShift == null)
      return const Center(child: Text('Please select a site and shift.'));
    if (_isFetchingEmployees)
      return const Center(child: CircularProgressIndicator());
    if (_employeeFetchError != null)
      return Center(
          child: Text('Error: $_employeeFetchError',
              style: const TextStyle(color: Colors.red)));
    if (_employees.isEmpty)
      return const Center(child: Text('No employees found for this shift.'));

    return ListView.builder(
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(employee.phone, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  // Iterate over the map's entries
                  children: _weekDayMap.entries.map((entry) {
                    final String shortName = entry.key; // e.g., "Sun"
                    final String fullName = entry.value; // e.g., "Sunday"

                    // Check if the FULL name is in the selected set
                    final isSelected = employee.selectedDays.contains(fullName);

                    return FilterChip(
                      // Display the SHORT name on the chip
                      label: Text(shortName),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          // Add or remove the FULL name from the data set
                          if (selected) {
                            employee.selectedDays.add(fullName);
                          } else {
                            employee.selectedDays.remove(fullName);
                          }
                        });
                      },
                      selectedColor: Colors.teal.withOpacity(0.3),
                      checkmarkColor: Colors.teal,
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
