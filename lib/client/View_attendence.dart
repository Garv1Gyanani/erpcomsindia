import 'package:coms_india/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import for date formatting

// --- DATA MODELS ---

// Model for the initial Shift dropdown
class Shift {
  final int id;
  final String name;

  Shift({required this.id, required this.name});

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['shift']['id'],
      name: json['shift']['name'],
    );
  }
}

// Model for the User nested in the attendance record
class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], name: json['name']);
  }
}

// Model for a single Attendance Record
class AttendanceRecord {
  final int id;
  final DateTime? punchIn;
  final DateTime? punchOut;
  final String status;
  final int? lateByMinutes;
  final User user;

  AttendanceRecord({
    required this.id,
    this.punchIn,
    this.punchOut,
    required this.status,
    this.lateByMinutes,
    required this.user,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse dates that might be null
    DateTime? parseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print("Error parsing date: $dateString - $e");
        return null; // Handle parsing errors gracefully
      }
    }

    return AttendanceRecord(
      id: json['id'],
      punchIn: parseDate(json['punch_in']),
      punchOut: parseDate(json['punch_out']),
      status: json['status'],
      lateByMinutes: json['late_by_minutes'],
      user: User.fromJson(json['user']),
    );
  }
}

// --- MAIN WIDGET ---

class ViewAttendence extends StatefulWidget {
  const ViewAttendence({Key? key}) : super(key: key);

  @override
  State<ViewAttendence> createState() => _ViewAttendenceState();
}

class _ViewAttendenceState extends State<ViewAttendence> {
  final StorageService _storageService = StorageService();

  // State for fetching shifts
  List<Shift> _shifts = [];
  int? _selectedShiftId;
  bool _isLoadingShifts = true;
  String? _shiftErrorMessage;

  // State for fetching and grouping attendance data
  Map<int, List<AttendanceRecord>> _groupedAttendance = {};
  bool _isLoadingAttendance = false;
  String? _attendanceErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  Future<void> _fetchShifts() async {
    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token'];

    final url =
        Uri.parse('https://erp.comsindia.in/api/client/site/shift/list');
    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final List<dynamic> shiftData = data['data'];
          setState(() {
            _shifts = shiftData.map((json) => Shift.fromJson(json)).toList();
            _isLoadingShifts = false;
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load shifts');
      }
    } catch (e) {
      setState(() {
        _shiftErrorMessage = e.toString();
        _isLoadingShifts = false;
      });
    }
  }

  Future<void> _fetchAttendance(int shiftId) async {
    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token'];

    setState(() {
      _isLoadingAttendance = true;
      _groupedAttendance = {}; // Clear previous data
      _attendanceErrorMessage = null;
    });

    final url = Uri.parse(
        'https://erp.comsindia.in/api/client/emp/attendance/$shiftId');
    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('this is attendence reponse $data');
        if (data['status'] == true) {
          final List<dynamic> attendanceData = data['data'];
          final records = attendanceData
              .map((json) => AttendanceRecord.fromJson(json))
              .toList();

          // Group records by user ID
          final Map<int, List<AttendanceRecord>> tempGrouped = {};
          for (var record in records) {
            (tempGrouped[record.user.id] ??= []).add(record);
          }

          setState(() {
            _groupedAttendance = tempGrouped;
            _isLoadingAttendance = false;
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception(
            'Failed to load attendance data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _attendanceErrorMessage = e.toString();
        _isLoadingAttendance = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Attendance",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingShifts) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    if (_shiftErrorMessage != null) {
      return Center(
          child: Text('Error: $_shiftErrorMessage',
              style: const TextStyle(color: Colors.red)));
    }
    if (_shifts.isEmpty) {
      return const Center(child: Text('No shifts available.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Shift',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _selectedShiftId,
          isExpanded: true,
          hint: const Text('Please select a shift'),
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          items: _shifts.map((Shift shift) {
            return DropdownMenuItem<int>(
                value: shift.id, child: Text(shift.name));
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedShiftId = newValue;
              });
              _fetchAttendance(newValue);
            }
          },
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        Text(
          'Employees',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildAttendanceList()),
      ],
    );
  }

  Widget _buildAttendanceList() {
    if (_isLoadingAttendance) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    if (_attendanceErrorMessage != null) {
      return Center(
          child: Text('Error: $_attendanceErrorMessage',
              style: const TextStyle(color: Colors.red)));
    }
    if (_selectedShiftId != null && _groupedAttendance.isEmpty) {
      return const Center(
        child: Text(
          'No attendance records found for this shift.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    if (_selectedShiftId == null) {
      return const Center(
        child: Text(
          'Please select a shift to view records.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final userIds = _groupedAttendance.keys.toList();

    return ListView.builder(
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final userId = userIds[index];
        final userRecords = _groupedAttendance[userId]!;
        final employeeName = userRecords.first.user.name;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Text(
                employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'U',
                style: TextStyle(
                    color: Colors.red.shade800, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(employeeName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Chip(
              label: Text('${userRecords.length} record(s)'),
              backgroundColor: Colors.grey.shade200,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EmployeeAttendanceDetailScreen(
                    employeeName: employeeName,
                    records: userRecords,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- DETAIL SCREEN WIDGET ---

class EmployeeAttendanceDetailScreen extends StatelessWidget {
  final String employeeName;
  final List<AttendanceRecord> records;

  const EmployeeAttendanceDetailScreen({
    Key? key,
    required this.employeeName,
    required this.records,
  }) : super(key: key);

  // Helper to format time, returns 'N/A' if date is null
  String _formatTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat.jm().format(date.toLocal()); // Use local time
  }

  // Helper to format date, returns 'N/A' if date is null
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date.toLocal()); // Use local time
  }

  // Helper to get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on_duty':
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(employeeName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          // Sort records by date, newest first, for better readability
          records.sort((a, b) => b.punchIn!.compareTo(a.punchIn!));
          return _buildAttendanceCard(record);
        },
      ),
    );
  }

  // Card widget to display a single attendance record
  Widget _buildAttendanceCard(AttendanceRecord record) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getStatusColor(record.status), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(record.punchIn ?? record.punchOut),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    record.status.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: _getStatusColor(record.status),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo(
                    'Punch In', _formatTime(record.punchIn), Icons.login),
                _buildTimeInfo(
                    'Punch Out', _formatTime(record.punchOut), Icons.logout),
              ],
            ),
            if (record.lateByMinutes != null && record.lateByMinutes! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Late by ${record.lateByMinutes} minutes',
                      style: const TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Punch In/Out display
  Widget _buildTimeInfo(String title, String time, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.red.shade700, size: 28),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(time,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
