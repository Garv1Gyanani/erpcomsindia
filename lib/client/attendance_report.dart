import 'dart:convert';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Future<AttendanceReport>? _futureAttendanceReport;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _futureAttendanceReport = _fetchAttendanceReport(_selectedDate);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _futureAttendanceReport = _fetchAttendanceReport(_selectedDate);
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF2196F3),
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _futureAttendanceReport = _fetchAttendanceReport(_selectedDate);
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Attendance Report',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today, size: 20),
              ),
              onPressed: () => _selectDate(context),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.refresh, size: 20),
              ),
              onPressed: _refreshData,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder<AttendanceReport>(
          future: _futureAttendanceReport,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            } else if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            } else if (!snapshot.hasData) {
              return _buildEmptyState();
            } else {
              return _buildSuccessState(snapshot.data!);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading attendance data...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No attendance data found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try selecting a different date',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(AttendanceReport report) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF2196F3),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildDateHeader(),
            _buildSummaryCards(report),
            _buildShiftDetails(report),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Selected Date',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(_selectedDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AttendanceReport report) {
    final totalEmployees = report.employeeCounts.isNotEmpty
        ? report.employeeCounts.first.employeeCount
        : 0;
    final totalPresent = report.attendanceCounts
        .fold(0, (sum, count) => sum + count.presentCount);
    final totalAbsent = report.site.manpower - totalPresent;
    final attendancePercentage = report.site.manpower > 0
        ? (totalPresent / report.site.manpower * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        report.site.siteName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Staff',
                        report.site.manpower.toString(),
                        Icons.people,
                        const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Present',
                        totalPresent.toString(),
                        Icons.check_circle,
                        const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Absent',
                        totalAbsent.toString(),
                        Icons.cancel,
                        const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Attendance',
                        '${attendancePercentage.toStringAsFixed(1)}%',
                        Icons.analytics,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftDetails(AttendanceReport report) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Shift-wise Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          if (report.attendanceCounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No shift data available',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.attendanceCounts.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final attendanceCount = report.attendanceCounts[index];
                final shift = report.site.siteShiftAssigns.firstWhere(
                  (element) => element.shiftId == attendanceCount.shiftId,
                  orElse: () => SiteShiftAssign(
                    id: -1,
                    siteId: -1,
                    shiftId: -1,
                    shift: Shift(id: -1, name: "Unknown"),
                  ),
                );
                final manpower = report.site.manpower;
                final present = attendanceCount.presentCount;
                final short = manpower - present;
                final attendanceRate =
                    manpower > 0 ? (present / manpower * 100) : 0.0;

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shift.shift.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${attendanceRate.toStringAsFixed(1)}% attendance',
                              style: TextStyle(
                                fontSize: 12,
                                color: attendanceRate >= 80
                                    ? const Color(0xFF10B981)
                                    : attendanceRate >= 60
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildShiftMetric('Staff', manpower.toString(),
                          const Color(0xFF8B5CF6)),
                      const SizedBox(width: 16),
                      _buildShiftMetric('Present', present.toString(),
                          const Color(0xFF10B981)),
                      const SizedBox(width: 16),
                      _buildShiftMetric(
                          'Short', short.toString(), const Color(0xFFEF4444)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildShiftMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<AttendanceReport> _fetchAttendanceReport(DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final url = Uri.parse(
        'https://erp.comsindia.in/api/client/attendance/report/$formattedDate');
    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token'];
    final token = authToken;

    if (token == null) {
      throw Exception('No token found. Please login.');
    }

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == true) {
        return AttendanceReport.fromJson(jsonData);
      } else {
        throw Exception(jsonData['message']);
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
      throw Exception(
          'Failed to load attendance data. Status code: ${response.statusCode}');
    }
  }
}

// Model classes (same as before)
class AttendanceReport {
  final bool status;
  final String message;
  final String date;
  final Site site;
  final List<EmployeeCount> employeeCounts;
  final List<AttendanceCount> attendanceCounts;

  AttendanceReport({
    required this.status,
    required this.message,
    required this.date,
    required this.site,
    required this.employeeCounts,
    required this.attendanceCounts,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      status: json['status'],
      message: json['message'],
      date: json['date'],
      site: Site.fromJson(json['site']),
      employeeCounts: (json['employee_counts'] as List)
          .map((e) => EmployeeCount.fromJson(e))
          .toList(),
      attendanceCounts: (json['attendance_counts'] as List)
          .map((e) => AttendanceCount.fromJson(e))
          .toList(),
    );
  }
}

class Site {
  final int id;
  final String siteName;
  final int manpower;
  final List<SiteShiftAssign> siteShiftAssigns;

  Site({
    required this.id,
    required this.siteName,
    required this.manpower,
    required this.siteShiftAssigns,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      siteName: json['site_name'],
      manpower: json['manpower'],
      siteShiftAssigns: (json['site_shift_assigns'] as List)
          .map((e) => SiteShiftAssign.fromJson(e))
          .toList(),
    );
  }
}

class SiteShiftAssign {
  final int id;
  final int siteId;
  final int shiftId;
  final Shift shift;

  SiteShiftAssign({
    required this.id,
    required this.siteId,
    required this.shiftId,
    required this.shift,
  });

  factory SiteShiftAssign.fromJson(Map<String, dynamic> json) {
    return SiteShiftAssign(
      id: json['id'],
      siteId: json['site_id'],
      shiftId: json['shift_id'],
      shift: Shift.fromJson(json['shift']),
    );
  }
}

class Shift {
  final int id;
  final String name;

  Shift({
    required this.id,
    required this.name,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'],
      name: json['name'],
    );
  }
}

class EmployeeCount {
  final int siteId;
  final int employeeCount;

  EmployeeCount({
    required this.siteId,
    required this.employeeCount,
  });

  factory EmployeeCount.fromJson(Map<String, dynamic> json) {
    return EmployeeCount(
      siteId: json['site_id'],
      employeeCount: json['employee_count'],
    );
  }
}

class AttendanceCount {
  final int siteId;
  final int shiftId;
  final int presentCount;

  AttendanceCount({
    required this.siteId,
    required this.shiftId,
    required this.presentCount,
  });

  factory AttendanceCount.fromJson(Map<String, dynamic> json) {
    return AttendanceCount(
      siteId: json['site_id'],
      shiftId: json['shift_id'],
      presentCount: json['present_count'],
    );
  }
}
