// lib/features/attendance/view/attendance_page.dart

import 'dart:convert';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// --- Theme & Style Constants (Unchanged) ---
const Color kPrimaryColor = Color(0xFFD32F2F);
const Color kBackgroundColor = Color(0xFFF8F9FA);
const Color kCardColor = Colors.white;
const Color kTextColor = Color(0xFF343A40);
const Color kSubtleTextColor = Color(0xFF6C757D);
const Color kSuccessColor = Color(0xFF28A745);
const Color kWarningColor = Color(0xFFFFC107);
const Color kAccentColor = Colors.blueAccent; // Used as a fallback

// --- Model (Unchanged) ---
class Attendance {
  final DateTime date;
  final String status;
  final Color color;
  final String? punchIn;
  final String? punchOut;
  final String workHours;
  final int lateBy;

  Attendance({
    required this.date,
    required this.status,
    required this.color,
    this.punchIn,
    this.punchOut,
    required this.workHours,
    required this.lateBy,
  });

  static Color _colorFromHex(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF" + hexColor;
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'Unknown',
      color: _colorFromHex(json['color'] ?? '#808080'),
      punchIn: json['punch_in'],
      punchOut: json['punch_out'],
      workHours: json['work_hours'] ?? '00:00',
      lateBy: json['late_by'] ?? 0,
    );
  }
}

class SelfAttendancePage extends StatefulWidget {
  const SelfAttendancePage({Key? key}) : super(key: key);

  @override
  State<SelfAttendancePage> createState() => _SelfAttendancePageState();
}

class _SelfAttendancePageState extends State<SelfAttendancePage> {
  final StorageService _storageService = StorageService();

  // State variables
  bool _isLoading = true;
  String _errorMessage = '';

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // MODIFIED: Add state for calendar format
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Data storage
  Map<DateTime, List<Attendance>> _attendanceEvents = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAttendance();
  }

  // --- Data Fetching (Unchanged) ---
  Future<void> _fetchAttendance() async {
    // ... (Your existing _fetchAttendance logic remains the same)
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token']?.trim();

    if (authToken == null || authToken.isEmpty) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication error. Please log in again.';
        });
      return;
    }
    const url = 'https://erp.comsindia.in/api/attendance/self';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == true) {
          List<Attendance> fetchedRecords = (jsonData['attendance'] as List)
              .map((item) => Attendance.fromJson(item))
              .toList();
          Map<DateTime, List<Attendance>> events = {};
          for (var record in fetchedRecords) {
            final dateOnly = DateTime.utc(
                record.date.year, record.date.month, record.date.day);
            if (events[dateOnly] == null) {
              events[dateOnly] = [];
            }
            events[dateOnly]!.add(record);
          }
          setState(() {
            _attendanceEvents = events;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                jsonData['message'] ?? 'Failed to parse attendance data.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Server Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  List<Attendance> _getEventsForDay(DateTime day) {
    final dateOnly = DateTime.utc(day.year, day.month, day.day);
    return _attendanceEvents[dateOnly] ?? [];
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('My Attendance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: kPrimaryColor, fontSize: 16)),
                ))
              : Column(
                  children: [
                    // The calendar is now inside a smaller, styled container
                    _buildCalendar(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildSelectedDayDetails(),
                    ),
                  ],
                ),
    );
  }

  // --- UI Widgets ---

  /// Builds the interactive and collapsible calendar widget.
  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<Attendance>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

        // MODIFIED: Control the calendar format (month/week)
        calendarFormat: _calendarFormat,

        // MODIFIED: Handle format changes
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },

        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        eventLoader: _getEventsForDay,
        calendarStyle: CalendarStyle(
          selectedDecoration:
              const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.3), shape: BoxShape.circle),
          markerDecoration: const BoxDecoration(
              color: kAccentColor, shape: BoxShape.circle), // Fallback
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          // MODIFIED: Make the format button visible to toggle views
          formatButtonVisible: true,
          // MODIFIED: Prevent button from showing next format (e.g., "2 weeks")
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: kSubtleTextColor.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          formatButtonTextStyle: const TextStyle(color: kSubtleTextColor),
          titleTextStyle: const TextStyle(
              fontSize: 18.0, fontWeight: FontWeight.bold, color: kTextColor),
          leftChevronIcon:
              const Icon(Icons.chevron_left, color: kSubtleTextColor),
          rightChevronIcon:
              const Icon(Icons.chevron_right, color: kSubtleTextColor),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events
                      .map((event) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: event.color, // Use color from API
                            ),
                          ))
                      .toList(),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  // The rest of the widgets remain unchanged as they were already well-designed.

  /// Builds the details section for the selected day.
  Widget _buildSelectedDayDetails() {
    // ... (This widget is unchanged)
    final selectedEvents = _getEventsForDay(_selectedDay ?? DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(_selectedDay ?? DateTime.now()),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: kTextColor),
          ),
          const SizedBox(height: 16),
          if (selectedEvents.isEmpty)
            Expanded(child: _buildEmptyState())
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: selectedEvents.length,
                itemBuilder: (context, index) {
                  final event = selectedEvents[index];
                  return _buildAttendanceDetailCard(event);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// A more visually appealing card for displaying attendance details.
  Widget _buildAttendanceDetailCard(Attendance event) {
    // ... (This widget is unchanged)
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(event.status,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: event.color)),
                        if (event.lateBy > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kWarningColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Late by ${event.lateBy} min',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn('Punch In', event.punchIn ?? '--:--',
                            Icons.login_rounded),
                        _buildInfoColumn('Punch Out', event.punchOut ?? '--:--',
                            Icons.logout_rounded),
                        _buildInfoColumn('Work Hours', event.workHours,
                            Icons.hourglass_bottom_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A widget for displaying an icon, title, and value.
  Widget _buildInfoColumn(String title, String value, IconData icon) {
    // ... (This widget is unchanged)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: kSubtleTextColor, size: 26),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(fontSize: 12, color: kSubtleTextColor)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: kTextColor)),
      ],
    );
  }

  /// A widget to show when there's no data for the selected day.
  Widget _buildEmptyState() {
    // ... (This widget is unchanged)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 60, color: Colors.grey[350]),
          const SizedBox(height: 16),
          const Text('No Record Found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kSubtleTextColor)),
          const SizedBox(height: 4),
          Text(
            'There is no attendance record for the selected date.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
