import 'package:coms_india/features/auth/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/attendance_model.dart';

class EmployeeAttendanceDetailsPage extends StatelessWidget {
  final List<AttendanceDetail> attendanceRecords;
  final UserModel user;

  const EmployeeAttendanceDetailsPage({
    super.key,
    required this.attendanceRecords,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    String formatMinutesToHoursa(int totalMinutes) {
      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;

      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    }

    String formatHoursFromString(String? timeStr) {
      if (timeStr == null) return 'N/A';

      double? decimalHours = double.tryParse(timeStr);
      if (decimalHours == null) return 'N/A';

      int hours = decimalHours.floor();
      int minutes = ((decimalHours - hours) * 60).round();

      if (hours == 0 && minutes == 0) return 'N/A';

      String hourStr = '$hours hour${hours != 1 ? 's' : ''}';
      String minuteStr = '$minutes minute${minutes != 1 ? 's' : ''}';

      return '$hourStr $minuteStr';
    }

    String formatMinutesToHM(String? minutesStr) {
      if (minutesStr == null) return 'N/A';

      int? totalMinutes = int.tryParse(minutesStr);
      if (totalMinutes == null || totalMinutes == 0) return 'N/A';

      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;

      String hourStr = hours > 0 ? '$hours hour${hours != 1 ? 's' : ''}' : '';
      String minuteStr =
          minutes > 0 ? '$minutes minute${minutes != 1 ? 's' : ''}' : '';

      // Combine non-empty parts with a space
      return [hourStr, minuteStr].where((part) => part.isNotEmpty).join(' ');
    }

    String formatWorkHours(String? totalWorkHours) {
      if (totalWorkHours == null) return 'N/A';

      final double? hoursDecimal = double.tryParse(totalWorkHours);
      if (hoursDecimal == null) return 'N/A';

      final int hours = hoursDecimal.floor();
      final int minutes = ((hoursDecimal - hours) * 60).round();

      if (hours > 0 && minutes > 0) {
        return '${hours}h ${minutes}m';
      } else if (hours > 0) {
        return '${hours}h';
      } else {
        return '${minutes}m';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.goNamed('attendance'),
        ),
      ),
      body: attendanceRecords.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No attendance records found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'This employee has no attendance records in the system yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                final record = attendanceRecords[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Date: ${record.formattedPunchInDate}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(record.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                record.status ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.login,
                          label: 'Punch In',
                          value: record.formattedPunchInTime,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.logout,
                          label: 'Punch Out',
                          value: record.formattedPunchOutTime,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.hourglass_bottom,
                          label: 'Total Hours',
                          value: formatWorkHours(record.totalWorkHours),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.timer,
                          label: 'Overtime',
                          value: formatHoursFromString(record.overtimeHours),
                        ),
                        if (record.lateByMinutes != null &&
                            record.lateByMinutes! > 0) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.warning,
                            label: 'Late By',
                            value: formatMinutesToHoursa(record.lateByMinutes!),
                            color: Colors.red,
                          ),
                        ],
                        if (record.remarks != null &&
                            record.remarks!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.comment,
                            label: 'Remarks',
                            value: record.remarks!,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'on_duty':
        return Colors.green;
      case 'off_duty':
        return Colors.grey;
      case 'present':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }
}
