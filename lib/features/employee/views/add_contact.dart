import 'package:coms_india/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/employee_provider.dart';
import '../../../core/utils/validation_utils.dart';

class ContactFormScreen extends StatefulWidget {
  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  bool sameAsPresent = false;

  // Contact field controllers
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyContactPersonController = TextEditingController();
  final _emergencyContactRelationController = TextEditingController();

  // Controllers for Present Address
  final Map<String, TextEditingController> presentControllers = {
    'Street Address': TextEditingController(),
    'City': TextEditingController(),
    'District': TextEditingController(),
    'Post Office': TextEditingController(),
    'Thana': TextEditingController(),
    'Pincode': TextEditingController(),
  };

  // Controllers for Permanent Address
  final Map<String, TextEditingController> permanentControllers = {
    'Street Address': TextEditingController(),
    'City': TextEditingController(),
    'District': TextEditingController(),
    'Post Office': TextEditingController(),
    'Thana': TextEditingController(),
    'Pincode': TextEditingController(),
  };

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Max length constraints
  static const int maxPhoneLength = 10;
  static const int maxEmergencyContactLength = 10;
  static const int maxPincodeLength = 6;
  static const int maxEmailLength = 50;
  static const int maxNameLength = 50;
  static const int maxAddressFieldLength = 100;

  @override
  void initState() {
    super.initState();
    // Pre-populate fields with sample data for easy testing (using unique values)
    _phoneController.text = "9876543210";
    _emailController.text = "utkarsh@gmail.com";
    _emergencyContactController.text = "9876543210";
    _emergencyContactPersonController.text = "Mike Doe";
    _emergencyContactRelationController.text = "Brother";

    // Pre-populate present address
    presentControllers['Street Address']?.text = "123 Main St";
    presentControllers['City']?.text = "Apt 4B";
    presentControllers['District']?.text = "Central District";
    presentControllers['Post Office']?.text = "Main PO";
    presentControllers['Thana']?.text = "City Police Station";
    presentControllers['Pincode']?.text = "110001";

    // Pre-populate permanent address
    permanentControllers['Street Address']?.text = "456 Secondary Rd";
    permanentControllers['City']?.text = "Floor 2";
    permanentControllers['District']?.text = "Secondary District";
    permanentControllers['Post Office']?.text = "Secondary PO";
    permanentControllers['Thana']?.text = "Secondary Police Station";
    permanentControllers['Pincode']?.text = "110002";

    print('🚀 DEBUG: Contact Details - Sample data pre-populated');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    _emergencyContactPersonController.dispose();
    _emergencyContactRelationController.dispose();
    presentControllers.values.forEach((c) => c.dispose());
    permanentControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _copyPresentToPermanent() {
    presentControllers.forEach((key, controller) {
      permanentControllers[key]?.text = controller.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Check if there's something to pop, otherwise go to previous employment
            if (context.canPop()) {
              context.pop(); // Go back to previous employment
            } else {
              context.goNamed(
                  'previous_employment'); // Fallback to previous employment
            }
          },
        ),
        title: const Text(
          'Contact Details',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 1.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contact Fields
              Column(
                children: [
                  _buildLabeledTextField(
                    context: context,
                    label: 'Mobile Number',
                    hintText: 'Phone Number',
                    isRequired: true,
                    controller: _phoneController,
                    maxLength: maxPhoneLength,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Mobile number is required';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'Only digits allowed';
                      }
                      if (value.length != maxPhoneLength) {
                        return 'Enter a valid 10-digit mobile number';
                      }
                      // Add check for valid Indian mobile number
                      if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                        return 'Enter a valid Indian mobile number (starting with 6-9)';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  _buildLabeledTextField(
                    context: context,
                    label: 'Email',
                    hintText: 'Email Address',
                    isRequired: true,
                    controller: _emailController,
                    maxLength: maxEmailLength,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (value.length > maxEmailLength) {
                        return 'Email too long';
                      }
                      if (!RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(value)) {
                        return 'Enter a valid email format';
                      }
                      // Additional email format validation
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Email must contain @ and . symbols';
                      }
                      if (value.startsWith('.') ||
                          value.endsWith('.') ||
                          value.startsWith('@') ||
                          value.endsWith('@')) {
                        return 'Invalid email format';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  _buildLabeledTextField(
                    context: context,
                    label: 'Emergency Contact',
                    hintText: 'Emergency Contact',
                    isRequired: true,
                    controller: _emergencyContactController,
                    maxLength: maxEmergencyContactLength,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Emergency contact is required';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'Only digits allowed';
                      }
                      if (value.length != maxEmergencyContactLength) {
                        return 'Enter a valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  _buildLabeledTextField(
                    context: context,
                    label: 'Emergency Contact Person Name',
                    hintText: 'Contact Person Name',
                    isRequired: true,
                    controller: _emergencyContactPersonController,
                    maxLength: maxNameLength,
                    validator: ValidationUtils.validateContactPersonName,
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Present Address
              _buildAddressSection(
                context: context,
                title: 'Present Address',
                isRequired: true,
                controllers: presentControllers,
                maxFieldLength: maxAddressFieldLength,
                maxPincodeLength: maxPincodeLength,
              ),
              SizedBox(height: 10),

              // Checkbox to copy address
              Row(
                children: [
                  Checkbox(
                    value: sameAsPresent,
                    onChanged: (value) {
                      setState(() {
                        sameAsPresent = value ?? false;
                        if (sameAsPresent) {
                          _copyPresentToPermanent();
                        } else {
                          permanentControllers.forEach((key, controller) {
                            controller.clear();
                          });
                        }
                      });
                    },
                  ),
                  const Text("Same as Present Address"),
                ],
              ),

              // Permanent Address
              _buildAddressSection(
                context: context,
                title: 'Permanent Address',
                isRequired: true,
                controllers: permanentControllers,
                maxFieldLength: maxAddressFieldLength,
                maxPincodeLength: maxPincodeLength,
              ),
              SizedBox(height: 16),

              // Relationship Field
              _buildLabeledTextField(
                context: context,
                label: 'Relationship with Emergency Contact',
                hintText: 'Relationship',
                isRequired: true,
                controller: _emergencyContactRelationController,
                maxLength: maxNameLength,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Relationship is required';
                  }
                  if (value.length > maxNameLength) {
                    return 'Relationship too long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),

              // Submit Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                        'Continue to Education Details',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400),
                      ))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequiredLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.black.withOpacity(0.85),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledTextField({
    required BuildContext context,
    required String label,
    required String hintText,
    bool isRequired = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isRequired
            ? _buildRequiredLabel(label)
            : Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.grey[50],
            counterText: "", // Hide counter
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildAddressSection({
    required BuildContext context,
    required String title,
    bool isRequired = false,
    required Map<String, TextEditingController> controllers,
    int maxFieldLength = 100,
    int maxPincodeLength = 6,
  }) {
    final addressFields = controllers.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isRequired
            ? _buildRequiredLabel(title)
            : Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
        SizedBox(height: 6),
        ...addressFields.map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: TextFormField(
              controller: controllers[field],
              style: TextStyle(fontSize: 13),
              maxLength: field == 'Pincode' ? maxPincodeLength : maxFieldLength,
              keyboardType: field == 'Pincode'
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                hintText: field,
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.grey[50],
                counterText: "",
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$field is required';
                }
                if (field == 'Pincode') {
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Only digits allowed';
                  }
                  if (value.length != maxPincodeLength) {
                    return 'Enter a valid 6-digit pincode';
                  }
                } else {
                  if (value.length > maxFieldLength) {
                    return '$field too long';
                  }
                }
                return null;
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      // If form is not valid, do not proceed
      return;
    }

    print('🐛 DEBUG: ===== CONTACT DETAILS FORM SUBMISSION =====');
    print('🐛 DEBUG: Phone: ${_phoneController.text}');
    print('🐛 DEBUG: Email: ${_emailController.text}');
    print('🐛 DEBUG: Emergency Contact: ${_emergencyContactController.text}');
    print(
        '🐛 DEBUG: Emergency Contact Person: ${_emergencyContactPersonController.text}');
    print(
        '🐛 DEBUG: Emergency Contact Relation: ${_emergencyContactRelationController.text}');

    // Debug present address
    final presentAddressList = presentControllers.values
        .map((c) => c.text)
        .where((text) => text.isNotEmpty)
        .toList();
    print('🐛 DEBUG: Present Address: ${presentAddressList.join(', ')}');

    // Debug permanent address
    final permanentAddressList = permanentControllers.values
        .map((c) => c.text)
        .where((text) => text.isNotEmpty)
        .toList();
    print('🐛 DEBUG: Permanent Address: ${permanentAddressList.join(', ')}');

    // Update provider with contact details data
    final provider = context.read<EmployeeProvider>();
    final contactData = {
      'phone': _phoneController.text,
      'email': _emailController.text,
      'emergency_contact': _emergencyContactController.text,
      'contact_person_name': _emergencyContactPersonController
          .text, // API uses 'contactPersionName'
      'emergency_contact_relation': _emergencyContactRelationController.text,
      'present_address': presentAddressList,
      'permanent_address': permanentAddressList,
    };

    provider.updateFormData('contact_details', contactData);
    print('🐛 DEBUG: Updated provider with contact details data');
    print(
        '🐛 DEBUG: Current completion: ${provider.getCompletionPercentage().toStringAsFixed(1)}%');

    // Print complete summary
    provider.printCompleteDebugSummary();

    print('🐛 DEBUG: ==========================================');
    print('🐛 DEBUG: Navigating to Education Details...');

    context.goNamed("education_details");
  }
}
