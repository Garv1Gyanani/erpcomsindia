import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

// --- Theme Constants (Good Practice) ---
const Color kPrimaryColor = Color(0xFFD32F2F);
const Color kBackgroundColor = Color(0xFFF5F5F5);

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({Key? key}) : super(key: key);

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  List<Department> departments = [];
  int? selectedDepartmentId;
  int? selectedDesignationId;
  String? selectedSubject;
  bool _isLoading = false;

  final List<String> subjects = [
    'Billing',
    'Maintenance',
    'IT Support',
    'Other'
  ];
  final TextEditingController messageController = TextEditingController();

  // --- State for Image Handling ---
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  // --- Image Picking Logic ---

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Image Source',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: kPrimaryColor),
                  title: const Text('Pick from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined,
                      color: kPrimaryColor),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compress image to reduce file size
        maxWidth: 1024, // Resize larger images for performance
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImageFile = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to pick image: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- API and Form Logic ---

  Future<void> fetchDepartments() async {
    const url = 'https://erp.comsindia.in/api/departments';
    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token'];

    if (authToken == null || authToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Authentication token is missing.'),
          backgroundColor: Colors.red));
      return;
    }
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken'
      });
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == true) {
          List<Department> fetchedDepartments = (jsonData['data'] as List)
              .map((item) => Department.fromJson(item))
              .toList();
          if (mounted) setState(() => departments = fetchedDepartments);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: ${jsonData['message']}'),
              backgroundColor: Colors.red));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('HTTP error: ${response.statusCode}'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> submitTicket() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    const url = 'https://erp.comsindia.in/api/tickets';
    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token'];

    if (authToken == null || authToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Authentication error. Please log in again.'),
          backgroundColor: Colors.red));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $authToken';

      request.fields['designation_id'] = selectedDesignationId!.toString();
      request.fields['subject_id'] = selectedSubject!;
      request.fields['message'] = messageController.text.trim();

      if (_selectedImageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // This key must match your backend's expectation
            _selectedImageFile!.path,
            filename: _selectedImageFile!
                .name, // It's good practice to provide a filename
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonData = json.decode(responseBody);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (jsonData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(jsonData['message'] ?? 'Ticket created successfully!'),
                backgroundColor: Colors.green),
          );
          // Reset the form
          setState(() {
            selectedDepartmentId = null;
            selectedDesignationId = null;
            selectedSubject = null;
            messageController.clear();
            _selectedImageFile = null;
            _formKey.currentState?.reset();
          });
          // TODO: Optionally, switch the user to the "Existing Tickets" tab here
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: ${jsonData['message']}'),
                backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Server Error: ${response.statusCode} - ${jsonData['message'] ?? responseBody}'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDropdownContainer(
                    child: DropdownButtonFormField2<int>(
                      decoration: _dropdownInputDecoration(),
                      isExpanded: true,
                      hint: const Text('Select Department *',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black54)),
                      value: selectedDepartmentId,
                      items: departments
                          .map((department) => DropdownMenuItem<int>(
                                value: department.id,
                                child: Text(department.departmentName,
                                    style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      validator: (value) =>
                          value == null ? 'Please select a department.' : null,
                      onChanged: (value) {
                        setState(() {
                          selectedDepartmentId = value;
                          selectedDesignationId = null;
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                          height: 40, padding: EdgeInsets.only(right: 14)),
                      iconStyleData: const IconStyleData(
                          icon: Icon(Icons.arrow_drop_down,
                              color: Colors.black45),
                          iconSize: 30),
                      dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8))),
                      menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                          padding: EdgeInsets.only(left: 14, right: 14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownContainer(
                    child: DropdownButtonFormField2<int>(
                      decoration: _dropdownInputDecoration(),
                      isExpanded: true,
                      hint: const Text('Select Designation *',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black54)),
                      value: selectedDesignationId,
                      items: (selectedDepartmentId != null
                              ? departments
                                  .firstWhere(
                                      (d) => d.id == selectedDepartmentId,
                                      orElse: () => Department(
                                          id: -1,
                                          departmentName: '',
                                          designations: []))
                                  .designations
                              : <Designation>[])
                          .map((designation) => DropdownMenuItem<int>(
                                value: designation.id,
                                child: Text(designation.designationName,
                                    style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      validator: (value) =>
                          value == null ? 'Please select a designation.' : null,
                      onChanged: (value) {
                        setState(() => selectedDesignationId = value);
                      },
                      buttonStyleData: const ButtonStyleData(
                          height: 40, padding: EdgeInsets.only(right: 14)),
                      iconStyleData: const IconStyleData(
                          icon: Icon(Icons.arrow_drop_down,
                              color: Colors.black45),
                          iconSize: 30),
                      dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8))),
                      menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                          padding: EdgeInsets.only(left: 14, right: 14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownContainer(
                    child: DropdownButtonFormField2<String>(
                      decoration: _dropdownInputDecoration(),
                      isExpanded: true,
                      hint: const Text('Select Subject *',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black54)),
                      value: selectedSubject,
                      items: subjects
                          .map((subject) => DropdownMenuItem<String>(
                              value: subject,
                              child: Text(subject,
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
                      validator: (value) =>
                          value == null ? 'Please select a subject.' : null,
                      onChanged: (value) {
                        setState(() => selectedSubject = value);
                      },
                      buttonStyleData: const ButtonStyleData(
                          height: 40, padding: EdgeInsets.only(right: 14)),
                      iconStyleData: const IconStyleData(
                          icon: Icon(Icons.arrow_drop_down,
                              color: Colors.black45),
                          iconSize: 30),
                      dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8))),
                      menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                          padding: EdgeInsets.only(left: 14, right: 14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Message *',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: kPrimaryColor)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 5,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Please enter your message.'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  _buildImagePicker(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : submitTicket,
                    child: const Text('Submit Ticket'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attach Image (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (_selectedImageFile != null) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_selectedImageFile!.path),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_selectedImageFile != null)
                TextButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Remove Image'),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700),
                  onPressed: () => setState(() => _selectedImageFile = null),
                ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(_selectedImageFile == null
                    ? 'Choose Image'
                    : 'Change Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _showImagePickerOptions,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _dropdownInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      border: InputBorder.none,
      hintStyle: TextStyle(color: Colors.grey[600]),
    );
  }
}

// --- Data Models (Keep these as they are) ---
class Department {
  final int id;
  final String departmentName;
  final List<Designation> designations;

  Department(
      {required this.id,
      required this.departmentName,
      required this.designations});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      departmentName: json['department_name'],
      designations: (json['designations'] as List)
          .map((item) => Designation.fromJson(item))
          .toList(),
    );
  }
}

class Designation {
  final int id;
  final String designationName;
  final int hierarchyLevel;
  final int departmentId;

  Designation(
      {required this.id,
      required this.designationName,
      required this.hierarchyLevel,
      required this.departmentId});

  factory Designation.fromJson(Map<String, dynamic> json) {
    return Designation(
      id: json['id'],
      designationName: json['designation_name'],
      hierarchyLevel: json['hierarchy_level'],
      departmentId: json['department_id'],
    );
  }
}
