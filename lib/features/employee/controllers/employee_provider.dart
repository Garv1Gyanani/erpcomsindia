import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import '../models/employee_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/di/service_locator.dart';

enum EmployeeStatus {
  initial,
  loading,
  success,
  error,
  idle,
}

class EmployeeProvider extends ChangeNotifier {
  EmployeeStatus _status = EmployeeStatus.initial;
  String? _errorMessage;
  EmployeeResponseModel? _response;

  final ApiService _apiService = getIt<ApiService>();

  bool _debugMode = kDebugMode;

  Map<String, dynamic> _allFormData = {};
  List<String> _debugLogs = [];

  Map<String, dynamic> _apiCallHistory = {};
  int _apiCallCount = 0;

  EmployeeStatus get status => _status;
  String? get errorMessage => _errorMessage;
  EmployeeResponseModel? get response => _response;
  Map<String, dynamic> get allFormData =>
      Map.from(_allFormData); // Defensive copy
  List<String> get debugLogs => List.from(_debugLogs); // Defensive copy
  bool get debugMode => _debugMode;
  Map<String, dynamic> get apiCallHistory => Map.from(_apiCallHistory);
  int get apiCallCount => _apiCallCount;

  bool get isLoading => _status == EmployeeStatus.loading;
  bool get isSuccess => _status == EmployeeStatus.success;
  bool get isError => _status == EmployeeStatus.error;

  void toggleDebugMode() {
    _debugMode = !_debugMode;
    _addDebugLog('Debug mode ${_debugMode ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  void _addDebugLog(String message) {
    if (_debugMode) {
      final timestamp = DateTime.now().toIso8601String();
      _debugLogs.add('[$timestamp] $message');
      print('🐛 DEBUG: $message');
    }
  }

  List<Map<String, dynamic>> _parseNestedList(dynamic source) {
    if (source == null) {
      return [];
    }

    try {
      if (source is String && source.isNotEmpty) {
        final decoded = json.decode(source);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(
              decoded.whereType<Map<String, dynamic>>());
        }
      } else if (source is List) {
        return List<Map<String, dynamic>>.from(
            source.whereType<Map<String, dynamic>>());
      }
    } catch (e) {
      print("Error parsing nested JSON data: $e. Source was: $source");
    }

    return [];
  }

  void clearDebugLogs() {
    _debugLogs.clear();
    notifyListeners();
  }

  void printCompleteDebugSummary() {
    print(
        '🐛 DEBUG: ============ COMPLETE DATA COLLECTION SUMMARY ============');
    print('🐛 DEBUG: Debug Mode: $_debugMode');
    print('🐛 DEBUG: Current Status: $_status');
    print(
        '🐛 DEBUG: Completion Percentage: ${getCompletionPercentage().toStringAsFixed(1)}%');
    print('🐛 DEBUG: Completed Screens: ${_allFormData.keys.length}/8');
    print('🐛 DEBUG: Screens: ${_allFormData.keys.join(', ')}');
    print('🐛 DEBUG: Missing Screens: ${getMissingScreens().join(', ')}');
    print('🐛 DEBUG: ');

    _allFormData.forEach((screenName, data) {
      print('🐛 DEBUG: [$screenName] Data:');
      if (data is Map<String, dynamic>) {
        data.forEach((key, value) {
          if (value is List) {
            print('🐛 DEBUG:   $key: ${value.length} items');
          } else if (value is String) {
            print('🐛 DEBUG:   $key: "${value.isEmpty ? 'EMPTY' : value}"');
          } else {
            print('🐛 DEBUG:   $key: $value');
          }
        });
      }
      print('🐛 DEBUG: ');
    });

    if (getCompletionPercentage() >= 100) {
      print('🐛 DEBUG: ✅ ALL SCREENS COMPLETED - READY FOR SINGLE API CALL!');
      print(
          '🐛 DEBUG: Call provider.createEmployeeFromCollectedData() to submit');

      final apiData = getFormattedDataForAPI();
      print(
          '🚀 DEBUG: Formatted data before FormData: $apiData'); // ADD THIS LINE

      print('🐛 DEBUG: API Data Summary: ${apiData.keys.length} fields ready');
      print('🐛 DEBUG: API Fields: ${apiData.keys.join(', ')}');
    } else {
      print('🐛 DEBUG: ⏳ Form completion in progress...');
      print(
          '🐛 DEBUG: Complete remaining screens to enable single API submission');
    }

    print('🐛 DEBUG: Total Debug Logs: ${_debugLogs.length}');
    print('🐛 DEBUG: ========================================================');
  }

  void updateFormData(String screenName, Map<String, dynamic> data) {
    print('📝 DEBUG: ===== UPDATING FORM DATA =====');
    print('📝 DEBUG: Screen: $screenName');
    print('📝 DEBUG: Data fields: ${data.keys.join(', ')}');

    // MERGE data instead of replacing
    if (_allFormData.containsKey(screenName)) {
      _allFormData[screenName]!.addAll(data); // Merge existing data
    } else {
      _allFormData[screenName] = data; // Create new entry if it doesn't exist
    }

    data.forEach((key, value) {
      if (value is List) {
        print('📝 DEBUG: $key: List with ${value.length} items');
      } else if (value is String) {
        print('📝 DEBUG: $key: "${value.isEmpty ? 'EMPTY' : value}"');
      } else {
        print('📝 DEBUG: $key: $value');
      }
    });

    final completion = getCompletionPercentage();
    final missing = getMissingScreens();
    print('📊 DEBUG: Overall completion: ${completion.toStringAsFixed(1)}%');
    print('📊 DEBUG: Completed screens: ${_allFormData.keys.join(', ')}');

    if (missing.isNotEmpty) {
      print('⏳ DEBUG: Missing screens: ${missing.join(', ')}');
    } else {
      print(
          '🎉 DEBUG: ALL SCREENS COMPLETED! Automatically triggering API submission...');
      Future.microtask(() async {
        await createEmployeeFromCollectedData();
      });
    }

    print('📝 DEBUG: ===============================');

    Future.microtask(() => notifyListeners());
  }

  Map<String, dynamic>? getScreenData(String screenName) {
    return _allFormData[screenName];
  }

  Map<String, dynamic> getFormattedDataForAPI() {
    final formattedData = <String, dynamic>{};

    print('🔄 DEBUG: ===== FORMATTING DATA FOR API (EXACT CURL FORMAT) =====');
    print(
        '🔄 DEBUG: Processing ${_allFormData.keys.length} screens for API format');

    if (_allFormData.containsKey('basic_info')) {
      final basicInfo = _allFormData['basic_info'] as Map<String, dynamic>;
      formattedData.addAll({
        'empName': basicInfo['name'] ?? 'User 3',
        'gender': basicInfo['gender'] ?? 'male',
        'date_of_birth': basicInfo['dob'] ?? '1990-01-01',
        'hire_date': basicInfo['doj'] ?? '2025-06-10',
        'marital_status': basicInfo['marital_status'] ?? 'married',
        'blood_group': basicInfo['blood_group'] ?? 'A+',
        'religion': basicInfo['religion'] ?? 'Hindu',
      });

      final familyMembers = basicInfo['family_members'] as List? ?? [];
      for (int i = 0; i < familyMembers.length; i++) {
        final member = familyMembers[i] as Map<String, dynamic>;
        formattedData['FamilyMembName[$i]'] = member['name'] ?? '';
        formattedData['relation[$i]'] = member['relation'] ?? '';
        formattedData['occupation[$i]'] = member['occupation'] ?? '';
        formattedData['dob[$i]'] = member['dob'] ?? '';
      }
    } else {
      formattedData.addAll({
        'empName': 'User 3',
        'gender': 'male',
        'date_of_birth': '1990-01-01',
        'hire_date': '2025-06-10',
        'marital_status': 'married',
        'blood_group': 'A+',
        'religion': 'Hindu',
        'FamilyMembName[0]': 'Jane Doe',
        'relation[0]': 'mother',
        'occupation[0]': 'Teacher',
        'dob[0]': '1992-01-01',
        'FamilyMembName[1]': 'suneeta',
        'relation[1]': 'Wife',
        'occupation[1]': 'Teacher',
        'dob[1]': '1992-01-01',
      });
    }

    if (_allFormData.containsKey('employment_details')) {
      print(
          '🔄 DEBUG: employment_details block is being executed!'); // ADD THIS LINE

      final empDetails =
          _allFormData['employment_details'] as Map<String, dynamic>;
      formattedData.addAll({
        'department_id': empDetails['department_id']?.toString() ?? '',
        'designation_id': empDetails['designation_id']?.toString() ?? '',
        'site_id': empDetails['site_id']?.toString() ?? '',
        'location': empDetails['location']?.toString() ?? '',
        'joining_mode': empDetails['joining_mode']?.toString() ?? '',
        'punching_code': empDetails['punching_code']?.toString() ?? '',
      });
    } else {
      formattedData.addAll({
        'department_id': '3',
        'designation_id': '3',
        'site_id': '1',
        'location': '1',
        'joining_mode': 'interview',
        'punching_code': '1234',
      });
    }

    if (_allFormData.containsKey('contact_details') &&
        _allFormData['contact_details'] != null) {
      final contactDetails =
          _allFormData['contact_details'] as Map<String, dynamic>;

      formattedData.addAll({
        'emergency_contact':
            contactDetails['emergency_contact']?.toString() ?? '9876543210',
        'contactPersionName':
            contactDetails['contact_person_name']?.toString() ?? 'Mike Doe',
        'emergency_contact_relation':
            contactDetails['emergency_contact_relation']?.toString() ??
                'Brother',
        'email': contactDetails['email']?.toString() ?? '',
        'phone': contactDetails['phone']?.toString() ?? '1131111111',
      });

      // Access the first element in the list
      final List<dynamic>? presentAddressList =
          contactDetails['present_address'] as List?;
      if (presentAddressList != null && presentAddressList.isNotEmpty) {
        final Map<String, dynamic> addressObject =
            presentAddressList[0] as Map<String, dynamic>;

        formattedData['present_address[0][street]'] =
            addressObject['street']?.toString() ?? '';
        formattedData['present_address[0][city]'] =
            addressObject['city']?.toString() ?? '';
        formattedData['present_address[0][district]'] =
            addressObject['district']?.toString() ?? '';
        formattedData['present_address[0][post_office]'] =
            addressObject['post_office']?.toString() ?? '';
        formattedData['present_address[0][thana]'] =
            addressObject['thana']?.toString() ?? '';
        formattedData['present_address[0][pincode]'] =
            addressObject['pincode']?.toString() ?? '';
      } else {
        formattedData['present_address[0][street]'] = '';
        formattedData['present_address[0][city]'] = '';
        formattedData['present_address[0][pincode]'] = '';
      }

      // Access the first element in the list
      final List<dynamic>? permanentAddressList =
          contactDetails['permanent_address'] as List?;
      if (permanentAddressList != null && permanentAddressList.isNotEmpty) {
        final Map<String, dynamic> addressObject =
            permanentAddressList[0] as Map<String, dynamic>;
        formattedData['permanent_address[0][street]'] =
            addressObject['street']?.toString() ?? '';
        formattedData['permanent_address[0][city]'] =
            addressObject['city']?.toString() ?? '';
        formattedData['permanent_address[0][district]'] =
            addressObject['district']?.toString() ?? '';
        formattedData['permanent_address[0][post_office]'] =
            addressObject['post_office']?.toString() ?? '';
        formattedData['permanent_address[0][thana]'] =
            addressObject['thana']?.toString() ?? '';
        formattedData['permanent_address[0][pincode]'] =
            addressObject['pincode']?.toString() ?? '';
      } else {
        formattedData['permanent_address[0][street]'] = '456 Secondary Rd';
        formattedData['permanent_address[0][city]'] = 'Default City 2';
        formattedData['permanent_address[0][pincode]'] = '654321';
      }
    } else {
      formattedData.addAll({
        'emergency_contact': '9876543210',
        'contactPersionName': 'Mike Doe',
        'emergency_contact_relation': 'Brother',
        'email': 'user@example.com',
        'phone': '1112223333',
        'present_address[0][street]': '123 Main St',
        'present_address[0][city]': 'Default City',
        'present_address[0][district]': 'Default District',
        'present_address[0][post_office]': 'Default PO',
        'present_address[0][thana]': 'Default Thana',
        'present_address[0][pincode]': '123456',
        'permanent_address[0][street]': '456 Secondary Rd',
        'permanent_address[0][city]': 'Default City 2',
        'permanent_address[0][district]': 'Default District 2',
        'permanent_address[0][post_office]': 'Default PO 2',
        'permanent_address[0][thana]': 'Default Thana 2',
        'permanent_address[0][pincode]': '654321',
      });
    }
    if (_allFormData.containsKey('education_details')) {
      final educationDetails =
          _allFormData['education_details'] as Map<String, dynamic>;
      final educationList = educationDetails['education'] as List? ?? [];

      for (int i = 0; i < educationList.length; i++) {
        final education = educationList[i] as Map<String, dynamic>;
        formattedData['education[$i][degree]'] = education['degree'] ?? '';
        formattedData['education[$i][university]'] =
            education['university'] ?? '';
        formattedData['education[$i][specialization]'] =
            education['specialization'] ?? '';
        formattedData['education[$i][from_year]'] =
            education['from_year'] ?? '';
        formattedData['education[$i][to_year]'] = education['to_year'] ?? '';
        formattedData['education[$i][percentage]'] =
            education['percentage'] ?? '';
      }
    } else {
      formattedData.addAll({
        'education[0][degree]': '',
        'education[0][university]': '',
        'education[0][specialization]': '',
        'education[0][from_year]': '',
        'education[0][to_year]': '',
        'education[0][percentage]': '',
        'education[1][degree]': '',
        'education[1][university]': '',
        'education[1][specialization]': '',
        'education[1][from_year]': '',
        'education[1][to_year]': '',
        'education[1][percentage]': '',
      });
    }

    if (_allFormData.containsKey('govt_bank_details')) {
      final govtDetails =
          _allFormData['govt_bank_details'] as Map<String, dynamic>;
      formattedData.addAll({
        'aadhar': govtDetails['aadhar'] ?? '',
        'pan': govtDetails['pan'] ?? '',
        'bank_name': govtDetails['bank_name'] ?? '',
        'bank_account': govtDetails['bank_account'] ?? '',
        'ifsc_code': govtDetails['ifsc_code'] ?? '',
        'remarks': govtDetails['remarks'] ?? '',
      });
    } else {
      formattedData.addAll({
        'aadhar': '',
        'pan': '',
        'bank_name': '',
        'bank_account': '',
        'ifsc_code': '',
        'remarks': '',
      });
    }

    if (_allFormData.containsKey('epf_declaration')) {
      final epfDetails =
          _allFormData['epf_declaration'] as Map<String, dynamic>;
      formattedData.addAll({
        'pf_member': epfDetails['pf_member']?.toString().toLowerCase() ?? '',
        'pension_member':
            epfDetails['pension_member']?.toString().toLowerCase() ?? '',
        'uan_number': epfDetails['uan_number'] ?? '',
        'previous_pf_number': epfDetails['previous_pf_number'] ?? '',
        'exit_date': epfDetails['exit_date'] ?? '2023-12-31',
        'scheme_certificate': epfDetails['scheme_certificate'] ?? '',
        'ppo': epfDetails['ppo'] ?? 'PPO67890',
        'international_worker':
            epfDetails['international_worker']?.toString().toLowerCase() ??
                'yes',
        'country_origin': epfDetails['country_origin'] ?? 'India',
        'passport_number': epfDetails['passport_number'] ?? 'M1234567',
        'passport_valid_from':
            epfDetails['passport_valid_from'] ?? '2020-01-01',
        'passport_valid_to': epfDetails['passport_valid_to'] ?? '2030-01-01',
      });

      final previousEmploymentList =
          epfDetails['previous_employment'] as List? ?? [];
      for (int i = 0; i < previousEmploymentList.length; i++) {
        final employment = previousEmploymentList[i] as Map<String, dynamic>;
        formattedData['previous_employment[$i][company_name]'] =
            employment['company_name'] ?? '';
        formattedData['previous_employment[$i][designation]'] =
            employment['designation'] ?? '';
        formattedData['previous_employment[$i][from_date]'] =
            employment['from_date'] ?? '';
        formattedData['previous_employment[$i][to_date]'] =
            employment['to_date'] ?? '';
        formattedData['previous_employment[$i][reason_for_leaving]'] =
            employment['reason_for_leaving'] ?? '';
      }
    } else {
      formattedData.addAll({
        'pf_member': 'yes',
        'pension_member': 'yes',
        'uan_number': '',
        'previous_pf_number': 'PF987654321',
        'exit_date': '2023-12-31',
        'scheme_certificate': 'SC12345',
        'ppo': 'PPO67890',
        'international_worker': 'yes',
        'country_origin': 'India',
        'passport_number': 'M1234567',
        'passport_valid_from': '2020-01-01',
        'passport_valid_to': '2030-01-01',
        'previous_employment[0][company_name]': ' ABC Ltd',
        'previous_employment[0][designation]': ' Developer',
        'previous_employment[0][from_date]': ' 2020-01-01',
        'previous_employment[0][to_date]': ' 2022-01-01',
        'previous_employment[0][reason_for_leaving]': ' for better option',
      });
    }

    if (_allFormData.containsKey('esic_declaration')) {
      final esicDetails =
          _allFormData['esic_declaration'] as Map<String, dynamic>;
      formattedData.addAll({
        'insurance_no': esicDetails['insurance_no'] ?? 'ESI12345',
        'branch_office': esicDetails['branch_office'] ?? 'Central Office',
        'dispensary': esicDetails['dispensary'] ?? 'City Health Center',
      });

      final familyList = esicDetails['family'] as List? ?? [];
      for (int i = 0; i < familyList.length; i++) {
        final family = familyList[i] as Map<String, dynamic>;
        formattedData['family[$i][name]'] = family['name'] ?? '';
        formattedData['family[$i][dob]'] = family['dob'] ?? '';
        formattedData['family[$i][relation]'] = family['relation'] ?? '';
        formattedData['family[$i][residing]'] = family['residing'] ?? '';
        formattedData['family[$i][residence]'] = family['residence'] ?? '';
      }
    } else {
      formattedData.addAll({
        'insurance_no': 'ESI12345',
        'branch_office': 'Central Office',
        'dispensary': 'City Health Center',
        'family[0][name]': 'Tommy Doe',
        'family[0][dob]': '2015-06-01',
        'family[0][relation]': 'Son',
        'family[0][residing]': 'Yes',
        'family[0][residence]': 'With Parents',
      });
    }

    if (_allFormData.containsKey('nomination_form')) {
      final nominationDetails =
          _allFormData['nomination_form'] as Map<String, dynamic>;
      formattedData.addAll({
        'witness_1_name': nominationDetails['witness1_name'] ?? 'Witness One',
        'witness_2_name': nominationDetails['witness2_name'] ?? 'Witness Two',
      });

      final epfList = nominationDetails['epf'] as List? ?? [];
      for (int i = 0; i < epfList.length; i++) {
        final epf = epfList[i] as Map<String, dynamic>;
        formattedData['epf[$i][name]'] = epf['name'] ?? '';
        formattedData['epf[$i][address]'] = epf['address'] ?? '';
        formattedData['epf[$i][relationship]'] = epf['relationship'] ?? '';
        formattedData['epf[$i][dob]'] = epf['dob'] ?? '1970-05-10';
        formattedData['epf[$i][share]'] = epf['share'] ?? '';
        formattedData['epf[$i][guardian]'] = epf['guardian'] ?? '';
      }

      final epsList = nominationDetails['eps'] as List? ?? [];
      for (int i = 0; i < epsList.length; i++) {
        final eps = epsList[i] as Map<String, dynamic>;
        formattedData['eps[$i][name]'] = eps['name'] ?? '';
        formattedData['eps[$i][age]'] = eps['age'] ?? '';
        formattedData['eps[$i][relationship]'] = eps['relationship'] ?? '';
      }

      final otherDocumentsList =
          nominationDetails['other_documents'] as List? ?? [];
      for (int i = 0; i < otherDocumentsList.length; i++) {
        final document = otherDocumentsList[i] as Map<String, dynamic>;
        formattedData['other_documents[$i][name]'] = document['name'] ?? '';
      }
    } else {
      formattedData.addAll({
        'witness_1_name': 'Witness One',
        'witness_2_name': 'Witness Two',
        'epf[0][name]': 'EPF Nominee',
        'epf[0][address]': '78 Colony, XYZ City',
        'epf[0][relationship]': 'Father',
        'epf[0][dob]': '1970-05-10',
        'epf[0][share]': '50%',
        'epf[0][guardian]': 'N/A',
        'epf[1][name]': 'EPF Nominee',
        'epf[1][address]': '78 Colony, XYZ City',
        'epf[1][relationship]': 'Father',
        'epf[1][dob]': '1970-05-10',
        'epf[1][share]': '50%',
        'epf[1][guardian]': 'N/A',
        'eps[0][name]': 'EPS Nominee',
        'eps[0][age]': '45',
        'eps[0][relationship]': 'Mother',
        'other_documents[0][name]': ' Experience Letter',
      });
    }

    print('✅ DEBUG: EXACT CURL FORMAT - ${formattedData.keys.length} fields');
    print('✅ DEBUG: REQUIRED FIELDS:');
    print('✅ DEBUG: department_id = ${formattedData['department_id']}');
    print('✅ DEBUG: designation_id = ${formattedData['designation_id']}');
    print('✅ DEBUG: site_id = ${formattedData['site_id']}');
    print('✅ DEBUG: location = ${formattedData['location']}');
    print('✅ DEBUG: joining_mode = ${formattedData['joining_mode']}');
    print('🔄 DEBUG: ===== END EXACT CURL FORMAT =====');

    return formattedData;
  }

  double getCompletionPercentage() {
    const totalScreens = 8;
    final completedScreens = _allFormData.keys.length;
    final percentage = (completedScreens / totalScreens) * 100;

    _addDebugLog(
        'Completion: $completedScreens/$totalScreens screens (${percentage.toStringAsFixed(1)}%)');
    return percentage;
  }

  List<String> getMissingScreens() {
    const allScreens = [
      'basic_info',
      'employment_details',
      'contact_details',
      'education_details',
      'govt_bank_details',
      'esic_declaration',
      'epf_declaration',
      'nomination_form'
    ];

    final missing = allScreens
        .where((screen) => !_allFormData.containsKey(screen))
        .toList();
    _addDebugLog('Missing screens: ${missing.join(', ')}');
    return missing;
  }

  void _setStatus(EmployeeStatus status) {
    _status = status;
    _addDebugLog('Status changed to: $status');
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = EmployeeStatus.error;
    _addDebugLog('Error: $message');
    notifyListeners();
  }

  void _setSuccess(EmployeeResponseModel response) {
    _response = response;
    _status = EmployeeStatus.success;
    _addDebugLog('Success: ${response.message}');
    notifyListeners();
  }

  Future<void> createEmployeeFromCollectedData() async {
    try {
      print('🚀 DEBUG: ===== STARTING API SUBMISSION =====');
      print('🚀 DEBUG: All Form Data Keys: ${_allFormData.keys.join(', ')}');
      print('🚀 DEBUG: Total Screens Completed: ${_allFormData.keys.length}/8');

      _setStatus(EmployeeStatus.loading);
      _errorMessage = null;

      final formattedData = getFormattedDataForAPI();
      print('🚀 DEBUG: API Endpoint: $formattedData');

      print('🚀 DEBUG: Formatted ${formattedData.keys.length} fields for API');
      print('🚀 DEBUG: API Endpoint: /employee/store');

      FormData formData = FormData();

      formattedData.forEach((key, value) {
        if (value is String) {
          formData.fields.add(MapEntry(key, value));
          print('🔥 DEBUG: Added field: $key = "$value"');
        }
      });

      _addFileFields(formData);

      print(
          '🔥 DEBUG: FormData prepared with ${formData.fields.length} fields and ${formData.files.length} files');

      // Debug output exactly like curl command
      print('🔥 DEBUG: === CURL COMMAND EQUIVALENT ===');
      print(
          'curl --location \'https://erp.comsindia.in/api/employee/store\' \\');
      print('--header \'Accept: application/json\' \\');
      print('--header \'Authorization: Bearer <TOKEN>\' \\');
      for (var field in formData.fields) {
        print('--form \'${field.key}="${field.value}"\' \\');
      }
      for (var file in formData.files) {
        print('--form \'${file.key}=@"${file.value.filename}"\' \\');
      }
      print('🔥 DEBUG: === END CURL COMMAND ===');

      print('📡 DEBUG: Making API call...');
      // Make API call using API service with proper auth token
      final response = await _apiService.createEmployee(formData);
      _apiCallCount++;
      _apiCallHistory[DateTime.now().toString()] = {
        'endpoint': '/employee/store',
        'request': formData.fields.map((e) => '${e.key}: ${e.value}').toList(),
        'status_code': response.statusCode,
        'response_data': response.data
      };

      print('🎉 DEBUG: API response received: Status ${response.statusCode}');
      print('🎉 DEBUG: Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        print('✅ DEBUG: SUCCESS! API Response:');
        print('✅ DEBUG: Status: ${responseData['status']}');
        print('✅ DEBUG: Message: ${responseData['message']}');

        final employeeResponse = EmployeeResponseModel(
          status: responseData['status'] ?? 'success',
          message: responseData['message'] ?? 'Employee created successfully',
        );

        _setSuccess(employeeResponse);
        // Clear collected data after successful submission
        _allFormData.clear();
        print('✅ DEBUG: Employee created successfully! Form data cleared');
        print(
            '✅ DEBUG: Navigation to home will be handled by the calling screen');
        print('✅ DEBUG: ========================================');
      } else {
        print('❌ DEBUG: API call failed with status: ${response.statusCode}');
        _setError('Failed to create employee: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ DEBUG: DioException occurred: ${e.message}');
      if (e.response != null) {
        print('❌ DEBUG: Response status: ${e.response?.statusCode}');
        print('❌ DEBUG: Response data: ${e.response?.data}');

        if (e.response?.statusCode == 422) {
          // Handle validation errors
          final errors = e.response?.data['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            String errorMessage = 'Validation failed:\n';
            errors.forEach((field, messages) {
              errorMessage +=
                  '$field: ${messages.join(', ')}\n'; // Join multiple messages for a field
            });
            _setError(errorMessage); // Set the formatted error message
          } else {
            _setError(
                'API Error: ${e.response?.data['message'] ?? e.message}'); //General API error
          }
        } else {
          _setError(
              'API Error: ${e.response?.data['message'] ?? e.message}'); // General API error
        }
      } else {
        print('❌ DEBUG: Network Error: ${e.message}');
        _setError('Network Error: ${e.message}');
      }
    } catch (e) {
      print('❌ DEBUG: Unexpected Exception: $e');
      _setError('Unexpected Error: $e');
    } finally {
      _setStatus(EmployeeStatus.idle); // or EmployeeStatus.error
    }
  }

  void _addFileFields(FormData formData) {
    print('📁 DEBUG: Checking for file fields in collected data...');
    int fileCount = 0;
    _allFormData.forEach((screenName, screenData) {
      if (screenData is Map<String, dynamic>) {
        screenData.forEach((key, value) {
          if (value is File) {
            formData.files.add(MapEntry(
              key,
              MultipartFile.fromFileSync(value.path),
            ));
            print('📁 DEBUG: Added file field: $key from screen: $screenName');
            fileCount++;
          }
        });
      }
    });

    if (_allFormData.containsKey('nomination_form')) {
      final nominationData =
          _allFormData['nomination_form'] as Map<String, dynamic>;
      if (nominationData.containsKey('witness1_signature') &&
          nominationData['witness1_signature'] is File) {
        formData.files.add(MapEntry(
          'witness_1_signature',
          MultipartFile.fromFileSync(
              (nominationData['witness1_signature'] as File).path),
        ));
        print('📁 DEBUG: Added witness_1_signature file');
        fileCount++;
      }
      if (nominationData.containsKey('witness2_signature') &&
          nominationData['witness2_signature'] is File) {
        formData.files.add(MapEntry(
          'witness_2_signature',
          MultipartFile.fromFileSync(
              (nominationData['witness2_signature'] as File).path),
        ));
        print('📁 DEBUG: Added witness_2_signature file');
        fileCount++;
      }
    }

    print('📁 DEBUG: Total files added: $fileCount');
  }

  Future<void> createEmployee(EmployeeRequestModel employee) async {
    try {
      _setStatus(EmployeeStatus.loading);
      _errorMessage = null;

      _addDebugLog('Creating employee using legacy method');

      // Helper to convert null or empty string to ''
      String emptyIfNull(String? value) =>
          value?.isNotEmpty == true ? value! : '';

      FormData formData = FormData();

      formData.fields.addAll([
        MapEntry('emp_name', employee.empName),
        MapEntry('gender', employee.gender),
        MapEntry('date_of_birth', employee.dateOfBirth),
        MapEntry('hire_date', employee.hireDate),
        MapEntry('marital_status', employee.maritalStatus),
        MapEntry('blood_group', employee.bloodGroup),
        MapEntry('religion', employee.religion),
        MapEntry('department_id', employee.departmentId),
        MapEntry('designation_id', employee.designationId),
        MapEntry('site_id', employee.siteId),
        MapEntry('location', employee.location),
        MapEntry('joining_mode', employee.joiningMode),
        MapEntry('punching_code', employee.punchingCode),
        MapEntry('emergency_contact', employee.emergencyContact),
        MapEntry('contact_person_name', employee.contactPersonName),
        MapEntry(
            'emergency_contact_relation', employee.emergencyContactRelation),
        MapEntry('email', emptyIfNull(employee.email)),
        MapEntry('phone', emptyIfNull(employee.phone)),
        MapEntry('aadhar', emptyIfNull(employee.aadhar)),
        MapEntry('pan', emptyIfNull(employee.pan)),
        MapEntry('bank_name', emptyIfNull(employee.bankName)),
        MapEntry('bank_account', emptyIfNull(employee.bankAccount)),
        MapEntry('ifsc_code', emptyIfNull(employee.ifscCode)),
        MapEntry('remarks', emptyIfNull(employee.remarks)),
        MapEntry('witness1_name', emptyIfNull(employee.witness1Name)),
        MapEntry('witness2_name', emptyIfNull(employee.witness2Name)),
        MapEntry('insurance_no', emptyIfNull(employee.insuranceNo)),
        MapEntry('branch_office', emptyIfNull(employee.branchOffice)),
        MapEntry('dispensary', emptyIfNull(employee.dispensary)),
        MapEntry('pf_member', emptyIfNull(employee.pfMember)),
        MapEntry('pension_member', emptyIfNull(employee.pensionMember)),
        MapEntry('uan_number', emptyIfNull(employee.uanNumber)),
        MapEntry('previous_pf_number', emptyIfNull(employee.previousPfNumber)),
        MapEntry('exit_date', emptyIfNull(employee.exitDate)),
        MapEntry('scheme_certificate', emptyIfNull(employee.schemeCertificate)),
        MapEntry('ppo', emptyIfNull(employee.ppo)),
        MapEntry(
            'international_worker', emptyIfNull(employee.internationalWorker)),
        MapEntry('country_origin', emptyIfNull(employee.countryOrigin)),
        MapEntry('passport_number', emptyIfNull(employee.passportNumber)),
        MapEntry(
            'passport_valid_from', emptyIfNull(employee.passportValidFrom)),
        MapEntry('passport_valid_to', emptyIfNull(employee.passportValidTo)),
      ]);

      // Encode complex nested fields
      formData.fields.addAll([
        MapEntry('present_address', jsonEncode(employee.presentAddress)),
        MapEntry('permanent_address', jsonEncode(employee.permanentAddress)),
        MapEntry('family_members',
            jsonEncode(employee.familyMembers.map((e) => e.toJson()).toList())),
        MapEntry('education',
            jsonEncode(employee.education.map((e) => e.toJson()).toList())),
        MapEntry(
            'epf', jsonEncode(employee.epf.map((e) => e.toJson()).toList())),
        MapEntry(
            'eps', jsonEncode(employee.eps.map((e) => e.toJson()).toList())),
        MapEntry('family',
            jsonEncode(employee.family.map((e) => e.toJson()).toList())),
      ]);

      // Attach files if they exist
      if (employee.aadharFront != null) {
        formData.files.add(MapEntry(
          'aadhar_front',
          await MultipartFile.fromFile(employee.aadharFront!.path),
        ));
      }

      if (employee.aadharBack != null) {
        formData.files.add(MapEntry(
          'aadhar_back',
          await MultipartFile.fromFile(employee.aadharBack!.path),
        ));
      }

      if (employee.panFile != null) {
        formData.files.add(MapEntry(
          'pan_file',
          await MultipartFile.fromFile(employee.panFile!.path),
        ));
      }

      if (employee.bankDocument != null) {
        formData.files.add(MapEntry(
          'bank_document',
          await MultipartFile.fromFile(employee.bankDocument!.path),
        ));
      }

      if (employee.employeeImage != null) {
        formData.files.add(MapEntry(
          'employee_image',
          await MultipartFile.fromFile(employee.employeeImage!.path),
        ));
      }

      if (employee.signatureThumb != null) {
        formData.files.add(MapEntry(
          'signature_thumb',
          await MultipartFile.fromFile(employee.signatureThumb!.path),
        ));
      }

      if (employee.witness1Signature != null) {
        formData.files.add(MapEntry(
          'witness1_signature',
          await MultipartFile.fromFile(employee.witness1Signature!.path),
        ));
      }

      if (employee.witness2Signature != null) {
        formData.files.add(MapEntry(
          'witness2_signature',
          await MultipartFile.fromFile(employee.witness2Signature!.path),
        ));
      }

      final response = await _apiService.dio.post(
        '/employee',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      _apiCallCount++;
      _apiCallHistory[DateTime.now().toString()] = {
        'endpoint': '/employee',
        'request': formData.fields.map((e) => '${e.key}: ${e.value}').toList(),
        'status_code': response.statusCode,
        'response_data': response.data
      };

      if (response.statusCode == 200 || response.statusCode == 201) {
        final employeeResponse = EmployeeResponseModel.fromJson(response.data);
        _setSuccess(employeeResponse);
      } else {
        _setError('Failed to create employee: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        _setError('API Error: ${e.response?.data['message'] ?? e.message}');
      } else {
        _setError('Network Error: ${e.message}');
      }
    } catch (e) {
      _setError('Unexpected Error: $e');
    } finally {
      _setStatus(EmployeeStatus.idle);
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == EmployeeStatus.error) {
      _status = EmployeeStatus.initial;
      notifyListeners();
    }
  }

  void reset() {
    _status = EmployeeStatus.initial;
    _errorMessage = null;
    _response = null;
    _allFormData.clear();
    _debugLogs.clear();
    _addDebugLog('Provider reset');
    notifyListeners();
  }
}
