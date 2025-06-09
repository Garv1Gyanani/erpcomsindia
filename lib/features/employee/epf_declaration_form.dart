import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'EPF Declaration Form',
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
              _buildProvidentPensionCard(),
              const SizedBox(height: 20),
              _buildPreviousEmploymentCard(),
              const SizedBox(height: 20),
              _buildInternationalWorkerCard(),
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
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 4,
          shadowColor: AppColors.success.withOpacity(0.4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 20),
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
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

      // Navigate back or to next screen
      context.pop();
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
