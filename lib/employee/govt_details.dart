import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GovernmentBankForm extends StatefulWidget {
  @override
  _GovernmentBankFormState createState() => _GovernmentBankFormState();
}

class _GovernmentBankFormState extends State<GovernmentBankForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers for text fields
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _uanController = TextEditingController();
  final TextEditingController _pfController = TextEditingController();
  final TextEditingController _esicController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  // File variables
  File? _aadharFrontImage;
  File? _aadharBackImage;
  File? _panCardImage;
  File? _bankPassbookImage;

  // Verification checkboxes
  bool _ifscVerified = false;
  bool _bankAccountVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ID & Bank Details Form',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Government IDs'),
                SizedBox(height: 16),
                _buildGovernmentIDsSection(),
                SizedBox(height: 32),
                _buildSectionHeader('Bank Details'),
                SizedBox(height: 16),
                _buildBankDetailsSection(),
                SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildGovernmentIDsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextFormField(
                  controller: _aadharController,
                  label: 'Aadhar Number *',
                  hint: 'Enter Aadhar Number',
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
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextFormField(
                  controller: _panController,
                  label: 'PAN Number *',
                  hint: 'Enter PAN Number',
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
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTextFormField(
            controller: _uanController,
            label: 'UAN Number',
            hint: 'Enter UAN Number',
            keyboardType: TextInputType.number,
            maxLength: 12,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextFormField(
                  controller: _pfController,
                  label: 'PF Member ID',
                  hint: 'Enter PF Member ID',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextFormField(
                  controller: _esicController,
                  label: 'ESIC Number',
                  hint: 'Enter ESIC Number',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFileUploadButton(
                  'Aadhar Card Front',
                  _aadharFrontImage,
                  () => _pickImage('aadhar_front'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFileUploadButton(
                  'Aadhar Card Back',
                  _aadharBackImage,
                  () => _pickImage('aadhar_back'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildFileUploadButton(
            'PAN Card Upload',
            _panCardImage,
            () => _pickImage('pan_card'),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextFormField(
                  controller: _bankNameController,
                  label: 'Bank Name *',
                  hint: 'Enter Bank Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bank name is required';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextFormField(
                  controller: _accountController,
                  label: 'Account Number *',
                  hint: 'Enter Account Number',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Account number is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextFormField(
                  controller: _ifscController,
                  label: 'IFSC Code *',
                  hint: 'Enter IFSC Code',
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
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFileUploadButton(
                  'Bank Passbook / Cheque Book',
                  _bankPassbookImage,
                  () => _pickImage('bank_passbook'),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: Text(
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
                  title: Text(
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 6),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadButton(String label, File? file, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                SizedBox(width: 8),
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
          backgroundColor: Colors.red[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Next',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form submitted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Here you would typically send the data to your backend
      print('Form submitted with data:');
      print('Aadhar: ${_aadharController.text}');
      print('PAN: ${_panController.text}');
      print('UAN: ${_uanController.text}');
      print('Bank Name: ${_bankNameController.text}');
      print('Account: ${_accountController.text}');
      print('IFSC: ${_ifscController.text}');
      print('IFSC Verified: $_ifscVerified');
      print('Bank Account Verified: $_bankAccountVerified');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields correctly'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
    super.dispose();
  }
}
