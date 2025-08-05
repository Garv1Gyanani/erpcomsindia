import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/core/services/api_service.dart';
import 'package:coms_india/core/di/service_locator.dart';
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
  final ApiService _apiService = getIt<ApiService>();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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

  List<DepartmentData> _departments = [];
  List<SiteData> _sites = [];
  List<LocationData> _locations = [];
  List<DesignationData> _availableDesignations = [];

  bool _isLoadingDepartments = false;
  bool _isLoadingSites = false;
  bool _isLoadingLocations = false;

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
    print('🚀 DEBUG: EmployeeEditPage initState started');
    print('🚀 DEBUG: Employee data: ${widget.employeeData}');
    print('🚀 DEBUG: Employee name: ${widget.employeeName}');
    _populateFormData();
    _loadDropdownData();
    print('🚀 DEBUG: EmployeeEditPage initState completed');
  }

  void _loadDropdownData() {
    print('📊 DEBUG: Starting to load dropdown data...');
    _loadDepartments();
    _loadSites();
    _loadLocations();
  }

  Future<void> _loadDepartments() async {
    try {
      print('🏢 DEBUG: Loading departments...');
      setState(() => _isLoadingDepartments = true);
      final response = await _apiService.getDepartments();
      print(
          '🏢 DEBUG: Departments API response status: ${response.statusCode}');
      print('🏢 DEBUG: Departments API response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> departmentsJson = data['data'];
          _departments = departmentsJson
              .map((json) => DepartmentData.fromJson(json))
              .toList();
          print(
              '✅ DEBUG: Departments loaded successfully: ${_departments.length} departments');
          for (var dept in _departments) {
            print(
                '🏢 DEBUG: Department - ID: ${dept.id}, Name: ${dept.name}, Designations: ${dept.designations.length}');
          }
        } else {
          print('❌ DEBUG: Departments API returned status false or null data');
        }
      } else {
        print(
            '❌ DEBUG: Departments API failed with status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error loading departments: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
    } finally {
      setState(() => _isLoadingDepartments = false);
      print(
          '🏢 DEBUG: Departments loading completed, isLoading: $_isLoadingDepartments');
    }
  }

  Future<void> _loadSites() async {
    try {
      print('🏗️ DEBUG: Loading sites...');
      setState(() => _isLoadingSites = true);
      final response = await _apiService.getSites();
      print('🏗️ DEBUG: Sites API response status: ${response.statusCode}');
      print('🏗️ DEBUG: Sites API response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> sitesJson = data['data'];
          _sites = sitesJson.map((json) => SiteData.fromJson(json)).toList();
          print('✅ DEBUG: Sites loaded successfully: ${_sites.length} sites');
          for (var site in _sites) {
            print('🏗️ DEBUG: Site - ID: ${site.id}, Name: ${site.name}');
          }
        } else {
          print('❌ DEBUG: Sites API returned status false or null data');
        }
      } else {
        print('❌ DEBUG: Sites API failed with status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error loading sites: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
    } finally {
      setState(() => _isLoadingSites = false);
      print('🏗️ DEBUG: Sites loading completed, isLoading: $_isLoadingSites');
    }
  }

  Future<void> _loadLocations() async {
    try {
      print('📍 DEBUG: Loading locations...');
      setState(() => _isLoadingLocations = true);
      final response = await _apiService.getLocations();
      print('📍 DEBUG: Locations API response status: ${response.statusCode}');
      print('📍 DEBUG: Locations API response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> locationsJson = data['data'];
          _locations =
              locationsJson.map((json) => LocationData.fromJson(json)).toList();
          print(
              '✅ DEBUG: Locations loaded successfully: ${_locations.length} locations');
          for (var location in _locations) {
            print(
                '📍 DEBUG: Location - ID: ${location.id}, Name: ${location.name}');
          }
        } else {
          print('❌ DEBUG: Locations API returned status false or null data');
        }
      } else {
        print(
            '❌ DEBUG: Locations API failed with status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error loading locations: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
    } finally {
      setState(() => _isLoadingLocations = false);
      print(
          '📍 DEBUG: Locations loading completed, isLoading: $_isLoadingLocations');
    }
  }

  void _populateFormData() {
    final emp = widget.employeeData;
    print('📝 DEBUG: Starting to populate form data...');
    print('📝 DEBUG: Employee data keys: ${emp.keys.toList()}');

    _empNameController.text = emp['empName'] ?? '';
    _selectedGender = emp['gender'] ?? 'male';
    _dobController.text = emp['date_of_birth'] ?? '';
    _hireDateController.text = emp['hire_date'] ?? '';
    _selectedMaritalStatus = emp['marital_status'] ?? 'single';
    _selectedBloodGroup = emp['blood_group'] ?? 'A+';
    _selectedReligion = emp['religion'] ?? 'Hindu';
    _selectedJoiningMode = emp['joining_mode'] ?? 'interview';
    _selectedPfMember = emp['pf_member'] ?? 'yes';
    _selectedPensionMember = emp['pension_member'] ?? 'yes';
    _selectedEsic = emp['ESIC'] ?? 'yes';
    _selectedInternationalWorker = emp['international_worker'] ?? 'no';
    _countryOrigin = emp['country_origin'] ?? 'India';

    print('📝 DEBUG: Basic fields populated:');
    print('📝 DEBUG: Name: ${_empNameController.text}');
    print('📝 DEBUG: Gender: $_selectedGender');
    print('📝 DEBUG: DOB: ${_dobController.text}');
    print('📝 DEBUG: Hire Date: ${_hireDateController.text}');
    print('📝 DEBUG: PF Member: $_selectedPfMember');
    print('📝 DEBUG: ESIC: $_selectedEsic');

    Future.microtask(() {
      print('📝 DEBUG: Starting async population of complex fields...');
      _populateComplexFields(emp);
    });
  }

  void _populateComplexFields(Map<String, dynamic> emp) {
    print('🔧 DEBUG: Populating complex fields...');
    final user = emp['user'] ?? {};
    print('🔧 DEBUG: User data: $user');

    _emailController.text = user['email'] ?? '';
    _phoneController.text = user['phone'] ?? '';
    print('🔧 DEBUG: Email: ${_emailController.text}');
    print('🔧 DEBUG: Phone: ${_phoneController.text}');

    _selectedDepartmentId = emp['department_id'];
    _selectedDesignationId = emp['designation_id'];
    print('🔧 DEBUG: Department ID: $_selectedDepartmentId');
    print('🔧 DEBUG: Designation ID: $_selectedDesignationId');

    if (emp['sites'] is List && (emp['sites'] as List).isNotEmpty) {
      _selectedSiteId = emp['sites'][0]['id'];
      print('🔧 DEBUG: Site ID from sites array: $_selectedSiteId');
      print('🔧 DEBUG: Sites data: ${emp['sites']}');
    }

    _selectedLocationId = emp['location'];
    print('🔧 DEBUG: Location ID: $_selectedLocationId');

    print('🔧 DEBUG: Starting JSON fields parsing...');
    _parseJsonFields();

    print('🔧 DEBUG: Complex fields population completed');
  }

  void _parseJsonFields() {
    final emp = widget.employeeData;

    try {
      if (emp['present_address'] != null) {
        final presentAddr = emp['present_address'];
        if (presentAddr is String) {
          final decodedAddr = json.decode(presentAddr);
          if (decodedAddr is List && decodedAddr.isNotEmpty) {
            final address = decodedAddr[0];
            if (address is Map<String, dynamic>) {
              _presentAddress = [
                address['street']?.toString() ?? '',
                address['city']?.toString() ?? '',
              ];
            } else {
              _presentAddress = List<String>.from(decodedAddr);
            }
          } else if (decodedAddr is List) {
            _presentAddress = List<String>.from(decodedAddr);
          }
        } else if (presentAddr is List) {
          if (presentAddr.isNotEmpty && presentAddr[0] is Map) {
            final address = presentAddr[0] as Map<String, dynamic>;
            _presentAddress = [
              address['street']?.toString() ?? '',
              address['city']?.toString() ?? '',
            ];
          } else {
            _presentAddress = List<String>.from(presentAddr);
          }
        } else if (presentAddr is Map<String, dynamic>) {
          _presentAddress = [
            presentAddr['street']?.toString() ?? '',
            presentAddr['city']?.toString() ?? '',
          ];
        }
      }

      if (emp['permanent_address'] != null) {
        final permanentAddr = emp['permanent_address'];
        if (permanentAddr is String) {
          final decodedAddr = json.decode(permanentAddr);
          if (decodedAddr is List && decodedAddr.isNotEmpty) {
            final address = decodedAddr[0];
            if (address is Map<String, dynamic>) {
              _permanentAddress = [
                address['street']?.toString() ?? '',
                address['city']?.toString() ?? '',
              ];
            } else {
              _permanentAddress = List<String>.from(decodedAddr);
            }
          } else if (decodedAddr is List) {
            _permanentAddress = List<String>.from(decodedAddr);
          }
        } else if (permanentAddr is List) {
          if (permanentAddr.isNotEmpty && permanentAddr[0] is Map) {
            final address = permanentAddr[0] as Map<String, dynamic>;
            _permanentAddress = [
              address['street']?.toString() ?? '',
              address['city']?.toString() ?? '',
            ];
          } else {
            _permanentAddress = List<String>.from(permanentAddr);
          }
        } else if (permanentAddr is Map<String, dynamic>) {
          _permanentAddress = [
            permanentAddr['street']?.toString() ?? '',
            permanentAddr['city']?.toString() ?? '',
          ];
        }
      }
    } catch (e) {
      print('Error parsing addresses: $e');
      if (_presentAddress.isEmpty) {
        _presentAddress = ['', ''];
      }
      if (_permanentAddress.isEmpty) {
        _permanentAddress = ['', ''];
      }
    }

    try {
      if (emp['education'] != null) {
        final education = emp['education'];
        if (education is String) {
          _educationList =
              List<Map<String, dynamic>>.from(json.decode(education));
        } else if (education is List) {
          _educationList = List<Map<String, dynamic>>.from(education);
        }
      }

      if (emp['epf_nominees'] != null) {
        final epfNominees = emp['epf_nominees'];
        if (epfNominees is String) {
          _epfNominees =
              List<Map<String, dynamic>>.from(json.decode(epfNominees));
        } else if (epfNominees is List) {
          _epfNominees = List<Map<String, dynamic>>.from(epfNominees);
        }
      }

      if (emp['eps_family_members'] != null) {
        final epsMembers = emp['eps_family_members'];
        if (epsMembers is String) {
          _epsNominees =
              List<Map<String, dynamic>>.from(json.decode(epsMembers));
        } else if (epsMembers is List) {
          _epsNominees = List<Map<String, dynamic>>.from(epsMembers);
        }
      }

      if (emp['family_members'] != null) {
        final familyMembers = emp['family_members'];
        if (familyMembers is String) {
          _familyMembersList =
              List<Map<String, dynamic>>.from(json.decode(familyMembers));
        } else if (familyMembers is List) {
          _familyMembersList = List<Map<String, dynamic>>.from(familyMembers);
        }
      }
    } catch (e) {
      print('Error parsing JSON fields: $e');
    }

    if (_educationList.isEmpty) {
      _educationList.add({
        'degree': '',
        'university': '',
        'specialization': '',
        'from_year': '',
        'to_year': '',
        'percentage': ''
      });
    }

    if (_epfNominees.isEmpty) {
      _epfNominees.add({
        'name': '',
        'address': '',
        'relationship': '',
        'dob': '',
        'share': '',
        'guardian': ''
      });
    }

    if (_epsNominees.isEmpty) {
      _epsNominees = [
        {"name": "", "age": null, "relationship": ""}
      ];
    }

    if (_presentAddress.isEmpty) {
      _presentAddress = ['', ''];
    }

    if (_permanentAddress.isEmpty) {
      _permanentAddress = ['', ''];
    }

    print('🔍 Initial data populated:');
    print('EPF Nominees: $_epfNominees');
    print('EPS Nominees: $_epsNominees');
    print('Present Address: $_presentAddress');
    print('Permanent Address: $_permanentAddress');

    _parseJsonFields();
  }

  Future<void> _saveEmployee() async {
    print('💾 DEBUG: Save employee button pressed');
    print('💾 DEBUG: Form validation starting...');

    if (!_formKey.currentState!.validate()) {
      print('❌ DEBUG: Form validation failed - missing required fields');
      return;
    }

    print('✅ DEBUG: Form validation passed');
    print('💾 DEBUG: Current form state:');
    print('💾 DEBUG: Department ID: $_selectedDepartmentId');
    print('💾 DEBUG: Designation ID: $_selectedDesignationId');
    print('💾 DEBUG: Site ID: $_selectedSiteId');
    print('💾 DEBUG: Location ID: $_selectedLocationId');
    print('💾 DEBUG: Employee Name: ${_empNameController.text}');
    print('💾 DEBUG: Email: ${_emailController.text}');
    print('💾 DEBUG: Phone: ${_phoneController.text}');

    setState(() => _isLoading = true);
    print('💾 DEBUG: Loading state set to true');

    try {
      print('💾 DEBUG: Preparing form data payload...');

      final token = await _storageService.getToken();
      print(
          '💾 DEBUG: Auth token retrieved: ${token != null ? "✅ Valid" : "❌ Missing"}');

      final employeeId = widget.employeeData['id'];
      final apiUrl = 'https://erp.comsindia.in/api/employee/update/$employeeId';
      print('💾 DEBUG: API URL: $apiUrl');
      print('💾 DEBUG: Employee ID: $employeeId');

      var request = http.MultipartRequest('PUT', Uri.parse(apiUrl));

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['_method'] = 'PUT';

      if (_empNameController.text.trim().isNotEmpty) {
        request.fields['empName'] = _empNameController.text.trim();
      }
      if (_emailController.text.trim().isNotEmpty) {
        request.fields['email'] = _emailController.text.trim();
      }
      if (_phoneController.text.trim().isNotEmpty) {
        request.fields['phone'] = _phoneController.text.trim();
      }
      request.fields['gender'] = _selectedGender;
      if (_dobController.text.trim().isNotEmpty) {
        request.fields['date_of_birth'] = _dobController.text.trim();
      }
      if (_hireDateController.text.trim().isNotEmpty) {
        request.fields['hire_date'] = _hireDateController.text.trim();
      }
      request.fields['marital_status'] = _selectedMaritalStatus;
      request.fields['blood_group'] = _selectedBloodGroup;
      request.fields['religion'] = _selectedReligion;
      request.fields['joining_mode'] = _selectedJoiningMode;
      if (_punchingCodeController.text.trim().isNotEmpty) {
        request.fields['punching_code'] = _punchingCodeController.text.trim();
      }
      if (_emergencyContactController.text.trim().isNotEmpty) {
        request.fields['emergency_contact'] =
            _emergencyContactController.text.trim();
      }
      if (_contactPersonNameController.text.trim().isNotEmpty) {
        request.fields['contactPersionName'] =
            _contactPersonNameController.text.trim();
      }
      if (_emergencyContactRelationController.text.trim().isNotEmpty) {
        request.fields['emergency_contact_relation'] =
            _emergencyContactRelationController.text.trim();
      }

      if (_selectedDepartmentId != null) {
        request.fields['department_id'] = _selectedDepartmentId.toString();
      }
      if (_selectedDesignationId != null) {
        request.fields['designation_id'] = _selectedDesignationId.toString();
      }
      if (_selectedLocationId != null) {
        request.fields['location'] = _selectedLocationId.toString();
      }
      if (_selectedSiteId != null) {
        request.fields['site_id[0]'] = _selectedSiteId.toString();
      }

      if (_presentAddress.isNotEmpty) {
        if (_presentAddress.length > 0 && _presentAddress[0].isNotEmpty) {
          request.fields['present_address[0][street]'] = _presentAddress[0];
        }
        if (_presentAddress.length > 1 && _presentAddress[1].isNotEmpty) {
          request.fields['present_address[0][city]'] = _presentAddress[1];
        }
        if (_presentAddress.length > 2 && _presentAddress[2].isNotEmpty) {
          request.fields['present_address[0][district]'] = _presentAddress[2];
        }
        if (_presentAddress.length > 3 && _presentAddress[3].isNotEmpty) {
          request.fields['present_address[0][post_office]'] =
              _presentAddress[3];
        }
        if (_presentAddress.length > 4 && _presentAddress[4].isNotEmpty) {
          request.fields['present_address[0][thana]'] = _presentAddress[4];
        }
        if (_presentAddress.length > 5 && _presentAddress[5].isNotEmpty) {
          request.fields['present_address[0][pincode]'] = _presentAddress[5];
        }
      }

      if (_permanentAddress.isNotEmpty) {
        if (_permanentAddress.length > 0 && _permanentAddress[0].isNotEmpty) {
          request.fields['permanent_address[0][street]'] = _permanentAddress[0];
        }
        if (_permanentAddress.length > 1 && _permanentAddress[1].isNotEmpty) {
          request.fields['permanent_address[0][city]'] = _permanentAddress[1];
        }
        if (_permanentAddress.length > 2 && _permanentAddress[2].isNotEmpty) {
          request.fields['permanent_address[0][district]'] =
              _permanentAddress[2];
        }
        if (_permanentAddress.length > 3 && _permanentAddress[3].isNotEmpty) {
          request.fields['permanent_address[0][post_office]'] =
              _permanentAddress[3];
        }
        if (_permanentAddress.length > 4 && _permanentAddress[4].isNotEmpty) {
          request.fields['permanent_address[0][thana]'] = _permanentAddress[4];
        }
        if (_permanentAddress.length > 5 && _permanentAddress[5].isNotEmpty) {
          request.fields['permanent_address[0][pincode]'] =
              _permanentAddress[5];
        }
      }

      for (int i = 0; i < _familyMembers.length; i++) {
        final member = _familyMembers[i];
        if (member['name'] != null && member['name'].toString().isNotEmpty) {
          request.fields['FamilyMembName[$i]'] = member['name'].toString();
        }
        if (member['relation'] != null &&
            member['relation'].toString().isNotEmpty) {
          request.fields['relation[$i]'] = member['relation'].toString();
        }
        if (member['occupation'] != null &&
            member['occupation'].toString().isNotEmpty) {
          request.fields['occupation[$i]'] = member['occupation'].toString();
        }
        if (member['dob'] != null && member['dob'].toString().isNotEmpty) {
          request.fields['dob[$i]'] = member['dob'].toString();
        }
      }

      for (int i = 0; i < _educationList.length; i++) {
        final education = _educationList[i];
        if (education['degree'] != null &&
            education['degree'].toString().isNotEmpty) {
          request.fields['education[$i][degree]'] =
              education['degree'].toString();
        }
        if (education['university'] != null &&
            education['university'].toString().isNotEmpty) {
          request.fields['education[$i][university]'] =
              education['university'].toString();
        }
        if (education['specialization'] != null &&
            education['specialization'].toString().isNotEmpty) {
          request.fields['education[$i][specialization]'] =
              education['specialization'].toString();
        }
        if (education['from_year'] != null &&
            education['from_year'].toString().isNotEmpty) {
          request.fields['education[$i][from_year]'] =
              education['from_year'].toString();
        }
        if (education['to_year'] != null &&
            education['to_year'].toString().isNotEmpty) {
          request.fields['education[$i][to_year]'] =
              education['to_year'].toString();
        }
        if (education['percentage'] != null &&
            education['percentage'].toString().isNotEmpty) {
          request.fields['education[$i][percentage]'] =
              education['percentage'].toString();
        }
      }

      if (_aadharController.text.trim().isNotEmpty) {
        request.fields['aadhar'] = _aadharController.text.trim();
      }
      if (_panController.text.trim().isNotEmpty) {
        request.fields['pan'] = _panController.text.trim();
      }
      if (_bankNameController.text.trim().isNotEmpty) {
        request.fields['bank_name'] = _bankNameController.text.trim();
      }
      if (_bankAccountController.text.trim().isNotEmpty) {
        request.fields['bank_account'] = _bankAccountController.text.trim();
      }
      if (_ifscCodeController.text.trim().isNotEmpty) {
        request.fields['ifsc_code'] = _ifscCodeController.text.trim();
      }
      if (_remarksController.text.trim().isNotEmpty) {
        request.fields['remarks'] = _remarksController.text.trim();
      }

      for (int i = 0; i < _epfNominees.length; i++) {
        final nominee = _epfNominees[i];
        if (nominee['name'] != null && nominee['name'].toString().isNotEmpty) {
          request.fields['epf[$i][name]'] = nominee['name'].toString();
        }
        if (nominee['address'] != null &&
            nominee['address'].toString().isNotEmpty) {
          request.fields['epf[$i][address]'] = nominee['address'].toString();
        }
        if (nominee['relationship'] != null &&
            nominee['relationship'].toString().isNotEmpty) {
          request.fields['epf[$i][relationship]'] =
              nominee['relationship'].toString();
        }
        if (nominee['dob'] != null && nominee['dob'].toString().isNotEmpty) {
          request.fields['epf[$i][dob]'] = nominee['dob'].toString();
        }
        if (nominee['share'] != null &&
            nominee['share'].toString().isNotEmpty) {
          request.fields['epf[$i][share]'] = nominee['share'].toString();
        }
        if (nominee['guardian'] != null &&
            nominee['guardian'].toString().isNotEmpty) {
          request.fields['epf[$i][guardian]'] = nominee['guardian'].toString();
        }
      }

      for (int i = 0; i < _epsNominees.length; i++) {
        final nominee = _epsNominees[i];
        if (nominee['name'] != null && nominee['name'].toString().isNotEmpty) {
          request.fields['eps[$i][name]'] = nominee['name'].toString();
        }
        if (nominee['age'] != null && nominee['age'].toString().isNotEmpty) {
          request.fields['eps[$i][age]'] = nominee['age'].toString();
        }
        if (nominee['relationship'] != null &&
            nominee['relationship'].toString().isNotEmpty) {
          request.fields['eps[$i][relationship]'] =
              nominee['relationship'].toString();
        }
      }

      if (_witness1NameController.text.trim().isNotEmpty) {
        request.fields['witness_1_name'] = _witness1NameController.text.trim();
      }
      if (_witness2NameController.text.trim().isNotEmpty) {
        request.fields['witness_2_name'] = _witness2NameController.text.trim();
      }

      if (_insuranceNoController.text.trim().isNotEmpty) {
        request.fields['insurance_no'] = _insuranceNoController.text.trim();
      }
      if (_branchOfficeController.text.trim().isNotEmpty) {
        request.fields['branch_office'] = _branchOfficeController.text.trim();
      }
      if (_dispensaryController.text.trim().isNotEmpty) {
        request.fields['dispensary'] = _dispensaryController.text.trim();
      }

      for (int i = 0; i < _familyMembersList.length; i++) {
        final member = _familyMembersList[i];
        if (member['name'] != null && member['name'].toString().isNotEmpty) {
          request.fields['family[$i][name]'] = member['name'].toString();
        }
        if (member['dob'] != null && member['dob'].toString().isNotEmpty) {
          request.fields['family[$i][dob]'] = member['dob'].toString();
        }
        if (member['relation'] != null &&
            member['relation'].toString().isNotEmpty) {
          request.fields['family[$i][relation]'] =
              member['relation'].toString();
        }
        if (member['residing'] != null &&
            member['residing'].toString().isNotEmpty) {
          request.fields['family[$i][residing]'] =
              member['residing'].toString();
        }
        if (member['residence'] != null &&
            member['residence'].toString().isNotEmpty) {
          request.fields['family[$i][residence]'] =
              member['residence'].toString();
        }
      }

      request.fields['pf_member'] = _selectedPfMember;
      request.fields['pension_member'] = _selectedPensionMember;
      if (_uanNumberController.text.trim().isNotEmpty) {
        request.fields['uan_number'] = _uanNumberController.text.trim();
      }
      if (_previousPfNumberController.text.trim().isNotEmpty) {
        request.fields['previous_pf_number'] =
            _previousPfNumberController.text.trim();
      }

      request.fields['international_worker'] = _selectedInternationalWorker;
      if (_countryOrigin.isNotEmpty) {
        request.fields['country_origin'] = _countryOrigin;
      }

      request.fields['ESIC'] = _selectedEsic;

      print('💾 DEBUG: Form data prepared successfully');
      print('💾 DEBUG: Form fields count: ${request.fields.length}');
      print('💾 DEBUG: Form files count: ${request.files.length}');
      print('💾 DEBUG: Key fields: ${request.fields.keys.toList()}');

      print('📡 DEBUG: Making HTTP multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 DEBUG: HTTP request completed');
      print('📡 DEBUG: Response status code: ${response.statusCode}');
      print('📡 DEBUG: Response headers: ${response.headers}');
      print('📡 DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ DEBUG: API request successful');
        final responseData = json.decode(response.body);
        print('✅ DEBUG: Response data: $responseData');

        if (responseData['status'] == 'success') {
          print('🎉 DEBUG: Employee update successful!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          print('❌ DEBUG: API returned non-success status');
          throw Exception(
              responseData['message'] ?? 'Failed to update employee');
        }
      } else {
        print(
            '❌ DEBUG: HTTP request failed with status: ${response.statusCode}');
        print('❌ DEBUG: Error response body: ${response.body}');
        throw Exception('Failed to update employee: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: Exception occurred during save: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating employee: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      print('💾 DEBUG: Loading state set to false');
    }
  }

  @override
  void dispose() {
    print('🧹 DEBUG: EmployeeEditPage dispose started');
    print('🧹 DEBUG: Cleaning up controllers and resources...');

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

    print('🧹 DEBUG: All controllers disposed');
    super.dispose();
    print('🧹 DEBUG: EmployeeEditPage dispose completed');
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
      _buildTextField(
        controller: _empNameController,
        label: 'Employee Name',
        validator: (value) => _validateRequired(value, 'Employee Name'),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _emailController,
        label: 'Email',
        // validator: _validateEmail,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _phoneController,
        label: 'Phone',
        validator: _validatePhone,
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null ? 'Gender is required' : null,
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
                labelText: 'Date of Birth *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _validateDate(value, 'Date of Birth'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().subtract(const Duration(days: 365 * 18)),
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
                labelText: 'Hire Date *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _validateDate(value, 'Hire Date'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1980),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
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
                labelText: 'Marital Status *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null ? 'Marital status is required' : null,
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
            child: TextFormField(
              initialValue: _selectedReligion,
              decoration: const InputDecoration(
                labelText: 'Religion *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _validateRequired(value, 'Religion'),
              onChanged: (value) => _selectedReligion = value,
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildContactSection() {
    return _buildSection('Emergency Contact', [
      _buildTextField(
        controller: _contactPersonNameController,
        label: 'Contact Person Name',
        validator: (value) => _validateRequired(value, 'Contact Person Name'),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _emergencyContactController,
        label: 'Emergency Contact',
        keyboardType: TextInputType.phone,
        validator: (value) => _validateRequired(value, 'Emergency Contact'),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _emergencyContactRelationController,
        label: 'Relation',
        validator: (value) => _validateRequired(value, 'Relation'),
      ),
    ]);
  }

  Widget _buildAddressSection() {
    return _buildSection('Address Information', [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Present Address',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _presentAddress.isNotEmpty ? _presentAddress[0] : '',
            decoration: const InputDecoration(
              labelText: 'Street *',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validateRequired(value, 'Street'),
            onChanged: (value) {
              if (_presentAddress.isEmpty) {
                _presentAddress = ['', ''];
              }
              _presentAddress[0] = value;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _presentAddress.length > 1 ? _presentAddress[1] : '',
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (_presentAddress.isEmpty) {
                _presentAddress = ['', ''];
              } else if (_presentAddress.length == 1) {
                _presentAddress.add('');
              }
              _presentAddress[1] = value;
            },
          ),
        ],
      ),
      const SizedBox(height: 20),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Permanent Address',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue:
                _permanentAddress.isNotEmpty ? _permanentAddress[0] : '',
            decoration: const InputDecoration(
              labelText: 'Street *',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validateRequired(value, 'Street'),
            onChanged: (value) {
              if (_permanentAddress.isEmpty) {
                _permanentAddress = ['', ''];
              }
              _permanentAddress[0] = value;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue:
                _permanentAddress.length > 1 ? _permanentAddress[1] : '',
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (_permanentAddress.isEmpty) {
                _permanentAddress = ['', ''];
              } else if (_permanentAddress.length == 1) {
                _permanentAddress.add('');
              }
              _permanentAddress[1] = value;
            },
          ),
        ],
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
                labelText: 'Aadhar Number *',
                border: OutlineInputBorder(),
              ),
              validator: _validateAadhar,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _panController,
              decoration: const InputDecoration(
                labelText: 'PAN Number *',
                border: OutlineInputBorder(),
              ),
              validator: _validatePan,
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildBankDetailsSection() {
    return _buildSection('Bank Details', [
      _buildTextField(
        controller: _bankNameController,
        label: 'Bank Name',
        validator: (value) => _validateRequired(value, 'Bank Name'),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _bankAccountController,
        label: 'Account Number',
        keyboardType: TextInputType.number,
        validator: _validateBankAccount,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _ifscCodeController,
        label: 'IFSC Code',
        validator: _validateIfsc,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveEmployee,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildEmploymentSection() {
    return _buildSection('Employment Details', [
      _buildDropdownField<DepartmentData>(
        label: 'Department *',
        value: _departments.cast<DepartmentData?>().firstWhere(
              (dept) => dept?.id == _selectedDepartmentId,
              orElse: () => null,
            ),
        items: _departments,
        itemBuilder: (dept) => dept.name,
        onChanged: _onDepartmentChanged,
        placeholder: 'Select Department',
        isLoading: _isLoadingDepartments,
        isRequired: true,
      ),
      const SizedBox(height: 12),
      _buildDropdownField<DesignationData>(
        label: 'Designation *',
        value: _availableDesignations.cast<DesignationData?>().firstWhere(
              (designation) => designation?.id == _selectedDesignationId,
              orElse: () => null,
            ),
        items: _availableDesignations,
        itemBuilder: (designation) => designation.name,
        onChanged: (value) =>
            setState(() => _selectedDesignationId = value?.id),
        placeholder: 'Select Designation',
        isLoading: false,
        isRequired: true,
      ),
      const SizedBox(height: 12),
      _buildDropdownField<SiteData>(
        label: 'Site *',
        value: _sites.cast<SiteData?>().firstWhere(
              (site) => site?.id == _selectedSiteId,
              orElse: () => null,
            ),
        items: _sites,
        itemBuilder: (site) => site.name,
        onChanged: _onSiteChanged,
        placeholder: 'Select Site',
        isLoading: _isLoadingSites,
        isRequired: true,
      ),
      const SizedBox(height: 12),
      _buildDropdownField<LocationData>(
        label: 'Location *',
        value: _locations.cast<LocationData?>().firstWhere(
              (location) => location?.id == _selectedLocationId,
              orElse: () => null,
            ),
        items: _locations,
        itemBuilder: (location) => location.name,
        onChanged: _onLocationChanged,
        placeholder: 'Select Location',
        isLoading: _isLoadingLocations,
        isRequired: true,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _punchingCodeController,
        label: 'Punching Code',
        validator: null,
      ),
      const SizedBox(height: 12),
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

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemBuilder,
    required void Function(T?) onChanged,
    required String placeholder,
    required bool isLoading,
    bool isRequired = false,
  }) {
    print('🎨 DEBUG: Building dropdown for $label');
    print('🎨 DEBUG: Current value: $value');
    print('🎨 DEBUG: Items count: ${items.length}');
    print('🎨 DEBUG: Is loading: $isLoading');
    print('🎨 DEBUG: Is required: $isRequired');

    if (items.isNotEmpty) {
      print('🎨 DEBUG: Available items:');
      for (var item in items) {
        print('🎨 DEBUG: - ${itemBuilder(item)}');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
          items: isLoading
              ? []
              : items.map<DropdownMenuItem<T>>((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemBuilder(item),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
          onChanged: isLoading
              ? null
              : (T? newValue) {
                  print(
                      '🎨 DEBUG: $label dropdown changed from $value to $newValue');
                  onChanged(newValue);
                },
          validator: isRequired
              ? (value) {
                  if (value == null) {
                    print(
                        '❌ DEBUG: Validation failed for $label - value is null');
                    return '$label is required';
                  }
                  print('✅ DEBUG: Validation passed for $label');
                  return null;
                }
              : null,
          hint: isLoading
              ? Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text('Loading $placeholder...'),
                  ],
                )
              : Text(placeholder),
        ),
      ],
    );
  }

  Widget _buildEPFSection() {
    return _buildSection('EPF/EPS Details', [
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPfMember,
              decoration: const InputDecoration(
                labelText: 'PF Member *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null ? 'PF member status is required' : null,
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
                labelText: 'Pension Member *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null ? 'Pension member status is required' : null,
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
      const SizedBox(height: 12),
      _buildTextField(
        controller: _uanNumberController,
        label: 'UAN Number',
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _previousPfNumberController,
        label: 'Previous PF Number',
        validator: (value) =>
            _selectedPfMember == 'yes' && (value?.isEmpty == true)
                ? 'Previous PF Number is required when PF member is yes'
                : null,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _witness1NameController,
        label: 'Witness 1 Name',
        validator: (value) => _validateRequired(value, 'Witness 1 Name'),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _witness2NameController,
        label: 'Witness 2 Name',
        validator: (value) => _validateRequired(value, 'Witness 2 Name'),
      ),
      const SizedBox(height: 20),
      const Text(
        'EPF Nominee Details',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: _epfNominees.isNotEmpty && _epfNominees[0]['name'] != null
            ? _epfNominees[0]['name']
            : 'EPF Nominee',
        decoration: const InputDecoration(
          labelText: 'Name *',
          border: OutlineInputBorder(),
        ),
        validator: (value) => _validateRequired(value, ''),
        onChanged: (value) {
          if (_epfNominees.isEmpty) {
            _epfNominees = [{}];
          }
          _epfNominees[0]['name'] = value;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue:
            _epfNominees.isNotEmpty && _epfNominees[0]['address'] != null
                ? _epfNominees[0]['address']
                : '78 Colony, XYZ City',
        decoration: const InputDecoration(
          labelText: 'Address *',
          border: OutlineInputBorder(),
        ),
        validator: (value) => _validateRequired(value, 'EPF Nominee Address'),
        onChanged: (value) {
          if (_epfNominees.isEmpty) {
            _epfNominees = [{}];
          }
          _epfNominees[0]['address'] = value;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue:
            _epfNominees.isNotEmpty && _epfNominees[0]['relationship'] != null
                ? _epfNominees[0]['relationship']
                : 'Father',
        decoration: const InputDecoration(
          labelText: 'Relationship *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            _validateRequired(value, 'EPF Nominee Relationship'),
        onChanged: (value) {
          if (_epfNominees.isEmpty) {
            _epfNominees = [{}];
          }
          _epfNominees[0]['relationship'] = value;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue: _epfNominees.isNotEmpty && _epfNominees[0]['dob'] != null
            ? _epfNominees[0]['dob']
            : '1970-05-10',
        decoration: const InputDecoration(
          labelText: 'Date of Birth *',
          border: OutlineInputBorder(),
        ),
        validator: (value) => _validateDate(value, 'EPF Nominee Date of Birth'),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate:
                DateTime.now().subtract(const Duration(days: 365 * 18)),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            final formattedDate =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            if (_epfNominees.isEmpty) {
              _epfNominees = [{}];
            }
            _epfNominees[0]['dob'] = formattedDate;
            setState(() {});
          }
        },
        readOnly: true,
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue:
            _epfNominees.isNotEmpty && _epfNominees[0]['share'] != null
                ? _epfNominees[0]['share']
                : '50%',
        decoration: const InputDecoration(
          labelText: 'Share *',
          border: OutlineInputBorder(),
        ),
        validator: (value) => _validateRequired(value, 'EPF Nominee Share'),
        onChanged: (value) {
          if (_epfNominees.isEmpty) {
            _epfNominees = [{}];
          }
          _epfNominees[0]['share'] = value;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue:
            _epfNominees.isNotEmpty && _epfNominees[0]['guardian'] != null
                ? _epfNominees[0]['guardian']
                : 'N/A',
        decoration: const InputDecoration(
          labelText: 'Guardian',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (_epfNominees.isEmpty) {
            _epfNominees = [{}];
          }
          _epfNominees[0]['guardian'] = value;
        },
      ),
      const SizedBox(height: 20),
      const Text(
        'EPS Nominee Details',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: _epsNominees.isNotEmpty && _epsNominees[0]['name'] != null
            ? _epsNominees[0]['name']
            : 'EPS Nominee',
        decoration: const InputDecoration(
          labelText: 'Name *',
          border: OutlineInputBorder(),
        ),
        validator: (value) => _validateRequired(value, ''),
        onChanged: (value) {
          if (_epsNominees.isEmpty) {
            _epsNominees = [{}];
          }
          _epsNominees[0]['name'] = value;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue: _epsNominees.isNotEmpty && _epsNominees[0]['age'] != null
            ? _epsNominees[0]['age'].toString()
            : '45',
        decoration: const InputDecoration(
          labelText: 'Age *',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Age is required';
          }
          final age = int.tryParse(value);
          if (age == null) {
            return 'Please enter a valid number';
          }
          if (age < 0 || age > 120) {
            return 'Age must be between 0 and 120';
          }
          return null;
        },
        onChanged: (value) {
          if (_epsNominees.isEmpty) {
            _epsNominees = [{}];
          }
          _epsNominees[0]['age'] = int.tryParse(value) ?? 0;
        },
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue:
            _epsNominees.isNotEmpty && _epsNominees[0]['relationship'] != null
                ? _epsNominees[0]['relationship']
                : 'Mother',
        decoration: const InputDecoration(
          labelText: 'Relationship *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            _validateRequired(value, 'EPS Nominee Relationship'),
        onChanged: (value) {
          if (_epsNominees.isEmpty) {
            _epsNominees = [{}];
          }
          _epsNominees[0]['relationship'] = value;
        },
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
      _buildTextField(
        controller: _insuranceNoController,
        label: 'Insurance Number',
        isRequired: false,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _branchOfficeController,
        label: 'Branch Office',
        isRequired: false,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _dispensaryController,
        label: 'Dispensary',
        isRequired: false,
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
      _buildUploadableImageRow(
        'Employee Photo',
        emp['employee_image_path'],
        _selectedEmployeeImage,
        () => _pickImage('employee_photo'),
      ),
      const SizedBox(height: 16),
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
        await Future.microtask(() async {
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
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                          cacheWidth: 400,
                          cacheHeight: 400,
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
                            Icons.image_not_supported_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Image not available',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please upload a new image',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
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

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // String? _validateEmail(String? value) {
  //   if (value == null || value.trim().isEmpty) {
  //     return 'Email is required';
  //   }
  //   final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  //   if (!emailRegex.hasMatch(value)) {
  //     return 'Please enter a valid email address';
  //   }
  //   return null;
  // }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (value.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Phone number must contain only digits';
    }
    return null;
  }

  String? _validateAadhar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aadhar number is required';
    }
    if (value.length != 12) {
      return 'Aadhar number must be 12 digits';
    }
    return null;
  }

  String? _validatePan(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PAN number is required';
    }
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegex.hasMatch(value)) {
      return 'Please enter a valid PAN number (e.g., ABCDE1234F)';
    }
    return null;
  }

  String? _validateDate(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    try {
      final date = DateTime.parse(value);
      if (fieldName == 'Date of Birth' && date.isAfter(DateTime.now())) {
        return 'Date of birth cannot be in the future';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid date in YYYY-MM-DD format';
    }
  }

  String? _validateBankAccount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bank account number is required';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Bank account must contain only digits';
    }
    return null;
  }

  String? _validateIfsc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IFSC code is required';
    }
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscRegex.hasMatch(value)) {
      return 'Please enter a valid IFSC code (e.g., HDFC0001234)';
    }
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator ??
            (isRequired ? (value) => _validateRequired(value, label) : null),
        keyboardType: keyboardType,
      ),
    );
  }

  void _onDepartmentChanged(DepartmentData? department) {
    print(
        '🏢 DEBUG: Department changed to: ${department?.name} (ID: ${department?.id})');
    setState(() {
      _selectedDepartmentId = department?.id;
      _selectedDesignationId = null;
      _availableDesignations = department?.designations ?? [];
    });
    print(
        '🏢 DEBUG: Available designations updated: ${_availableDesignations.length} designations');
    for (var designation in _availableDesignations) {
      print(
          '🏢 DEBUG: Designation - ID: ${designation.id}, Name: ${designation.name}');
    }
  }

  void _onLocationChanged(LocationData? location) {
    print(
        '📍 DEBUG: Location changed to: ${location?.name} (ID: ${location?.id})');
    setState(() {
      _selectedLocationId = location?.id;
    });
    print('📍 DEBUG: Selected location ID updated to: $_selectedLocationId');
  }

  void _onSiteChanged(SiteData? site) {
    print('🏗️ DEBUG: Site changed to: ${site?.name} (ID: ${site?.id})');
    setState(() {
      _selectedSiteId = site?.id;
    });
    print('🏗️ DEBUG: Selected site ID updated to: $_selectedSiteId');
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
    if (index < _familyMembers.length) {
      setState(() {
        _familyMembers.removeAt(index);
        if (index < _familyNameControllers.length) {
          _familyNameControllers[index].dispose();
          _familyNameControllers.removeAt(index);
        }
        if (index < _familyRelationControllers.length) {
          _familyRelationControllers[index].dispose();
          _familyRelationControllers.removeAt(index);
        }
        if (index < _familyOccupationControllers.length) {
          _familyOccupationControllers[index].dispose();
          _familyOccupationControllers.removeAt(index);
        }
        if (index < _familyDobControllers.length) {
          _familyDobControllers[index].dispose();
          _familyDobControllers.removeAt(index);
        }
      });
    }
  }
}

class DepartmentData {
  final int id;
  final String name;
  final List<DesignationData> designations;

  DepartmentData({
    required this.id,
    required this.name,
    required this.designations,
  });

  factory DepartmentData.fromJson(Map<String, dynamic> json) {
    return DepartmentData(
      id: json['id'] ?? 0,
      name: json['department_name'] ?? '',
      designations: (json['designations'] as List<dynamic>?)
              ?.map((d) => DesignationData.fromJson(d))
              .toList() ??
          [],
    );
  }
}

class DesignationData {
  final int id;
  final String name;

  DesignationData({
    required this.id,
    required this.name,
  });

  factory DesignationData.fromJson(Map<String, dynamic> json) {
    return DesignationData(
      id: json['id'] ?? 0,
      name: json['designation_name'] ?? '',
    );
  }
}

class SiteData {
  final int id;
  final String name;

  SiteData({
    required this.id,
    required this.name,
  });

  factory SiteData.fromJson(Map<String, dynamic> json) {
    return SiteData(
      id: json['id'] ?? 0,
      name: json['site_name'] ?? '',
    );
  }
}

class LocationData {
  final int id;
  final String name;

  LocationData({
    required this.id,
    required this.name,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      id: json['id'] ?? 0,
      name: json['location_name'] ?? '',
    );
  }
}
