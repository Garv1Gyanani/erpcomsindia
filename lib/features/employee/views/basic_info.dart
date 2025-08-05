import 'package:coms_india/core/constants/app_colors.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/employee_provider.dart';
import '../../../core/utils/validation_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FamilyMemberUI {
  TextEditingController nameController = TextEditingController();
  TextEditingController relationController = TextEditingController();
  TextEditingController occupationController = TextEditingController();
  DateTime? dateOfBirth;

  void dispose() {
    nameController.dispose();
    relationController.dispose();
    occupationController.dispose();
  }
}

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  int currentStep = 0;

  final _nameController = TextEditingController();
  final _genderOptions = ['Male', 'Female', 'Other'];
  final _statusOptions = ['Single', 'Married', 'Divorced'];
  final _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final _religionOptions = ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Other'];

  String? _selectedGender;
  String? _selectedStatus;
  String? _selectedBloodGroup;
  String? _selectedReligion;
  DateTime? _dob;
  DateTime? _doj;

  // Updated family information structure
  List<FamilyMemberUI> familyMembers = [FamilyMemberUI()];
  bool _hasPermission =
      false; // Start with false, assume no permission initially
  bool _isLoadingPermission = true; // Track if permission check is in progress
  final StorageService _storageService = StorageService();

  Future<void> _selectDate(BuildContext context,
      Function(DateTime) onDatePicked, bool isFamilyMember) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime(1950);
    final DateTime lastDate =
        DateTime(now.year, now.month, now.day); // Today's date

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: initialDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      if (picked.isAfter(lastDate)) {
        // Optionally display an error message if the selected date is in the future
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Date of Birth cannot be today or a future date.')),
        );
        return;
      }
      onDatePicked(picked);
    }
  }

  void _addFamilyMember() {
    setState(() {
      familyMembers.add(FamilyMemberUI());
    });
  }

  void _removeFamilyMember(int index) {
    if (familyMembers.length > 1) {
      setState(() {
        familyMembers[index].dispose();
        familyMembers.removeAt(index);
      });
    }
  }

  Future<void> _submitForm() async {
    print('🐛 DEBUG: ===== BASIC INFO FORM SUBMISSION =====');
    print('🐛 DEBUG: Employee Name: ${_nameController.text}');
    print('🐛 DEBUG: Gender: $_selectedGender');
    print('🐛 DEBUG: DOB: $_dob');
    print('🐛 DEBUG: DOJ: $_doj');
    print('🐛 DEBUG: Marital Status: $_selectedStatus');
    print('🐛 DEBUG: Blood Group: $_selectedBloodGroup');
    print('🐛 DEBUG: Religion: $_selectedReligion');
    print('🐛 DEBUG: Family Members: ${familyMembers.length}');

    if (_formKey.currentState!.validate()) {
      try {
        // ✅ ONLY update provider with basic info data - no API call here
        final provider = context.read<EmployeeProvider>();
        final basicInfoData = {
          'name': _nameController.text,
          'gender': _selectedGender?.toLowerCase() ?? '',
          'dob': _dob?.toIso8601String().split('T')[0] ?? '',
          'doj': _doj?.toIso8601String().split('T')[0] ?? '',
          'marital_status': _selectedStatus?.toLowerCase() ?? '',
          'blood_group': _selectedBloodGroup ?? '',
          'religion': _selectedReligion ?? '',
          'family_members': familyMembers
              .map((member) => {
                    'name': member.nameController.text,
                    'relation': member.relationController.text,
                    'occupation': member.occupationController.text,
                    'dob':
                        member.dateOfBirth?.toIso8601String().split('T')[0] ??
                            '',
                  })
              .toList(),
        };

        print('🐛 DEBUG: About to update provider with basic info data...');
        provider.updateFormData('basic_info', basicInfoData);
        print('🐛 DEBUG: Successfully updated provider with basic info data');
        print(
            '🐛 DEBUG: Current completion: ${provider.getCompletionPercentage().toStringAsFixed(1)}%');
        print('🐛 DEBUG: Provider status: ${provider.status}');
        print('🐛 DEBUG: ========================================');

        // ✅ Navigate to next screen instead of calling API
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Basic info saved! Continue to next step.')),
          );
          // Navigate to employment details screen
          context.goNamed('employment_details');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    for (var member in familyMembers) {
      member.dispose();
    }
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    setState(() {
      _isLoadingPermission = true; // Start loading
    });
    String? authToken;

    try {
      final authData = await _storageService.getAllAuthData();
      authToken = authData['token'];
    } catch (e) {
      print('Error getting token from storage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error getting token from storage: ${e.toString()}')),
      );
      setState(() {
        _hasPermission = false;
        _isLoadingPermission = false;
      });
      return; // Exit if token retrieval fails
    }

    if (authToken == null || authToken.isEmpty) {
      print('Auth token is missing.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auth token is missing.')),
      );
      setState(() {
        _hasPermission = false; // No token, no permission
        _isLoadingPermission = false;
      });
      return;
    }

    final url = Uri.parse('https://erp.comsindia.in/api/employee/store');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    try {
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 403 &&
          jsonDecode(response.body)['message'] ==
              "You do not have permission to create an employee.") {
        setState(() {
          _hasPermission = false;
          _isLoadingPermission = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('You do not have permission to create an employee.')),
        );
      } else {
        setState(() {
          _hasPermission = true;
          _isLoadingPermission = false;
        });
      }
    } catch (e) {
      print('Error checking permission: $e');
      // Handle network or server errors as needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking permission: ${e.toString()}')),
      );
      setState(() {
        _hasPermission = false; // Assume no permission on error
        _isLoadingPermission = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermission(); // Check permission when the page loads
    // Pre-populate fields with sample data for easy testing
    // _nameController.text = "Utkarsh";
    // _selectedGender = "Male";
    // _selectedStatus = "Married";
    // _selectedBloodGroup = "A+";
    // _selectedReligion = "Hindu";
    // _dob = DateTime(1990, 1, 1);
    // _doj = DateTime(2025, 6, 10);
    // // Pre-populate first family member
    // familyMembers[0].nameController.text = "Jane Doe";
    // familyMembers[0].relationController.text = "Wife";
    // familyMembers[0].occupationController.text = "Teacher";
    // familyMembers[0].dateOfBirth = DateTime(1992, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Check if there's something to pop, otherwise go to employees list
            if (context.canPop()) {
              context.pop(); // Go back to employee list
            } else {
              context.goNamed('employees'); // Fallback to employee list
            }
          },
        ),
        backgroundColor: AppColors.primary,
        title: const Text('Basic Information',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: Builder(
          // Use a Builder to get a context *within* the build method
          builder: (BuildContext context) {
        return Consumer<EmployeeProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.isError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${provider.errorMessage}'),
                    ElevatedButton(
                      onPressed: () => provider.clearError(),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            if (_isLoadingPermission) {
              return const Center(
                child: CircularProgressIndicator(),
              ); // Show loading indicator while checking permission
            }

            return _hasPermission
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentStep == 0) ...[
                            rowWrap([
                              _buildTextField(
                                  _nameController, 'Employee Name *'),
                            ]),
                            rowWrap([
                              _buildDropdown(
                                  'Gender *', _genderOptions, _selectedGender,
                                  (val) {
                                setState(() => _selectedGender = val);
                              }),
                              _buildDropdown('Marital Status *', _statusOptions,
                                  _selectedStatus, (val) {
                                setState(() => _selectedStatus = val);
                              }),
                            ]),
                            rowWrap([
                              _buildDatePicker('Date of Birth *', _dob, (date) {
                                setState(() => _dob = date);
                              }),
                              _buildDatePicker('Date of Joining *', _doj,
                                  (date) {
                                setState(() => _doj = date);
                              }),
                            ]),
                            rowWrap([
                              _buildDropdown('Blood Group', _bloodGroupOptions,
                                  _selectedBloodGroup, (val) {
                                setState(() => _selectedBloodGroup = val);
                              }),
                              _buildDropdown('Religion *', _religionOptions,
                                  _selectedReligion, (val) {
                                setState(() => _selectedReligion = val);
                              }),
                            ]),
                            const SizedBox(height: 20),
                            // Action button moved to bottomNavigationBar
                          ] else if (currentStep == 1) ...[
                            // Updated Family Information Section
                            sectionTitle('Family Information'),
                            const SizedBox(height: 16),

                            // Dynamic Family Members List
                            ...familyMembers.asMap().entries.map((entry) {
                              int index = entry.key;
                              FamilyMemberUI member = entry.value;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade50,
                                ),
                                child: Column(
                                  children: [
                                    // First Row: Name and Relation
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabelWithAsterisk('Name *'),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: member.nameController,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                          validator: ValidationUtils
                                              .validateFamilyMemberName,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Relation',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: member.relationController,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Second Row: Occupation and Date of Birth
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Occupation',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller:
                                              member.occupationController,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Date of Birth',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: () =>
                                              _selectDate(context, (date) {
                                            setState(() =>
                                                member.dateOfBirth = date);
                                          }, true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  member.dateOfBirth != null
                                                      ? '${member.dateOfBirth!.day.toString().padLeft(2, '0')}-${member.dateOfBirth!.month.toString().padLeft(2, '0')}-${member.dateOfBirth!.year}'
                                                      : 'dd-mm-yyyy',
                                                  style: TextStyle(
                                                    color: member.dateOfBirth !=
                                                            null
                                                        ? Colors.black
                                                        : Colors.grey.shade600,
                                                  ),
                                                ),
                                                Icon(Icons.calendar_today,
                                                    size: 16,
                                                    color:
                                                        Colors.grey.shade600),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Remove button (show only if more than one member)
                                    if (familyMembers.length > 1) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                            onPressed: () =>
                                                _removeFamilyMember(index),
                                            child: const Text('Remove',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),

                            // Add More button positioned after all family members
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    _addFamilyMember();
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Add More Family Member',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 140),
                            // Action button moved to bottomNavigationBar
                          ]
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                            "You do not have permission to create an employee."),
                      ],
                    ),
                  );
          },
        );
      }),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: _getInputDecorationWithRedAsterisk(label),
        validator: (value) {
          if (label == 'Employee Name ') {
            return ValidationUtils.validateEmployeeName(value);
          }
          if (label.contains('') && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  TextStyle? _getLabelStyle(String label) {
    return const TextStyle(
      color: Colors.black87,
    );
  }

  InputDecoration _getInputDecorationWithRedAsterisk(String label) {
    return InputDecoration(
      label: _buildLabelWithAsterisk(label),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildLabelWithAsterisk(String label) {
    List<String> parts = label.split(' *');
    if (parts.length > 1) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          children: [
            TextSpan(text: parts[0]),
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<String>(
        decoration: _getInputDecorationWithRedAsterisk(label),
        value: selectedValue,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: (value) {
          if (label.contains('*') && value == null) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker(
      String label, DateTime? selectedDate, Function(DateTime) onDatePicked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () => _selectDate(context, (date) {
          onDatePicked(date);
        }, false),
        child: InputDecorator(
          decoration: InputDecoration(
            label: _buildLabelWithAsterisk(label),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            selectedDate != null
                ? '${selectedDate.day}-${selectedDate.month}-${selectedDate.year}'
                : 'dd-mm-yyyy',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget rowWrap(List<Widget> children) {
    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 10),
        if (children.length > 1) Expanded(child: children[1]),
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  /// Bottom bar that shows the primary action button for the current step.
  Widget _buildBottomNavigationBar() {
    // Hide the bottom bar when the provider is busy or in error state
    final provider = context.read<EmployeeProvider>();
    if (provider.isLoading ||
        provider.isError ||
        _isLoadingPermission ||
        !_hasPermission) {
      return const SizedBox.shrink();
    }
    final String buttonText = currentStep == 0
        ? 'Continue to Family Information'
        : 'Continue to Education Details';

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (currentStep == 0) {
                // Validate and move to the next step
                if (_formKey.currentState!.validate()) {
                  setState(() => currentStep = 1);
                }
              } else {
                // Submit the form on the final step
                _submitForm();
              }
            },
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
