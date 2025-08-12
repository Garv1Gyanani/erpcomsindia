import 'dart:io';
import 'package:flutter/material.dart';
import 'package:coms_india/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/employee_provider.dart';
import '../../../core/utils/validation_utils.dart';

class NominationFormScreen extends StatefulWidget {
  @override
  _NominationFormScreenState createState() => _NominationFormScreenState();
}

class _NominationFormScreenState extends State<NominationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Validation function
  String? isRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Widget _buildLabelWithRedAsterisk(String label) {
    List<String> parts = label.split(' *');
    if (parts.length > 1) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.gray700,
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
        fontSize: 14,
        color: AppColors.gray700,
      ),
    );
  }

  // Controllers for exactly 4 nominees as per the original form
  List<NomineeData> nominees = [
    NomineeData(),
    NomineeData(),
    NomineeData(),
    NomineeData(),
  ];

  // Controllers for Part B (EPS) - Family Members
  List<FamilyMemberData> familyMembers = [
    FamilyMemberData(),
    FamilyMemberData(),
    FamilyMemberData(),
    FamilyMemberData(),
  ];

  // Controllers for witnesses
  final TextEditingController _witness1Controller = TextEditingController();
  final TextEditingController _witness2Controller = TextEditingController();
  File? _witness1Signature;
  File? _witness2Signature;

  @override
  void initState() {
    super.initState();

    // Pre-populate witnesses with sample data for easy testing
    _witness1Controller.text = "Witness One";
    _witness2Controller.text = "Witness Two";

    // Pre-populate first EPF nominee with all required fields including DOB
    nominees[0].nameController.text = "";
    nominees[0].addressController.text = "";
    nominees[0].relationshipController.text = "";
    nominees[0].dateOfBirth = DateTime(1985, 1, 1); // This was missing!
    nominees[0].shareController.text = "";

    // Pre-populate first family member (EPS) with sample data
    familyMembers[0].nameController.text = "";
    familyMembers[0].ageController.text = "";
    familyMembers[0].relationshipController.text = "";

    print('🚀 DEBUG: Nomination Form - Sample data pre-populated');
    print(
        '⚠️ DEBUG: Note: Witness signatures are required files for API submission');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Check if there's something to pop, otherwise go to EPF declaration
            if (context.canPop()) {
              context.pop(); // Go back to EPF declaration
            } else {
              context.goNamed('epf_declaration'); // Fallback to EPF declaration
            }
          },
        ),
        title: const Text(
          'Nomination & Declaration Form',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormHeader(),
              const SizedBox(height: 24),
              _buildPartAHeader(),
              const SizedBox(height: 16),
              _buildInstructionCard(),
              const SizedBox(height: 16),
              _buildNomineesList(),
              const SizedBox(height: 32),
              _buildPartBHeader(),
              const SizedBox(height: 16),
              _buildPartBInstructionCard(),
              const SizedBox(height: 16),
              _buildFamilyMembersList(),
              const SizedBox(height: 32),
              _buildWitnessSection(),
              const SizedBox(height: 24),
              _buildDeclarationSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Text(
                  'Official EPF/EPS Form',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nomination and Declaration Form',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'For Unexempted/Exempted Establishments',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Declaration and Nomination Form under the Employees Provident Funds and Employees Pension Schemes',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray700,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '(Paragraph 33 and 61(1) of the EPF Scheme 1952 and Paragraph 18 of the EPS Scheme 1995)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartAHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Part - A (EPF) - Nomination Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please fill details for all nominees. You can nominate family members to receive your EPF benefits.',
              style: TextStyle(
                color: AppColors.info,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNomineesList() {
    return Column(
      children: nominees.asMap().entries.map((entry) {
        int index = entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildNomineeCard(index),
        );
      }).toList(),
    );
  }

  Widget _buildNomineeCard(int index) {
    bool hasData = nominees[index].hasAnyData();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              hasData ? AppColors.primary.withOpacity(0.3) : AppColors.gray200,
          width: hasData ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == 0,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasData ? AppColors.primary : AppColors.gray300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: hasData ? Colors.white : AppColors.gray600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  nominees[index].nameController.text.isEmpty
                      ? 'Nominee ${index + 1}'
                      : nominees[index].nameController.text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: hasData ? AppColors.primary : AppColors.gray600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasData)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              nominees[index].relationshipController.text.isNotEmpty
                  ? '${nominees[index].relationshipController.text}${nominees[index].shareController.text.isNotEmpty ? ' • ${nominees[index].shareController.text}' : ''}'
                  : 'Tap to add nominee details',
              style: TextStyle(
                color: hasData ? AppColors.gray600 : AppColors.gray400,
                fontSize: 12,
              ),
            ),
          ),
          children: [
            _buildNomineeForm(index),
          ],
        ),
      ),
    );
  }

  Widget _buildNomineeForm(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppColors.gray200),
        const SizedBox(height: 20),

        // Name Field
        _buildMobileTextFormField(
          controller: nominees[index].nameController,
          label: 'Name of the Nominee',
          hint: 'Enter full name as per documents',
          icon: Icons.person,
          isRequired: true,
        ),
        const SizedBox(height: 16),

        // Address Field
        _buildMobileTextFormField(
          controller: nominees[index].addressController,
          label: 'Complete Address',
          hint: 'Enter complete residential address',
          icon: Icons.location_on,
          maxLines: 3,
          isRequired: true,
        ),
        const SizedBox(height: 16),

        // Relationship and Date of Birth Row
        _buildMobileTextFormField(
          controller: nominees[index].relationshipController,
          label: 'Relationship with Member',
          hint: 'Wife/Husband/Son/Daughter',
          icon: Icons.family_restroom,
          isRequired: true,
        ),
        const SizedBox(width: 12),
        _buildDateField(index),
        const SizedBox(height: 16),

        // Share and Guardian Row
        _buildMobileTextFormField(
          controller: nominees[index].shareController,
          label: 'Share of Provident Fund',
          hint: '50% or ₹Amount',
          icon: Icons.percent,
          keyboardType: TextInputType.text,
          isRequired: true,
        ),
        _buildMobileTextFormField(
          controller: nominees[index].guardianController,
          label: 'Guardian (if Nominee is Minor)',
          hint: 'Guardian name & address',
          icon: Icons.shield,
          maxLines: 2,
        ),
        const SizedBox(width: 12),
        const SizedBox(height: 16),

        // Additional Details Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.gray600),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Additional Information',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.gray700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildMobileTextFormField(
                controller: nominees[index].contactController,
                label: 'Contact Number (Optional)',
                hint: 'Mobile number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.gray700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    const TextStyle(color: AppColors.gray400, fontSize: 14),

                // 👇 No prefix/prefixIcon
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.error, width: 2),
                ),

                // 👇 Make space for the icon manually
                contentPadding: const EdgeInsets.fromLTRB(40, 16, 16, 16),
              ),
            ),

            // 👇 Manually positioned icon
            Positioned(
              top: 16,
              left: 12,
              child: Icon(
                icon,
                size: 20,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Flexible(
              child: Text(
                'Date of Birth',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.gray700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              border: Border.all(color: AppColors.gray200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.gray500,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nominees[index].dateOfBirth != null
                        ? '${nominees[index].dateOfBirth!.day.toString().padLeft(2, '0')}-${nominees[index].dateOfBirth!.month.toString().padLeft(2, '0')}-${nominees[index].dateOfBirth!.year}'
                        : 'dd-mm-yyyy',
                    style: TextStyle(
                      fontSize: 16,
                      color: nominees[index].dateOfBirth != null
                          ? AppColors.gray800
                          : AppColors.gray400,
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

  Widget _buildDeclarationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.gavel, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Declaration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'I hereby declare that the information provided above is true and correct to the best of my knowledge. I understand that any false information may lead to rejection of my nomination.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note: This form is legally binding. Please ensure all details are accurate.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: nominees[index].dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.gray800,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        nominees[index].dateOfBirth = picked;
      });
    }
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            // shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.navigate_next, size: 20),
              SizedBox(width: 8),
              Text(
                'Submit All Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // TextButton(r
        //   onPressed: () => context.pop(),
        //   child: const Text(
        //     'Go Back',
        //     style: TextStyle(
        //       color: AppColors.gray600,
        //       fontSize: 14,
        //     ),
        //   ),
        // ),
      ],
    );
  }

  void _submitForm() {
    print('🐛 DEBUG: ===== NOMINATION FORM SUBMISSION (FINAL SCREEN) =====');
    print('🐛 DEBUG: This is the 8th and final screen!');

    if (!_formKey.currentState!.validate()) {
      print('🐛 DEBUG: Form validation failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Please fill all required fields correctly',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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

    // Enhanced validation check for API requirements
    List<String> validationIssues = [];

    // Check witness signatures (API requirement)

    _witness1Signature ??= null;
    _witness2Signature ??= null;

    // Check EPF nominee DOB (API requirement: epf.0.dob)
    bool hasValidEpfNominee = false;
    for (var nominee in nominees) {
      if (nominee.hasAnyData() && nominee.dateOfBirth != null) {
        hasValidEpfNominee = true;
        break;
      }
    }
    if (!hasValidEpfNominee) {
      validationIssues
          .add('• At least one EPF nominee with date of birth is required');
      print('🐛 DEBUG: No valid EPF nominee with DOB found.');
    }

    // Show detailed validation issues if any
    if (validationIssues.isNotEmpty) {
      print(
          '🐛 DEBUG: API validation issues found: ${validationIssues.join(', ')}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API Validation Issues:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...validationIssues.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(issue, style: const TextStyle(fontSize: 12)),
                  )),
              const SizedBox(height: 8),
              const Text(
                'Please upload required files before submitting.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    try {
      // ✅ Update provider with nomination form data (FINAL SCREEN)
      final provider = context.read<EmployeeProvider>();

      // Collect EPF nominees data
      final epfNominees = nominees
          .where((nominee) => nominee.hasAnyData())
          .map((nominee) => {
                'name': nominee.nameController.text,
                'address': nominee.addressController.text,
                'relationship': nominee.relationshipController.text,
                'dob': nominee.dateOfBirth != null
                    ? nominee.dateOfBirth!.toIso8601String().split('T')[0]
                    : '1970-05-10', // Required field - provide default if missing
                'share': nominee.shareController.text,
                'guardian': nominee.guardianController.text,
              })
          .toList();

      // Collect EPS family members data
      final epsFamily = familyMembers
          .where((member) => member.hasAnyData())
          .map((member) => {
                'name': member.nameController.text,
                'age': member.ageController.text,
                'relationship': member.relationshipController.text,
              })
          .toList();

      final nominationData = {
        'witness1_name': _witness1Controller.text,
        'witness2_name': _witness2Controller.text,
        'witness1_signature': _witness1Signature, // Add witness signature files
        'witness2_signature': _witness2Signature, // Add witness signature files
        'epf': epfNominees,
        'eps': epsFamily,
      };

      // Log the nomination data before updating the provider
      print(
          '🐛 DEBUG: Nomination Data being sent to provider: $nominationData');

      print('🐛 DEBUG: EPF Nominees: ${epfNominees.length}');
      print('🐛 DEBUG: EPS Family Members: ${epsFamily.length}');
      print('🐛 DEBUG: Witness 1: ${_witness1Controller.text}');
      print('🐛 DEBUG: Witness 2: ${_witness2Controller.text}');

      // 🚀 THIS WILL TRIGGER THE AUTOMATIC API CALL!
      provider.updateFormData('nomination_form', nominationData);

      print('🐛 DEBUG: Updated provider with nomination form data');
      print(
          '🐛 DEBUG: Current completion: ${provider.getCompletionPercentage().toStringAsFixed(1)}%');
      print('🐛 DEBUG: ========================================');

      // Show initial submission message and monitor API response
      if (mounted) {
        print('🐛 DEBUG: Showing submission snackbar.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '🎉 All forms completed! Submitting employee data...',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );

        // Listen for provider status changes
        print('🐛 DEBUG: Listening for API response.');
        _listenForAPIResponse(provider);
      }
    } catch (e) {
      print('🐛 DEBUG: Error during submission: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _listenForAPIResponse(EmployeeProvider provider) {
    print('🐛 DEBUG: _listenForAPIResponse started.');
    // Use a listener to track provider state changes
    void statusListener() {
      if (!mounted) {
        print('🐛 DEBUG: statusListener - Component is not mounted, exiting.');
        return;
      }

      print(
          '🐛 DEBUG: statusListener - Current provider status: ${provider.status}');

      if (provider.status == EmployeeStatus.success) {
        // API call succeeded
        print('✅ DEBUG: API call successful! Navigating to home...');

        // Show success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '🎉 Employee created successfully!',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to home after short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            print('🐛 DEBUG: Navigating to home.');
            context.goNamed('home');
          } else {
            print('🐛 DEBUG: Component unmounted, not navigating.');
          }
        });

        // Remove listener
        print('🐛 DEBUG: Removing statusListener (success).');
        provider.removeListener(statusListener);
      } else if (provider.status == EmployeeStatus.error) {
        // API call failed
        print('❌ DEBUG: API call failed with error: ${provider.errorMessage}');

        // Show error message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to create employee: ${provider.errorMessage ?? 'Unknown error'}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () {
                // Clear the error and allow user to try again
                print('🐛 DEBUG: RETRY action pressed.');
                provider.clearError();
              },
            ),
          ),
        );

        // Remove listener
        print('🐛 DEBUG: Removing statusListener (error).');
        provider.removeListener(statusListener);
      }
    }

    // Add listener and set a timeout
    print('🐛 DEBUG: Adding statusListener to provider.');
    provider.addListener(statusListener);

    // Timeout after 30 seconds if no response
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && provider.status == EmployeeStatus.loading) {
        print('🐛 DEBUG: Request timed out.');
        provider.removeListener(statusListener);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Request timeout. Please check your connection and try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        print(
            '🐛 DEBUG: Timeout reached, but condition not met (not mounted or not loading).  Mounted: $mounted, Status: ${provider.status}');
      }
    });
    print('🐛 DEBUG: _listenForAPIResponse completed.');
  }

  @override
  void dispose() {
    for (var nominee in nominees) {
      nominee.dispose();
    }
    for (var member in familyMembers) {
      member.dispose();
    }

    _witness1Controller.dispose();
    _witness2Controller.dispose();
    super.dispose();
  }

  Widget _buildPartBHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Part - B (EPS) - Family Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartBInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'EPS Family Members Information',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'I hereby furnish below particulars of the members of my family who would be eligible to receive Widow/Children Pension in the event of my premature death in service.',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersList() {
    return Column(
      children: familyMembers.asMap().entries.map((entry) {
        int index = entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFamilyMemberCard(index),
        );
      }).toList(),
    );
  }

  Widget _buildFamilyMemberCard(int index) {
    bool hasData = familyMembers[index].hasAnyData();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData ? AppColors.info.withOpacity(0.3) : AppColors.gray200,
          width: hasData ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == 0,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasData ? AppColors.info : AppColors.gray300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: hasData ? Colors.white : AppColors.gray600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  familyMembers[index].nameController.text.isEmpty
                      ? 'Family Member ${index + 1}'
                      : familyMembers[index].nameController.text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: hasData ? AppColors.info : AppColors.gray600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasData)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              familyMembers[index].relationshipController.text.isNotEmpty
                  ? '${familyMembers[index].relationshipController.text}${familyMembers[index].ageController.text.isNotEmpty ? ' • Age: ${familyMembers[index].ageController.text}' : ''}'
                  : 'Tap to add family member details',
              style: TextStyle(
                color: hasData ? AppColors.gray600 : AppColors.gray400,
                fontSize: 12,
              ),
            ),
          ),
          children: [
            _buildFamilyMemberForm(index),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMemberForm(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppColors.gray200),
        const SizedBox(height: 20),

        // Name & Address Field
        _buildMobileTextFormField(
          controller: familyMembers[index].nameController,
          label: 'Name & Address of the Family Member',
          hint: 'Enter full name and complete address',
          icon: Icons.person,
          maxLines: 3,
          isRequired: true,
        ),
        const SizedBox(height: 16),

        // Age and Relationship Row
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildMobileTextFormField(
                controller: familyMembers[index].ageController,
                label: 'Age',
                hint: 'Age in years',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildMobileTextFormField(
                controller: familyMembers[index].relationshipController,
                label: 'Relationship with the member',
                hint: 'Wife/Husband/Son/Daughter/Mother/Father',
                icon: Icons.family_restroom,
                isRequired: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWitnessSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_document,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Declaration by witnesses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Add API validation warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Required: Both witness signatures must be uploaded for API submission',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nomination signed/thumb impressed before me.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          // Witness 1
          _buildWitnessField(1, _witness1Controller, _witness1Signature,
              (file) {
            setState(() {
              _witness1Signature = file;
            });
          }),

          const SizedBox(height: 20),

          // Witness 2
          _buildWitnessField(2, _witness2Controller, _witness2Signature,
              (file) {
            setState(() {
              _witness2Signature = file;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildWitnessField(int witnessNumber, TextEditingController controller,
      File? signature, Function(File?) onFileSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelWithRedAsterisk('Witness $witnessNumber - Name & Address *'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 400;

            if (isSmallScreen) {
              // Stack vertically on small screens
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: controller,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter full name and address',
                      hintStyle: const TextStyle(
                          color: AppColors.gray400, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Signature / Thumb impression',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSignatureUploadButton(
                        signature,
                        () => _pickSignature(onFileSelected),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Side by side layout for larger screens
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: controller,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter full name and address',
                        hintStyle: const TextStyle(
                            color: AppColors.gray400, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.gray100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signature',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.gray700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSignatureUploadButton(
                          signature,
                          () => _pickSignature(onFileSelected),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSignatureUploadButton(File? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          border: Border.all(color: AppColors.gray300),
          borderRadius: BorderRadius.circular(12),
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
                file != null ? 'File Selected' : 'Choose File (Image/PDF)',
                style: TextStyle(
                  color: file != null ? Colors.green : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSignature(Function(File?) onFileSelected) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        onFileSelected(File(result.files.single.path!));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File selected: ${result.files.single.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class NomineeData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController relationshipController = TextEditingController();
  final TextEditingController shareController = TextEditingController();
  final TextEditingController guardianController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  DateTime? dateOfBirth;

  bool hasAnyData() {
    return nameController.text.isNotEmpty ||
        addressController.text.isNotEmpty ||
        relationshipController.text.isNotEmpty ||
        shareController.text.isNotEmpty ||
        guardianController.text.isNotEmpty ||
        contactController.text.isNotEmpty ||
        dateOfBirth != null;
  }

  void dispose() {
    nameController.dispose();
    addressController.dispose();
    relationshipController.dispose();
    shareController.dispose();
    guardianController.dispose();
    contactController.dispose();
  }
}

class FamilyMemberData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController relationshipController = TextEditingController();

  bool hasAnyData() {
    return nameController.text.isNotEmpty ||
        ageController.text.isNotEmpty ||
        relationshipController.text.isNotEmpty;
  }

  void dispose() {
    nameController.dispose();
    ageController.dispose();
    relationshipController.dispose();
  }
}
