import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:coms_india/features/shift/controllers/shift_controller.dart';
import 'package:coms_india/features/shift/models/shift_model.dart';

class AssignShiftPage extends StatefulWidget {
  final String? preSelectedSite; // New parameter for pre-selected site

  const AssignShiftPage({Key? key, this.preSelectedSite}) : super(key: key);

  @override
  State<AssignShiftPage> createState() => _AssignShiftPageState();
}

class _AssignShiftPageState extends State<AssignShiftPage> {
  late final ShiftController _shiftController;
  String? _selectedSite;
  final TextEditingController _searchController = TextEditingController();
  List<ShiftModel> _filteredShifts = [];
  bool _isInitialLoad = true;

  // Sites will be loaded from API
  List<String> _sites = [];

  // Shift selection state
  final Set<int> _selectedShiftIds = <int>{};
  int? _defaultShiftId;

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
    // Load shifts after build
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
    final query = _searchController.text.toLowerCase();
    final allShifts = _shiftController.availableShiftsForAssign;

    setState(() {
      _filteredShifts = allShifts.where((shift) {
        final matchesSearch = shift.shiftName.toLowerCase().contains(query) ||
            shift.siteDetails.toLowerCase().contains(query);
        return matchesSearch;
      }).toList();
    });
  }

  Future<void> _refreshShifts() async {
    await _shiftController.refreshAssignShiftData();
    // Update sites list from assigned sites API, filter shifts, and mark initial load as complete
    setState(() {
      _sites = _shiftController.assignedSiteNames;
      _isInitialLoad = false;
    });

    // Pre-select site if provided
    if (widget.preSelectedSite != null &&
        _sites.contains(widget.preSelectedSite)) {
      _selectedSite = widget.preSelectedSite;
      _preSelectExistingShifts();
    }

    // Immediately filter shifts after loading
    _filterShifts();
  }

  // Pre-select shifts that are already assigned to the selected site
  void _preSelectExistingShifts() {
    if (_selectedSite == null) return;

    // Get shifts that are already assigned to this site
    final existingShifts = _shiftController.getShiftsForSite(_selectedSite!);

    setState(() {
      // Clear previous selections
      _selectedShiftIds.clear();
      _defaultShiftId = null;

      // Pre-select existing shifts
      for (final shift in existingShifts) {
        _selectedShiftIds.add(shift.id);
      }

      // Set default shift - prioritize existing default, then first active, then first shift
      final defaultShift =
          _shiftController.getDefaultShiftForSite(_selectedSite!);
      if (defaultShift != null && _selectedShiftIds.contains(defaultShift.id)) {
        _defaultShiftId = defaultShift.id;
      } else {
        // Find first active shift
        final activeShift =
            existingShifts.firstWhereOrNull((shift) => shift.isActive);
        if (activeShift != null) {
          _defaultShiftId = activeShift.id;
        } else if (existingShifts.isNotEmpty) {
          // Fallback to first shift
          _defaultShiftId = existingShifts.first.id;
        }
      }
    });

    print(
        '🔄 Pre-selected ${_selectedShiftIds.length} shifts for site: $_selectedSite');
    if (_defaultShiftId != null) {
      print('⭐ Default shift set to ID: $_defaultShiftId');
    }
  }

  void _onSiteChanged(String? newSite) {
    setState(() {
      _selectedSite = newSite;
      _selectedShiftIds.clear();
      _defaultShiftId = null;
    });

    if (newSite != null) {
      _preSelectExistingShifts();
    }
  }

  void _clearAllSelections() {
    setState(() {
      _selectedShiftIds.clear();
      _defaultShiftId = null;
    });
  }

  void _assignShiftToSite() async {
    if (_selectedSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a site first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedShiftIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one shift'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_defaultShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a default shift'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showAssignConfirmation();
    if (!confirmed) return;

    // Call the API
    final success = await _shiftController.assignShiftsToSite(
      _selectedSite!,
      _selectedShiftIds.toList(),
      _defaultShiftId!,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shifts assigned successfully to $_selectedSite'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh shifts data to get updated information
      await _shiftController.fetchShifts();

      // Navigate to shifts page with updated data
      context.goNamed('shifts');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_shiftController.errorMessage.isNotEmpty
              ? _shiftController.errorMessage
              : 'Failed to assign shifts'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showAssignConfirmation() async {
    final selectedShifts = _filteredShifts
        .where((shift) => _selectedShiftIds.contains(shift.id))
        .toList();
    final defaultShift =
        selectedShifts.firstWhere((shift) => shift.id == _defaultShiftId);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Assignment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Assign ${selectedShifts.length} shifts to $_selectedSite?'),
                  const SizedBox(height: 16),
                  const Text('Selected Shifts:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...selectedShifts.map((shift) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Row(
                          children: [
                            Icon(
                              shift.id == _defaultShiftId
                                  ? Icons.star
                                  : Icons.circle,
                              size: 12,
                              color: shift.id == _defaultShiftId
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${shift.shiftName} (${shift.formattedTimeRange})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: shift.id == _defaultShiftId
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'Default: ${defaultShift.shiftName}',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Assign',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.goNamed('shifts');
          },
        ),
        title: const Text(
          'ASSIGN SHIFT',
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
          // Site Selection Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick assign message if coming from add shift page
                if (widget.preSelectedSite != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Select a site below to see existing shifts and assign new ones',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Select Site',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: _isInitialLoad ? Colors.grey[100] : Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSite,
                      hint: Text(
                        _isInitialLoad
                            ? 'Loading sites...'
                            : 'Choose a site...',
                        style: TextStyle(
                          color: _isInitialLoad ? Colors.grey[500] : null,
                        ),
                      ),
                      isExpanded: true,
                      items: _isInitialLoad
                          ? null
                          : _sites.map((String site) {
                              return DropdownMenuItem<String>(
                                value: site,
                                child: Text(site),
                              );
                            }).toList(),
                      onChanged: _isInitialLoad ? null : _onSiteChanged,
                    ),
                  ),
                ),
                if (_selectedSite != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selected: $_selectedSite',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedShiftIds.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 16, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_selectedShiftIds.length} existing shifts pre-selected',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _clearAllSelections,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Divider
          Container(
            height: 8,
            color: Colors.grey[100],
          ),

          // Shifts Section Header with Add Button
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Shifts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.goNamed('addShift');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add New Shift',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              enabled: !_isInitialLoad,
              decoration: InputDecoration(
                hintText: _isInitialLoad ? 'Loading...' : 'Search shifts...',
                prefixIcon: Icon(
                  Icons.search,
                  color: _isInitialLoad ? Colors.grey[400] : null,
                ),
                filled: _isInitialLoad,
                fillColor: _isInitialLoad ? Colors.grey[100] : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _isInitialLoad
                        ? Colors.grey.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _isInitialLoad
                        ? Colors.grey.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Shifts List
          Expanded(
            child: Obx(() {
              // Show loading during initial load or when refreshing
              if (_shiftController.isLoading || _isInitialLoad) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Loading shifts...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (_shiftController.hasError.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading shifts',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _shiftController.errorMessage,
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshShifts,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              // Update filtered shifts when data changes (only after initial load)
              if (!_isInitialLoad &&
                  (_filteredShifts.isEmpty ||
                      _filteredShifts.length !=
                          _shiftController.availableShiftsForAssign.length)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _filterShifts();
                  }
                });
              }

              // Only show "no shifts" if we're not in initial load and actually have no data
              if (!_isInitialLoad &&
                  _filteredShifts.isEmpty &&
                  _shiftController.availableShiftsForAssign.isEmpty) {
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
                        onPressed: () => context.goNamed('addShift'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Shift',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              // Only show search results if we have completed initial load
              if (!_isInitialLoad &&
                  _filteredShifts.isEmpty &&
                  _shiftController.availableShiftsForAssign.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No shifts match your search',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              // Show the actual shifts list only if we have data and completed initial load
              if (!_isInitialLoad && _filteredShifts.isNotEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredShifts.length,
                  itemBuilder: (context, index) {
                    final shift = _filteredShifts[index];
                    return _buildShiftCard(shift);
                  },
                );
              }

              // Fallback to loading state
              return const Center(
                child: CircularProgressIndicator(color: Colors.red),
              );
            }),
          ),
        ],
      ),

      // Bottom Action Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: (_selectedSite != null &&
                  _selectedShiftIds.isNotEmpty &&
                  _defaultShiftId != null)
              ? _assignShiftToSite
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _getBottomButtonText(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _getBottomButtonText() {
    if (_selectedSite == null) {
      return 'SELECT A SITE TO CONTINUE';
    } else if (_selectedShiftIds.isEmpty) {
      return 'SELECT SHIFTS TO ASSIGN';
    } else if (_defaultShiftId == null) {
      return 'SELECT DEFAULT SHIFT';
    } else {
      return 'ASSIGN ${_selectedShiftIds.length} SHIFTS TO $_selectedSite';
    }
  }

  Widget _buildShiftCard(ShiftModel shift) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Checkbox for selection
            Checkbox(
              value: _selectedShiftIds.contains(shift.id),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedShiftIds.add(shift.id);
                  } else {
                    _selectedShiftIds.remove(shift.id);
                    // Clear default if this was the default shift
                    if (_defaultShiftId == shift.id) {
                      _defaultShiftId = null;
                    }
                  }
                });
              },
              activeColor: Colors.red,
            ),

            // Shift Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.shiftName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        shift.formattedTimeRange,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
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

            // Status Badge and Default Selection
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        shift.isActive ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
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
                if (_selectedShiftIds.contains(shift.id)) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _defaultShiftId =
                            _defaultShiftId == shift.id ? null : shift.id;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: _defaultShiftId == shift.id
                            ? Colors.orange[100]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _defaultShiftId == shift.id
                              ? Colors.orange
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _defaultShiftId == shift.id
                                ? Icons.star
                                : Icons.star_border,
                            size: 12,
                            color: _defaultShiftId == shift.id
                                ? Colors.orange[800]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 9,
                              color: _defaultShiftId == shift.id
                                  ? Colors.orange[800]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
