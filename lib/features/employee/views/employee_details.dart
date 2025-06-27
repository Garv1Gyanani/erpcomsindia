import 'package:coms_india/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/employee/views/employee_edit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
          _buildEmployeePhotoSection(),
          const SizedBox(height: 20),
          _buildBasicInfoSection(),
          const SizedBox(height: 16),
          _buildFamilyMembersSection(),
          const SizedBox(height: 16),
          _buildPreviousEmploymentSection(),
          const SizedBox(height: 16),
          _buildEmploymentSection(),
          const SizedBox(height: 16),
          _buildContactSection(),
          const SizedBox(height: 16),
          _buildAddressSection(),
          const SizedBox(height: 16),
          _buildEducationSection(),
          const SizedBox(height: 16),
          _buildDocumentsWithDataSection(),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          _buildEPFSection(),
          const SizedBox(height: 16),
          _buildEPSSection(),
          const SizedBox(height: 16),
          _buildESICSection(),
          const SizedBox(height: 16),
          _buildEPFOSection(),
          const SizedBox(height: 16),
          _buildRemarksSection(),
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
    final user = _employeeData!['user'] ?? {};

    return _buildSection('Contact Information', [
      _buildDetailRow('Mobile Number', user['phone']),
      _buildDetailRow('Email', user['email']),
      _buildDetailRow('Contact Person', _employeeData!['contactPersionName']),
      _buildDetailRow('Emergency Contact', _employeeData!['emergency_contact']),
      _buildDetailRow('Relationship with Emergency Contact',
          _employeeData!['emergency_contact_relation']),
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

  Widget _buildDocumentsWithDataSection() {
    return Column(
      children: [
        _buildAadharDocumentCard(),
        const SizedBox(height: 16),
        _buildPANDocumentCard(),
        const SizedBox(height: 16),
        _buildBankDocumentCard(),
        const SizedBox(height: 16),
        _buildSignatureDocumentCard(),
        const SizedBox(height: 16),
        _buildOtherDocumentsCard(),
      ],
    );
  }

  Widget _buildAadharDocumentCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Aadhar Card Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('Aadhar Number', _employeeData!['aadhar']),
            const SizedBox(height: 16),
            const Text(
              'Document Images:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildDocumentImageCard(
                  'Aadhar Front',
                  _employeeData!['aadhar_front_path'],
                ),
                const SizedBox(height: 12),
                _buildDocumentImageCard(
                  'Aadhar Back',
                  _employeeData!['aadhar_back_path'],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPANDocumentCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'PAN Card Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('PAN Number', _employeeData!['pan']),
            const SizedBox(height: 16),
            const Text(
              'Document Image:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildDocumentImageCard(
              'PAN Card',
              _employeeData!['pan_file_path'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassportDocumentCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.travel_explore, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Passport Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow(
                'Passport Number', _employeeData!['passport_number']),
            _buildDetailRow(
                'Valid From', _employeeData!['passport_valid_from']),
            _buildDetailRow('Valid To', _employeeData!['passport_valid_to']),
            if (_employeeData!['passport_number'] == null ||
                _employeeData!['passport_number'].toString().isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No passport information available',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDocumentCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Bank Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'Bank Details:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Bank Name', _employeeData!['bank_name']),
            _buildDetailRow('Account Number', _employeeData!['bank_account']),
            _buildDetailRow('IFSC Code', _employeeData!['ifsc_code']),
            _buildDetailRow('Account Verified',
                _employeeData!['bank_account_verified'] == 1 ? 'Yes' : 'No'),
            _buildDetailRow('IFSC Verified',
                _employeeData!['ifsc_code_verified'] == 1 ? 'Yes' : 'No'),
            const SizedBox(height: 16),
            const Text(
              'Bank Document Image:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildDocumentImageCard(
              'Bank Document',
              _employeeData!['bank_document_path'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureDocumentCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.draw, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Employee Signature',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'Signature Image:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildDocumentImageCard(
              'Employee Signature',
              _employeeData!['signature_thumb_path'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherDocumentsCard() {
    // Parse other documents
    List<dynamic> otherDocuments = [];
    try {
      if (_employeeData!['otherDocuments'] != null) {
        otherDocuments = json.decode(_employeeData!['otherDocuments']);
      }
    } catch (e) {
      print('Error parsing other documents: $e');
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_open, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Other Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (otherDocuments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No other documents available',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...otherDocuments.asMap().entries.map((entry) {
                final index = entry.key;
                final document = entry.value;
                final documentName = document['name'] ?? 'Unknown Document';
                final filePath = document['file_path'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document ${index + 1}: $documentName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (filePath != null && filePath.isNotEmpty)
                        _buildOtherDocumentCard(
                          documentName,
                          filePath,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.description,
                                color: Colors.grey.shade600,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$documentName - File not available',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _openPdfDocument(String pdfUrl, String title) async {
    try {
      // Show dialog with options
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Choose how to open the PDF document:'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pdfUrl,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              // TextButton(
              //   onPressed: () async {
              //     Navigator.of(context).pop();
              //     await _downloadPdf(pdfUrl, title);
              //   },
              //   style: TextButton.styleFrom(
              //     foregroundColor: Colors.orange,
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(Icons.download, size: 16),
              //       SizedBox(width: 4),
              //       Text('Download'),
              //     ],
              //   ),
              // ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Show loading state
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Opening PDF...'),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );

                  await _launchPdfUrl(pdfUrl);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Open PDF'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchPdfUrl(String url) async {
    print('🔗 Attempting to open URL: $url');

    // Validate URL format
    if (url.isEmpty) {
      _showUrlError('URL is empty', url);
      return;
    }

    // Ensure URL has proper scheme
    String validUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      validUrl = 'https://$url';
      print('🔧 Fixed URL scheme: $validUrl');
    }

    // Always copy to clipboard first as reliable fallback
    await Clipboard.setData(ClipboardData(text: validUrl));

    // Try simple approach first
    try {
      final Uri uri = Uri.parse(validUrl);
      print('📋 Parsed URI: $uri');

      // Try the most basic launch first
      await launchUrl(uri);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF opened successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      print('✅ PDF launched successfully');
    } catch (e) {
      print('❌ Basic launch failed: $e');

      // Try with explicit external mode
      try {
        final Uri uri = Uri.parse(validUrl);
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF opened in external app!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        print('✅ PDF launched in external app');
      } catch (e2) {
        print('❌ External launch failed: $e2');

        // Ultimate fallback: Show URL to user
        _showUrlFallback(validUrl);
      }
    }
  }

  void _showUrlError(String error, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showUrlFallback(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('PDF URL'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Cannot open PDF directly. Please copy the URL and open it in your browser:'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                url,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'URL has been copied to your clipboard',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('URL copied again to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Copy Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherDocumentCard(String title, String? filePath) {
    final String fullUrl = filePath != null && filePath.isNotEmpty
        ? 'https://erp.comsindia.in/$filePath'
        : '';

    // Debug: Print the URL being generated
    if (fullUrl.isNotEmpty) {
      print('🔍 Generated URL for $title: $fullUrl');
    }

    // Check if it's a PDF file
    final bool isPdf = filePath?.toLowerCase().endsWith('.pdf') ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              if (fullUrl.isNotEmpty) {
                if (isPdf) {
                  // For PDF files, you might want to open in a web view or external app
                  _openPdfDocument(fullUrl, title);
                } else {
                  // For image files, show full screen
                  _showFullScreenImage(fullUrl);
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: isPdf
                    ? Container(
                        color: Colors.red.shade50,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 48,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'PDF Document',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildDocumentPreview(filePath),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fullUrl.isNotEmpty
                ? isPdf
                    ? 'PDF Available - Tap to open'
                    : 'Available - Tap to view'
                : 'Not Available',
            style: TextStyle(
              fontSize: 12,
              color: fullUrl.isNotEmpty ? Colors.green : Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentImageCard(String title, String? imagePath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              if (imagePath != null && imagePath.isNotEmpty) {
                _showFullScreenImage('https://erp.comsindia.in/$imagePath');
              }
            },
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: _buildDocumentPreview(imagePath),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            imagePath != null && imagePath.isNotEmpty
                ? 'Available - Tap to view'
                : 'Not Available',
            style: TextStyle(
              fontSize: 12,
              color: imagePath != null && imagePath.isNotEmpty
                  ? Colors.green
                  : Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentSection() {
    final user = _employeeData!['user'] ?? {};
    final empAssignSite = user['emp_assign_site'] ?? {};
    final site = empAssignSite['site'] ?? {};

    return _buildSection('Current Employment Details', [
      _buildDetailRow('Site', site['site_name']),
      _buildDetailRow('Site Address', site['address']),
      _buildDetailRow('Site Contact Person', site['contact_person']),
      _buildDetailRow('Site Email', site['email']),
      _buildDetailRow('Site Phone', site['phone']),
      _buildDetailRow('Contract Start', site['contract_start_date']),
      _buildDetailRow('Contract End', site['contract_end_date']),
      _buildDetailRow('Joining Mode', _employeeData!['joining_mode']),
      _buildDetailRow('Punching Code', _employeeData!['punching_code']),
    ]);
  }

  Widget _buildPreviousEmploymentSection() {
    // Parse previous employment
    List<dynamic> previousEmployment = [];
    try {
      if (_employeeData!['previous_employment'] != null) {
        previousEmployment = json.decode(_employeeData!['previous_employment']);
      }
    } catch (e) {
      print('Error parsing previous employment: $e');
    }

    return _buildSection('Previous Employment Details', [
      if (previousEmployment.isEmpty)
        const Text('No previous employment records available')
      else
        ...previousEmployment.asMap().entries.map((entry) {
          final index = entry.key;
          final emp = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employment ${index + 1}:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              _buildDetailRow('Company', emp['company_name']),
              _buildDetailRow('Designation', emp['designation']),
              _buildDetailRow('From Date', emp['from_date']),
              _buildDetailRow('To Date', emp['to_date']),
              _buildDetailRow('Reason for Leaving', emp['reason_for_leaving']),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
    ]);
  }

  Widget _buildEPSSection() {
    // Parse EPS family members
    List<dynamic> epsFamilyMembers = [];
    try {
      if (_employeeData!['eps_family_members'] != null) {
        epsFamilyMembers = json.decode(_employeeData!['eps_family_members']);
      }
    } catch (e) {
      print('Error parsing EPS family members: $e');
    }

    return _buildSection('EPS Details', [
      if (epsFamilyMembers.isNotEmpty) ...[
        ...epsFamilyMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Family Member ${index + 1}:',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              _buildDetailRow('Name', member['name']),
              _buildDetailRow('Relationship', member['relationship']),
              _buildDetailRow('Age', member['age']),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ] else ...[
        const Text('No EPS family members available',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      ],
      const SizedBox(height: 16),
      const Text('Witnesses:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
      const SizedBox(height: 8),
      if (_employeeData!['witness_1_name'] != null)
        _buildDetailRow('Witness 1 Name', _employeeData!['witness_1_name']),
      if (_employeeData!['witness_1_signature_path'] != null) ...[
        const Text('Witness 1 Signature:',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Image.network(
          'https://erp.comsindia.in/${_employeeData!['witness_1_signature_path']}',
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Failed to load signature',
                style: TextStyle(color: Colors.red));
          },
        ),
        const SizedBox(height: 8),
      ],
      if (_employeeData!['witness_2_name'] != null)
        _buildDetailRow('Witness 2 Name', _employeeData!['witness_2_name']),
      if (_employeeData!['witness_2_signature_path'] != null) ...[
        const Text('Witness 2 Signature:',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Image.network(
          'https://erp.comsindia.in/${_employeeData!['witness_2_signature_path']}',
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Failed to load signature',
                style: TextStyle(color: Colors.red));
          },
        ),
        const SizedBox(height: 8),
      ],
    ]);
  }

  Widget _buildEPFSection() {
    // Parse EPF nominees
    List<dynamic> epfNominees = [];
    try {
      if (_employeeData!['epf_nominees'] != null) {
        epfNominees = json.decode(_employeeData!['epf_nominees']);
      }
    } catch (e) {
      print('Error parsing EPF data: $e');
    }

    return _buildSection('EPF Details', [
      if (epfNominees.isNotEmpty) ...[
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
              if (nominee['guardian'] != null)
                _buildDetailRow('Guardian', nominee['guardian']),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ] else ...[
        const Text('No EPF nominees available',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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

  Widget _buildEmployeePhotoSection() {
    final user = _employeeData!['user'] ?? {};
    final employeeName = user['name'] ?? 'Employee';
    final employeeId = _employeeData!['employee_id'] ?? '';
    final imagePath = _employeeData!['employee_image_path'];

    return Center(
      child: Column(
        children: [
          // Circular Employee Photo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: ClipOval(
              child: _buildCircularEmployeeImage(imagePath),
            ),
          ),
          const SizedBox(height: 16),
          // Employee Name
          Text(
            employeeName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Employee ID
          Text(
            'ID: $employeeId',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularEmployeeImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: 150,
        height: 150,
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.person,
          size: 80,
          color: Colors.grey,
        ),
      );
    }

    final imageUrl = 'https://erp.comsindia.in/$imagePath';

    return Image.network(
      imageUrl,
      width: 150,
      height: 150,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 150,
          height: 150,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 150,
          height: 150,
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.person,
            size: 80,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildDocumentPreview(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: 80,
        height: 60,
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.image_not_supported,
          size: 24,
          color: Colors.grey,
        ),
      );
    }

    final imageUrl = 'https://erp.comsindia.in/$imagePath';

    return Image.network(
      imageUrl,
      width: 80,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 80,
          height: 60,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 80,
          height: 60,
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.error_outline,
            size: 24,
            color: Colors.red,
          ),
        );
      },
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

  Widget _buildWitnessCard(
      String witnessTitle, String? witnessName, String? signaturePath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Witness Information
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  witnessTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Name: ${witnessName ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  signaturePath != null &&
                          signaturePath.isNotEmpty &&
                          signaturePath != '0'
                      ? 'Signature Available'
                      : 'Signature Not Available',
                  style: TextStyle(
                    fontSize: 12,
                    color: signaturePath != null &&
                            signaturePath.isNotEmpty &&
                            signaturePath != '0'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Signature Preview
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                if (signaturePath != null &&
                    signaturePath.isNotEmpty &&
                    signaturePath != '0') {
                  _showFullScreenImage(
                      'https://erp.comsindia.in/$signaturePath');
                }
              },
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: _buildSignaturePreview(signaturePath),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturePreview(String? signaturePath) {
    if (signaturePath == null ||
        signaturePath.isEmpty ||
        signaturePath == '0') {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.draw,
                size: 24,
                color: Colors.grey,
              ),
              SizedBox(height: 4),
              Text(
                'No Signature',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final imageUrl = 'https://erp.comsindia.in/$signaturePath';

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 24,
                  color: Colors.red,
                ),
                SizedBox(height: 4),
                Text(
                  'Failed to Load',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFamilyMembersSection() {
    // Parse family member data
    List<dynamic> familyMemberNames = [];
    List<dynamic> relations = [];
    List<dynamic> occupations = [];
    List<dynamic> dobs = [];

    try {
      if (_employeeData!['FamilyMembername'] != null) {
        familyMemberNames = json.decode(_employeeData!['FamilyMembername']);
      }
      if (_employeeData!['relation'] != null) {
        relations = json.decode(_employeeData!['relation']);
      }
      if (_employeeData!['occupation'] != null) {
        occupations = json.decode(_employeeData!['occupation']);
      }
      if (_employeeData!['dob'] != null) {
        dobs = json.decode(_employeeData!['dob']);
      }
    } catch (e) {
      print('Error parsing family member data: $e');
    }

    // Find the maximum length to handle cases where arrays might have different lengths
    final maxLength = [
      familyMemberNames.length,
      relations.length,
      occupations.length,
      dobs.length
    ].reduce((a, b) => a > b ? a : b);

    if (maxLength == 0) {
      return _buildSection('Family Members', [
        const Text('No family member information available'),
      ]);
    }

    return _buildSection('Family Members', [
      ...List.generate(maxLength, (index) {
        final memberName =
            index < familyMemberNames.length ? familyMemberNames[index] : 'N/A';
        final relation = index < relations.length ? relations[index] : 'N/A';
        final occupation =
            index < occupations.length ? occupations[index] : 'N/A';
        final dob = index < dobs.length ? dobs[index] : 'N/A';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Family Member ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Name', memberName),
              _buildDetailRow('Relation', relation),
              _buildDetailRow('Occupation', occupation),
              _buildDetailRow('Date of Birth', dob),
            ],
          ),
        );
      }).toList(),
    ]);
  }

  Widget _buildEPFOSection() {
    return _buildSection('EPFO Details', [
      _buildDetailRow('PF Member', _employeeData!['pf_member'] ?? 'N/A'),
      _buildDetailRow(
          'Pension Member', _employeeData!['pension_member'] ?? 'N/A'),
      _buildDetailRow('UAN Number', _employeeData!['uan_number'] ?? 'N/A'),
      _buildDetailRow(
          'Previous PF Number', _employeeData!['previous_pf_number'] ?? 'N/A'),
      _buildDetailRow('Exit Date', _employeeData!['exit_date'] ?? 'N/A'),
      _buildDetailRow(
          'Scheme Certificate', _employeeData!['scheme_certificate'] ?? 'N/A'),
      _buildDetailRow('PPO', _employeeData!['ppo'] ?? 'N/A'),
      const SizedBox(height: 16),
      const Text('International Worker Details:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
      const SizedBox(height: 8),
      _buildDetailRow('International Worker',
          _employeeData!['international_worker'] ?? 'N/A'),
      _buildDetailRow(
          'Country of Origin', _employeeData!['country_origin'] ?? 'N/A'),
      const SizedBox(height: 16),
      const Text('Passport Information:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
      const SizedBox(height: 8),
      _buildDetailRow(
          'Passport Number', _employeeData!['passport_number'] ?? 'N/A'),
      _buildDetailRow('Passport Valid From',
          _employeeData!['passport_valid_from'] ?? 'N/A'),
      _buildDetailRow(
          'Passport Valid To', _employeeData!['passport_valid_to'] ?? 'N/A'),
    ]);
  }

  Widget _buildRemarksSection() {
    final remarks = _employeeData!['remarks'];

    return _buildSection('Remarks', [
      _buildDetailRow('Remarks', remarks ?? 'No remarks available'),
    ]);
  }

  Future<void> _downloadPdf(String url, String fileName) async {
    try {
      print('📥 Starting PDF download: $url');

      // Show download progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Downloading PDF...'),
              SizedBox(height: 8),
              Text(
                fileName,
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Storage permission required to download PDF'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Download the file
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Get downloads directory
        Directory? downloadsDir;
        if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            downloadsDir = await getExternalStorageDirectory();
          }
        } else if (Platform.isIOS) {
          downloadsDir = await getApplicationDocumentsDirectory();
        }

        if (downloadsDir != null) {
          // Clean filename
          String cleanFileName =
              fileName.replaceAll(RegExp(r'[^\w\s-.]'), '').trim();
          if (!cleanFileName.endsWith('.pdf')) {
            cleanFileName += '.pdf';
          }

          // Create file path
          String filePath = '${downloadsDir.path}/$cleanFileName';

          // Write file
          File file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          Navigator.of(context).pop(); // Close loading dialog

          // Show success message with option to open
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PDF downloaded successfully!'),
                  SizedBox(height: 4),
                  Text(
                    'Saved to: $filePath',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () async {
                  try {
                    final Uri fileUri = Uri.file(filePath);
                    await launchUrl(fileUri);
                  } catch (e) {
                    print('Error opening downloaded file: $e');
                  }
                },
              ),
            ),
          );

          print('✅ PDF downloaded successfully: $filePath');
        } else {
          throw Exception('Could not access downloads directory');
        }
      } else {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Download error: $e');

      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Download failed: ${e.toString()}'),
              SizedBox(height: 4),
              Text('Try copying the URL instead',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Copy URL',
            textColor: Colors.white,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
            },
          ),
        ),
      );
    }
  }
}
