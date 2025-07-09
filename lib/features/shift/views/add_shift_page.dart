import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:coms_india/features/shift/controllers/shift_controller.dart';
import 'package:coms_india/features/shift/models/shift_model.dart';

class AddShiftPage extends StatefulWidget {
  final String? shiftId;

  const AddShiftPage({Key? key, this.shiftId}) : super(key: key);

  @override
  State<AddShiftPage> createState() => _AddShiftPageState();
}

class _AddShiftPageState extends State<AddShiftPage> {
  late final ShiftController _shiftController;
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _shiftNameController = TextEditingController();

  // Form State
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isActive = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Get or create the shift controller instance
    try {
      _shiftController = Get.find<ShiftController>();
    } catch (e) {
      _shiftController = Get.put(ShiftController());
    }

    _isEditMode = widget.shiftId != null;
    if (_isEditMode) {
      _loadShiftData();
    }
  }

  void _loadShiftData() {
    final shiftId = int.tryParse(widget.shiftId ?? '');
    if (shiftId != null) {
      final shift =
          _shiftController.shifts.firstWhereOrNull((s) => s.id == shiftId);
      if (shift != null) {
        _shiftNameController.text = shift.shiftName;
        _startTime = _parseTimeString(shift.startTime);
        _endTime = _parseTimeString(shift.endTime);
        _isActive = shift.isActive;
      }
    }
  }

  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 17, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveShift() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select end time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final shiftData = ShiftCreateModel(
      shiftName: _shiftNameController.text.trim(),
      startTime: _formatTimeOfDay(_startTime!),
      endTime: _formatTimeOfDay(_endTime!),
      workingDays: [],
      isActive: _isActive,
    );

    bool success;
    if (_isEditMode) {
      final shiftId = int.parse(widget.shiftId!);
      success = await _shiftController.updateShift(shiftId, shiftData);
    } else {
      success = await _shiftController.createShift(shiftData);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Shift ${_isEditMode ? 'updated' : 'created'} successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to assign shift page for new shifts, back to shifts page for edits
      if (_isEditMode) {
        context.goNamed('shifts');
      } else {
        context.goNamed('assignShift');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_shiftController.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _shiftNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEditMode ? 'EDIT SHIFT' : 'ADD SHIFT',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Obx(() => _shiftController.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveShift,
                  child: Text(
                    _isEditMode ? 'UPDATE' : 'SAVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shift Name
              _buildCard(
                title: 'Shift Information',
                children: [
                  TextFormField(
                    controller: _shiftNameController,
                    decoration: const InputDecoration(
                      labelText: 'Shift Name *',
                      hintText: 'e.g., Morning Shift',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Shift name is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time Selection
              _buildCard(
                title: 'Shift Timing',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeSelector(
                          'Start Time',
                          _startTime,
                          () => _selectTime(context, true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeSelector(
                          'End Time',
                          _endTime,
                          () => _selectTime(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_startTime != null && _endTime != null)
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
                              size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Duration: ${_calculateDuration().toStringAsFixed(1)} hours',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  // Cancel/Back Button
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          context.goNamed('shifts');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Save Button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: Obx(() => ElevatedButton(
                            onPressed:
                                _shiftController.isLoading ? null : _saveShift,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _shiftController.isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Saving...'),
                                    ],
                                  )
                                : Text(
                                    _isEditMode
                                        ? 'UPDATE SHIFT'
                                        : 'CREATE SHIFT',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  time != null ? time.format(context) : 'Select time',
                  style: TextStyle(
                    fontSize: 16,
                    color: time != null ? Colors.black87 : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDuration() {
    if (_startTime == null || _endTime == null) return 0.0;

    final start = _startTime!.hour + (_startTime!.minute / 60);
    final end = _endTime!.hour + (_endTime!.minute / 60);

    if (end > start) {
      return end - start;
    } else {
      // Handle overnight shifts
      return (24 - start) + end;
    }
  }
}
