import 'dart:convert';
import 'dart:io';
import 'package:coms_india/core/di/service_locator.dart';
import 'package:coms_india/core/services/api_service.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class Designation {
  final int id;
  final String name;
  Designation({required this.id, required this.name});
  factory Designation.fromJson(Map<String, dynamic> json) =>
      Designation(id: json['id'] ?? 0, name: json['designation_name'] ?? '');
}

class DepartmentData {
  final int id;
  final String name;
  final List<Designation> designations;
  DepartmentData(
      {required this.id, required this.name, required this.designations});
  factory DepartmentData.fromJson(Map<String, dynamic> json) {
    var list = json['designations'] as List? ?? [];
    List<Designation> dList = list.map((i) => Designation.fromJson(i)).toList();
    return DepartmentData(
        id: json['id'] ?? 0,
        name: json['department_name'] ?? '',
        designations: dList);
  }
}

class SiteData {
  final int id;
  final String name;
  SiteData({required this.id, required this.name});
  factory SiteData.fromJson(Map<String, dynamic> json) =>
      SiteData(id: json['id'] ?? 0, name: json['site_name'] ?? '');
}

class LocationData {
  final int id;
  final String name;
  LocationData({required this.id, required this.name});
  factory LocationData.fromJson(Map<String, dynamic> json) =>
      LocationData(id: json['id'] ?? 0, name: json['location_name'] ?? '');
}

class EmployeeEditPage extends StatefulWidget {
  final int userId;
  final String employeeName;

  EmployeeEditPage({
    Key? key,
    required this.userId,
    required this.employeeName,
  }) : super(key: key);

  @override
  State<EmployeeEditPage> createState() => _EmployeeEditPageState();
}

class _EmployeeEditPageState extends State<EmployeeEditPage> {
  bool _isDataInitialized = false;

  late Map<String, dynamic> _employeeData;

  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  final ApiService _apiService = getIt<ApiService>();

  late TextEditingController _nameController,
      _dobController,
      _hireDateController,
      _phoneController,
      _emailController,
      _emergencyContactController,
      _emergencyPersonController,
      _emergencyRelationController,
      _aadharController,
      _panController,
      _bankNameController,
      _bankAccountController,
      _ifscCodeController,
      _punchingCodeController,
      _uanNumberController,
      _previousPfNumberController,
      _witness1NameController,
      _witness2NameController,
      _remarksController;

  String? _gender,
      _maritalStatus,
      _joiningMode,
      _pfMemberStatus,
      _pensionMemberStatus,
      _bloodgroup,
      _internationalWorkerStatus,
      _employeeRelegion;

  bool _isLoadingDepartments = false,
      _isLoadingSites = false,
      _isLoadingLocations = false;
  List<DepartmentData> _departments = [];
  List<Designation> _designations = [];
  List<SiteData> _sites = [];
  List<LocationData> _locations = [];

  List<String> religion = ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Other'];
  List<String> bloodGroupsList = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  int? _selectedDepartmentId,
      _selectedDesignationId,
      _selectedSiteId,
      _selectedLocationId;

  late TextEditingController _presentStreetController,
      _presentCityController,
      _presentDistrictController,
      _presentPincodeController,
      _presentPostOfficeController,
      _presentThanaController;
  late TextEditingController _permanentStreetController,
      _permanentCityController,
      _permanentDistrictController,
      _permanentPincodeController,
      _permanentPostOfficeController,
      _permanentThanaController;
  List<Map<String, TextEditingController>> _familyMembers = [],
      _educationList = [],
      _epfNominees = [],
      _epsNominees = [];
  File? _employeeImageFile,
      _aadharFrontFile,
      _aadharBackFile,
      _panFile,
      _bankDocumentFile,
      _signatureThumbFile,
      _witness1SignatureFile,
      _witness2SignatureFile;

  @override
  void initState() {
    super.initState();
    _initializeEmptyControllers();
    fetchEmployeeDetails(widget.userId);
    _loadDepartments();
    _loadSites();
    _loadLocations();
    _addEpfNominee(); // Ensure one EPF nominee is always present
    _addEpsNominee(); // Ensure one EPS nominee is added
  }

  void _initializeEmptyControllers() {
    _nameController = TextEditingController();
    _dobController = TextEditingController();
    _hireDateController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _emergencyPersonController = TextEditingController();
    _emergencyRelationController = TextEditingController();
    _aadharController = TextEditingController();
    _panController = TextEditingController();
    _bankNameController = TextEditingController();
    _bankAccountController = TextEditingController();
    _ifscCodeController = TextEditingController();
    _punchingCodeController = TextEditingController();
    _uanNumberController = TextEditingController();
    _previousPfNumberController = TextEditingController();
    _witness1NameController = TextEditingController();
    _witness2NameController = TextEditingController();
    _remarksController = TextEditingController();
    _presentStreetController = TextEditingController();
    _presentCityController = TextEditingController();
    _presentDistrictController = TextEditingController();
    _presentPincodeController = TextEditingController();
    _presentPostOfficeController = TextEditingController();
    _presentThanaController = TextEditingController();
    _permanentStreetController = TextEditingController();
    _permanentCityController = TextEditingController();
    _permanentDistrictController = TextEditingController();
    _permanentPincodeController = TextEditingController();
    _permanentPostOfficeController = TextEditingController();
    _permanentThanaController = TextEditingController();
  }

  Future<void> fetchEmployeeDetails(int userId) async {
    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token'];

    final url = Uri.parse('https://erp.comsindia.in/api/employee/$userId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == true && jsonData['employee'] != null) {
          setState(() {
            _employeeData = jsonData['employee'];
            _initializeControllersWithData();
            _isDataInitialized = true;
          });
        } else {
          print('API returned success=false or missing data');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(jsonData['message'] ?? 'Failed to load data.'),
              backgroundColor: Colors.red));
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Failed to load employee details. Status: ${response.statusCode}'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      print('Error fetching employee: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('An error occurred: $e'), backgroundColor: Colors.red));
    }
  }

  void _initializeControllersWithData() {
    final data = _employeeData;
    final user = data['user'] as Map<String, dynamic>;
    final site_id = user['emp_assign_site']?.isNotEmpty == true
        ? user['emp_assign_site'][0]['site_id']
        : null;
    final location_id = data['location_id'];

    _nameController.text = user['name'] ?? '';
    _dobController.text = data['date_of_birth'] ?? '';
    _hireDateController.text = data['hire_date'] ?? '';
    _phoneController.text = user['phone'] ?? '';
    _emailController.text = user['email'] ?? '';
    _emergencyContactController.text = data['emergency_contact'] ?? '';
    _emergencyPersonController.text = data['contactPersionName'] ?? '';
    _emergencyRelationController.text =
        data['emergency_contact_relation'] ?? '';
    _aadharController.text = data['aadhar'] ?? '';
    _panController.text = data['pan'] ?? '';
    _bankNameController.text = data['bank_name'] ?? '';
    _bankAccountController.text = data['bank_account'] ?? '';
    _ifscCodeController.text = data['ifsc_code'] ?? '';
    _punchingCodeController.text = data['punching_code'] ?? '';
    _uanNumberController.text = data['uan_number'] ?? '';
    _previousPfNumberController.text = data['previous_pf_number'] ?? '';
    _witness1NameController.text = data['witness_1_name'] ?? '';
    _witness2NameController.text = data['witness_2_name'] ?? '';
    _remarksController.text = data['remarks'] ?? '';

    _gender = data['gender'];
    _maritalStatus = data['marital_status'];
    _bloodgroup = data['blood_group'];
    _employeeRelegion = data['religion'];
    _joiningMode = data['joining_mode'];
    _pfMemberStatus = data['pf_member'];
    _pensionMemberStatus = data['pension_member'];
    _internationalWorkerStatus = data['international_worker'];
    _selectedDepartmentId = data['department_id'] != null
        ? int.tryParse(data['department_id'].toString())
        : null;
    _selectedDesignationId = data['designation_id'] != null
        ? int.tryParse(data['designation_id'].toString())
        : null;
    _selectedSiteId = site_id != null ? int.tryParse(site_id.toString()) : null;
    _selectedLocationId =
        location_id != null ? int.parse(location_id.toString()) : null;

    _initializeAddressControllers();
    _initializeFamilyMembers();
    _initializeEducationList();
    _initializeEpfNominees();
    _initializeEpsNominees();
  }

  void _initializeAddressControllers() {
    final data = _employeeData;
    List<dynamic> presentAddr = [];
    List<dynamic> permanentAddr = [];

    try {
      final pAddrData = data['present_address'];
      if (pAddrData != null) {
        presentAddr = pAddrData is String ? json.decode(pAddrData) : pAddrData;
      }
    } catch (e) {
      print("Could not parse present address: $e");
    }

    try {
      final permAddrData = data['permanent_address'];
      if (permAddrData != null) {
        permanentAddr =
            permAddrData is String ? json.decode(permAddrData) : permAddrData;
      }
    } catch (e) {
      print("Could not parse permanent address: $e");
    }

    Map<String, dynamic> presentAddrMap =
        presentAddr.isNotEmpty ? Map<String, dynamic>.from(presentAddr[0]) : {};
    Map<String, dynamic> permanentAddrMap = permanentAddr.isNotEmpty
        ? Map<String, dynamic>.from(permanentAddr[0])
        : {};

    _presentStreetController.text = presentAddrMap['street'] ?? '';
    _presentCityController.text = presentAddrMap['city'] ?? '';
    _presentDistrictController.text = presentAddrMap['district'] ?? '';
    _presentPincodeController.text =
        presentAddrMap['pincode']?.toString() ?? '';
    _presentPostOfficeController.text = presentAddrMap['post_office'] ?? '';
    _presentThanaController.text = presentAddrMap['thana'] ?? '';

    _permanentStreetController.text = permanentAddrMap['street'] ?? '';
    _permanentCityController.text = permanentAddrMap['city'] ?? '';
    _permanentDistrictController.text = permanentAddrMap['district'] ?? '';
    _permanentPincodeController.text =
        permanentAddrMap['pincode']?.toString() ?? '';
    _permanentPostOfficeController.text = permanentAddrMap['post_office'] ?? '';
    _permanentThanaController.text = permanentAddrMap['thana'] ?? '';
  }

  void _initializeFamilyMembers() {
    try {
      if (_employeeData['FamilyMembername'] == null) return;
      final n =
          json.decode(_employeeData['FamilyMembername'] as String) as List;
      final r = json.decode(_employeeData['relation'] as String) as List;
      final o = json.decode(_employeeData['occupation'] as String) as List;
      final d = json.decode(_employeeData['dob'] as String) as List;
      _familyMembers.clear();
      for (int i = 0; i < n.length; i++) {
        _familyMembers.add({
          'name': TextEditingController(text: n.length > i ? n[i] ?? '' : ''),
          'relation':
              TextEditingController(text: r.length > i ? r[i] ?? '' : ''),
          'occupation':
              TextEditingController(text: o.length > i ? o[i] ?? '' : ''),
          'dob': TextEditingController(text: d.length > i ? d[i] ?? '' : '')
        });
      }
    } catch (e) {
      print("Could not parse family members: $e");
    }
  }

  void _initializeEducationList() {
    try {
      if (_employeeData['education'] == null ||
          _employeeData['education'] is! String) return;
      final ed = json.decode(_employeeData['education'] as String) as List;
      _educationList.clear();
      for (var e in ed) {
        _educationList.add({
          'degree': TextEditingController(text: e['degree'] ?? ''),
          'university': TextEditingController(text: e['university'] ?? ''),
          'specialization':
              TextEditingController(text: e['specialization'] ?? ''),
          'from_year': TextEditingController(text: e['from_year'] ?? ''),
          'to_year': TextEditingController(text: e['to_year'] ?? ''),
          'percentage':
              TextEditingController(text: e['percentage']?.toString() ?? '')
        });
      }
    } catch (e) {
      print("Could not parse education list: $e");
    }
  }

  void _initializeEpfNominees() {
    try {
      if (_employeeData['epf_nominees'] == null ||
          _employeeData['epf_nominees'] is! String) return;
      final n = json.decode(_employeeData['epf_nominees'] as String) as List;
      _epfNominees.clear();
      for (var nom in n) {
        _epfNominees.add({
          'name': TextEditingController(text: nom['name'] ?? ''),
          'address': TextEditingController(text: nom['address'] ?? ''),
          'relationship':
              TextEditingController(text: nom['relationship'] ?? ''),
          'dob': TextEditingController(text: nom['dob'] ?? ''),
          'share': TextEditingController(text: nom['share']?.toString() ?? ''),
          'guardian': TextEditingController(text: nom['guardian'] ?? '')
        });
      }
    } catch (e) {
      print("Could not parse EPF nominees: $e");
    }
  }

  void _initializeEpsNominees() {
    try {
      if (_employeeData['eps_nominees'] == null ||
          _employeeData['eps_nominees'] is! String) return;
      final n = json.decode(_employeeData['eps_nominees'] as String) as List;
      _epsNominees.clear();
      for (var nom in n) {
        _epsNominees.add({
          'name': TextEditingController(text: nom['name'] ?? ''),
          'age': TextEditingController(text: nom['age']?.toString() ?? ''),
          'relationship': TextEditingController(text: nom['relationship'] ?? '')
        });
      }
    } catch (e) {
      print("Could not parse EPS nominees: $e");
    }
  }

  Future<void> _loadDepartments() async {
    try {
      setState(() => _isLoadingDepartments = true);
      final r = await _apiService.getDepartments();
      if (r.statusCode == 200 && r.data['status'] == true) {
        final List<dynamic> dJ = r.data['data'];
        _departments = dJ.map((j) => DepartmentData.fromJson(j)).toList();
        if (_selectedDepartmentId != null) {
          final sD = _departments.firstWhere(
              (d) => d.id == _selectedDepartmentId,
              orElse: () => _departments.first);
          _designations = sD.designations;
        }
      }
    } catch (e) {
      print('❌ Error loading departments: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDepartments = false);
      }
    }
  }

  Future<void> _loadSites() async {
    try {
      setState(() => _isLoadingSites = true);
      final r = await _apiService.getSites();
      if (r.statusCode == 200 && r.data['status'] == true) {
        final List<dynamic> sJ = r.data['data'];
        _sites = sJ.map((j) => SiteData.fromJson(j)).toList();
      }
    } catch (e) {
      print('❌ DEBUG: Error loading sites: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSites = false);
      }
    }
  }

  Future<void> _loadLocations() async {
    try {
      setState(() => _isLoadingLocations = true);
      final r = await _apiService.getLocations();
      if (r.statusCode == 200 && r.data['status'] == true) {
        final List<dynamic> lJ = r.data['data'];
        _locations = lJ.map((j) => LocationData.fromJson(j)).toList();
        final iLN = _employeeData['location'];
        if (iLN != null) {
          try {
            final iL = _locations.firstWhere((l) => l.name == iLN);
            _selectedLocationId = iL.id;
          } catch (e) {
            print("Could not find initial location '$iLN' in the list.");
          }
        }
      }
    } catch (e) {
      print('❌ DEBUG: Error loading locations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _updateEmployeeDetails() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isLoading = true);
    final token = await _storageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Authentication error. Please log in again.'),
          backgroundColor: Colors.red));
      setState(() => _isLoading = false);
      return;
    }

    final formData = FormData();
    formData.fields.add(const MapEntry('_method', 'PUT'));

    formData.fields.addAll([
      MapEntry('empName', _nameController.text),
      MapEntry('gender', _gender ?? ""),
      MapEntry('date_of_birth', _dobController.text),
      MapEntry('hire_date', _hireDateController.text),
      MapEntry('marital_status', _maritalStatus ?? ""),
      MapEntry('blood_group', _bloodgroup ?? ""),
      MapEntry('religion', _employeeRelegion ?? ""),
      MapEntry('remarks', _remarksController.text),
    ]);

    for (int i = 0; i < _familyMembers.length; i++) {
      formData.fields.addAll([
        MapEntry('FamilyMembName[$i]', _familyMembers[i]['name']!.text),
        MapEntry('relation[$i]', _familyMembers[i]['relation']!.text),
        MapEntry('occupation[$i]', _familyMembers[i]['occupation']!.text),
        MapEntry('dob[$i]', _familyMembers[i]['dob']!.text),
      ]);
    }

    formData.fields.addAll([
      MapEntry('department_id', _selectedDepartmentId?.toString() ?? ""),
      MapEntry('designation_id', _selectedDesignationId?.toString() ?? ""),
      MapEntry('site_id[0]', _selectedSiteId?.toString() ?? ""),
      MapEntry('location', _selectedLocationId?.toString() ?? ""),
      MapEntry('joining_mode', _joiningMode ?? ""),
      MapEntry('punching_code', _punchingCodeController.text),
    ]);

    formData.fields.addAll([
      MapEntry('phone', _phoneController.text),
      MapEntry('email', _emailController.text),
      MapEntry('emergency_contact', _emergencyContactController.text),
      MapEntry('contactPersionName', _emergencyPersonController.text),
      MapEntry('emergency_contact_relation', _emergencyRelationController.text),
    ]);

    formData.fields.addAll([
      MapEntry('present_address[0][street]', _presentStreetController.text),
      MapEntry('present_address[0][city]', _presentCityController.text),
      MapEntry('present_address[0][district]', _presentDistrictController.text),
      MapEntry(
          'present_address[0][post_office]', _presentPostOfficeController.text),
      MapEntry('present_address[0][thana]', _presentThanaController.text),
      MapEntry('present_address[0][pincode]', _presentPincodeController.text),
      MapEntry('permanent_address[0][street]', _permanentStreetController.text),
      MapEntry('permanent_address[0][city]', _permanentCityController.text),
      MapEntry(
          'permanent_address[0][district]', _permanentDistrictController.text),
      MapEntry('permanent_address[0][post_office]',
          _permanentPostOfficeController.text),
      MapEntry('permanent_address[0][thana]', _permanentThanaController.text),
      MapEntry(
          'permanent_address[0][pincode]', _permanentPincodeController.text),
    ]);

    for (int i = 0; i < _educationList.length; i++) {
      formData.fields.addAll([
        MapEntry('education[$i][degree]', _educationList[i]['degree']!.text),
        MapEntry(
            'education[$i][university]', _educationList[i]['university']!.text),
        MapEntry('education[$i][specialization]',
            _educationList[i]['specialization']!.text),
        MapEntry(
            'education[$i][from_year]', _educationList[i]['from_year']!.text),
        MapEntry('education[$i][to_year]', _educationList[i]['to_year']!.text),
        MapEntry(
            'education[$i][percentage]', _educationList[i]['percentage']!.text),
      ]);
    }

    formData.fields.addAll([
      MapEntry('aadhar', _aadharController.text),
      MapEntry('pan', _panController.text),
      MapEntry('bank_name', _bankNameController.text),
      MapEntry('bank_account', _bankAccountController.text),
      MapEntry('ifsc_code', _ifscCodeController.text),
    ]);

    formData.fields.addAll([
      MapEntry('witness_1_name', _witness1NameController.text),
      MapEntry('witness_2_name', _witness2NameController.text),
      MapEntry('pf_member', _pfMemberStatus ?? "no"),
      MapEntry('pension_member', _pensionMemberStatus ?? "no"),
      MapEntry('uan_number', _uanNumberController.text),
      MapEntry('previous_pf_number', _previousPfNumberController.text),
      MapEntry('international_worker', _internationalWorkerStatus ?? "no"),
    ]);
    String emptyIfNull(TextEditingController? controller) {
      if (controller == null) return '';
      final text = controller.text.trim();
      return text.isEmpty ? '' : text;
    }

    for (int i = 0; i < _epfNominees.length; i++) {
      final nominee = _epfNominees[i];

      formData.fields.addAll([
        MapEntry('epf[$i][name]', emptyIfNull(nominee['name'])),
        MapEntry('epf[$i][address]', emptyIfNull(nominee['address'])),
        MapEntry('epf[$i][relationship]', emptyIfNull(nominee['relationship'])),
        MapEntry('epf[$i][dob]', emptyIfNull(nominee['dob'])),
        MapEntry('epf[$i][share]', emptyIfNull(nominee['share'])),
        MapEntry('epf[$i][guardian]', emptyIfNull(nominee['guardian'])),
      ]);
    }

    for (int i = 0; i < _epsNominees.length; i++) {
      final name = emptyIfNull(_epsNominees[i]['name']);
      final age = emptyIfNull(_epsNominees[i]['age']);
      final relationship = emptyIfNull(_epsNominees[i]['relationship']);

      formData.fields.addAll([
        MapEntry('eps[$i][name]', name),
        MapEntry('eps[$i][age]', age),
        MapEntry('eps[$i][relationship]', relationship),
      ]);
    }

    formData.fields.addAll([
      MapEntry('insurance_no', ''),
      MapEntry('branch_office', ''),
      MapEntry('dispensary', ''),
      MapEntry('family', ''),
      MapEntry('exit_date', ''),
      MapEntry('scheme_certificate', ''),
      MapEntry('ppo', ''),
      MapEntry('country_origin', ''),
      MapEntry('passport_number', ''),
      MapEntry('passport_valid_from', ''),
      MapEntry('passport_valid_to', ''),
      MapEntry('previous_employment', ''),
    ]);

    if (_employeeImageFile != null) {
      formData.files.add(MapEntry(
        'employee_image',
        await MultipartFile.fromFile(_employeeImageFile!.path),
      ));
    }
    if (_aadharFrontFile != null) {
      formData.files.add(MapEntry(
        'aadhar_front',
        await MultipartFile.fromFile(_aadharFrontFile!.path),
      ));
    }
    if (_aadharBackFile != null) {
      formData.files.add(MapEntry(
        'aadhar_back',
        await MultipartFile.fromFile(_aadharBackFile!.path),
      ));
    }
    if (_panFile != null) {
      formData.files.add(MapEntry(
        'pan_file',
        await MultipartFile.fromFile(_panFile!.path),
      ));
    }
    if (_bankDocumentFile != null) {
      formData.files.add(MapEntry(
        'bank_document',
        await MultipartFile.fromFile(_bankDocumentFile!.path),
      ));
    }
    if (_signatureThumbFile != null) {
      formData.files.add(MapEntry(
        'signature_thumb',
        await MultipartFile.fromFile(_signatureThumbFile!.path),
      ));
    }
    if (_witness1SignatureFile != null) {
      formData.files.add(MapEntry(
        'witness_1_signature',
        await MultipartFile.fromFile(_witness1SignatureFile!.path),
      ));
    }
    if (_witness2SignatureFile != null) {
      formData.files.add(MapEntry(
        'witness_2_signature',
        await MultipartFile.fromFile(_witness2SignatureFile!.path),
      ));
    }

    try {
      final dio = Dio();
      final response = await dio.post(
          'https://erp.comsindia.in/api/employee/update/${widget.userId}',
          data: formData,
          options: Options(headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token'
          }));
      if (response.statusCode == 200 && response.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Employee updated successfully!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(response.data['message']?.toString() ??
                'Failed to update employee.'),
            backgroundColor: Colors.red));
      }
    } on DioException catch (e) {
      String errorMessage = 'An unknown error occurred.';
      if (e.response != null) {
        print("DioError Response Data: ${e.response?.data}");
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'];
          if (responseData.containsKey('errors')) {
            final errors = responseData['errors'] as Map;
            errorMessage +=
                '\n${errors.entries.map((me) => '${me.key}: ${me.value.join(', ')}').join('\n')}';
          }
        } else {
          errorMessage = (e.response?.data.toString() ?? e.message)!;
        }
      } else {
        errorMessage = e.message ?? "Network request failed.";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage, maxLines: 10),
          backgroundColor: Colors.red));
    } catch (e) {
      print("Generic Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('A critical error occurred: $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> jMItems = ['interview', 'online', 'offline', 'other'];
    if (_joiningMode != null && !jMItems.contains(_joiningMode)) {
      jMItems.add(_joiningMode!);
    }
    return Scaffold(
      appBar: AppBar(
          title: Text('Edit ${widget.employeeName}'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white),
      body: !_isDataInitialized
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Personal Information'),
                    _buildTextField(_nameController, 'Full Name'),
                    _buildDateField(_dobController, 'Date of Birth'),
                    _buildDropdownField(
                        'Gender',
                        _gender,
                        ['male', 'female', 'other'],
                        (v) => setState(() => _gender = v)),
                    _buildDropdownField(
                        'Marital Status',
                        _maritalStatus,
                        ['married', 'unmarried', 'divorced'],
                        (v) => setState(() => _maritalStatus = v)),
                    _buildDropdownField(
                        'Blood Group',
                        _bloodgroup,
                        bloodGroupsList,
                        (v) => setState(() => _bloodgroup = v)),
                    _buildDropdownField('Religion', _employeeRelegion, religion,
                        (v) => setState(() => _employeeRelegion = v)),
                    _buildSectionHeader('Official Information'),
                    _buildDateField(_hireDateController, 'Hire Date'),
                    _buildTextField(_punchingCodeController, 'Punching Code'),
                    _buildDepartmentDropdown(),
                    _buildDesignationDropdown(),
                    _buildSiteDropdown(),
                    _buildLocationDropdown(),
                    _buildDropdownField('Joining Mode', _joiningMode, jMItems,
                        (v) => setState(() => _joiningMode = v)),
                    _buildDropdownField(
                        'International Worker?',
                        _internationalWorkerStatus,
                        ['yes', 'no'],
                        (v) => setState(() => _internationalWorkerStatus = v)),
                    _buildSectionHeader('Contact & Address'),
                    _buildTextField(_phoneController, 'Phone',
                        keyboardType: TextInputType.phone),
                    _buildTextField(_emailController, 'Email',
                        keyboardType: TextInputType.emailAddress),
                    _buildTextField(
                        _emergencyContactController, 'Emergency Contact No.'),
                    _buildTextField(
                        _emergencyPersonController, 'Emergency Contact Person'),
                    _buildTextField(_emergencyRelationController,
                        'Emergency Contact Relation'),
                    _buildSectionHeader('Present Address'),
                    _buildTextField(_presentStreetController, 'Street'),
                    _buildTextField(_presentCityController, 'City'),
                    _buildTextField(_presentDistrictController, 'District'),
                    _buildTextField(
                        _presentPostOfficeController, 'Post Office'),
                    _buildTextField(
                        _presentThanaController, 'Thana (Police Station)'),
                    _buildTextField(_presentPincodeController, 'Pincode',
                        keyboardType: TextInputType.number),
                    _buildSectionHeader('Permanent Address'),
                    _buildTextField(_permanentStreetController, 'Street'),
                    _buildTextField(_permanentCityController, 'City'),
                    _buildTextField(_permanentDistrictController, 'District'),
                    _buildTextField(
                        _permanentPostOfficeController, 'Post Office'),
                    _buildTextField(
                        _permanentThanaController, 'Thana (Police Station)'),
                    _buildTextField(_permanentPincodeController, 'Pincode',
                        keyboardType: TextInputType.number),
                    _buildSectionHeader('Bank Details'),
                    _buildTextField(_bankNameController, 'Bank Name'),
                    _buildTextField(
                        _bankAccountController, 'Bank Account Number'),
                    _buildTextField(_ifscCodeController, 'IFSC Code'),
                    _buildSectionHeader('Family Members'),
                    ..._buildFamilyMemberFields(),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Member'),
                            onPressed: _addFamilyMember)),
                    _buildSectionHeader('Education'),
                    ..._buildEducationFields(),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Education'),
                            onPressed: _addEducation)),
                    _buildEpfSection(),
                    _buildSectionHeader('Remarks'),
                    _buildTextField(_remarksController, 'Remarks',
                        isMultiLine: true),
                    _buildSectionHeader('Documents & Files'),
                    _buildTextField(_aadharController, 'Aadhar Number'),
                    _buildTextField(_panController, 'PAN Number'),
                    _buildFilePicker("Employee Image", _employeeImageFile,
                        (f) => setState(() => _employeeImageFile = f)),
                    _buildFilePicker("Aadhar Front", _aadharFrontFile,
                        (f) => setState(() => _aadharFrontFile = f)),
                    _buildFilePicker("Aadhar Back", _aadharBackFile,
                        (f) => setState(() => _aadharBackFile = f)),
                    _buildFilePicker("PAN Card", _panFile,
                        (f) => setState(() => _panFile = f)),
                    _buildFilePicker("Bank Document", _bankDocumentFile,
                        (f) => setState(() => _bankDocumentFile = f)),
                    _buildFilePicker("Signature/Thumb", _signatureThumbFile,
                        (f) => setState(() => _signatureThumbFile = f)),
                    _buildFilePicker(
                        "Witness 1 Signature",
                        _witness1SignatureFile,
                        (f) => setState(() => _witness1SignatureFile = f)),
                    _buildFilePicker(
                        "Witness 2 Signature",
                        _witness2SignatureFile,
                        (f) => setState(() => _witness2SignatureFile = f)),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Update Employee'),
                              onPressed: _updateEmployeeDetails,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16)))),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0)
          .copyWith(top: 24),
      child: Text(title,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
    );
  }

  Widget _buildTextField(TextEditingController c, String l,
      {TextInputType? keyboardType,
      String? Function(String?)? validator,
      bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: isMultiLine ? null : 1,
        decoration: InputDecoration(
            labelText: l,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true),
      ),
    );
  }

  Widget _buildDateField(TextEditingController c, String l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
          controller: c,
          decoration: InputDecoration(
              labelText: l,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today)),
          readOnly: true,
          onTap: () async {
            DateTime? d = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(c.text) ?? DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime.now().add(const Duration(days: 365)));
            if (d != null) {
              c.text =
                  "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
            }
          }),
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue,
      List<String> items, ValueChanged<String?> onChanged) {
    final uniqueItems = items.toSet().toList();
    final validValue =
        uniqueItems.contains(selectedValue) ? selectedValue : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: uniqueItems
            .map((s) => DropdownMenuItem<String>(
                  value: s,
                  child: Text(s[0].toUpperCase() + s.substring(1)),
                ))
            .toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? 'Please select an option' : null,
      ),
    );
  }

  Widget _buildLocationDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<int>(
          value: _selectedLocationId ?? 0,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: 'Location',
              border: const OutlineInputBorder(),
              suffixIcon: _isLoadingLocations
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : null),
          items: _locations
              .map((LocationData loc) => DropdownMenuItem<int>(
                  value: loc.id,
                  child: Text(loc.name, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (int? v) => setState(() => _selectedLocationId = v),
          validator: (v) => v == null ? 'Please select a Location' : null),
    );
  }

  Widget _buildSiteDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<int>(
          value: _selectedSiteId,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: 'Site',
              border: const OutlineInputBorder(),
              suffixIcon: _isLoadingSites
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : null),
          items: _sites
              .map((SiteData s) => DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (int? v) => setState(() => _selectedSiteId = v),
          validator: (v) => v == null ? 'Please select a Site' : null),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<int>(
          value: _selectedDepartmentId,
          decoration: InputDecoration(
              labelText: 'Department',
              border: const OutlineInputBorder(),
              suffixIcon: _isLoadingDepartments
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : null),
          items: _departments
              .map((DepartmentData d) =>
                  DropdownMenuItem<int>(value: d.id, child: Text(d.name)))
              .toList(),
          onChanged: (int? v) {
            setState(() {
              _selectedDepartmentId = v;
              _selectedDesignationId = null;
              if (v != null) {
                _designations =
                    _departments.firstWhere((d) => d.id == v).designations;
              } else {
                _designations = [];
              }
            });
          },
          validator: (v) => v == null ? 'Please select a Department' : null),
    );
  }

  Widget _buildDesignationDropdown() {
    final designationItems = _designations
        .map((Designation d) =>
            DropdownMenuItem<int>(value: d.id, child: Text(d.name)))
        .toList();

    // Add a default "Select designation" item
    designationItems.insert(
      0,
      const DropdownMenuItem<int>(
        value: 0,
        child: Text('Select designation'),
      ),
    );

    // Ensure selected value is valid
    final isValidValue =
        _designations.any((d) => d.id == _selectedDesignationId);
    final dropdownValue = isValidValue ? _selectedDesignationId : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<int>(
        value: dropdownValue,
        decoration: InputDecoration(
          labelText: 'Designation',
          border: const OutlineInputBorder(),
          hintText: _selectedDepartmentId == null
              ? 'Select a department first'
              : 'Select designation',
        ),
        onChanged: _selectedDepartmentId == null
            ? null
            : (int? v) => setState(() => _selectedDesignationId = v),
        items: designationItems,
        validator: (v) =>
            (v == null || v == 0) ? 'Please select a Designation' : null,
      ),
    );
  }

  List<Widget> _buildFamilyMemberFields() {
    return List.generate(
      _familyMembers.length,
      (i) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Member ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _removeFamilyMember(i))
                    ]),
                _buildTextField(_familyMembers[i]['name']!, 'Name'),
                _buildTextField(_familyMembers[i]['relation']!, 'Relation'),
                _buildTextField(_familyMembers[i]['occupation']!, 'Occupation'),
                _buildDateField(_familyMembers[i]['dob']!, 'Date of Birth')
              ]))),
    );
  }

  void _addFamilyMember() {
    setState(() {
      _familyMembers.add({
        'name': TextEditingController(),
        'relation': TextEditingController(),
        'occupation': TextEditingController(),
        'dob': TextEditingController()
      });
    });
  }

  void _removeFamilyMember(int i) {
    _familyMembers[i].forEach((k, c) => c.dispose());
    setState(() => _familyMembers.removeAt(i));
  }

  List<Widget> _buildEducationFields() {
    return List.generate(
      _educationList.length,
      (i) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Education #${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _removeEducation(i))
                    ]),
                _buildTextField(_educationList[i]['degree']!, 'Degree/Course'),
                _buildTextField(
                    _educationList[i]['university']!, 'University/Board'),
                _buildTextField(
                    _educationList[i]['specialization']!, 'Specialization'),
                Row(children: [
                  Expanded(
                      child: _buildTextField(
                          _educationList[i]['from_year']!, 'From',
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTextField(
                          _educationList[i]['to_year']!, 'To',
                          keyboardType: TextInputType.number)),
                ]),
                _buildTextField(
                    _educationList[i]['percentage']!, 'Percentage/CGPA',
                    keyboardType: TextInputType.number)
              ]))),
    );
  }

  void _addEducation() {
    setState(() {
      _educationList.add({
        'degree': TextEditingController(),
        'university': TextEditingController(),
        'specialization': TextEditingController(),
        'from_year': TextEditingController(),
        'to_year': TextEditingController(),
        'percentage': TextEditingController()
      });
    });
  }

  void _removeEducation(int i) {
    _educationList[i].forEach((k, c) => c.dispose());
    setState(() => _educationList.removeAt(i));
  }

  Widget _buildEpfSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('EPF/EPS Details'),
      Row(children: [
        Expanded(
            child: _buildDropdownField('PF Member', _pfMemberStatus,
                ['yes', 'no'], (v) => setState(() => _pfMemberStatus = v))),
        const SizedBox(width: 12),
        Expanded(
            child: _buildDropdownField('Pension Member', _pensionMemberStatus,
                ['yes', 'no'], (v) => setState(() => _pensionMemberStatus = v)))
      ]),
      _buildTextField(_uanNumberController, 'UAN Number',
          validator: (v) => null),
      _buildTextField(_previousPfNumberController, 'Previous PF Number',
          validator: (v) => null),
      _buildTextField(_witness1NameController, 'Witness 1 Name'),
      _buildTextField(_witness2NameController, 'Witness 2 Name'),
      ..._buildEpfNomineeFields(),
      Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add EPF Nominee'),
              onPressed: _addEpfNominee)),
      ..._buildEpsNomineeFields(),
      Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add EPS Nominee'),
              onPressed: _addEpsNominee))
    ]);
  }

  List<Widget> _buildEpfNomineeFields() {
    return List.generate(
      _epfNominees.length,
      (i) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('EPF Nominee #${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _removeEpfNominee(i))
                    ]),
                _buildTextField(_epfNominees[i]['name']!, 'Name'),
                _buildTextField(_epfNominees[i]['address']!, 'Address'),
                _buildTextField(
                    _epfNominees[i]['relationship']!, 'Relationship'),
                _buildDateField(_epfNominees[i]['dob']!, 'Date of Birth'),
                _buildTextField(_epfNominees[i]['share']!, 'Share (%)',
                    keyboardType: TextInputType.number),
                _buildTextField(
                    _epfNominees[i]['guardian']!, 'Guardian (if minor)',
                    validator: (v) => null)
              ]))),
    );
  }

  void _addEpfNominee() {
    if (_epfNominees.isEmpty) {
      setState(() {
        _epfNominees.add({
          'name': TextEditingController(),
          'address': TextEditingController(),
          'relationship': TextEditingController(),
          'dob': TextEditingController(),
          'share': TextEditingController(),
          'guardian': TextEditingController()
        });
      });
    }
  }

  void _removeEpfNominee(int i) {
    _epfNominees[i].forEach((k, c) => c.dispose());
    setState(() => _epfNominees.removeAt(i));
  }

  List<Widget> _buildEpsNomineeFields() {
    return List.generate(
      _epsNominees.length,
      (i) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('EPS Nominee #${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _removeEpsNominee(i))
                    ]),
                _buildTextField(_epsNominees[i]['name']!, 'Name'),
                _buildTextField(_epsNominees[i]['age']!, 'Age',
                    keyboardType: TextInputType.number),
                _buildTextField(
                    _epsNominees[i]['relationship']!, 'Relationship')
              ]))),
    );
  }

  void _addEpsNominee() {
    if (_epsNominees.isEmpty) {
      setState(() {
        _epsNominees.add({
          'name': TextEditingController(text: ''),
          'age': TextEditingController(text: ''),
          'relationship': TextEditingController(text: ''),
        });
      });
    }
  }

  void _removeEpsNominee(int i) {
    _epsNominees[i].forEach((k, c) => c.dispose());
    setState(() => _epsNominees.removeAt(i));
  }

  Widget _buildFilePicker(
      String label, File? file, Function(File?) onFilePicked) {
    Future<void> pickImage() async {
      final p = ImagePicker();
      final f =
          await p.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (f != null) {
        onFilePicked(File(f.path));
      }
    }

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(children: [
          Expanded(
            flex: 3,
            child: Text(
              file == null ? label : 'Selected: ${file.path.split('/').last}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: pickImage,
            child: Text(file == null ? 'Select File' : 'Change'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
            ),
          )
        ]));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _hireDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    _emergencyPersonController.dispose();
    _emergencyRelationController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _ifscCodeController.dispose();
    _punchingCodeController.dispose();
    _uanNumberController.dispose();
    _previousPfNumberController.dispose();
    _witness1NameController.dispose();
    _witness2NameController.dispose();
    _remarksController.dispose();
    _presentStreetController.dispose();
    _presentCityController.dispose();
    _presentDistrictController.dispose();
    _presentPincodeController.dispose();
    _presentPostOfficeController.dispose();
    _presentThanaController.dispose();
    _permanentStreetController.dispose();
    _permanentCityController.dispose();
    _permanentDistrictController.dispose();
    _permanentPincodeController.dispose();
    _permanentPostOfficeController.dispose();
    _permanentThanaController.dispose();
    for (var m in _familyMembers) {
      m.forEach((k, c) => c.dispose());
    }
    for (var e in _educationList) {
      e.forEach((k, c) => c.dispose());
    }
    for (var e in _epfNominees) {
      e.forEach((k, c) => c.dispose());
    }
    for (var e in _epsNominees) {
      e.forEach((k, c) => c.dispose());
    }
    super.dispose();
  }
}
