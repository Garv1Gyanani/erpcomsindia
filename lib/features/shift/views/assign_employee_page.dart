import 'dart:convert';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class AssignEmployeePage extends StatefulWidget {
  const AssignEmployeePage({super.key});

  @override
  State<AssignEmployeePage> createState() => _AssignEmployeePageState();
}

class _AssignEmployeePageState extends State<AssignEmployeePage> {
  final StorageService _storageService = StorageService();

  // Site selection
  String? _selectedSiteId;
  List<dynamic>? _sites;
  Future<void>? _sitesFuture;

  // Shift selection
  String? _selectedShiftId;
  List<dynamic>? _shiftsForSite;
  bool _isShiftLoading = false;

  // Employee selection
  final List<String> _selectedEmployeeIds = [];
  List<dynamic>? _employees;
  bool _isEmployeeLoading = false;

  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _sitesFuture = _fetchSites();
  }

  Future<void> _fetchSites() async {
    final token = await _storageService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('https://erp.comsindia.in/api/site/list/assigned'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['user'] is List) {
        setState(() {
          _sites = responseData['user'] as List<dynamic>;
        });
      } else {
        throw Exception('Assigned sites not found in response.');
      }
    } else {
      throw Exception('Failed to load sites.');
    }
  }

  Future<void> _fetchShiftsForSite(String siteId) async {
    setState(() {
      _isShiftLoading = true;
      _shiftsForSite = null;
      _selectedShiftId = null;
      _employees = null;
      _selectedEmployeeIds.clear();
    });

    final token = await _storageService.getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.get(
      Uri.parse('https://erp.comsindia.in/api/site/shift/index'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == true && responseData['data'] is List) {
        final allSiteShifts = responseData['data'] as List<dynamic>;
        final siteShiftsData = allSiteShifts.firstWhere(
            (site) => site['site_id'].toString() == siteId,
            orElse: () => null);
        setState(() {
          _shiftsForSite =
              siteShiftsData != null ? siteShiftsData['shifts'] : [];
          _isShiftLoading = false;
        });
      } else {
        throw Exception('Failed to load shifts for site.');
      }
    } else {
      throw Exception('Failed to load shifts.');
    }
  }

  // --- MODIFIED LOGIC ---
  Future<void> _fetchEmployees() async {
    // Ensure a site is selected before fetching employees
    if (_selectedSiteId == null) {
      return;
    }

    setState(() {
      _isEmployeeLoading = true;
      _employees = null;
      _selectedEmployeeIds.clear();
    });

    final token = await _storageService.getToken();
    if (token == null) throw Exception('Authentication token not found.');

    // Use the selected site ID to build the dynamic URL
    final url =
        'https://erp.comsindia.in/api/shift/site/$_selectedSiteId/emp/list';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == true && responseData['data'] is List) {
        setState(() {
          _employees = responseData['data'] as List<dynamic>;

          // Pre-select employees who are already assigned to the selected shift
          if (_selectedShiftId != null) {
            final selectedShiftIdInt = int.parse(_selectedShiftId!);
            for (var site in _employees!) {
              final employees = site['employees'] as List<dynamic>? ?? [];
              for (var employee in employees) {
                final employeeShiftId = employee['shift_id'];
                if (employeeShiftId == selectedShiftIdInt) {
                  _selectedEmployeeIds.add(employee['id'].toString());
                }
              }
            }
          }
          _isEmployeeLoading = false;
        });
      } else {
        setState(() {
          _isEmployeeLoading = false;
          // Set employees to an empty list to avoid showing old data
          _employees = [];
        });
        // Optionally show an error message from the API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'Failed to load employees.'),
          ),
        );
      }
    } else {
      setState(() {
        _isEmployeeLoading = false;
      });
      throw Exception(
          'Failed to load employees. Status code: ${response.statusCode}');
    }
  }
  // --- END OF MODIFIED LOGIC ---

  Future<void> _assignShiftToEmployees() async {
    if (_selectedSiteId == null ||
        _selectedShiftId == null ||
        _selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select a site, a shift, and at least one employee.')),
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    final token = await _storageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error.')),
      );
      setState(() => _isAssigning = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://erp.comsindia.in/api/shift/site/assign/emp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'site_id': int.parse(_selectedSiteId!),
          'shift_id': int.parse(_selectedShiftId!),
          'user_id': _selectedEmployeeIds.map((id) => int.parse(id)).toList(),
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift assigned successfully!')),
        );
        context.go('/site-shifts');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(responseData['message'] ?? 'Failed to assign shift.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isAssigning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Assign Shift', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: _sitesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _sites == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_sites == null)
                  const Center(child: Text('No sites found.'))
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select a Site',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSiteId,
                    items: _sites!.map((site) {
                      final siteName = site['site']?['site_name'] as String? ??
                          'Unnamed Site';
                      return DropdownMenuItem<String>(
                        value: site['site_id'].toString(),
                        child: Text(siteName),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSiteId = newValue;
                        });
                        // When a site is selected, fetch its shifts
                        _fetchShiftsForSite(newValue);
                      }
                    },
                  ),
                const SizedBox(height: 16),
                if (_isShiftLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_shiftsForSite != null)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select a Shift',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedShiftId,
                    items: _shiftsForSite!.map((shift) {
                      return DropdownMenuItem<String>(
                        value: shift['shift_id'].toString(),
                        child: Text(
                            '${shift['shift_name']} (${shift['start_time'].substring(0, 5)} - ${shift['end_time'].substring(0, 5)})'), // Display shift name and time
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedShiftId = newValue;
                        // When a shift is selected, fetch the employees for the selected site
                        if (newValue != null) {
                          _fetchEmployees();
                        }
                      });
                    },
                  ),
                const SizedBox(height: 16),
                if (_isEmployeeLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_employees != null)
                  ..._employees!.map((site) {
                    final siteName =
                        site['site_name'] as String? ?? 'Unnamed Site';
                    final employees = site['employees'] as List<dynamic>? ?? [];

                    // If there are no employees for this site, don't show anything
                    if (employees.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final siteEmployeeIds =
                        employees.map((e) => e['id'].toString()).toList();

                    final numSelected = siteEmployeeIds
                        .where((id) => _selectedEmployeeIds.contains(id))
                        .length;

                    bool? isSiteSelected;
                    if (numSelected == 0) {
                      isSiteSelected = false;
                    } else if (numSelected == siteEmployeeIds.length) {
                      isSiteSelected = true;
                    } else {
                      isSiteSelected = null; // Indeterminate state
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            siteName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        CheckboxListTile(
                          title: const Text('Select All',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          value: isSiteSelected,
                          tristate: true,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                // Select all employees for this site
                                _selectedEmployeeIds.addAll(
                                    siteEmployeeIds.where((id) =>
                                        !_selectedEmployeeIds.contains(id)));
                              } else {
                                // Deselect all employees for this site
                                _selectedEmployeeIds.removeWhere(
                                    (id) => siteEmployeeIds.contains(id));
                              }
                            });
                          },
                        ),
                        const Divider(height: 1),
                        ...employees.map((employee) {
                          final employeeId = employee['id'].toString();
                          final isSelected =
                              _selectedEmployeeIds.contains(employeeId);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            elevation: 2,
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              title: Text(
                                employee['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.email,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            employee['email'] ?? 'No Email',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone,
                                            size: 16, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text(
                                          employee['phone'] ?? 'No Phone',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule,
                                            size: 16, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.orange.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.orange
                                                    .withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            employee['shift_name'] ??
                                                'No Shift',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              value: isSelected,
                              activeColor: Colors.red,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedEmployeeIds.add(employeeId);
                                  } else {
                                    _selectedEmployeeIds.remove(employeeId);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isAssigning ? null : _assignShiftToEmployees,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isAssigning
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Assign Shift',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
