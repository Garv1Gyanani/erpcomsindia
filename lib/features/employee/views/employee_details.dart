import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/employee/views/employee_edit.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final int userId;
  final String employeeName;

  const EmployeeDetailsPage({
    super.key,
    required this.userId,
    required this.employeeName,
  });

  @override
  State<EmployeeDetailsPage> createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> {
  final StorageService _storageService = StorageService();
  Map<String, dynamic>? _employeeData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeDetails();
  }

  Future<void> _fetchEmployeeDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://erp.comsindia.in/api/employee/${widget.userId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 Employee Details API Response Status: ${response.statusCode}');
      print('🔍 Employee Details API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == true &&
            responseData['employee'] != null) {
          setState(() {
            _employeeData = responseData['employee'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Failed to load employee details';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load employee details. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching employee details: $e');
      setState(() {
        _errorMessage =
            'Network error. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEditPage() async {
    if (_employeeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee data not loaded yet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeEditPage(
          userId: widget.userId,
          employeeName: widget.employeeName,
          employeeData: _employeeData!,
        ),
      ),
    );

    // If the edit was successful, refresh the data
    if (result == true) {
      _fetchEmployeeDetails();
    }
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
          'Employee Details - ${widget.employeeName}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _navigateToEditPage,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchEmployeeDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading employee details...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchEmployeeDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_employeeData == null) {
      return const Center(
        child: Text('No employee data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfoSection(),
          const SizedBox(height: 16),
          _buildContactSection(),
          const SizedBox(height: 16),
          _buildAddressSection(),
          const SizedBox(height: 16),
          _buildEducationSection(),
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
        ],
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

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final user = _employeeData!['user'] ?? {};
    final department = _employeeData!['department'] ?? {};
    final designation = _employeeData!['designation'] ?? {};

    return _buildSection('Basic Information', [
      _buildDetailRow('Name', user['name']),
      _buildDetailRow('Employee ID', _employeeData!['employee_id']),
      _buildDetailRow('Email', user['email']),
      _buildDetailRow('Phone', user['phone']),
      _buildDetailRow('Gender', _employeeData!['gender']),
      _buildDetailRow('Date of Birth', _employeeData!['date_of_birth']),
      _buildDetailRow('Hire Date', _employeeData!['hire_date']),
      _buildDetailRow('Marital Status', _employeeData!['marital_status']),
      _buildDetailRow('Blood Group', _employeeData!['blood_group']),
      _buildDetailRow('Religion', _employeeData!['religion']),
      _buildDetailRow('Department', department['department_name']),
      _buildDetailRow('Designation', designation['designation_name']),
      _buildDetailRow('Status', user['status']),
    ]);
  }

  Widget _buildContactSection() {
    return _buildSection('Emergency Contact', [
      _buildDetailRow('Contact Person', _employeeData!['contactPersionName']),
      _buildDetailRow('Emergency Contact', _employeeData!['emergency_contact']),
      _buildDetailRow('Relation', _employeeData!['emergency_contact_relation']),
    ]);
  }

  Widget _buildAddressSection() {
    // Parse JSON addresses
    Map<String, dynamic> presentAddress = {};
    Map<String, dynamic> permanentAddress = {};

    try {
      if (_employeeData!['present_address'] != null) {
        presentAddress = json.decode(_employeeData!['present_address']);
      }
      if (_employeeData!['permanent_address'] != null) {
        permanentAddress = json.decode(_employeeData!['permanent_address']);
      }
    } catch (e) {
      print('Error parsing addresses: $e');
    }

    return _buildSection('Address Information', [
      const Text('Present Address:',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _buildDetailRow('Street', presentAddress['street']),
      _buildDetailRow('City', presentAddress['city']),
      _buildDetailRow('District', presentAddress['district']),
      _buildDetailRow('Thana', presentAddress['thana']),
      _buildDetailRow('Post Office', presentAddress['post_office']),
      _buildDetailRow('Pincode', presentAddress['pincode']),
      const SizedBox(height: 16),
      const Text('Permanent Address:',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _buildDetailRow('Street', permanentAddress['street']),
      _buildDetailRow('City', permanentAddress['city']),
      _buildDetailRow('District', permanentAddress['district']),
      _buildDetailRow('Thana', permanentAddress['thana']),
      _buildDetailRow('Post Office', permanentAddress['post_office']),
      _buildDetailRow('Pincode', permanentAddress['pincode']),
    ]);
  }

  Widget _buildEducationSection() {
    List<dynamic> education = [];
    try {
      if (_employeeData!['education'] != null) {
        education = json.decode(_employeeData!['education']);
      }
    } catch (e) {
      print('Error parsing education: $e');
    }

    return _buildSection('Education Details', [
      if (education.isEmpty)
        const Text('No education details available')
      else
        ...education.asMap().entries.map((entry) {
          final index = entry.key;
          final edu = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Education ${index + 1}:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              _buildDetailRow('Degree', edu['degree']),
              _buildDetailRow('Specialization', edu['specialization']),
              _buildDetailRow('University', edu['university']),
              _buildDetailRow('From Year', edu['from_year']),
              _buildDetailRow('To Year', edu['to_year']),
              _buildDetailRow('Percentage', edu['percentage']),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
    ]);
  }

  Widget _buildDocumentsSection() {
    return _buildSection('Documents', [
      _buildDetailRow('Aadhar Number', _employeeData!['aadhar']),
      _buildDetailRow('PAN Number', _employeeData!['pan']),
      _buildDetailRow('Passport Number', _employeeData!['passport_number']),
      _buildDetailRow(
          'Passport Valid From', _employeeData!['passport_valid_from']),
      _buildDetailRow('Passport Valid To', _employeeData!['passport_valid_to']),
    ]);
  }

  Widget _buildBankDetailsSection() {
    return _buildSection('Bank Details', [
      _buildDetailRow('Bank Name', _employeeData!['bank_name']),
      _buildDetailRow('Account Number', _employeeData!['bank_account']),
      _buildDetailRow('IFSC Code', _employeeData!['ifsc_code']),
      _buildDetailRow('Account Verified',
          _employeeData!['bank_account_verified'] == 1 ? 'Yes' : 'No'),
      _buildDetailRow('IFSC Verified',
          _employeeData!['ifsc_code_verified'] == 1 ? 'Yes' : 'No'),
    ]);
  }

  Widget _buildEmploymentSection() {
    // Parse previous employment
    List<dynamic> previousEmployment = [];
    try {
      if (_employeeData!['previous_employment'] != null) {
        previousEmployment = json.decode(_employeeData!['previous_employment']);
      }
    } catch (e) {
      print('Error parsing previous employment: $e');
    }

    final user = _employeeData!['user'] ?? {};
    final empAssignSite = user['emp_assign_site'] ?? {};
    final site = empAssignSite['site'] ?? {};

    return _buildSection('Employment Details', [
      _buildDetailRow('Site', site['site_name']),
      _buildDetailRow('Site Address', site['address']),
      _buildDetailRow('Site Contact Person', site['contact_person']),
      _buildDetailRow('Site Email', site['email']),
      _buildDetailRow('Site Phone', site['phone']),
      _buildDetailRow('Contract Start', site['contract_start_date']),
      _buildDetailRow('Contract End', site['contract_end_date']),
      _buildDetailRow('Joining Mode', _employeeData!['joining_mode']),
      _buildDetailRow('Punching Code', _employeeData!['punching_code']),
      const SizedBox(height: 16),
      if (previousEmployment.isNotEmpty) ...[
        const Text('Previous Employment:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...previousEmployment.asMap().entries.map((entry) {
          final index = entry.key;
          final emp = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employment ${index + 1}:',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              _buildDetailRow('Company', emp['company_name']),
              _buildDetailRow('Designation', emp['designation']),
              _buildDetailRow('From Date', emp['from_date']),
              _buildDetailRow('To Date', emp['to_date']),
              _buildDetailRow('Reason for Leaving', emp['reason_for_leaving']),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    ]);
  }

  Widget _buildEPFSection() {
    // Parse EPF nominees
    List<dynamic> epfNominees = [];
    List<dynamic> epsFamilyMembers = [];
    try {
      if (_employeeData!['epf_nominees'] != null) {
        epfNominees = json.decode(_employeeData!['epf_nominees']);
      }
      if (_employeeData!['eps_family_members'] != null) {
        epsFamilyMembers = json.decode(_employeeData!['eps_family_members']);
      }
    } catch (e) {
      print('Error parsing EPF data: $e');
    }

    return _buildSection('EPF/EPS Details', [
      _buildDetailRow('PF Member', _employeeData!['pf_member']),
      _buildDetailRow('Pension Member', _employeeData!['pension_member']),
      _buildDetailRow('UAN Number', _employeeData!['uan_number']),
      _buildDetailRow(
          'Previous PF Number', _employeeData!['previous_pf_number']),
      _buildDetailRow(
          'Scheme Certificate', _employeeData!['scheme_certificate']),
      _buildDetailRow('PPO', _employeeData!['ppo']),
      const SizedBox(height: 16),
      if (epfNominees.isNotEmpty) ...[
        const Text('EPF Nominees:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...epfNominees.asMap().entries.map((entry) {
          final index = entry.key;
          final nominee = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nominee ${index + 1}:',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              _buildDetailRow('Name', nominee['name']),
              _buildDetailRow('Relationship', nominee['relationship']),
              _buildDetailRow('Share', nominee['share']),
              _buildDetailRow('Date of Birth', nominee['dob']),
              _buildDetailRow('Address', nominee['address']),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    ]);
  }

  Widget _buildESICSection() {
    // Parse family members
    List<dynamic> familyMembers = [];
    try {
      if (_employeeData!['family_members'] != null) {
        familyMembers = json.decode(_employeeData!['family_members']);
      }
    } catch (e) {
      print('Error parsing family members: $e');
    }

    return _buildSection('ESIC Details', [
      _buildDetailRow('ESIC', _employeeData!['ESIC']),
      _buildDetailRow('Insurance No', _employeeData!['insurance_no']),
      _buildDetailRow('Branch Office', _employeeData!['branch_office']),
      _buildDetailRow('Dispensary', _employeeData!['dispensary']),
      _buildDetailRow(
          'International Worker', _employeeData!['international_worker']),
      _buildDetailRow('Country of Origin', _employeeData!['country_origin']),
      const SizedBox(height: 16),
      if (familyMembers.isNotEmpty) ...[
        const Text('Family Members:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...familyMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Member ${index + 1}:',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              _buildDetailRow('Name', member['name']),
              _buildDetailRow('Relation', member['relation']),
              _buildDetailRow('Date of Birth', member['dob']),
              _buildDetailRow('Residing', member['residing']),
              _buildDetailRow('Residence', member['residence']),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    ]);
  }
}
