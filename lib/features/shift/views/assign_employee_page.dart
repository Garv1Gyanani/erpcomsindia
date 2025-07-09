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

  Future<void> _fetchEmployees() async {
    setState(() {
      _isEmployeeLoading = true;
      _employees = null;
      _selectedEmployeeIds.clear();
    });

    final token = await _storageService.getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.get(
      Uri.parse('https://erp.comsindia.in/api/shift/site/emp/list'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == true && responseData['data'] is List) {
        setState(() {
          _employees = responseData['data'] as List<dynamic>;
          _isEmployeeLoading = false;
        });
      } else {
        throw Exception('Failed to load employees.');
      }
    } else {
      throw Exception('Failed to load employees.');
    }
  }

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
        title: const Text('Assign Employee',
            style: TextStyle(color: Colors.white)),
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
                      return DropdownMenuItem<String>(
                        value: site['site_id'].toString(),
                        child: Text(site['site']['site_name']),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSiteId = newValue;
                        });
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
                        child: Text(shift['shift_name']),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedShiftId = newValue;
                        if (newValue != null) {
                          _fetchEmployees();
                        }
                      });
                    },
                  ),
                const SizedBox(height: 16),
                if (_isEmployeeLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_employees != null) ...[
                  const Text('Select Employees:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    height: 200,
                    child: ListView(
                      children: _employees!.map((employee) {
                        final employeeId = employee['id'].toString();
                        return CheckboxListTile(
                          title: Text(employee['name']),
                          value: _selectedEmployeeIds.contains(employeeId),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedEmployeeIds.add(employeeId);
                              } else {
                                _selectedEmployeeIds.remove(employeeId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isAssigning ? null : _assignShiftToEmployees,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isAssigning
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        )
                      : const Text('Assign',
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
