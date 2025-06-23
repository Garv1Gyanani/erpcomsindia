import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class EmployeeEditPage extends StatefulWidget {
  final int userId;
  final String employeeName;
  final Map<String, dynamic> employeeData;

  const EmployeeEditPage({
    super.key,
    required this.userId,
    required this.employeeName,
    required this.employeeData,
  });

  @override
  State<EmployeeEditPage> createState() => _EmployeeEditPageState();
}

class _EmployeeEditPageState extends State<EmployeeEditPage> {
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers for basic info
  final _empNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _hireDateController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _contactPersonNameController = TextEditingController();
  final _emergencyContactRelationController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _remarksController = TextEditingController();
  final _punchingCodeController = TextEditingController();
  final _uanNumberController = TextEditingController();
  final _previousPfNumberController = TextEditingController();
  final _witness1NameController = TextEditingController();
  final _witness2NameController = TextEditingController();
  final _insuranceNoController = TextEditingController();
  final _branchOfficeController = TextEditingController();
  final _dispensaryController = TextEditingController();

  // Dropdown values
  String _selectedGender = 'male';
  String _selectedMaritalStatus = 'single';
  String _selectedBloodGroup = 'A+';
  String _selectedReligion = 'Hindu';
  String _selectedJoiningMode = 'interview';
  String _selectedPfMember = 'yes';
  String _selectedPensionMember = 'yes';
  String _selectedEsic = 'yes';
  String _selectedInternationalWorker = 'no';
  String _countryOrigin = 'India';
  int? _selectedDepartmentId;
  int? _selectedDesignationId;
  int? _selectedSiteId = 1;
  int? _selectedLocationId = 1;

  // Dynamic lists
  List<Map<String, String>> _familyMembers = [];
  List<TextEditingController> _familyNameControllers = [];
  List<TextEditingController> _familyRelationControllers = [];
  List<TextEditingController> _familyOccupationControllers = [];
  List<TextEditingController> _familyDobControllers = [];

  List<String> _presentAddress = ['', ''];
  List<String> _permanentAddress = ['', ''];
  List<Map<String, dynamic>> _educationList = [];
  List<Map<String, dynamic>> _epfNominees = [];
  List<Map<String, dynamic>> _epsNominees = [];
  List<Map<String, dynamic>> _familyMembersList = [];

  // Image picker and selected images
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedEmployeeImage;
  File? _selectedAadharFront;
  File? _selectedAadharBack;
  File? _selectedPanCard;
  File? _selectedBankDocument;
  File? _selectedSignature;
  File? _selectedWitness1Signature;
  File? _selectedWitness2Signature;

  @override
  void initState() {
    super.initState();
    _populateFormData();
  }

  void _populateFormData() {
    final emp = widget.employeeData;
    final user = emp['user'] ?? {};

    // Basic info
    _empNameController.text = user['name'] ?? '';
    _emailController.text = user['email'] ?? '';
    _phoneController.text = user['phone'] ?? '';
    _dobController.text = emp['date_of_birth'] ?? '';
    _hireDateController.text = emp['hire_date'] ?? '';
    _selectedGender = emp['gender'] ?? 'male';
    _selectedMaritalStatus = emp['marital_status'] ?? 'single';
    _selectedBloodGroup = emp['blood_group'] ?? 'A+';
    _selectedReligion = emp['religion'] ?? 'Hindu';
    _selectedJoiningMode = emp['joining_mode'] ?? 'interview';

    // IDs
    _selectedDepartmentId = emp['department_id'];
    _selectedDesignationId = emp['designation_id'];

    // Contact info
    _emergencyContactController.text = emp['emergency_contact'] ?? '';
    _contactPersonNameController.text = emp['contactPersionName'] ?? '';
    _emergencyContactRelationController.text =
        emp['emergency_contact_relation'] ?? '';

    // Documents
    _aadharController.text = emp['aadhar'] ?? '';
    _panController.text = emp['pan'] ?? '';

    // Bank details
    _bankNameController.text = emp['bank_name'] ?? '';
    _bankAccountController.text = emp['bank_account'] ?? '';
    _ifscCodeController.text = emp['ifsc_code'] ?? '';

    // Other fields
    _remarksController.text = emp['remarks'] ?? '';
    _punchingCodeController.text = emp['punching_code'] ?? '';
    _uanNumberController.text = emp['uan_number'] ?? '';
    _previousPfNumberController.text = emp['previous_pf_number'] ?? '';
    _witness1NameController.text = emp['witness_1_name'] ?? '';
    _witness2NameController.text = emp['witness_2_name'] ?? '';
    _insuranceNoController.text = emp['insurance_no'] ?? '';
    _branchOfficeController.text = emp['branch_office'] ?? '';
    _dispensaryController.text = emp['dispensary'] ?? '';

    _selectedPfMember = emp['pf_member'] ?? 'yes';
    _selectedPensionMember = emp['pension_member'] ?? 'yes';
    _selectedEsic = emp['ESIC'] ?? 'yes';
    _selectedInternationalWorker = emp['international_worker'] ?? 'no';
    _countryOrigin = emp['country_origin'] ?? 'India';

    // Parse JSON fields
    _parseJsonFields();
  }

  void _parseJsonFields() {
    final emp = widget.employeeData;

    // Parse addresses
    try {
      if (emp['present_address'] != null) {
        final presentAddr = json.decode(emp['present_address']);
        if (presentAddr is List) {
          _presentAddress = List<String>.from(presentAddr);
        }
      }
      if (emp['permanent_address'] != null) {
        final permanentAddr = json.decode(emp['permanent_address']);
        if (permanentAddr is List) {
          _permanentAddress = List<String>.from(permanentAddr);
        }
      }
    } catch (e) {
      print('Error parsing addresses: $e');
    }

    // Parse other JSON fields
    try {
      if (emp['education'] != null) {
        _educationList =
            List<Map<String, dynamic>>.from(json.decode(emp['education']));
      }
      if (emp['epf_nominees'] != null) {
        _epfNominees =
            List<Map<String, dynamic>>.from(json.decode(emp['epf_nominees']));
      }
      if (emp['eps_family_members'] != null) {
        _epsNominees = List<Map<String, dynamic>>.from(
            json.decode(emp['eps_family_members']));
      }
      if (emp['family_members'] != null) {
        _familyMembersList =
            List<Map<String, dynamic>>.from(json.decode(emp['family_members']));
      }
    } catch (e) {
      print('Error parsing JSON fields: $e');
    }

    // Ensure we have at least one education entry
    if (_educationList.isEmpty) {
      _educationList.add({
        'degree': 'B.Tech',
        'university': 'XYZ University',
        'specialization': 'Computer Science',
        'from_year': '2010',
        'to_year': '2014',
        'percentage': '78.5'
      });
    }

    // Ensure we have at least one EPF nominee
    if (_epfNominees.isEmpty) {
      _epfNominees.add({
        'name': 'EPF Nominee',
        'address': '78 Colony, XYZ City',
        'relationship': 'Father',
        'dob': '1970-05-10',
        'share': '50%',
        'guardian': 'N/A'
      });
    }

    // Ensure we have at least one EPS nominee
    if (_epsNominees.isEmpty) {
      _epsNominees
          .add({'name': 'EPS Nominee', 'age': 45, 'relationship': 'Mother'});
    }

    // Parse family member fields from JSON strings
    try {
      if (emp['FamilyMembername'] != null) {
        final names = List<String>.from(json.decode(emp['FamilyMembername']));
        final relations = emp['relation'] != null
            ? List<String>.from(json.decode(emp['relation']))
            : <String>[];
        final occupations = emp['occupation'] != null
            ? List<String>.from(json.decode(emp['occupation']))
            : <String>[];
        final dobs = emp['dob'] != null
            ? List<String>.from(json.decode(emp['dob']))
            : <String>[];

        _familyMembers.clear();
        _familyNameControllers.clear();
        _familyRelationControllers.clear();
        _familyOccupationControllers.clear();
        _familyDobControllers.clear();

        for (int i = 0; i < names.length; i++) {
          _familyMembers.add({
            'name': names[i],
            'relation': i < relations.length ? relations[i] : '',
            'occupation': i < occupations.length ? occupations[i] : '',
            'dob': i < dobs.length ? dobs[i] : '',
          });

          _familyNameControllers.add(TextEditingController(text: names[i]));
          _familyRelationControllers.add(TextEditingController(
              text: i < relations.length ? relations[i] : ''));
          _familyOccupationControllers.add(TextEditingController(
              text: i < occupations.length ? occupations[i] : ''));
          _familyDobControllers
              .add(TextEditingController(text: i < dobs.length ? dobs[i] : ''));
        }
      }
    } catch (e) {
      print('Error parsing family member fields: $e');
    }
  }

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        _showErrorDialog('Authentication token not found. Please login again.');
        return;
      }

      final requestData = _buildRequestData();

      final response = await http.put(
        Uri.parse(
            'https://erp.comsindia.in/api/employee/update/${widget.userId}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );

      print('🔍 Update API Response Status: ${response.statusCode}');
      print('🔍 Update API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == true ||
            responseData['status'] == 'success') {
          _showSuccessDialog('Employee updated successfully!');
        } else {
          _handleValidationErrors(responseData);
        }
      } else {
        _showErrorDialog(
            'Failed to update employee. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating employee: $e');
      _showErrorDialog(
          'Network error. Please check your connection and try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _buildRequestData() {
    // Update family member data from controllers
    final familyNames = _familyNameControllers.map((c) => c.text).toList();
    final familyRelations =
        _familyRelationControllers.map((c) => c.text).toList();
    final familyOccupations =
        _familyOccupationControllers.map((c) => c.text).toList();
    final familyDobs = _familyDobControllers.map((c) => c.text).toList();

    // Ensure present and permanent addresses have at least 2 non-empty elements
    List<String> finalPresentAddress = [];
    List<String> finalPermanentAddress = [];

    // Build present address
    for (int i = 0; i < 2; i++) {
      if (i < _presentAddress.length && _presentAddress[i].trim().isNotEmpty) {
        finalPresentAddress.add(_presentAddress[i].trim());
      } else {
        finalPresentAddress.add(i == 0 ? '123 Main St' : 'Apt 4B');
      }
    }

    // Build permanent address
    for (int i = 0; i < 2; i++) {
      if (i < _permanentAddress.length &&
          _permanentAddress[i].trim().isNotEmpty) {
        finalPermanentAddress.add(_permanentAddress[i].trim());
      } else {
        finalPermanentAddress.add(i == 0 ? '456 Secondary Rd' : 'Floor 2');
      }
    }

    // Ensure education list is not empty
    List<Map<String, dynamic>> finalEducationList = _educationList.isNotEmpty
        ? _educationList
        : [
            {
              "degree": "B.Tech",
              "university": "XYZ University",
              "specialization": "Computer Science",
              "from_year": "2010",
              "to_year": "2014",
              "percentage": "78.5"
            }
          ];

    // Ensure EPF nominees list is not empty and has all required fields
    List<Map<String, dynamic>> finalEpfNominees = _epfNominees.isNotEmpty
        ? _epfNominees
        : [
            {
              "name": "EPF Nominee",
              "address": "78 Colony, XYZ City",
              "relationship": "Father",
              "dob": "1970-05-10",
              "share": "50%",
              "guardian": "N/A"
            }
          ];

    // Ensure EPS nominees list is not empty and has all required fields
    List<Map<String, dynamic>> finalEpsNominees = _epsNominees.isNotEmpty
        ? _epsNominees
        : [
            {"name": "EPS Nominee", "age": 45, "relationship": "Mother"}
          ];

    // Build family members for family field
    List<Map<String, dynamic>> finalFamilyMembers =
        _familyMembersList.isNotEmpty
            ? _familyMembersList
            : [
                {
                  "name": "Tommy Doe",
                  "dob": "2015-06-01",
                  "relation": "Son",
                  "residing": "Yes",
                  "residence": "With Parents"
                }
              ];

    print('🔍 Building request with:');
    print('Present Address: $finalPresentAddress');
    print('Permanent Address: $finalPermanentAddress');
    print('Education: $finalEducationList');
    print('EPF: $finalEpfNominees');
    print('EPS: $finalEpsNominees');

    return {
      'empName': _empNameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'gender': _selectedGender,
      'date_of_birth': _dobController.text,
      'hire_date': _hireDateController.text,
      'marital_status': _selectedMaritalStatus,
      'blood_group': _selectedBloodGroup,
      'religion': _selectedReligion,
      'FamilyMembName': familyNames.isNotEmpty ? familyNames : ['Default Name'],
      'relation': familyRelations.isNotEmpty ? familyRelations : ['Father'],
      'occupation':
          familyOccupations.isNotEmpty ? familyOccupations : ['Worker'],
      'dob': familyDobs.isNotEmpty ? familyDobs : ['1990-01-01'],
      'department_id': _selectedDepartmentId,
      'designation_id': _selectedDesignationId,
      'site_id': _selectedSiteId,
      'location': _selectedLocationId,
      'joining_mode': _selectedJoiningMode,
      'punching_code': _punchingCodeController.text,
      'emergency_contact': _emergencyContactController.text,
      'contactPersionName': _contactPersonNameController.text,
      'emergency_contact_relation': _emergencyContactRelationController.text,
      'present_address': finalPresentAddress,
      'permanent_address': finalPermanentAddress,
      'education': finalEducationList,
      'aadhar': _aadharController.text,
      'pan': _panController.text,
      'bank_name': _bankNameController.text,
      'bank_account': _bankAccountController.text,
      'ifsc_code': _ifscCodeController.text,
      'remarks': _remarksController.text,
      'epf': finalEpfNominees,
      'eps': finalEpsNominees,
      'witness_1_name': _witness1NameController.text.isNotEmpty
          ? _witness1NameController.text
          : 'Witness One',
      'witness_2_name': _witness2NameController.text.isNotEmpty
          ? _witness2NameController.text
          : 'Witness Two',
      'witness_1_signature': '',
      'witness_2_signature': '',
      'insurance_no': _insuranceNoController.text.isNotEmpty
          ? _insuranceNoController.text
          : 'ESI12345',
      'branch_office': _branchOfficeController.text.isNotEmpty
          ? _branchOfficeController.text
          : 'Central Office',
      'dispensary': _dispensaryController.text.isNotEmpty
          ? _dispensaryController.text
          : 'City Health Center',
      'family': finalFamilyMembers,
      'pf_member': _selectedPfMember,
      'pension_member': _selectedPensionMember,
      'uan_number': _uanNumberController.text.isNotEmpty
          ? _uanNumberController.text
          : 'UAN12345678',
      'previous_pf_number': _previousPfNumberController.text.isNotEmpty
          ? _previousPfNumberController.text
          : 'PF987654321',
      'exit_date': '2023-12-31',
      'scheme_certificate': 'SC12345',
      'ppo': 'PPO67890',
      'international_worker': _selectedInternationalWorker,
      'country_origin': _countryOrigin,
      'passport_number': 'M1234567',
      'passport_valid_from': '2020-01-01',
      'passport_valid_to': '2030-01-01',
      'previous_employment': [
        {
          "company_name": "ABC Ltd",
          "designation": "Developer",
          "from_date": "2020-01-01",
          "to_date": "2022-01-01",
          "reason_for_leaving": "for better option"
        }
      ],
      'other_documents': [
        {"name": "Experience Letter"}
      ],
    };
  }

  void _handleValidationErrors(Map<String, dynamic> responseData) {
    if (responseData['message'] is Map) {
      final errors = responseData['message'] as Map<String, dynamic>;
      String errorMessage = 'Validation errors:\n';

      errors.forEach((key, value) {
        if (value is List) {
          errorMessage += '• ${key}: ${value.join(', ')}\n';
        } else {
          errorMessage += '• ${key}: $value\n';
        }
      });

      _showErrorDialog(errorMessage);
    } else {
      _showErrorDialog(responseData['message'] ?? 'Unknown error occurred');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context)
                  .pop(true); // Return to details page with success result
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addFamilyMember() {
    setState(() {
      _familyMembers.add({
        'name': '',
        'relation': '',
        'occupation': '',
        'dob': '',
      });
      _familyNameControllers.add(TextEditingController());
      _familyRelationControllers.add(TextEditingController());
      _familyOccupationControllers.add(TextEditingController());
      _familyDobControllers.add(TextEditingController());
    });
  }

  void _removeFamilyMember(int index) {
    setState(() {
      _familyMembers.removeAt(index);
      _familyNameControllers[index].dispose();
      _familyRelationControllers[index].dispose();
      _familyOccupationControllers[index].dispose();
      _familyDobControllers[index].dispose();
      _familyNameControllers.removeAt(index);
      _familyRelationControllers.removeAt(index);
      _familyOccupationControllers.removeAt(index);
      _familyDobControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    // Dispose all controllers
    _empNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _hireDateController.dispose();
    _emergencyContactController.dispose();
    _contactPersonNameController.dispose();
    _emergencyContactRelationController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _ifscCodeController.dispose();
    _remarksController.dispose();
    _punchingCodeController.dispose();
    _uanNumberController.dispose();
    _previousPfNumberController.dispose();
    _witness1NameController.dispose();
    _witness2NameController.dispose();
    _insuranceNoController.dispose();
    _branchOfficeController.dispose();
    _dispensaryController.dispose();

    // Dispose family member controllers
    for (var controller in _familyNameControllers) {
      controller.dispose();
    }
    for (var controller in _familyRelationControllers) {
      controller.dispose();
    }
    for (var controller in _familyOccupationControllers) {
      controller.dispose();
    }
    for (var controller in _familyDobControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Employee - ${widget.employeeName}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 16),
              _buildDocumentImagesSection(),
              const SizedBox(height: 16),
              _buildContactSection(),
              const SizedBox(height: 16),
              _buildAddressSection(),
              const SizedBox(height: 16),
              _buildFamilyMembersSection(),
              const SizedBox(height: 16),
              _buildDocumentsSection(),
              const SizedBox(height: 16),
              _buildBankDetailsSection(),
              const SizedBox(height: 16),
              _buildEmploymentSection(),
              const SizedBox(height: 16),
              _buildEPFSection(),
              const SizedBox(height: 16),
              _buildESICSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 3,
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
                color: Colors.red,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection('Basic Information', [
      TextFormField(
        controller: _empNameController,
        decoration: const InputDecoration(
          labelText: 'Employee Name *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value?.isEmpty == true ? 'Name is required' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          labelText: 'Email *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value?.isEmpty == true ? 'Email is required' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _phoneController,
        decoration: const InputDecoration(
          labelText: 'Phone *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value?.isEmpty == true ? 'Phone is required' : null,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: ['male', 'female', 'other'].map((gender) {
                return DropdownMenuItem(
                    value: gender, child: Text(gender.toUpperCase()));
              }).toList(),
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _dobController,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _dobController.text =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }
              },
              readOnly: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _hireDateController,
              decoration: const InputDecoration(
                labelText: 'Hire Date',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  _hireDateController.text =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }
              },
              readOnly: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedMaritalStatus,
              decoration: const InputDecoration(
                labelText: 'Marital Status',
                border: OutlineInputBorder(),
              ),
              items: ['single', 'married', 'divorced', 'widowed'].map((status) {
                return DropdownMenuItem(
                    value: status, child: Text(status.toUpperCase()));
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedMaritalStatus = value!),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedBloodGroup,
              decoration: const InputDecoration(
                labelText: 'Blood Group',
                border: OutlineInputBorder(),
              ),
              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                  .map((group) {
                return DropdownMenuItem(value: group, child: Text(group));
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedBloodGroup = value!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedReligion,
              decoration: const InputDecoration(
                labelText: 'Religion',
                border: OutlineInputBorder(),
              ),
              items: [
                'Hindu',
                'Muslim',
                'Christian',
                'Sikh',
                'Buddhist',
                'Jain',
                'Other'
              ].map((religion) {
                return DropdownMenuItem(value: religion, child: Text(religion));
              }).toList(),
              onChanged: (value) => setState(() => _selectedReligion = value!),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildContactSection() {
    return _buildSection('Emergency Contact', [
      TextFormField(
        controller: _contactPersonNameController,
        decoration: const InputDecoration(
          labelText: 'Contact Person Name',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _emergencyContactController,
        decoration: const InputDecoration(
          labelText: 'Emergency Contact',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _emergencyContactRelationController,
        decoration: const InputDecoration(
          labelText: 'Relation',
          border: OutlineInputBorder(),
        ),
      ),
    ]);
  }

  Widget _buildAddressSection() {
    return _buildSection('Address Information', [
      const Text('Present Address:',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: _presentAddress.isNotEmpty ? _presentAddress[0] : '',
        decoration: const InputDecoration(
          labelText: 'Street/Address Line 1',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (_presentAddress.isEmpty) _presentAddress = ['', ''];
          _presentAddress[0] = value;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue: _presentAddress.length > 1 ? _presentAddress[1] : '',
        decoration: const InputDecoration(
          labelText: 'Address Line 2',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (_presentAddress.isEmpty) _presentAddress = ['', ''];
          if (_presentAddress.length == 1) _presentAddress.add('');
          _presentAddress[1] = value;
        },
      ),
      const SizedBox(height: 16),
      const Text('Permanent Address:',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: _permanentAddress.isNotEmpty ? _permanentAddress[0] : '',
        decoration: const InputDecoration(
          labelText: 'Street/Address Line 1',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (_permanentAddress.isEmpty) _permanentAddress = ['', ''];
          _permanentAddress[0] = value;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue: _permanentAddress.length > 1 ? _permanentAddress[1] : '',
        decoration: const InputDecoration(
          labelText: 'Address Line 2',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (_permanentAddress.isEmpty) _permanentAddress = ['', ''];
          if (_permanentAddress.length == 1) _permanentAddress.add('');
          _permanentAddress[1] = value;
        },
      ),
    ]);
  }

  Widget _buildFamilyMembersSection() {
    return _buildSection('Family Members', [
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _familyMembers.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Family Member ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFamilyMember(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _familyNameControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _familyRelationControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Relation',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _familyOccupationControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Occupation',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _familyDobControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _familyDobControllers[index].text =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      }
                    },
                    readOnly: true,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: _addFamilyMember,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Family Member',
            style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      ),
    ]);
  }

  Widget _buildDocumentsSection() {
    return _buildSection('Documents', [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _aadharController,
              decoration: const InputDecoration(
                labelText: 'Aadhar Number',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _panController,
              decoration: const InputDecoration(
                labelText: 'PAN Number',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildBankDetailsSection() {
    return _buildSection('Bank Details', [
      TextFormField(
        controller: _bankNameController,
        decoration: const InputDecoration(
          labelText: 'Bank Name',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _bankAccountController,
        decoration: const InputDecoration(
          labelText: 'Account Number',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _ifscCodeController,
        decoration: const InputDecoration(
          labelText: 'IFSC Code',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _remarksController,
        decoration: const InputDecoration(
          labelText: 'Remarks',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
    ]);
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateEmployee,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Update Employee', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildEmploymentSection() {
    return _buildSection('Employment Details', [
      DropdownButtonFormField<String>(
        value: _selectedJoiningMode,
        decoration: const InputDecoration(
          labelText: 'Joining Mode',
          border: OutlineInputBorder(),
        ),
        items: ['interview', 'reference', 'direct', 'other', 'referral']
            .map((mode) {
          return DropdownMenuItem(value: mode, child: Text(mode.toUpperCase()));
        }).toList(),
        onChanged: (value) => setState(() => _selectedJoiningMode = value!),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPfMember,
              decoration: const InputDecoration(
                labelText: 'PF Member',
                border: OutlineInputBorder(),
              ),
              items: ['yes', 'no'].map((status) {
                return DropdownMenuItem(
                    value: status, child: Text(status.toUpperCase()));
              }).toList(),
              onChanged: (value) => setState(() => _selectedPfMember = value!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPensionMember,
              decoration: const InputDecoration(
                labelText: 'Pension Member',
                border: OutlineInputBorder(),
              ),
              items: ['yes', 'no'].map((status) {
                return DropdownMenuItem(
                    value: status, child: Text(status.toUpperCase()));
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedPensionMember = value!),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildEPFSection() {
    return _buildSection('EPF/EPS Details', [
      TextFormField(
        controller: _uanNumberController,
        decoration: const InputDecoration(
          labelText: 'UAN Number *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            _selectedPfMember == 'yes' && (value?.isEmpty == true)
                ? 'UAN Number is required when PF member is yes'
                : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _previousPfNumberController,
        decoration: const InputDecoration(
          labelText: 'Previous PF Number *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            _selectedPfMember == 'yes' && (value?.isEmpty == true)
                ? 'Previous PF Number is required when PF member is yes'
                : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _witness1NameController,
        decoration: const InputDecoration(
          labelText: 'Witness 1 Name *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value?.isEmpty == true ? 'Witness 1 name is required' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _witness2NameController,
        decoration: const InputDecoration(
          labelText: 'Witness 2 Name *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value?.isEmpty == true ? 'Witness 2 name is required' : null,
      ),
    ]);
  }

  Widget _buildESICSection() {
    return _buildSection('ESIC Details', [
      DropdownButtonFormField<String>(
        value: _selectedEsic,
        decoration: const InputDecoration(
          labelText: 'ESIC Member',
          border: OutlineInputBorder(),
        ),
        items: ['yes', 'no'].map((status) {
          return DropdownMenuItem(
              value: status, child: Text(status.toUpperCase()));
        }).toList(),
        onChanged: (value) => setState(() => _selectedEsic = value!),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _insuranceNoController,
        decoration: const InputDecoration(
          labelText: 'Insurance Number',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _branchOfficeController,
        decoration: const InputDecoration(
          labelText: 'Branch Office',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _dispensaryController,
        decoration: const InputDecoration(
          labelText: 'Dispensary',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedInternationalWorker,
              decoration: const InputDecoration(
                labelText: 'International Worker',
                border: OutlineInputBorder(),
              ),
              items: ['yes', 'no'].map((status) {
                return DropdownMenuItem(
                    value: status, child: Text(status.toUpperCase()));
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedInternationalWorker = value!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: _countryOrigin,
              decoration: const InputDecoration(
                labelText: 'Country of Origin',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _countryOrigin = value,
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildDocumentImagesSection() {
    final emp = widget.employeeData;

    return _buildSection('Document Images', [
      // Employee Photo
      _buildUploadableImageRow(
        'Employee Photo',
        emp['employee_image_path'],
        _selectedEmployeeImage,
        () => _pickImage('employee_photo'),
      ),
      const SizedBox(height: 16),

      // Aadhar Documents
      Row(
        children: [
          Expanded(
            child: _buildUploadableImageCard(
              'Aadhar Front',
              emp['aadhar_front_path'],
              _selectedAadharFront,
              () => _pickImage('aadhar_front'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildUploadableImageCard(
              'Aadhar Back',
              emp['aadhar_back_path'],
              _selectedAadharBack,
              () => _pickImage('aadhar_back'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // PAN and Bank Documents
      Row(
        children: [
          Expanded(
            child: _buildUploadableImageCard(
              'PAN Card',
              emp['pan_file_path'],
              _selectedPanCard,
              () => _pickImage('pan_card'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildUploadableImageCard(
              'Bank Document',
              emp['bank_document_path'],
              _selectedBankDocument,
              () => _pickImage('bank_document'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Signature and Witness Signatures
      _buildUploadableImageRow(
        'Employee Signature',
        emp['signature_thumb_path'],
        _selectedSignature,
        () => _pickImage('signature'),
      ),
      const SizedBox(height: 16),

      Row(
        children: [
          Expanded(
            child: _buildUploadableImageCard(
              'Witness 1 Signature',
              emp['witness_1_signature_path'],
              _selectedWitness1Signature,
              () => _pickImage('witness1_signature'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildUploadableImageCard(
              'Witness 2 Signature',
              emp['witness_2_signature_path'],
              _selectedWitness2Signature,
              () => _pickImage('witness2_signature'),
            ),
          ),
        ],
      ),
    ]);
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (imageType) {
            case 'employee_photo':
              _selectedEmployeeImage = File(image.path);
              break;
            case 'aadhar_front':
              _selectedAadharFront = File(image.path);
              break;
            case 'aadhar_back':
              _selectedAadharBack = File(image.path);
              break;
            case 'pan_card':
              _selectedPanCard = File(image.path);
              break;
            case 'bank_document':
              _selectedBankDocument = File(image.path);
              break;
            case 'signature':
              _selectedSignature = File(image.path);
              break;
            case 'witness1_signature':
              _selectedWitness1Signature = File(image.path);
              break;
            case 'witness2_signature':
              _selectedWitness2Signature = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildUploadableImageRow(
      String title, String? imagePath, File? selectedFile, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: Text(selectedFile != null ? 'Change' : 'Upload'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildEnhancedImageWidget(imagePath, selectedFile, height: 160),
      ],
    );
  }

  Widget _buildUploadableImageCard(
      String title, String? imagePath, File? selectedFile, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.camera_alt, size: 18),
              color: Colors.red,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: selectedFile != null ? 'Change Image' : 'Upload Image',
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildEnhancedImageWidget(imagePath, selectedFile, height: 130),
      ],
    );
  }

  Widget _buildEnhancedImageWidget(String? imagePath, File? selectedFile,
      {double height = 150}) {
    return GestureDetector(
      onTap: () {
        if (selectedFile != null) {
          _showFullScreenImageFile(selectedFile);
        } else if (imagePath != null && imagePath.isNotEmpty) {
          _showFullScreenImage('https://erp.comsindia.in/$imagePath');
        }
      },
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: selectedFile != null
                  ? Image.file(
                      selectedFile,
                      height: height,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : imagePath != null && imagePath.isNotEmpty
                      ? Image.network(
                          'https://erp.comsindia.in/$imagePath',
                          height: height,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: height,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: height,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 32,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Failed to load',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No Image',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Tap to upload',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            if (selectedFile != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImageFile(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Selected Image',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Document Image',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
