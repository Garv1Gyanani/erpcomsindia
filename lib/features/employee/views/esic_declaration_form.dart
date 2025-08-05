import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:coms_india/core/constants/app_colors.dart';
import '../controllers/employee_provider.dart';
import '../../../core/utils/validation_utils.dart';

class EsicDeclarationForm extends StatefulWidget {
  const EsicDeclarationForm({Key? key}) : super(key: key);

  @override
  State<EsicDeclarationForm> createState() => _EsicDeclarationFormState();
}

class _EsicDeclarationFormState extends State<EsicDeclarationForm> {
  final _formKey = GlobalKey<FormState>();
  final _insuranceNoController = TextEditingController();
  final _branchOfficeController = TextEditingController();
  final _dispensaryController = TextEditingController();

  static const int maxFamilyMembers = 5;
  List<FamilyMember> familyMembers = [FamilyMember()];

  @override
  void initState() {
    super.initState();

    // Pre-populate fields with sample data for easy testing
    _insuranceNoController.text = "";
    _branchOfficeController.text = "";
    _dispensaryController.text = "";

    // Initialize first family member's data
    familyMembers[0].nameController.text = "";
    familyMembers[0].dobController.text = "";
    familyMembers[0].relationshipController.text = "";
    familyMembers[0].residing = "Yes"; // Default to "Yes"
    familyMembers[0].residenceController.text = "";

    _setupDebugListeners();
    print('🐛 DEBUG: ESIC Declaration Form initialized with sample data');
  }

  void _setupDebugListeners() {
    _insuranceNoController.addListener(() {
      print('🐛 DEBUG: Insurance No changed: ${_insuranceNoController.text}');
      _updateProviderData();
    });

    _branchOfficeController.addListener(() {
      print('🐛 DEBUG: Branch Office changed: ${_branchOfficeController.text}');
      _updateProviderData();
    });

    _dispensaryController.addListener(() {
      print('🐛 DEBUG: Dispensary changed: ${_dispensaryController.text}');
      _updateProviderData();
    });
  }

  void _updateProviderData() {
    final provider = context.read<EmployeeProvider>();
    final data = _collectFormData();
    provider.updateFormData('esic_declaration', data);
    print('🐛 DEBUG: Updated ESIC data in provider: ${data.keys.join(', ')}');
  }

  Map<String, dynamic> _collectFormData() {
    final familyData = familyMembers
        .map((member) => {
              'name': member.nameController.text,
              'dob': member.dobController.text,
              'relation': member.relationshipController.text,
              'residing': member.residing,
              'residence': member.residenceController.text,
            })
        .toList();

    print(
        '🐛 DEBUG: Collecting ESIC form data - ${familyData.length} family members');

    return {
      'insurance_no': _insuranceNoController.text,
      'branch_office': _branchOfficeController.text,
      'dispensary': _dispensaryController.text,
      'family': familyData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'ESIC Declaration Form',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              onPressed: () {
                // Check if there's something to pop, otherwise go to govt & bank details
                if (context.canPop()) {
                  context.pop(); // Go back to govt & bank details
                } else {
                  context.goNamed(
                      'govt_bank_details'); // Fallback to govt & bank details
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 20),
                  _buildBasicInfoCard(),
                  const SizedBox(height: 20),
                  _buildFamilyParticularCard(),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'ESIC (DECLARATION FORM)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Mobile layout
                return Column(
                  children: [
                    _buildTextField(
                      controller: _insuranceNoController,
                      label: '1. Insurance No.',
                      hint: 'e.g. 1234567890',
                      maxLength: 20,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _branchOfficeController,
                      label: 'Branch Office',
                      hint: 'e.g. Mumbai Central',
                      maxLength: 30,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _dispensaryController,
                      label: 'Dispensary',
                      hint: 'e.g. ESIC Dispensary No. 5',
                      maxLength: 30,
                    ),
                  ],
                );
              } else {
                // Desktop layout
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _insuranceNoController,
                        label: '1. Insurance No.',
                        hint: 'e.g. 1234567890',
                        maxLength: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _branchOfficeController,
                        label: 'Branch Office',
                        hint: 'e.g. Mumbai Central',
                        maxLength: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _dispensaryController,
                        label: 'Dispensary',
                        hint: 'e.g. ESIC Dispensary No. 5',
                        maxLength: 30,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
            filled: true,
            fillColor: AppColors.gray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            counterText: '', // Hide counter
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyParticularCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Family Particulars of Insured Person',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: familyMembers.length >= maxFamilyMembers
                    ? null
                    : _addFamilyMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: familyMembers.length >= maxFamilyMembers
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                  ),
                ),
              ),
              if (familyMembers.length >= maxFamilyMembers)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Maximum 5 family members allowed',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFamilyMembersList(),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          // Mobile layout - use cards
          return Column(
            children: familyMembers.asMap().entries.map((entry) {
              int index = entry.key;
              return _buildFamilyMemberCard(index);
            }).toList(),
          );
        } else {
          // Desktop layout - use table
          return _buildDesktopTable(); // You’ll define this separately
        }
      },
    );
  }

  Widget _buildFamilyMemberCard(int index) {
    final member = familyMembers[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.gray100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Family Member ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.gray800,
                ),
              ),
              if (familyMembers.length > 1)
                IconButton(
                  onPressed: () => _removeFamilyMember(index),
                  icon: const Icon(Icons.delete,
                      color: AppColors.error, size: 20),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: member.nameController,
            label: 'Name',
            hint: 'e.g. Ramesh Kumar',
            maxLength: 30,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: member.dobController,
            label: 'Date of Birth / Age',
            hint: 'e.g. 15/08/1980 or 43',
            maxLength: 15,
            // validator: (value) {
            //   if (value == null || value.trim().isEmpty) {
            //     return 'Date of Birth or Age is required';
            //   }
            //   // Accepts DD/MM/YYYY or age (number)
            //   final dobReg = RegExp(r'^\d{2}/\d{2}/\d{4}$');
            //   final ageReg = RegExp(r'^\d{1,3}$');
            //   if (!dobReg.hasMatch(value.trim()) &&
            //       !ageReg.hasMatch(value.trim())) {
            //     return 'Enter as DD/MM/YYYY or Age';
            //   }
            //   return null;
            // },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: member.relationshipController,
            label: 'Relationship with Employee',
            hint: 'e.g. Spouse, Child, Parent',
            maxLength: 20,
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Whether residing with him/her?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: member
                    .residing, // Use the stored value, which defaults to "Yes"
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.gray100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                  DropdownMenuItem(value: 'No', child: Text('No')),
                ],
                onChanged: (value) {
                  setState(() {
                    member.residing =
                        value ?? 'Yes'; // Ensure a value is always set
                  });
                  print(
                      '🐛 DEBUG: Family member residing status changed to: $value');
                  _updateProviderData();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select Yes or No';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: member.residenceController,
            label: 'If \'No\', state Place of Residence',
            hint: 'e.g. Pune, Maharashtra',
            maxLength: 30,
            validator: (value) {
              if (member.residing == 'No') {
                if (value == null || value.trim().isEmpty) {
                  return 'Place of residence is required if not residing';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text('Sl. No.',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Name',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Date of Birth / Age',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Relationship',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Residing with?',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Place of Residence',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Action',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          // Table Rows
          Column(
            children: familyMembers.asMap().entries.map((entry) {
              int index = entry.key;
              return _buildDesktopTableRow(index);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableRow(int index) {
    final member = familyMembers[index];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.gray300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: member.nameController,
              maxLength: 30,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name required';
                }
                if (value.length < 2) {
                  return 'Enter valid name';
                }
                return null;
              },
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
                hintText: 'e.g. Ramesh Kumar',
                counterText: '',
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: member.dobController,
              maxLength: 15,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'DOB/Age required';
                }
                final dobReg = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                final ageReg = RegExp(r'^\d{1,3}$');
                if (!dobReg.hasMatch(value.trim()) &&
                    !ageReg.hasMatch(value.trim())) {
                  return 'DD/MM/YYYY or Age';
                }
                return null;
              },
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
                hintText: 'e.g. 15/08/1980 or 43',
                counterText: '',
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: member.relationshipController,
              maxLength: 20,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Relationship required';
                }
                return null;
              },
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
                hintText: 'e.g. Spouse, Child',
                counterText: '',
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: member.residing, // Correctly using the stored value.
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              style: const TextStyle(fontSize: 12, color: Colors.black),
              items: const [
                DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                DropdownMenuItem(value: 'No', child: Text('No')),
              ],
              onChanged: (value) {
                setState(() {
                  member.residing = value ?? 'Yes'; // Ensure value is set.
                });
                print(
                    '🐛 DEBUG: Desktop table - Family member residing status changed to: $value');
                _updateProviderData();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Select Yes/No';
                }
                return null;
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: member.residenceController,
              maxLength: 30,
              validator: (value) {
                if (member.residing == 'No') {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required if not residing';
                  }
                }
                return null;
              },
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
                hintText: 'e.g. Pune, Maharashtra',
                counterText: '',
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: familyMembers.length > 1
                ? IconButton(
                    onPressed: () => _removeFamilyMember(index),
                    icon: const Icon(
                      Icons.delete,
                      color: AppColors.error,
                      size: 20,
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Row(
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
            'Continue to EPF Declaration',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  void _addFamilyMember() {
    if (familyMembers.length < maxFamilyMembers) {
      setState(() {
        familyMembers.add(FamilyMember());
      });
      print('🐛 DEBUG: Added family member. Total: ${familyMembers.length}');
      _updateProviderData();
    } else {
      print(
          '🐛 DEBUG: Cannot add more family members. Max limit reached: $maxFamilyMembers');
    }
  }

  void _removeFamilyMember(int index) {
    if (familyMembers.length > 1) {
      setState(() {
        familyMembers[index].dispose();
        familyMembers.removeAt(index);
      });
      print(
          '🐛 DEBUG: Removed family member at index $index. Total: ${familyMembers.length}');
      _updateProviderData();
    } else {
      print('🐛 DEBUG: Cannot remove last family member');
    }
  }

  void _submitForm() {
    print('🐛 DEBUG: Starting ESIC form submission validation...');

    bool valid = _formKey.currentState?.validate() ?? false;
    print('🐛 DEBUG: Form validation result: $valid');

    if (!valid) {
      print('🐛 DEBUG: Form validation failed - showing error message');
      // Show error if not valid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Please fill all required fields correctly.'),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Final data update to provider before submission
    _updateProviderData();

    final provider = context.read<EmployeeProvider>();
    final allData = provider.allFormData;
    final completionPercentage = provider.getCompletionPercentage();
    final missingScreens = provider.getMissingScreens();

    print('🐛 DEBUG: ===== ESIC FORM SUBMISSION SUCCESS =====');
    print('🐛 DEBUG: Insurance No: ${_insuranceNoController.text}');
    print('🐛 DEBUG: Branch Office: ${_branchOfficeController.text}');
    print('🐛 DEBUG: Dispensary: ${_dispensaryController.text}');
    print('🐛 DEBUG: Family Members Count: ${familyMembers.length}');
    print(
        '🐛 DEBUG: Overall Completion: ${completionPercentage.toStringAsFixed(1)}%');
    print('🐛 DEBUG: Completed Screens: ${allData.keys.join(', ')}');
    print('🐛 DEBUG: Missing Screens: ${missingScreens.join(', ')}');
    print('🐛 DEBUG: ==========================================');

    // Print complete data collection summary
    provider.printCompleteDebugSummary();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('ESIC Declaration form saved successfully!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );

    // Show debug info about single API integration
    print(
        '🐛 DEBUG: Ready to integrate with single API when all screens completed');
    if (completionPercentage >= 100) {
      print(
          '🐛 DEBUG: All screens completed! API call will be triggered automatically!');
    }

    // Navigate to EPF Declaration Form
    print('🐛 DEBUG: Navigating to EPF Declaration Form...');
    context.goNamed('epf_declaration');
  }

  @override
  void dispose() {
    _insuranceNoController.dispose();
    _branchOfficeController.dispose();
    _dispensaryController.dispose();
    for (var member in familyMembers) {
      member.dispose();
    }
    super.dispose();
  }
}

class FamilyMember {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController relationshipController = TextEditingController();
  final TextEditingController residenceController = TextEditingController();
  String residing = 'Yes'; // Default value is now set here.

  void dispose() {
    nameController.dispose();
    dobController.dispose();
    relationshipController.dispose();
    residenceController.dispose();
  }
}
