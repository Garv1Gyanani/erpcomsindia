import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class EsicDeclarationForm extends StatefulWidget {
  const EsicDeclarationForm({super.key});

  @override
  State<EsicDeclarationForm> createState() => _EsicDeclarationFormState();
}

class _EsicDeclarationFormState extends State<EsicDeclarationForm> {
  final _formKey = GlobalKey<FormState>();
  final _insuranceNoController = TextEditingController();
  final _branchOfficeController = TextEditingController();
  final _dispensaryController = TextEditingController();

  List<FamilyMember> familyMembers = [FamilyMember()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ESIC Declaration Form',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
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
          Text(
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
                      hint: 'Enter insurance number',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _branchOfficeController,
                      label: 'Branch Office',
                      hint: 'Enter branch office',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _dispensaryController,
                      label: 'Dispensary',
                      hint: 'Enter dispensary',
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
                        hint: 'Enter insurance number',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _branchOfficeController,
                        label: 'Branch Office',
                        hint: 'Enter branch office',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _dispensaryController,
                        label: 'Dispensary',
                        hint: 'Enter dispensary',
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
              Expanded(
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
                onPressed: _addFamilyMember,
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
                label: const Text(
                  'Add',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
          return _buildDesktopTable();
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
              IconButton(
                onPressed: () => _removeFamilyMember(index),
                icon:
                    const Icon(Icons.delete, color: AppColors.error, size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: member.nameController,
            label: 'Name',
            hint: 'Enter family member name',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: member.dobController,
            label: 'Date of Birth / Age',
            hint: 'DD/MM/YYYY or Age',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: member.relationshipController,
            label: 'Relationship with Employee',
            hint: 'e.g., Spouse, Child, Parent',
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
                value: member.residing,
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
                    member.residing = value ?? 'Yes';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: member.residenceController,
            label: 'If \'No\', state Place of Residence',
            hint: 'Town & State',
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
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
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
      decoration: BoxDecoration(
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
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: member.dobController,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
                hintText: 'DD/MM/YYYY',
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: member.relationshipController,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: member.residing,
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
                  member.residing = value ?? 'Yes';
                });
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: member.residenceController,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              onPressed: () => _removeFamilyMember(index),
              icon: const Icon(
                Icons.delete,
                color: AppColors.error,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 4,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 8),
            Text(
              'Submit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addFamilyMember() {
    setState(() {
      familyMembers.add(FamilyMember());
    });
  }

  void _removeFamilyMember(int index) {
    if (familyMembers.length > 1) {
      setState(() {
        familyMembers[index].dispose();
        familyMembers.removeAt(index);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
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

      // Navigate to EPF Declaration Form
      context.goNamed('epfDeclarationForm');
    }
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
  String residing = 'Yes';

  void dispose() {
    nameController.dispose();
    dobController.dispose();
    relationshipController.dispose();
    residenceController.dispose();
  }
}
