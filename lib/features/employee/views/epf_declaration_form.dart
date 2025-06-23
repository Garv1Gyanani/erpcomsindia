import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:coms_india/core/constants/app_colors.dart';
import '../controllers/employee_provider.dart';

class EpfDeclarationForm extends StatefulWidget {
  const EpfDeclarationForm({super.key});

  @override
  State<EpfDeclarationForm> createState() => _EpfDeclarationFormState();
}

class _EpfDeclarationFormState extends State<EpfDeclarationForm> {
  final _formKey = GlobalKey<FormState>();

  // Provident & Pension Scheme Controllers
  bool _earlierProvidentMember = true;
  bool _earlierPensionMember = true;

  // Previous Employment Controllers
  final _uanController = TextEditingController();
  final _previousPfController = TextEditingController();
  final _exitDateController = TextEditingController();
  final _schemeCertificateController = TextEditingController();
  final _ppoController = TextEditingController();

  // International Worker Controllers
  bool _isInternationalWorker = true;
  final _countryController = TextEditingController();
  final _passportController = TextEditingController();
  final _passportFromController = TextEditingController();
  final _passportToController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Pre-populate fields with sample data for easy testing
    _uanController.text = "UAN12345678";
    _previousPfController.text = "PF987654321";
    _exitDateController.text = "2023-12-31";
    _schemeCertificateController.text = "SC12345";
    _ppoController.text = "PPO67890";
    _countryController.text = "India";
    _passportController.text = "M1234567";
    _passportFromController.text = "2020-01-01";
    _passportToController.text = "2030-01-01";

    print('🚀 DEBUG: EPF Declaration Form - Sample data pre-populated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'EPF Declaration Form',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            // Check if there's something to pop, otherwise go to ESIC declaration
            if (context.canPop()) {
              context.pop(); // Go back to ESIC declaration
            } else {
              context
                  .goNamed('esic_declaration'); // Fallback to ESIC declaration
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
              _buildProvidentPensionCard(),
              const SizedBox(height: 20),
              _buildPreviousEmploymentCard(),
              const SizedBox(height: 20),
              _buildInternationalWorkerCard(),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildSubmitButton(),
                ],
              ),
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
            'EMPLOYEES\' PROVIDENT FUND ORGANISATION',
            style: TextStyle(
              fontSize: 20,
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

  Widget _buildProvidentPensionCard() {
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
          Text(
            'Employee\'s Provident & Pension Scheme Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 20),
          // Question 7
          _buildQuestionSection(
            '7. Whether earlier member of the Employee\'s Provident Fund Scheme, 1952?',
            _earlierProvidentMember,
            (value) => setState(() => _earlierProvidentMember = value),
          ),
          const SizedBox(height: 16),
          // Question 8
          _buildQuestionSection(
            '8. Whether earlier member of the Employee\'s Pension Scheme, 1995?',
            _earlierPensionMember,
            (value) => setState(() => _earlierPensionMember = value),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousEmploymentCard() {
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
          Text(
            'Previous Employment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return _buildMobilePreviousEmploymentLayout();
              } else {
                return _buildDesktopPreviousEmploymentLayout();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePreviousEmploymentLayout() {
    return Column(
      children: [
        _buildTextField(
          controller: _uanController,
          label: 'a) Universal Account Number (UAN)',
          hint: 'Enter UAN Number',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _previousPfController,
          label: 'b) Previous PF Account Number',
          hint: 'Enter Previous PF Number',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          controller: _exitDateController,
          label: 'c) Date of Exit from previous Employment',
          hint: 'dd-mm-yyyy',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _schemeCertificateController,
          label: 'd) Scheme Certificate No (if issued)',
          hint: 'Enter Scheme Certificate No',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _ppoController,
          label: 'e) Pension Payment Order (PPO) (if issued)',
          hint: 'Enter PPO No',
        ),
      ],
    );
  }

  Widget _buildDesktopPreviousEmploymentLayout() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _uanController,
                label: 'a) Universal Account Number (UAN)',
                hint: 'Enter UAN Number',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _previousPfController,
                label: 'b) Previous PF Account Number',
                hint: 'Enter Previous PF Number',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                controller: _exitDateController,
                label: 'c) Date of Exit from previous Employment',
                hint: 'dd-mm-yyyy',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _schemeCertificateController,
                label: 'd) Scheme Certificate No (if issued)',
                hint: 'Enter Scheme Certificate No',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _ppoController,
          label: 'e) Pension Payment Order (PPO) (if issued)',
          hint: 'Enter PPO No',
        ),
      ],
    );
  }

  Widget _buildInternationalWorkerCard() {
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
          Text(
            '10. International Worker Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 20),
          _buildQuestionSection(
            'a) Are you an International Worker?',
            _isInternationalWorker,
            (value) => setState(() => _isInternationalWorker = value),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return _buildMobileInternationalLayout();
              } else {
                return _buildDesktopInternationalLayout();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInternationalLayout() {
    return Column(
      children: [
        _buildTextField(
          controller: _countryController,
          label: 'b) If Yes, state country of origin',
          hint: 'Country of origin',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passportController,
          label: 'c) Passport Number',
          hint: 'Passport No.',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          controller: _passportFromController,
          label: 'd) Validity of passport (From)',
          hint: 'dd-mm-yyyy',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          controller: _passportToController,
          label: 'd) Validity of passport (To)',
          hint: 'dd-mm-yyyy',
        ),
      ],
    );
  }

  Widget _buildDesktopInternationalLayout() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _countryController,
                label: 'b) If Yes, state country of origin',
                hint: 'Country of origin',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _passportController,
                label: 'c) Passport Number',
                hint: 'Passport No.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                controller: _passportFromController,
                label: 'd) Validity of passport (From)',
                hint: 'dd-mm-yyyy',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                controller: _passportToController,
                label: 'd) Validity of passport (To)',
                hint: 'dd-mm-yyyy',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionSection(
    String question,
    bool value,
    Function(bool) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: value,
              onChanged: (val) => onChanged(val!),
              activeColor: AppColors.primary,
            ),
            const Text('Yes'),
            const SizedBox(width: 20),
            Radio<bool>(
              value: false,
              groupValue: value,
              onChanged: (val) => onChanged(val!),
              activeColor: AppColors.primary,
            ),
            const Text('No'),
          ],
        ),
      ],
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

  Widget _buildDateField({
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
            suffixIcon:
                const Icon(Icons.calendar_today, color: AppColors.gray400),
          ),
          onTap: () => _selectDate(controller),
          readOnly: true,
        ),
      ],
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
    }
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _submitForm,
      label: const Text(
        'Continue to Nomination Form',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(200, 40),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 1,
        shadowColor: AppColors.primary.withOpacity(0.15),
      ),
    );
  }

  void _submitForm() {
    print('🐛 DEBUG: ===== EPF DECLARATION FORM SUBMISSION =====');
    print('🐛 DEBUG: Earlier Provident Member: $_earlierProvidentMember');
    print('🐛 DEBUG: Earlier Pension Member: $_earlierPensionMember');
    print('🐛 DEBUG: UAN Number: ${_uanController.text}');
    print('🐛 DEBUG: Previous PF Number: ${_previousPfController.text}');
    print('🐛 DEBUG: Exit Date: ${_exitDateController.text}');
    print('🐛 DEBUG: International Worker: $_isInternationalWorker');
    print('🐛 DEBUG: Country: ${_countryController.text}');
    print('🐛 DEBUG: Passport Number: ${_passportController.text}');

    if (_formKey.currentState!.validate()) {
      // Update provider with EPF data
      final provider = context.read<EmployeeProvider>();
      final epfData = {
        'pf_member': _earlierProvidentMember ? 'Yes' : 'No',
        'pension_member': _earlierPensionMember ? 'Yes' : 'No',
        'uan_number': _uanController.text,
        'previous_pf_number': _previousPfController.text,
        'exit_date': _exitDateController.text,
        'scheme_certificate': _schemeCertificateController.text,
        'ppo': _ppoController.text,
        'international_worker': _isInternationalWorker ? 'Yes' : 'No',
        'country_origin': _countryController.text,
        'passport_number': _passportController.text,
        'passport_valid_from': _passportFromController.text,
        'passport_valid_to': _passportToController.text,
      };

      provider.updateFormData('epf_declaration', epfData);
      print('🐛 DEBUG: Updated provider with EPF data');
      print(
          '🐛 DEBUG: Current completion: ${provider.getCompletionPercentage().toStringAsFixed(1)}%');

      // Print complete summary to show single API integration
      provider.printCompleteDebugSummary();

      print('🐛 DEBUG: ============================================');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('EPF Declaration form submitted successfully!'),
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

      // Example: If all forms are completed, show ready for API call
      if (provider.getCompletionPercentage() >= 100) {
        print('🐛 DEBUG: 🎉 ALL FORMS COMPLETED! Calling single API...');
        print('🐛 DEBUG: Call: provider.createEmployeeFromCollectedData()');
        // Uncomment the line below to actually make the API call
        // provider.createEmployeeFromCollectedData();
      }

      // Navigate to final screen (nomination form)
      print('🐛 DEBUG: Navigating to Nomination Form...');
      context.goNamed('nomination_form');
    } else {
      print('🐛 DEBUG: EPF form validation failed');
    }
  }

  @override
  void dispose() {
    _uanController.dispose();
    _previousPfController.dispose();
    _exitDateController.dispose();
    _schemeCertificateController.dispose();
    _ppoController.dispose();
    _countryController.dispose();
    _passportController.dispose();
    _passportFromController.dispose();
    _passportToController.dispose();
    super.dispose();
  }
}
