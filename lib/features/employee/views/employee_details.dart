import 'dart:io';

import 'package:coms_india/core/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final int userId;
  final String employeeName;

  const EmployeeDetailsPage({
    Key? key,
    required this.userId,
    required this.employeeName,
  }) : super(key: key);

  @override
  State<EmployeeDetailsPage> createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> {
  final StorageService _storageService = StorageService();
  Map<String, dynamic>? _employeeDetails;
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
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://erp.comsindia.in/api/employee/${widget.userId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['employee'] != null) {
          setState(() {
            _employeeDetails = data['employee'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                data['message'] ?? 'Failed to load employee details';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load employee details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          widget.employeeName,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            ElevatedButton(
              onPressed: _fetchEmployeeDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_employeeDetails == null) {
      return const Center(child: Text('No employee details found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildSectionHeader('Personal Information'),
          _buildPersonalInfo(),
          const SizedBox(height: 24),
          _buildSectionHeader('Contact Information'),
          _buildContactInfo(),
          const SizedBox(height: 24),
          _buildSectionHeader('Employment Details'),
          _buildEmploymentInfo(),
          const SizedBox(height: 24),
          _buildSectionHeader('Documents'),
          _buildDocumentsInfo(),
          const SizedBox(height: 24),
          _buildSectionHeader('Bank Details'),
          _buildBankInfo(),
          const SizedBox(height: 24),
          _buildSectionHeader('Family Information'),
          _buildFamilyInfo(),
          const SizedBox(height: 24),
          _buildSectionHeader('Education'),
          _buildEducationInfo(),
          const SizedBox(height: 24),
          _buildSectionHeader('EPF & ESIC Details'),
          _buildEpfEsicInfo(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final imageUrl = _employeeDetails!['employee_image_path'] != null
        ? 'https://erp.comsindia.in/${_employeeDetails!['employee_image_path']}'
        : null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (imageUrl != null) {
                  _showFullScreenImage(imageUrl, 'Profile Photo');
                }
              },
              child: Hero(
                tag: 'profile_photo',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade100, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: imageUrl != null
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(imageUrl),
                          onBackgroundImageError: (e, s) =>
                              const Icon(Icons.person),
                        )
                      : const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.red,
                          child:
                              Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _employeeDetails!['user']['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ID: ${_employeeDetails!['employee_id'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _employeeDetails!['designation']['designation_name'] ??
                        'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Gender',
              _employeeDetails!['gender']?.toString().toUpperCase() ?? 'N/A'),
          _buildInfoRow(
              'Date of Birth', _employeeDetails!['date_of_birth'] ?? 'N/A'),
          _buildInfoRow(
              'Blood Group', _employeeDetails!['blood_group'] ?? 'N/A'),
          _buildInfoRow('Religion', _employeeDetails!['religion'] ?? 'N/A'),
          _buildInfoRow(
              'Marital Status',
              _employeeDetails!['marital_status']?.toString().toUpperCase() ??
                  'N/A'),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final presentAddress =
        _parseJsonString(_employeeDetails!['present_address']);
    final permanentAddress =
        _parseJsonString(_employeeDetails!['permanent_address']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Phone', _employeeDetails!['user']['phone'] ?? 'N/A'),
          _buildInfoRow('Email', _employeeDetails!['user']['email'] ?? 'N/A'),
          _buildInfoRow('Emergency Contact',
              _employeeDetails!['emergency_contact'] ?? 'N/A'),
          _buildInfoRow('Emergency Contact Person',
              _employeeDetails!['contactPersionName'] ?? 'N/A'),
          _buildInfoRow('Emergency Contact Relation',
              _employeeDetails!['emergency_contact_relation'] ?? 'N/A'),
          const Divider(height: 32),
          Text('Present Address',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700)),
          const SizedBox(height: 12),
          if (presentAddress != null) ...[
            _buildAddressDetails(presentAddress),
          ],
          if (permanentAddress != null) ...[
            const Divider(height: 32),
            Text('Permanent Address',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700)),
            const SizedBox(height: 12),
            _buildAddressDetails(permanentAddress),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressDetails(Map<String, dynamic> address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Street', address['street'] ?? 'N/A'),
        _buildInfoRow('City', address['city'] ?? 'N/A'),
        _buildInfoRow('District', address['district'] ?? 'N/A'),
        _buildInfoRow('Pincode', address['pincode'] ?? 'N/A'),
        _buildInfoRow('Post Office', address['post_office'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildEmploymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Department',
              _employeeDetails!['department']['department_name'] ?? 'N/A'),
          _buildInfoRow('Designation',
              _employeeDetails!['designation']['designation_name'] ?? 'N/A'),
          _buildInfoRow('Hire Date', _employeeDetails!['hire_date'] ?? 'N/A'),
          _buildInfoRow(
              'Joining Mode',
              _employeeDetails!['joining_mode']?.toString().toUpperCase() ??
                  'N/A'),
          const Divider(height: 32),
          Text('Assigned Sites',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700)),
          const SizedBox(height: 12),
          ..._buildSitesList(),
        ],
      ),
    );
  }

  List<Widget> _buildSitesList() {
    final sites = _employeeDetails!['user']['emp_assign_site'] as List;
    return sites.map((site) {
      final siteInfo = site['site'];
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              siteInfo['site_name'] ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Address', siteInfo['address'] ?? 'N/A'),
            _buildInfoRow('City',
                '${siteInfo['city'] ?? 'N/A'}, ${siteInfo['state'] ?? 'N/A'}'),
            _buildInfoRow(
                'Contact Person', siteInfo['contact_person'] ?? 'N/A'),
            _buildInfoRow('Email', siteInfo['email'] ?? 'N/A'),
            _buildInfoRow('Phone', siteInfo['phone'] ?? 'N/A'),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDocumentsInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentSection(
            'Aadhar Card',
            _employeeDetails!['aadhar'] ?? 'N/A',
            _employeeDetails!['aadhar_front_path'],
            _employeeDetails!['aadhar_back_path'],
            true,
          ),
          const Divider(height: 32),
          _buildDocumentSection(
            'PAN Card',
            _employeeDetails!['pan'] ?? 'N/A',
            _employeeDetails!['pan_file_path'],
            null,
            false,
          ),
          const Divider(height: 32),
          _buildDocumentSection(
            'Bank Document',
            _employeeDetails!['bank_account'] ?? 'N/A',
            _employeeDetails!['bank_document_path'],
            null,
            false,
          ),
          if (_employeeDetails!['otherDocuments'] != null) ...[
            const Divider(height: 32),
            Text(
              'Other Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildOtherDocuments(),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentSection(String title, String number, String? frontPath,
      String? backPath, bool hasTwo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Number', number),
        const SizedBox(height: 12),
        if (frontPath != null || backPath != null)
          Row(
            children: [
              if (frontPath != null)
                Expanded(
                  child: _buildDocumentPreview(
                    'https://erp.comsindia.in/$frontPath',
                    hasTwo ? 'Front Side' : 'Document',
                    '$title ${hasTwo ? 'Front Side' : ''}'.trim(),
                  ),
                ),
              if (hasTwo && frontPath != null && backPath != null)
                const SizedBox(width: 16),
              if (backPath != null && hasTwo)
                Expanded(
                  child: _buildDocumentPreview(
                    'https://erp.comsindia.in/$backPath',
                    'Back Side',
                    '$title Back Side',
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDocumentPreview(
      String url, String label, String downloadFileName) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showFullScreenImage(url, downloadFileName),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade50,
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Hero(
                tag: url,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.description,
                        size: 40,
                        color: Colors.red.shade300,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon:
                    Icon(Icons.download, color: Colors.red.shade700, size: 20),
                tooltip: 'Download',
                onPressed: () => _downloadFile(url, downloadFileName),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOtherDocuments() {
    try {
      final documents =
          json.decode(_employeeDetails!['otherDocuments'] as String) as List;
      return documents.map((doc) {
        final filePath = doc['file_path'] as String?;
        final fileUrl =
            filePath != null ? 'https://erp.comsindia.in/$filePath' : null;
        final docName = doc['name'] ?? 'Unnamed Document';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: Colors.red.shade300),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      doc['name'] ?? 'Unnamed Document',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (fileUrl != null) ...[
                const SizedBox(height: 12),
                _buildDocumentPreview(fileUrl, 'Preview', docName),
              ],
            ],
          ),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildBankInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Bank Name', _employeeDetails!['bank_name'] ?? 'N/A'),
          _buildInfoRow(
              'Account Number', _employeeDetails!['bank_account'] ?? 'N/A'),
          _buildInfoRow('IFSC Code', _employeeDetails!['ifsc_code'] ?? 'N/A'),
          _buildInfoRow('Account Verified',
              _employeeDetails!['bank_account_verified'] == 1 ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildFamilyInfo() {
    List<dynamic> familyMembers = [];
    try {
      familyMembers =
          json.decode(_employeeDetails!['FamilyMembername'] as String);
      final relations = json.decode(_employeeDetails!['relation'] as String);
      final occupations =
          json.decode(_employeeDetails!['occupation'] as String);
      final dobs = json.decode(_employeeDetails!['dob'] as String);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            familyMembers.length,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Member ${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Name', familyMembers[index]),
                  _buildInfoRow('Relation', relations[index]),
                  _buildInfoRow('Occupation', occupations[index]),
                  _buildInfoRow('Date of Birth', dobs[index]),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text('No family information available'),
      );
    }
  }

  Widget _buildEducationInfo() {
    try {
      final education =
          json.decode(_employeeDetails!['education'] as String) as List;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: education
              .map((edu) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edu['degree'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('University', edu['university'] ?? 'N/A'),
                        _buildInfoRow(
                            'Specialization', edu['specialization'] ?? 'N/A'),
                        _buildInfoRow('Duration',
                            '${edu['from_year']} - ${edu['to_year']}'),
                        _buildInfoRow('Percentage', '${edu['percentage']}%'),
                      ],
                    ),
                  ))
              .toList(),
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text('No education information available'),
      );
    }
  }

  Widget _buildEpfEsicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('ESIC Member', _employeeDetails!['ESIC'] ?? 'N/A'),
          _buildInfoRow('PF Member', _employeeDetails!['pf_member'] ?? 'N/A'),
          _buildInfoRow('UAN Number', _employeeDetails!['uan_number'] ?? 'N/A'),
          _buildInfoRow('Previous PF Number',
              _employeeDetails!['previous_pf_number'] ?? 'N/A'),
          if (_employeeDetails!['epf_nominees'] != null) ...[
            const Divider(height: 32),
            Text('EPF Nominees',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700)),
            const SizedBox(height: 12),
            ..._buildEpfNominees(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildEpfNominees() {
    try {
      final nominees =
          json.decode(_employeeDetails!['epf_nominees'] as String) as List;
      return nominees
          .map((nominee) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Name', nominee['name'] ?? 'N/A'),
                    _buildInfoRow(
                        'Relationship', nominee['relationship'] ?? 'N/A'),
                    _buildInfoRow('Share', '${nominee['share']}%'),
                    _buildInfoRow('Date of Birth', nominee['dob'] ?? 'N/A'),
                  ],
                ),
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _parseJsonString(String? jsonString) {
    if (jsonString == null) return null;
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  void _showFullScreenImage(String imageUrl, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(title),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Download',
                onPressed: () {
                  _downloadFile(imageUrl, title);
                },
              ),
            ],
          ),
          body: Container(
            color: Colors.black,
            child: Hero(
              tag: imageUrl,
              child: PhotoView(
                imageProvider: NetworkImage(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
                loadingBuilder: (context, event) => Center(
                  child: CircularProgressIndicator(
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded /
                            (event.expectedTotalBytes ?? 1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFile(String url, String fileName) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Check for and request storage permission
      final status = await Permission.storage.request();

      if (!status.isGranted) {
        // If permission is denied, show a message.
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Storage permission denied.')),
        );
        return;
      }

      // 2. Get the downloads directory
      Directory? downloadsDirectory;
      if (Platform.isIOS) {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      } else {
        downloadsDirectory = await getDownloadsDirectory();
      }

      if (downloadsDirectory == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('Could not access downloads directory.')),
        );
        return;
      }

      // 3. Prepare file path
      final fileExtension = url.split('.').last.split('?').first;
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[\/\\]'), '_');
      final uniqueFileName = '$sanitizedFileName.$fileExtension';
      final savePath = '${downloadsDirectory.path}/$uniqueFileName';

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Downloading $fileName...')),
      );

      // 4. Download file
      final dio = Dio();
      await dio.download(url, savePath);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Successfully downloaded: $uniqueFileName'),
        ),
      );
    } catch (e) {
      print('Error downloading file: $e');
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Error downloading file.')),
      );
    }
  }
}
