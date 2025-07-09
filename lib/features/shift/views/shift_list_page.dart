import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:coms_india/features/shift/controllers/shift_controller.dart';
import 'package:coms_india/features/shift/models/shift_model.dart';

class ShiftListPage extends StatefulWidget {
  const ShiftListPage({Key? key}) : super(key: key);

  @override
  State<ShiftListPage> createState() => _ShiftListPageState();
}

class _ShiftListPageState extends State<ShiftListPage> {
  late final ShiftController _shiftController;
  final TextEditingController _searchController = TextEditingController();

  // Static sites with shifts data (as requested)
  final Map<String, List<ShiftModel>> _siteShifts = {};

  // Static list of sites
  final List<String> _sites = [
    'Site A - Main Office',
    'Site B - Warehouse',
    'Site C - Manufacturing Unit',
    'Site D - Research Center',
    'Site E - Distribution Hub',
    'Site F - Customer Service Center',
  ];

  // Mock data for demonstration
  final List<ShiftModel> _mockShifts = [
    // Site A - Main Office (3 shifts)
    ShiftModel(
      id: 1,
      shiftName: 'Morning Office Shift',
      startTime: '09:00',
      endTime: '17:00',
      siteDetails: 'Main Office Building, Floor 1-3',
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: true,
    ),
    ShiftModel(
      id: 2,
      shiftName: 'Evening Support Shift',
      startTime: '17:00',
      endTime: '01:00',
      siteDetails: 'Main Office Building, Floor 1',
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: true,
    ),
    ShiftModel(
      id: 3,
      shiftName: 'Weekend Maintenance',
      startTime: '08:00',
      endTime: '16:00',
      siteDetails: 'Main Office Building, All Floors',
      workingDays: ['Saturday', 'Sunday'],
      isActive: true,
    ),

    // Site B - Warehouse (4 shifts)
    ShiftModel(
      id: 4,
      shiftName: 'Day Warehouse Shift',
      startTime: '08:00',
      endTime: '16:00',
      siteDetails: 'Warehouse Section A-D',
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: true,
    ),
    ShiftModel(
      id: 5,
      shiftName: 'Evening Warehouse Shift',
      startTime: '16:00',
      endTime: '00:00',
      siteDetails: 'Warehouse Section A-B',
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: true,
    ),
    ShiftModel(
      id: 6,
      shiftName: 'Night Security Shift',
      startTime: '00:00',
      endTime: '08:00',
      siteDetails: 'Warehouse Security & Monitoring',
      workingDays: [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ],
      isActive: true,
    ),
    ShiftModel(
      id: 7,
      shiftName: 'Weekend Loading Shift',
      startTime: '10:00',
      endTime: '18:00',
      siteDetails: 'Warehouse Loading Dock',
      workingDays: ['Saturday', 'Sunday'],
      isActive: false,
    ),

    // Site C - Manufacturing Unit (3 shifts)
    ShiftModel(
      id: 8,
      shiftName: 'Production Shift A',
      startTime: '06:00',
      endTime: '14:00',
      siteDetails: 'Manufacturing Floor 1-2',
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: true,
    ),
    ShiftModel(
      id: 9,
      shiftName: 'Production Shift B',
      startTime: '14:00',
      endTime: '22:00',
      siteDetails: 'Manufacturing Floor 1-2',
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: true,
    ),
    ShiftModel(
      id: 10,
      shiftName: 'Night Maintenance',
      startTime: '22:00',
      endTime: '06:00',
      siteDetails: 'Manufacturing Maintenance',
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: true,
    ),

    // Site D - Research Center (2 shifts)
    ShiftModel(
      id: 11,
      shiftName: 'Research Day Shift',
      startTime: '09:00',
      endTime: '18:00',
      siteDetails: 'Research Labs 1-5',
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: true,
    ),
    ShiftModel(
      id: 12,
      shiftName: 'Lab Security Shift',
      startTime: '18:00',
      endTime: '06:00',
      siteDetails: 'Research Center Security',
      workingDays: [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ],
      isActive: true,
    ),

    // Site E - Distribution Hub (2 shifts)
    ShiftModel(
      id: 13,
      shiftName: 'Distribution Day Shift',
      startTime: '07:00',
      endTime: '15:00',
      siteDetails: 'Distribution Center',
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: true,
    ),
    ShiftModel(
      id: 14,
      shiftName: 'Evening Dispatch',
      startTime: '15:00',
      endTime: '23:00',
      siteDetails: 'Distribution Dispatch Center',
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      isActive: false,
    ),

    // Site F - Customer Service (1 shift)
    ShiftModel(
      id: 15,
      shiftName: 'Customer Support Shift',
      startTime: '08:00',
      endTime: '20:00',
      siteDetails: 'Customer Service Center',
      workingDays: [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ],
      isActive: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Get or create the shift controller instance
    try {
      _shiftController = Get.find<ShiftController>();
    } catch (e) {
      _shiftController = Get.put(ShiftController());
    }

    _searchController.addListener(_filterShifts);
    // Fetch shifts after build to avoid setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshShifts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshShifts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterShifts() {
    // Force refresh of the grouped sites
    _groupShiftsBySite();
  }

  void _groupShiftsBySite() {
    final query = _searchController.text.toLowerCase();

    // Clear previous data
    _siteShifts.clear();

    // Use API data from site shifts
    for (final siteShift in _shiftController.siteShifts) {
      final siteName = siteShift.siteName;
      _siteShifts[siteName] = [];

      for (final shift in siteShift.shifts) {
        // Apply search filter
        if (query.isEmpty ||
            shift.shiftName.toLowerCase().contains(query) ||
            siteName.toLowerCase().contains(query) ||
            shift.siteDetails.toLowerCase().contains(query)) {
          _siteShifts[siteName]!.add(shift);
        }
      }
    }

    setState(() {});
  }

  Future<void> _refreshShifts() async {
    await _shiftController.refreshShifts();
    // Force update filtered shifts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _groupShiftsBySite();
      }
    });
  }

  void _showDeleteConfirmation(ShiftModel shift) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Shift'),
          content:
              Text('Are you sure you want to delete "${shift.shiftName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await _shiftController.deleteShift(shift.id);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shift deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _groupShiftsBySite();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_shiftController.errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'SHIFT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshShifts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section with Assign Shift Button
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Assign Shift Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.pushNamed('assignShift');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_ind, size: 20),
                    label: const Text(
                      'ASSIGN SHIFT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search sites or shifts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Sites and Shifts List
          Expanded(
            child: Builder(builder: (context) {
              // Update grouped shifts when data changes
              if (_siteShifts.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _groupShiftsBySite();
                });
              }

              if (_shiftController.shifts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No shifts available',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first shift to get started',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.pushNamed('assignShift'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        icon: const Icon(Icons.assignment_ind,
                            color: Colors.white),
                        label: const Text('Assign Shifts',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshShifts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _siteShifts.keys.length,
                  itemBuilder: (context, index) {
                    final siteName = _siteShifts.keys.elementAt(index);
                    final siteShifts = _siteShifts[siteName] ?? [];
                    return _buildSiteCard(siteName, siteShifts);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteCard(String siteName, List<ShiftModel> shifts) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Site Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    siteName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        shifts.isEmpty ? Colors.grey[300] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${shifts.length} Shifts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          shifts.isEmpty ? Colors.grey[600] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Shifts List
          if (shifts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.schedule_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No shifts assigned to this site',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => context.pushNamed('assignShift'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Assign Shifts'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: shifts.map((shift) => _buildShiftRow(shift)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShiftRow(ShiftModel shift) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Shift Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      shift.shiftName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (shift.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                size: 12, color: Colors.orange[800]),
                            const SizedBox(width: 2),
                            Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      shift.formattedTimeRange,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: shift.duration >= 8
                            ? Colors.orange[100]
                            : Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${shift.duration.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 10,
                          color: shift.duration >= 8
                              ? Colors.orange[800]
                              : Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status and Actions
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: shift.isActive ? Colors.green[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  shift.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        shift.isActive ? Colors.green[800] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom FAB for adding shifts
class _AddShiftFab extends StatelessWidget {
  const _AddShiftFab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        context.pushNamed('addShift');
      },
      backgroundColor: Colors.red,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
