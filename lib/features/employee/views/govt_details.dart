import 'dart:io';
import 'package:coms_india/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/employee_provider.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../core/services/ifsc_service.dart';

class GovernmentBankForm extends StatefulWidget {
  @override
  State<GovernmentBankForm> createState() => _GovernmentBankFormState();
}

class _GovernmentBankFormState extends State<GovernmentBankForm> {
  final _formKey = GlobalKey<FormState>();

  Widget _buildLabelWithAsterisk(String label) {
    List<String> parts = label.split(' *');
    if (parts.length > 1) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 14,
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
        fontWeight: FontWeight.w600,
        color: Colors.black,
        fontSize: 14,
      ),
    );
  }

  // Controllers for text fields
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _uanController = TextEditingController();
  final TextEditingController _pfController = TextEditingController();
  final TextEditingController _esicController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  // File variables
  File? _aadharFrontImage;
  File? _aadharBackImage;
  File? _panCardImage;
  File? _bankPassbookImage;
  File? _employeePhotoImage;
  File? _employeeSignatureImage;

  // Other Documents Data
  List<OtherDocumentData> otherDocuments = [OtherDocumentData()];

  // Verification checkboxes
  bool _ifscVerified = false;
  bool _bankAccountVerified = false;

  // IFSC bank details
  Map<String, dynamic>? _ifscBankDetails;
  bool _isLoadingIfsc = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate fields with sample data for easy testing
    _aadharController.text = "";
    _panController.text = "";
    _uanController.text = "";
    _pfController.text = "";
    _esicController.text = "";
    _bankNameController.text = "";
    _accountController.text = "";
    _ifscController.text = "";
    _remarksController.text = "";

    // Pre-populate first document with sample data
    otherDocuments[0].nameController.text = "Experience Letter";

    print('🚀 DEBUG: Government & Bank Details - Sample data pre-populated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Check if there's something to pop, otherwise go to education details
            if (context.canPop()) {
              context.pop(); // Go back to education details
            } else {
              context.goNamed('education_details');
            }
          },
        ),
        title: const Text(
          'ID & Bank Details Form',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Government IDs'),
              const SizedBox(height: 16),
              _buildGovernmentIDsSection(),
              const SizedBox(height: 32),
              _buildSectionHeader('Bank Details'),
              const SizedBox(height: 16),
              _buildBankDetailsSection(),
              const SizedBox(height: 32),
              _buildSectionHeader('Documents & Remarks'),
              const SizedBox(height: 16),
              _buildDocumentsRemarksSection(),
              const SizedBox(height: 32),
              _buildOtherDocumentsSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildGovernmentIDsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextFormField(
            controller: _aadharController,
            label: 'Aadhar Number *',
            hint: 'Enter Aadhar Number (12 digits)',
            sample: 'Sample: 1234 5678 9012',
            keyboardType: TextInputType.number,
            maxLength: 12,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Aadhar number is required';
              }
              if (value.length != 12) {
                return 'Aadhar number must be 12 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextFormField(
            controller: _panController,
            label: 'PAN Number', // Removed asterisk, making it optional
            hint: 'Enter PAN Number (10 characters)',
            sample: 'Sample: ABCDE1234F',
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _pfController,
            label: 'PF Member ID',
            hint: 'Enter PF Member ID',
            sample: 'Sample: ABCD1234567',
          ),
          const SizedBox(height: 12),
          _buildTextFormField(
            controller: _esicController,
            label: 'ESIC Number',
            hint: 'Enter ESIC Number',
            sample: 'Sample: 1234567890',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFileUploadButton(
                  'Aadhar Card Front *',
                  _aadharFrontImage,
                  () => _pickFile('aadhar_front'),
                  sample: 'Sample: Upload clear document of front side',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFileUploadButton(
                  'Aadhar Card Back *',
                  _aadharBackImage,
                  () => _pickFile('aadhar_back'),
                  sample: 'Sample: Upload clear document of back side',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFileUploadButton(
            'PAN Card Upload *',
            _panCardImage,
            () => _pickFile('pan_card'),
            sample: 'Sample: Upload clear document of PAN card',
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextFormField(
            controller: _bankNameController,
            label: 'Bank Name *',
            hint: 'Enter Bank Name',
            sample: 'Sample: State Bank of India',
            validator: ValidationUtils.validateBankName,
          ),
          const SizedBox(height: 12),
          _buildTextFormField(
            controller: _accountController,
            label: 'Account Number *',
            hint: 'Enter Account Number',
            sample: 'Sample: 1234567890123456',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Account number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _ifscController,
            label: 'IFSC Code *',
            hint: 'Enter IFSC Code (11 characters)',
            sample: 'Sample: SBIN0001234',
            textCapitalization: TextCapitalization.characters,
            maxLength: 11,
            validator: ValidationUtils.validateIfscCode,
            suffixIcon: IconButton(
              icon: _isLoadingIfsc
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              onPressed: _isLoadingIfsc ? null : _fetchIfscDetails,
              tooltip: 'Verify IFSC Code',
            ),
          ),
          const SizedBox(height: 12),

          // IFSC Bank Details Section
          if (_ifscBankDetails != null) ...[
            _buildIfscBankDetailsSection(),
            const SizedBox(height: 16),
          ],

          _buildFileUploadButton(
            'Bank Passbook / Cheque Book *',
            _bankPassbookImage,
            () => _pickFile('bank_passbook'),
            sample: 'Sample: Upload clear document of passbook/cheque',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text(
                    'IFSC Code Verified',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _ifscVerified,
                  onChanged: (bool? value) {
                    setState(() {
                      _ifscVerified = value ?? false;
                    });
                  },
                  activeColor: Colors.red[700],
                  dense: true,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text(
                    'Bank Account Verified',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _bankAccountVerified,
                  onChanged: (bool? value) {
                    setState(() {
                      _bankAccountVerified = value ?? false;
                    });
                  },
                  activeColor: Colors.red[700],
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsRemarksSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Photo and Signature Upload Row
          Row(
            children: [
              Expanded(
                child: _buildFileUploadButton(
                  'Employee Photo *',
                  _employeePhotoImage,
                  () => _pickFile('employee_photo'),
                  sample: 'Sample: Upload recent passport size photo',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFileUploadButton(
                  'Employee Signature or Thumb Mark *',
                  _employeeSignatureImage,
                  () => _pickFile('employee_signature'),
                  sample: 'Sample: Upload clear signature or thumb mark',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Remarks Text Field
          _buildTextAreaField(
            controller: _remarksController,
            label: 'Remarks',
            hint: 'Enter any additional remarks or notes...',
            sample: 'Sample: No remarks',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildOtherDocumentsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.attach_file,
                        color: Colors.orange, size: 10),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Other Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _addOtherDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '+ Add Document',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upload any additional documents like experience letters, certificates, or other supporting documents.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...otherDocuments.asMap().entries.map((entry) {
            int index = entry.key;
            OtherDocumentData document = entry.value;
            return _buildOtherDocumentCard(document, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOtherDocumentCard(OtherDocumentData document, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Document Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: document.nameController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g., Experience Letter',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                      validator: ValidationUtils.validateDocumentName,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Document File',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickOtherDocument(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Choose',
                                  style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                document.file != null
                                    ? document.file!.path.split('/').last
                                    : 'No file chosen',
                                style: TextStyle(
                                  color: document.file != null
                                      ? Colors.green
                                      : Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (otherDocuments.length > 1)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    onPressed: () => _removeOtherDocument(index),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _addOtherDocument() {
    setState(() {
      otherDocuments.add(OtherDocumentData());
    });
  }

  void _removeOtherDocument(int index) {
    if (otherDocuments.length > 1) {
      setState(() {
        otherDocuments[index].dispose();
        otherDocuments.removeAt(index);
      });
    }
  }

  Future<void> _pickOtherDocument(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          otherDocuments[index].file = File(result.files.single.path!);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File selected: ${result.files.single.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? sample,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelWithAsterisk(label),
        if (sample != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Text(
              sample,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[700]!, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            counterText: '',
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? sample,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 14,
          ),
        ),
        if (sample != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Text(
              sample,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[700]!, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadButton(String label, File? file, VoidCallback onTap,
      {String? sample}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelWithAsterisk(label),
        if (sample != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Text(
              sample,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.upload_file,
                  color: file != null ? Colors.green : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file != null
                        ? 'File Selected'
                        : 'Choose File (PDF, Images, Docs)',
                    style: TextStyle(
                      color: file != null ? Colors.green : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _submitForm,
        child: const Text(
          'Continue to ESIC Declaration',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ),
    ]);
  }

  Future<void> _pickFile(String fileType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          switch (fileType) {
            case 'aadhar_front':
              _aadharFrontImage = File(result.files.single.path!);
              break;
            case 'aadhar_back':
              _aadharBackImage = File(result.files.single.path!);
              break;
            case 'pan_card':
              _panCardImage = File(result.files.single.path!);
              break;
            case 'bank_passbook':
              _bankPassbookImage = File(result.files.single.path!);
              break;
            case 'employee_photo':
              _employeePhotoImage = File(result.files.single.path!);
              break;
            case 'employee_signature':
              _employeeSignatureImage = File(result.files.single.path!);
              break;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File selected: ${result.files.single.name}'),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _fetchIfscDetails() async {
    final ifscCode = _ifscController.text.trim();

    if (ifscCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an IFSC code first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final validationError = ValidationUtils.validateIfscCode(ifscCode);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingIfsc = true;
    });

    try {
      final bankDetails = await IfscService.fetchBankDetails(ifscCode);

      setState(() {
        _ifscBankDetails = bankDetails;
        _isLoadingIfsc = false;
      });

      if (bankDetails != null) {
        // Auto-fill bank name if it's empty
        if (_bankNameController.text.trim().isEmpty) {
          _bankNameController.text = bankDetails['BANK'] ?? '';
        }

        // Mark IFSC as verified
        setState(() {
          _ifscVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'IFSC verified: ${bankDetails['BANK']} - ${bankDetails['BRANCH']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IFSC code not found or invalid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingIfsc = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying IFSC: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildIfscBankDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'IFSC Bank Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Bank', _ifscBankDetails!['BANK']),
          _buildDetailRow('Branch', _ifscBankDetails!['BRANCH']),
          _buildDetailRow('Address', _ifscBankDetails!['ADDRESS']),
          _buildDetailRow('City', _ifscBankDetails!['CITY']),
          _buildDetailRow('District', _ifscBankDetails!['DISTRICT']),
          _buildDetailRow('State', _ifscBankDetails!['STATE']),
          _buildDetailRow('MICR', _ifscBankDetails!['MICR']),
          _buildDetailRow('Contact', _ifscBankDetails!['CONTACT'] ?? 'N/A'),
          const SizedBox(height: 8),
          const Text(
            'Payment Services:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildServiceChip('UPI', _ifscBankDetails!['UPI'] ?? false),
              _buildServiceChip('NEFT', _ifscBankDetails!['NEFT'] ?? false),
              _buildServiceChip('RTGS', _ifscBankDetails!['RTGS'] ?? false),
              _buildServiceChip('IMPS', _ifscBankDetails!['IMPS'] ?? false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String service, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade100 : Colors.grey.shade100,
        border: Border.all(
          color: isAvailable ? Colors.green.shade300 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        service,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isAvailable ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }

  void _submitForm() {
    print('🐛 DEBUG: ===== GOVERNMENT & BANK DETAILS FORM SUBMISSION =====');
    print('🐛 DEBUG: Starting validation of all required fields...');

    // First validate form fields
    if (!(_formKey.currentState?.validate() ?? false)) {
      print('🐛 DEBUG: Form field validation failed');
      _showValidationError('Please fill all required fields correctly');
      return;
    }

    // Validate required documents according to API
    List<String> missingDocuments = [];

    // Check required documents
    if (_aadharFrontImage == null) {
      missingDocuments.add('Aadhar Card Front');
    }
    if (_aadharBackImage == null) {
      missingDocuments.add('Aadhar Card Back');
    }
    // PAN Card image is no longer mandatory
    if (_bankPassbookImage == null) {
      missingDocuments.add('Bank Passbook/Cheque');
    }
    if (_employeePhotoImage == null) {
      missingDocuments.add('Employee Photo');
    }
    if (_employeeSignatureImage == null) {
      missingDocuments.add('Employee Signature');
    }

    // If any required documents are missing, show error
    if (missingDocuments.isNotEmpty) {
      print(
          '🐛 DEBUG: Missing required documents: ${missingDocuments.join(', ')}');
      _showDocumentValidationError(missingDocuments);
      return;
    }

    // Check required text fields according to API
    List<String> missingFields = [];

    if (_aadharController.text.trim().isEmpty) {
      missingFields.add('Aadhar Number');
    }

    // pan card is no longer required
    if (_bankNameController.text.trim().isEmpty) {
      missingFields.add('Bank Name');
    }
    if (_accountController.text.trim().isEmpty) {
      missingFields.add('Account Number');
    }
    if (_ifscController.text.trim().isEmpty) {
      missingFields.add('IFSC Code');
    }

    if (missingFields.isNotEmpty) {
      print('🐛 DEBUG: Missing required fields: ${missingFields.join(', ')}');
      _showValidationError(
          'Required fields missing: ${missingFields.join(', ')}');
      return;
    }

    // All validations passed
    print('🐛 DEBUG: All validations passed successfully');
    print('🐛 DEBUG: Aadhar Number: ${_aadharController.text}');
    print('🐛 DEBUG: PAN Number: ${_panController.text}');
    print('🐛 DEBUG: UAN Number: ${_uanController.text}');
    print('🐛 DEBUG: PF Member ID: ${_pfController.text}');
    print('🐛 DEBUG: ESIC Number: ${_esicController.text}');
    print('🐛 DEBUG: Bank Name: ${_bankNameController.text}');
    print('🐛 DEBUG: Account Number: ${_accountController.text}');
    print('🐛 DEBUG: IFSC Code: ${_ifscController.text}');
    print('🐛 DEBUG: Remarks: ${_remarksController.text}');
    print('🐛 DEBUG: All required documents uploaded successfully');

    // Update provider with government & bank details data
    final provider = context.read<EmployeeProvider>();
    final govtBankData = {
      'aadhar': _aadharController.text,
      'pan': _panController.text, // PAN is nullable now
      'uan_number': _uanController.text,
      'pf_member_id': _pfController.text,
      'esic_number': _esicController.text,
      'bank_name': _bankNameController.text,
      'bank_account': _accountController.text,
      'ifsc_code': _ifscController.text,
      'remarks': _remarksController.text,
      'aadhar_front': _aadharFrontImage,
      'aadhar_back': _aadharBackImage,
      'pan_file': _panCardImage, // PAN Card image is nullable now
      'bank_document': _bankPassbookImage,
      'employee_image': _employeePhotoImage,
      'signature_thumb': _employeeSignatureImage,
      'other_documents': otherDocuments
          .where((doc) => doc.hasAnyData())
          .map((doc) => {
                'name': doc.nameController.text,
                'file': doc.file,
              })
          .toList(),
    };

    provider.updateFormData('govt_bank_details', govtBankData);
    print('🐛 DEBUG: Updated provider with Government & Bank details data');
    print(
        '🐛 DEBUG: Current completion: ${provider.getCompletionPercentage().toStringAsFixed(1)}%');

    // Print complete summary
    provider.printCompleteDebugSummary();

    print('🐛 DEBUG: ===============================================');

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Government & Bank details saved successfully!'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // Navigate to ESIC declaration using GoRouter
    print('🐛 DEBUG: Navigating to ESIC Declaration...');
    context.goNamed('esic_declaration');
  }

  void _showValidationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showDocumentValidationError(List<String> missingDocuments) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_upload, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Required Documents Missing:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...missingDocuments.map((doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• $doc', style: const TextStyle(fontSize: 12)),
                  )),
              const SizedBox(height: 8),
              const Text(
                'Please upload all required documents to proceed.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  void dispose() {
    _aadharController.dispose();
    _panController.dispose();
    _uanController.dispose();
    _pfController.dispose();
    _esicController.dispose();
    _bankNameController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _remarksController.dispose();

    // Dispose other documents
    for (var document in otherDocuments) {
      document.dispose();
    }

    super.dispose();
  }
}

class OtherDocumentData {
  final TextEditingController nameController = TextEditingController();
  File? file;

  void dispose() {
    nameController.dispose();
  }

  bool hasAnyData() {
    return nameController.text.isNotEmpty || file != null;
  }
}
