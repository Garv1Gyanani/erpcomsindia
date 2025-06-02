import 'package:coms_india/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TaskListPage extends StatefulWidget {
  const TaskListPage({Key? key}) : super(key: key);

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final TextEditingController _searchController = TextEditingController();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  
  File? _taskCompletionImage;

  List<TaskDetailData> _allTasks = [];
  List<TaskDetailData> _filteredTasks = [];
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;
  String _selectedFilter = 'today'; // 'today' or 'upcoming'

  @override
  void initState() {
    super.initState();
    _loadTasksFromAPI();
  }

  Future<void> _loadTasksFromAPI() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authData = await _storageService.getAllAuthData();
      final userData = authData['user'];
      final String? authToken = authData['token'];
      print('Auth token inside task page =========: $authToken');
      if (userData != null) {
        _currentUserId = userData['id'];
        print('Current user ID: $_currentUserId');
      } else {
        throw Exception('User data not found in storage');
      }

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Auth token not found in storage');
      }

      // Make API call using token from SharedPreferences
      final response = await http.get(
        Uri.parse('https://erp.comsindia.in/api/view/task/$_currentUserId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      print('API Response URL: ${response.request?.url}');
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final taskList = jsonData['Task'] as List;

        setState(() {
          _allTasks = taskList
              .map((taskJson) => TaskDetailData.fromJson(taskJson))
              .toList();
          _filterTasks();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading tasks: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // First, filter out completed tasks
    final incompleteTasks = _allTasks.where((task) => 
      !task.status.toLowerCase().contains('completed')).toList();

    if (_selectedFilter == 'today') {
      // Show only today's tasks
      _filteredTasks = incompleteTasks.where((task) {
        try {
          final taskDate = DateTime.parse(task.fromDate);
          final taskDateOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
          return taskDateOnly.isAtSameMomentAs(today);
        } catch (e) {
          return false;
        }
      }).toList();
    } else {
      // Show upcoming 3 tasks (from tomorrow onwards)
      final upcomingTasks = incompleteTasks.where((task) {
        try {
          final taskDate = DateTime.parse(task.fromDate);
          final taskDateOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
          return taskDateOnly.isAfter(today);
        } catch (e) {
          return false;
        }
      }).toList();

      // Sort by date and take only first 3
      upcomingTasks.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.fromDate);
          final dateB = DateTime.parse(b.fromDate);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

      _filteredTasks = upcomingTasks.take(3).toList();
    }

    // Apply search filter if there's a search query
    if (_searchController.text.isNotEmpty) {
      _filteredTasks = _filteredTasks.where((task) =>
          task.taskName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          task.taskDescription.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }
  }

  Future<void> _completeTask(int taskId) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Completing task...'),
              ],
            ),
          );
        },
      );

      // Get auth token from storage
      final authData = await _storageService.getAllAuthData();
      final String? authToken = authData['token'];

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Auth token not found');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://erp.comsindia.in/api/completed/task'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      });

      // Add form field for taskId
      request.fields['taskId'] = taskId.toString();

      // Add the image file to the request
      if (_taskCompletionImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'completion_image',
          _taskCompletionImage!.path,
        ));
      }

      print('Completing task with ID: $taskId');
      print('Using token: $authToken');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Clear the image after successful upload
      _taskCompletionImage = null;

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh tasks list
        await _refreshTasks();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to complete task');
      }
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();

      print('Error completing task: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCompleteTaskDialog(TaskDetailData task) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Complete Task'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text(
                        'Are you sure you want to mark this task as completed?'),
                    const SizedBox(height: 10),
                    Text(
                      'Task: ${task.taskName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    if (_taskCompletionImage == null) ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final hasPermission =
                                await _requestCameraPermission();
                            if (!hasPermission) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Camera permission is required'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.camera,
                              maxWidth: 800,
                              maxHeight: 800,
                              imageQuality: 80,
                              preferredCameraDevice: CameraDevice.rear,
                            );

                            if (image != null && mounted) {
                              setState(() {
                                _taskCompletionImage = File(image.path);
                              });
                            }
                          } catch (e) {
                            print('Error taking photo: $e');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Failed to take photo: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Completion Photo'),
                      ),
                    ] else ...[
                      Column(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _taskCompletionImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _taskCompletionImage = null;
                              });
                            },
                            child: const Text('Retake Photo'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    _taskCompletionImage = null;
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Complete'),
                  onPressed: _taskCompletionImage == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _completeTask(task.id);
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _refreshTasks() async {
    await _loadTasksFromAPI();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: const Text(
          'TASK LIST',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'today';
                        _filterTasks();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedFilter == 'today' 
                            ? Colors.blue[50] 
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedFilter == 'today' 
                                ? Colors.blue 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Today\'s Tasks',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedFilter == 'today' 
                              ? Colors.blue[700] 
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'upcoming';
                        _filterTasks();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedFilter == 'upcoming' 
                            ? Colors.orange[50] 
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedFilter == 'upcoming' 
                                ? Colors.orange 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Upcoming (3)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedFilter == 'upcoming' 
                              ? Colors.orange[700] 
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[400]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _filterTasks();
                });
              },
            ),
          ),

          // Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading tasks...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'today' 
                  ? 'No tasks for today' 
                  : 'No upcoming tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'today' 
                  ? 'You have no tasks scheduled for today' 
                  : 'No tasks scheduled for the next few days',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
        onRefresh: _refreshTasks,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredTasks.length,
          itemBuilder: (context, index) {
            final task = _filteredTasks[index];
            return _buildTaskCard(task);
          },
        ));
  }

  Widget _buildTaskCard(TaskDetailData task) {
    final isToday = _isTaskToday(task.fromDate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today indicator
            if (isToday) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'TODAY',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Header row with task name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.taskName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Task Description
            if (task.taskDescription.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.taskDescription,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Date and Duration Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'From Date',
                    _formatDate(task.fromDate),
                    Icons.calendar_today,
                    Colors.green[600]!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    'To Date',
                    _formatDate(task.toDate),
                    Icons.calendar_today,
                    Colors.red[600]!,
                  ),
                ),
                const SizedBox(width: 12),
                _buildInfoItem(
                  'Days',
                  '${task.totalDays}',
                  Icons.timelapse,
                  Colors.blue[600]!,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Complete Task Button (only for pending tasks)
            if (task.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCompleteTaskDialog(task),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Mark as Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isTaskToday(String dateString) {
    try {
      final taskDate = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final taskDateOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
      return taskDateOnly.isAtSameMomentAs(today);
    } catch (e) {
      return false;
    }
  }

  Widget _buildInfoItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTimeString.split('T')[0];
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[600]!;
      case 'completed':
      case 'completed on time':
        return Colors.green[600]!;
      case 'in progress':
        return Colors.blue[600]!;
      case 'overdue':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  void _showCreateTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateTaskDialog(
          onTaskCreated: _refreshTasks,
        );
      },
    );
  }

  // Update the _requestCameraPermission method
  Future<bool> _requestCameraPermission() async {
    try {
      if (await Permission.camera.isGranted) {
        return true;
      }

      var result = await Permission.camera.request();
      return result.isGranted;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class CreateTaskDialog extends StatefulWidget {
  final VoidCallback? onTaskCreated;

  const CreateTaskDialog({Key? key, this.onTaskCreated}) : super(key: key);

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_task, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'NEW TASK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Name
                      const Text(
                        'Task Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _taskNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Task name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Date Selection Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From Date',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _fromDateController,
                                  decoration: InputDecoration(
                                    hintText: 'dd-mm-yyyy',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    suffixIcon:
                                        const Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () =>
                                      _selectDate(context, _fromDateController),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To Date',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _toDateController,
                                  decoration: InputDecoration(
                                    hintText: 'dd-mm-yyyy',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    suffixIcon:
                                        const Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () =>
                                      _selectDate(context, _toDateController),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Task Description
                      const Text(
                        'Task Description',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _taskDescriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Task description is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Create Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isCreating ? null : _createTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isCreating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Create Task',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Here you would make an API call to create the task
      // For now, just simulate success
      await Future.delayed(const Duration(seconds: 1));

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onTaskCreated != null) {
        widget.onTaskCreated!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDescriptionController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }
}

class TaskDetailData {
  final int id;
  final int employeeId;
  final String taskName;
  final String fromDate;
  final String toDate;
  final int totalDays;
  final String taskDescription;
  final String status;
  final String createdAt;
  final String updatedAt;

  TaskDetailData({
    required this.id,
    required this.employeeId,
    required this.taskName,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.taskDescription,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskDetailData.fromJson(Map<String, dynamic> json) {
    return TaskDetailData(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      taskName: json['task_name'] ?? '',
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      totalDays: json['total_days'] ?? 0,
      taskDescription: json['task_description'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'task_name': taskName,
      'from_date': fromDate,
      'to_date': toDate,
      'total_days': totalDays,
      'task_description': taskDescription,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}