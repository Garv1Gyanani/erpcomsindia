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

  // MODIFIED: Separate selection sets for clarity and correctness
  final Set<int> _selectedForPunchIn = <int>{};
  final Set<int> _selectedForPunchOut = <int>{};

  bool _selectAllPunchIn = false;
  bool _selectAllPunchOut = false;

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

  // Helper to reset selection when shift changes
  void _resetSelection() {
    setState(() {
      _selectedForPunchIn.clear();
      _selectedForPunchOut.clear();
      _selectAllPunchIn = false;
      _selectAllPunchOut = false;
    });
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
                    : _buildEmployeeLists(controller),
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
                _resetSelection();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPunchInOutControls(AttendanceController controller) {
    // MODIFIED: Logic now depends on the specific selection sets
    final canPunchIn = _selectedForPunchIn.isNotEmpty;
    final canPunchOut = _selectedForPunchOut.isNotEmpty;
    final totalSelected =
        _selectedForPunchIn.length + _selectedForPunchOut.length;

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
                '$totalSelected employee(s) selected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      canPunchIn ? () => _handlePunchIn(controller) : null,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Punch In',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    disabledBackgroundColor: Colors.green.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      canPunchOut ? () => _handlePunchOut(controller) : null,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Punch Out',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    disabledBackgroundColor: Colors.orange.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NEW: A parent widget to hold the separated employee lists.
  Widget _buildEmployeeLists(AttendanceController controller) {
    final onDutyEmployees = controller.getOnDutyEmployees();
    final availableEmployees = controller.getAvailableForPunchInEmployees();
    final weekendEmployees = controller.employees
        .where((e) => controller.isEmployeeOnWeekend(e.userId))
        .toList();

    if (controller.employees.isEmpty) {
      return const Center(
        child: Text(
          'No employees found for this shift',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- ON DUTY LIST (FOR PUNCH OUT) ---
        if (onDutyEmployees.isNotEmpty)
          _buildListSection(
            title: "On Duty (${onDutyEmployees.length})",
            icon: Icons.check_circle,
            iconColor: Colors.green,
            employees: onDutyEmployees,
            controller: controller,
            isForPunchIn: false,
          ),

        // --- AVAILABLE LIST (FOR PUNCH IN) ---
        if (availableEmployees.isNotEmpty)
          _buildListSection(
            title: "Available for Punch In (${availableEmployees.length})",
            icon: Icons.person_add_alt_1,
            iconColor: Colors.red,
            employees: availableEmployees,
            controller: controller,
            isForPunchIn: true,
          ),

        // --- WEEKEND/LEAVE LIST (NON-SELECTABLE) ---
        if (weekendEmployees.isNotEmpty)
          _buildListSection(
              title: "On Weekend/Leave (${weekendEmployees.length})",
              icon: Icons.bedtime,
              iconColor: Colors.blueGrey,
              employees: weekendEmployees,
              controller: controller,
              isSelectable: false),
      ],
    );
  }

  // NEW: A reusable widget for each list section (On Duty, Available, etc.)
  Widget _buildListSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<AttendanceEmployeeData> employees,
    required AttendanceController controller,
    bool isSelectable = true,
    bool isForPunchIn = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ],
              ),
              if (isSelectable)
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (isForPunchIn) {
                        _selectAllPunchIn = !_selectAllPunchIn;
                        if (_selectAllPunchIn) {
                          _selectedForPunchIn
                              .addAll(employees.map((e) => e.userId));
                        } else {
                          _selectedForPunchIn.clear();
                        }
                      } else {
                        _selectAllPunchOut = !_selectAllPunchOut;
                        if (_selectAllPunchOut) {
                          _selectedForPunchOut
                              .addAll(employees.map((e) => e.userId));
                        } else {
                          _selectedForPunchOut.clear();
                        }
                      }
                    });
                  },
                  child: Text(isForPunchIn
                      ? (_selectAllPunchIn ? 'Deselect All' : 'Select All')
                      : (_selectAllPunchOut ? 'Deselect All' : 'Select All')),
                )
            ],
          ),
        ),
        ...employees.map((employee) {
          if (!isSelectable) {
            return _buildWeekendEmployeeTile(employee,
                controller.getEmployeeAttendanceStatus(employee.userId));
          }
          return _buildSelectableEmployeeTile(
            employee: employee,
            controller: controller,
            isForPunchIn: isForPunchIn,
          );
        }).toList(),
      ],
    );
  }

  // MODIFIED: A generic tile for selectable employees.
  Widget _buildSelectableEmployeeTile({
    required AttendanceEmployeeData employee,
    required AttendanceController controller,
    required bool isForPunchIn,
  }) {
    final isSelected = isForPunchIn
        ? _selectedForPunchIn.contains(employee.userId)
        : _selectedForPunchOut.contains(employee.userId);

    final attendanceStatus =
        controller.getEmployeeAttendanceStatus(employee.userId);
    final color = isForPunchIn ? Colors.red : Colors.green;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            final selectionSet =
                isForPunchIn ? _selectedForPunchIn : _selectedForPunchOut;
            if (value == true) {
              selectionSet.add(employee.userId);
            } else {
              selectionSet.remove(employee.userId);
            }
          });
        },
        title: Text(employee.user.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.user.email),
            Text(employee.user.phone),
            if (attendanceStatus != null &&
                attendanceStatus.punchIn != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      attendanceStatus.formattedStatus,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ],
        ),
        secondary: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            employee.user.name.isNotEmpty
                ? employee.user.name[0].toUpperCase()
                : '?',
            style: TextStyle(color: color[700], fontWeight: FontWeight.bold),
          ),
        ),
        activeColor: color,
      ),
    );
  }

  Widget _buildWeekendEmployeeTile(
      AttendanceEmployeeData employee, AttendanceStatus? status) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[200],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey.withOpacity(0.1),
          child: Text(
            employee.user.name.isNotEmpty
                ? employee.user.name[0].toUpperCase()
                : '?',
            style: TextStyle(
                color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(employee.user.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black54)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.user.email,
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
      ),
    );
  }

  // ... (Rest of your widgets: _buildAttendanceViewList, _buildAttendanceEmployeeTile, _buildErrorWidget remain the same)
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

  // MODIFIED: Punch In handler uses the correct selection set
  void _handlePunchIn(AttendanceController controller) async {
    if (controller.selectedShiftId == null ||
        controller.selectedSiteId == null) {
      _showMessage('Please select a shift first.');
      return;
    }

    final success = await controller.punchInEmployees(
      _selectedForPunchIn.toList(),
      controller.selectedSiteId!,
      controller.selectedShiftId!,
    );

    if (success) {
      _showMessage('Employees punched in successfully!');
      _resetSelection();
      // No need for extra refresh, as controller state is updated internally
    } else if (controller.errorMessage != null) {
      _showMessage(controller.errorMessage!);
    }
  }

  // MODIFIED: Punch Out handler uses the correct selection set
  void _handlePunchOut(AttendanceController controller) async {
    final TextEditingController remarksController = TextEditingController();

    final shouldPunchOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Punch Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Punch out ${_selectedForPunchOut.length} employee(s)?'),
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
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Punch Out')),
        ],
      ),
    );

    if (shouldPunchOut == true) {
      final success = await controller.punchOutEmployees(
        _selectedForPunchOut.toList(),
        remarksController.text,
      );

      if (success) {
        _showMessage('Employees punched out successfully!');
        _resetSelection();
        // No need for extra refresh
      } else if (controller.errorMessage != null) {
        _showMessage(controller.errorMessage!);
      }
    }
  }

  // ... (Rest of your methods: _loadAttendanceView, _showMessage, _navigateToEmployeeDetails remain the same)
  void _loadAttendanceView(AttendanceController controller) {
    if (controller.selectedShiftId != null &&
        controller.selectedSiteId != null &&
        controller.employees.isNotEmpty) {
      final userIds = controller.getAllUserIds();
      controller.fetchAttendanceView(
        userIds,
        controller.selectedSiteId!, // Use dynamic siteId
        controller.selectedShiftId!,
      );
    } else {
      _showMessage(
          "Cannot load attendance. Select a shift with employees first.");
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToEmployeeDetails(AttendanceEmployee employee) async {
    if (!mounted) return;
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
