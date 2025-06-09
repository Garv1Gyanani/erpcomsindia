import 'dart:io';
import 'package:flutter/material.dart';
import 'package:coms_india/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class NominationFormScreen extends StatefulWidget {
  @override
  _NominationFormScreenState createState() => _NominationFormScreenState();
}

class _NominationFormScreenState extends State<NominationFormScreen> {
  final _formKey = GlobalKey<FormState>();

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
        Row(
          children: [
            Expanded(
              child: _buildMobileTextFormField(
                controller: nominees[index].relationshipController,
                label: 'Relationship with Member',
                hint: 'Wife/Husband/Son/Daughter',
                icon: Icons.family_restroom,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(index),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Share and Guardian Row
        Row(
          children: [
            Expanded(
              child: _buildMobileTextFormField(
                controller: nominees[index].shareController,
                label: 'Share of Provident Fund',
                hint: '50% or ₹Amount',
                icon: Icons.percent,
                keyboardType: TextInputType.text,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileTextFormField(
                controller: nominees[index].guardianController,
                label: 'Guardian (if Nominee is Minor)',
                hint: 'Guardian name & address',
                icon: Icons.shield,
                maxLines: 2,
              ),
            ),
          ],
        ),
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
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.gray500, size: 20),
            filled: true,
            fillColor: AppColors.gray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
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
          onPressed: () {
            context.pushNamed('esicDeclarationForm');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.navigate_next, size: 20),
              SizedBox(width: 8),
              Text(
                'Next',
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
    if (!_formKey.currentState!.validate()) {
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

    // Validate that at least one nominee is filled
    bool hasNominee = nominees.any((nominee) => nominee.hasAnyData());

    if (!hasNominee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Please add at least one nominee',
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

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Nomination form submitted successfully!',
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
      ),
    );

    // Here you would typically send the data to your backend
    print('Nomination Form submitted:');
    for (int i = 0; i < nominees.length; i++) {
      if (nominees[i].hasAnyData()) {
        print('Nominee ${i + 1}:');
        print('  Name: ${nominees[i].nameController.text}');
        print('  Address: ${nominees[i].addressController.text}');
        print('  Relationship: ${nominees[i].relationshipController.text}');
        print('  DOB: ${nominees[i].dateOfBirth}');
        print('  Share: ${nominees[i].shareController.text}');
        print('  Guardian: ${nominees[i].guardianController.text}');
        print('  Contact: ${nominees[i].contactController.text}');
      }
    }
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
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
        Text(
          'Witness $witnessNumber - Name & Address',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.gray700,
          ),
        ),
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
                      GestureDetector(
                        onTap: () => _pickSignature(onFileSelected),
                        child: Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            border: Border.all(color: AppColors.gray300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: signature != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        signature,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload_file,
                                      color: AppColors.gray500,
                                      size: 24,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Upload Signature',
                                      style: TextStyle(
                                        color: AppColors.gray500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
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
                        GestureDetector(
                          onTap: () => _pickSignature(onFileSelected),
                          child: Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              border: Border.all(color: AppColors.gray300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: signature != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          signature,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file,
                                        color: AppColors.gray500,
                                        size: 20,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Upload',
                                        style: TextStyle(
                                          color: AppColors.gray500,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
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

  Future<void> _pickSignature(Function(File?) onFileSelected) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (image != null) {
        onFileSelected(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
