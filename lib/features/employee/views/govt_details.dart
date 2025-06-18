import 'dart:io';
import 'package:coms_india/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/employee_provider.dart';
import '../../../core/utils/validation_utils.dart';

class GovernmentBankForm extends StatefulWidget {
  @override
  State<GovernmentBankForm> createState() => _GovernmentBankFormState();
}

class _GovernmentBankFormState extends State<GovernmentBankForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

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

  // Verification checkboxes
  bool _ifscVerified = false;
  bool _bankAccountVerified = false;
  bool _softCopyJoiningKitReceived = false;
  bool _hardCopyJoiningKitReceived = false;

  @override
  void initState() {
    super.initState();
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
              context.goNamed(
                  'education_details'); // Fallback to education details
            }
          },
        ),
        title: const Text(
          'ID & Bank Details Form',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        backgroundColor: Colors.red,
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
            fieldNumber: 1,
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
            fieldNumber: 2,
            controller: _panController,
            label: 'PAN Number *',
            hint: 'Enter PAN Number (10 characters)',
            sample: 'Sample: ABCDE1234F',
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'PAN number is required';
              }
              if (value.length != 10) {
                return 'PAN must be 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            fieldNumber: 3,
            controller: _uanController,
            label: 'UAN Number',
            hint: 'Enter UAN Number (12 digits)',
            sample: 'Sample: 123456789012',
            keyboardType: TextInputType.number,
            maxLength: 12,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            fieldNumber: 4,
            controller: _pfController,
            label: 'PF Member ID',
            hint: 'Enter PF Member ID',
            sample: 'Sample: ABCD1234567',
          ),
          const SizedBox(height: 12),
          _buildTextFormField(
            fieldNumber: 5,
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
                  'Aadhar Card Front (6)',
                  _aadharFrontImage,
                  () => _pickImage('aadhar_front'),
                  sample: 'Sample: Upload clear image of front side',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFileUploadButton(
                  'Aadhar Card Back (7)',
                  _aadharBackImage,
                  () => _pickImage('aadhar_back'),
                  sample: 'Sample: Upload clear image of back side',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFileUploadButton(
            'PAN Card Upload (8)',
            _panCardImage,
            () => _pickImage('pan_card'),
            sample: 'Sample: Upload clear image of PAN card',
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
            fieldNumber: 9,
            controller: _bankNameController,
            label: 'Bank Name *',
            hint: 'Enter Bank Name',
            sample: 'Sample: State Bank of India',
            validator: ValidationUtils.validateBankName,
          ),
          const SizedBox(height: 12),
          _buildTextFormField(
            fieldNumber: 10,
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
            fieldNumber: 11,
            controller: _ifscController,
            label: 'IFSC Code *',
            hint: 'Enter IFSC Code (11 characters)',
            sample: 'Sample: SBIN0001234',
            textCapitalization: TextCapitalization.characters,
            maxLength: 11,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'IFSC code is required';
              }
              if (value.length != 11) {
                return 'IFSC code must be 11 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildFileUploadButton(
            'Bank Passbook / Cheque Book (12)',
            _bankPassbookImage,
            () => _pickImage('bank_passbook'),
            sample: 'Sample: Upload clear image of passbook/cheque',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text(
                    'IFSC Code Verified (13)',
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
                    'Bank Account Verified (14)',
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
                  'Employee Photo (15)',
                  _employeePhotoImage,
                  () => _pickImage('employee_photo'),
                  sample: 'Sample: Upload recent passport size photo',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFileUploadButton(
                  'Employee Signature or Thumb Mark (16)',
                  _employeeSignatureImage,
                  () => _pickImage('employee_signature'),
                  sample: 'Sample: Upload clear signature or thumb mark',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Joining Kit Checkboxes Row
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text(
                    'Soft Copy Joining Kit Received (17)',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _softCopyJoiningKitReceived,
                  onChanged: (bool? value) {
                    setState(() {
                      _softCopyJoiningKitReceived = value ?? false;
                    });
                  },
                  activeColor: Colors.red[700],
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          CheckboxListTile(
            title: const Text(
              'Hard Copy Joining Kit Received (18)',
              style: TextStyle(fontSize: 14),
            ),
            value: _hardCopyJoiningKitReceived,
            onChanged: (bool? value) {
              setState(() {
                _hardCopyJoiningKitReceived = value ?? false;
              });
            },
            activeColor: Colors.red[700],
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 16),

          // Remarks Text Field
          _buildTextAreaField(
            fieldNumber: 19,
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

  Widget _buildTextFormField({
    required int fieldNumber,
    required TextEditingController controller,
    required String label,
    required String hint,
    String? sample,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabelWithAsterisk(label),
            Text(
              '  ($fieldNumber)',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ],
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
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required int fieldNumber,
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
          '$label  ($fieldNumber)',
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
                    file != null ? 'File Selected' : 'Choose File',
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
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ]);
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (imageType) {
            case 'aadhar_front':
              _aadharFrontImage = File(image.path);
              break;
            case 'aadhar_back':
              _aadharBackImage = File(image.path);
              break;
            case 'pan_card':
              _panCardImage = File(image.path);
              break;
            case 'bank_passbook':
              _bankPassbookImage = File(image.path);
              break;
            case 'employee_photo':
              _employeePhotoImage = File(image.path);
              break;
            case 'employee_signature':
              _employeeSignatureImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _submitForm() {
    print('🐛 DEBUG: ===== GOVERNMENT & BANK DETAILS FORM SUBMISSION =====');
    print('🐛 DEBUG: Aadhar Number: ${_aadharController.text}');
    print('🐛 DEBUG: PAN Number: ${_panController.text}');
    print('🐛 DEBUG: UAN Number: ${_uanController.text}');
    print('🐛 DEBUG: PF Member ID: ${_pfController.text}');
    print('🐛 DEBUG: ESIC Number: ${_esicController.text}');
    print('🐛 DEBUG: Bank Name: ${_bankNameController.text}');
    print('🐛 DEBUG: Account Number: ${_accountController.text}');
    print('🐛 DEBUG: IFSC Code: ${_ifscController.text}');
    print('🐛 DEBUG: Remarks: ${_remarksController.text}');
    print(
        '🐛 DEBUG: Aadhar Front Image: ${_aadharFrontImage?.path ?? 'Not selected'}');
    print(
        '🐛 DEBUG: Aadhar Back Image: ${_aadharBackImage?.path ?? 'Not selected'}');
    print('🐛 DEBUG: PAN Card Image: ${_panCardImage?.path ?? 'Not selected'}');
    print(
        '🐛 DEBUG: Bank Passbook Image: ${_bankPassbookImage?.path ?? 'Not selected'}');
    print(
        '🐛 DEBUG: Employee Photo: ${_employeePhotoImage?.path ?? 'Not selected'}');
    print(
        '🐛 DEBUG: Employee Signature: ${_employeeSignatureImage?.path ?? 'Not selected'}');

    if (_formKey.currentState?.validate() ?? false) {
      // Update provider with government & bank details data
      final provider = context.read<EmployeeProvider>();
      final govtBankData = {
        'aadhar': _aadharController.text,
        'pan': _panController.text,
        'uan_number': _uanController.text,
        'pf_member_id': _pfController.text,
        'esic_number': _esicController.text,
        'bank_name': _bankNameController.text,
        'bank_account': _accountController.text,
        'ifsc_code': _ifscController.text,
        'remarks': _remarksController.text,
        'aadhar_front': _aadharFrontImage,
        'aadhar_back': _aadharBackImage,
        'pan_file': _panCardImage,
        'bank_document': _bankPassbookImage,
        'employee_image': _employeePhotoImage,
        'signature_thumb': _employeeSignatureImage,
      };

      provider.updateFormData('govt_bank_details', govtBankData);
      print('🐛 DEBUG: Updated provider with Government & Bank details data');
      print(
          '🐛 DEBUG: Current completion: ${provider.getCompletionPercentage().toStringAsFixed(1)}%');

      // Print complete summary
      provider.printCompleteDebugSummary();

      print('🐛 DEBUG: ===============================================');

      // Navigate to ESIC declaration using GoRouter
      print('🐛 DEBUG: Navigating to ESIC Declaration...');
      context.goNamed('esic_declaration');
    } else {
      print('🐛 DEBUG: Government & Bank form validation failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fill all required fields correctly'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
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
    super.dispose();
  }
}
