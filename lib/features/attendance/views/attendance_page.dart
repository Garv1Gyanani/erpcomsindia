import 'package:coms_india/features/attendance/controllers/attendance_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/attendance_model.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Set<int> selectedEmployees = <int>{};
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceController>().fetchShifts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Attendance Management',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.goNamed('team'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<AttendanceController>().refreshData();
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Punch In/Out'),
            Tab(text: 'Attendance View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPunchInOutTab(),
          _buildAttendanceViewTab(),
        ],
      ),
    );
  }

  Widget _buildPunchInOutTab() {
    return Consumer<AttendanceController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.shifts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage != null && controller.shifts.isEmpty) {
          return _buildErrorWidget(controller);
        }

        return Column(
          children: [
            _buildShiftSelector(controller),
            if (controller.selectedShiftId != null) ...[
              _buildPunchInOutControls(controller),
              Expanded(
                child: controller.isLoading && controller.employees.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _buildEmployeeSelectionList(controller),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAttendanceViewTab() {
    return Consumer<AttendanceController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage != null) {
          return _buildErrorWidget(controller);
        }

        if (controller.attendanceView.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No attendance data available',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.selectedShiftId != null
                      ? () => _loadAttendanceView(controller)
                      : null,
                  child: const Text('Load Attendance'),
                ),
              ],
            ),
          );
        }

        return _buildAttendanceViewList(controller);
      },
    );
  }

  Widget _buildShiftSelector(AttendanceController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text(
                'Select Shift',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: controller.selectedShiftId,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Choose a shift'),
            items: controller.shifts.map((shift) {
              return DropdownMenuItem<int>(
                value: shift.id,
                child: Text('${shift.name} (${shift.formattedTimeRange()})'),
              );
            }).toList(),
            onChanged: (int? shiftId) {
              if (shiftId != null) {
                controller.setSelectedShift(shiftId);
                controller.fetchEmployeesByShift(shiftId);
                selectedEmployees.clear();
                selectAll = false;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPunchInOutControls(AttendanceController controller) {
    final hasSelectedEmployees = selectedEmployees.isNotEmpty;
    final availableEmployees = controller.getAvailableForPunchInEmployees();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '${selectedEmployees.length} employee(s) selected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: availableEmployees.isNotEmpty
                    ? () {
                        setState(() {
                          if (selectAll) {
                            selectedEmployees.clear();
                            selectAll = false;
                          } else {
                            selectedEmployees.addAll(
                                availableEmployees.map((e) => e.userId));
                            selectAll = true;
                          }
                        });
                      }
                    : null,
                child: Text(selectAll ? 'Deselect All' : 'Select All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasSelectedEmployees
                      ? () => _handlePunchIn(controller)
                      : null,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Punch In',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasSelectedEmployees
                      ? () => _handlePunchOut(controller)
                      : null,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Punch Out',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSelectionList(AttendanceController controller) {
    if (controller.employees.isEmpty) {
      return const Center(
        child: Text(
          'No employees found for this shift',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.employees.length,
      itemBuilder: (context, index) {
        final employee = controller.employees[index];
        final isSelected = selectedEmployees.contains(employee.userId);
        final attendanceStatus =
            controller.getEmployeeAttendanceStatus(employee.userId);
        final isOnDuty = controller.isEmployeeOnDuty(employee.userId);
        final isWeekend = controller.isEmployeeOnWeekend(employee.userId);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Builder(builder: (context) {
            if (isWeekend) {
              return _buildWeekendEmployeeTile(employee, attendanceStatus);
            } else if (isOnDuty) {
              return _buildOnDutyEmployeeTile(
                  employee, attendanceStatus, controller);
            } else {
              return _buildAvailableEmployeeTile(
                  employee, isSelected, attendanceStatus, controller);
            }
          }),
        );
      },
    );
  }

  Widget _buildWeekendEmployeeTile(
      AttendanceEmployeeData employee, AttendanceStatus? status) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blueGrey.withOpacity(0.1),
        child: Text(
          employee.user.name.isNotEmpty
              ? employee.user.name[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.blueGrey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        employee.user.name,
        style:
            const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(employee.user.email,
              style: const TextStyle(color: Colors.black54)),
          Text(employee.user.phone,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status?.formattedStatus ?? 'Weekend',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnDutyEmployeeTile(AttendanceEmployeeData employee,
      AttendanceStatus? status, AttendanceController controller) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: Text(
          employee.user.name.isNotEmpty
              ? employee.user.name[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        employee.user.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(employee.user.email),
          Text(employee.user.phone),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status?.formattedStatus ?? 'On Duty',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              if (status?.punchIn != null) ...[
                const SizedBox(width: 8),
                Text(
                  'In: ${status!.punchInTime}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: ElevatedButton.icon(
        onPressed: () => _handleIndividualPunchOut(employee, controller),
        icon: const Icon(Icons.logout, size: 16),
        label: const Text('Punch Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(80, 36),
        ),
      ),
    );
  }

  Widget _buildAvailableEmployeeTile(AttendanceEmployeeData employee,
      bool isSelected, AttendanceStatus? attendanceStatus, controller) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            selectedEmployees.add(employee.userId);
          } else {
            selectedEmployees.remove(employee.userId);
          }
          final availableCount =
              controller.getAvailableForPunchInEmployees().length;
          selectAll =
              availableCount > 0 && selectedEmployees.length == availableCount;
        });
      },
      title: Text(
        employee.user.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(employee.user.email),
          Text(employee.user.phone),
          if (attendanceStatus != null && !attendanceStatus.isWeekend) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                attendanceStatus.formattedStatus,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
      secondary: CircleAvatar(
        backgroundColor: Colors.red.withOpacity(0.1),
        child: Text(
          employee.user.name.isNotEmpty
              ? employee.user.name[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      activeColor: Colors.red,
    );
  }

  Widget _buildAttendanceViewList(AttendanceController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.attendanceView.length,
      itemBuilder: (context, index) {
        final siteName = controller.attendanceView.keys.elementAt(index);
        final employees = controller.attendanceView[siteName]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              siteName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: Icon(Icons.business, color: Colors.red[700]),
            children: employees
                .map((employee) => _buildAttendanceEmployeeTile(employee))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceEmployeeTile(AttendanceEmployee employee) {
    final hasAttendance = employee.attendance != null;
    final latestAttendance = hasAttendance ? employee.attendance : null;

    return ListTile(
      onTap: () => _navigateToEmployeeDetails(employee),
      leading: CircleAvatar(
        backgroundColor: employee.statusColor.withOpacity(0.1),
        child: Text(
          employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: employee.statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(employee.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${employee.empId} • ${employee.designation}'),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: employee.statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  employee.currentStatus,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              if (latestAttendance != null) ...[
                const SizedBox(width: 8),
                Text(
                  'In: ${latestAttendance.punchInTime}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (latestAttendance.punchOut != null) ...[
                  const Text(' • ', style: TextStyle(fontSize: 12)),
                  Text(
                    'Out: ${latestAttendance.punchOutTime}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ],
          ),
          if (latestAttendance != null && latestAttendance.lateBy > 0) ...[
            const SizedBox(height: 2),
            Text(
              latestAttendance.lateByText,
              style: const TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(AttendanceController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                controller.clearError();
                controller.refreshData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePunchIn(AttendanceController controller) async {
    if (controller.selectedShiftId == null) {
      _showMessage('Please select a shift first');
      return;
    }

    const int siteId = 1;

    final success = await controller.punchInEmployees(
      selectedEmployees.toList(),
      siteId,
      controller.selectedShiftId!,
    );

    if (success) {
      _showMessage('Employees punched in successfully!');
      selectedEmployees.clear();
      selectAll = false;
      setState(() {});
      controller.refreshData(); // Refresh data to update the view
    } else if (controller.errorMessage != null) {
      _showMessage(controller.errorMessage!);
    }
  }

  void _handlePunchOut(AttendanceController controller) async {
    final TextEditingController remarksController = TextEditingController();

    final shouldPunchOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Punch Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Punch out ${selectedEmployees.length} employee(s)?'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Punch Out'),
          ),
        ],
      ),
    );

    if (shouldPunchOut == true) {
      final success = await controller.punchOutEmployees(
        selectedEmployees.toList(),
        remarksController.text,
      );

      if (success) {
        _showMessage('Employees punched out successfully!');
        selectedEmployees.clear();
        selectAll = false;
        setState(() {});
        controller.refreshData();
      } else if (controller.errorMessage != null) {
        _showMessage(controller.errorMessage!);
      }
    }
  }

  void _handleIndividualPunchOut(
      AttendanceEmployeeData employee, AttendanceController controller) async {
    final TextEditingController remarksController = TextEditingController();

    final shouldPunchOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Punch Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Punch out ${employee.user.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Punch Out'),
          ),
        ],
      ),
    );

    if (shouldPunchOut == true) {
      final success = await controller.punchOutEmployees(
        [employee.userId],
        remarksController.text,
      );

      if (success) {
        _showMessage('Employee punched out successfully!');
        selectedEmployees.remove(employee.userId);
        selectAll = false;
        setState(() {});
        controller.refreshData();
      } else if (controller.errorMessage != null) {
        _showMessage(controller.errorMessage!);
      }
    }
  }

  void _loadAttendanceView(AttendanceController controller) {
    if (controller.selectedShiftId != null && controller.employees.isNotEmpty) {
      const int siteId = 1;
      final userIds = controller.getAllUserIds();
      controller.fetchAttendanceView(
          userIds, siteId, controller.selectedShiftId!);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToEmployeeDetails(AttendanceEmployee employee) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final controller = context.read<AttendanceController>();

      try {
        final attendanceDetails =
            await controller.fetchUserAttendanceDetails(employee.id);

        if (mounted) Navigator.of(context).pop();

        final attendanceJson = attendanceDetails
            .map((detail) => {
                  'id': detail.id,
                  'user_id': detail.userId,
                  'site_id': detail.siteId,
                  'shift_id': detail.shiftId,
                  'punch_in': detail.punchIn?.toIso8601String(),
                  'punch_out': detail.punchOut?.toIso8601String(),
                  'is_weekend': detail.isWeekend ? 1 : 0,
                  'total_work_hours': detail.totalWorkHours,
                  'overtime_hours': detail.overtimeHours,
                  'late_by_minutes': detail.lateByMinutes,
                  'left_early_by_minutes': detail.leftEarlyByMinutes,
                  'status': detail.status,
                  'marked_by': detail.markedBy,
                  'remarks': detail.remarks,
                  'user': {
                    'id': detail.user.id,
                    'name': detail.user.name,
                    'email': detail.user.email,
                    'phone': detail.user.phone,
                  },
                })
            .toList();

        if (mounted) {
          context.goNamed(
            'employeeAttendanceDetails',
            pathParameters: {'userId': employee.id.toString()},
            extra: attendanceJson,
          );
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Attendance Records'),
              content: Text(e.toString().replaceAll('Exception: ', '')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        _showMessage('Failed to load attendance details: $e');
      }
    }
  }
}
