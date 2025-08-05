import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/employee_provider.dart';
import '../../../core/utils/validation_utils.dart';

class EmploymentDetailsScreen extends StatefulWidget {
  const EmploymentDetailsScreen({super.key});

  @override
  State<EmploymentDetailsScreen> createState() =>
      _EmploymentDetailsScreenState();
}

class _EmploymentDetailsScreenState extends State<EmploymentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  List<PreviousEmploymentData> previousEmployments = [PreviousEmploymentData()];

  @override
  void initState() {
    super.initState();
    // Pre-populate with sample data for testing
    previousEmployments[0].companyNameController.text = "";
    previousEmployments[0].designationController.text = "";
    previousEmployments[0].fromDate = DateTime(2020, 1, 1);
    previousEmployments[0].toDate = DateTime(2022, 1, 1);
    previousEmployments[0].reasonController.text = "";

    print('🚀 DEBUG: Previous Employment Details - Sample data pre-populated');
  }

  @override
  void dispose() {
    for (var employment in previousEmployments) {
      employment.dispose();
    }
    super.dispose();
  }

  void _addPreviousEmployment() {
    setState(() {
      previousEmployments.add(PreviousEmploymentData());
    });
  }

  void _removePreviousEmployment(int index) {
    if (previousEmployments.length > 1) {
      setState(() {
        previousEmployments[index].dispose();
        previousEmployments.removeAt(index);
      });
    }
  }

  Future<void> _selectDate(
      BuildContext context, Function(DateTime) onDateSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) onDateSelected(picked);
  }

Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final provider = context.read<EmployeeProvider>();

        // Collect previous employment data
        final previousEmploymentData = previousEmployments
            .where((emp) => emp.hasAnyData())
            .map((emp) => {
                  'company_name': emp.companyNameController.text,
                  'designation': emp.designationController.text,
                  'from_date':
                      emp.fromDate?.toIso8601String().split('T')[0] ?? '',
                  'to_date': emp.toDate?.toIso8601String().split('T')[0] ?? '',
                  'reason_for_leaving': emp.reasonController.text,
                })
            .toList();

        final employmentDetailsData = {
          'previous_employment': previousEmploymentData,
        };

        print('🐛 DEBUG: Previous Employment Data: $employmentDetailsData');
        provider.updateFormData('previous_employment_details', employmentDetailsData); // CHANGED KEY HERE

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Previous employment details saved! Continue to next step.')),
          );
          context.goNamed('contact_details'); // Navigate to contact details
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('employment_details');
            }
          },
        ),
        title: const Text(
          'Previous Employment Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildPreviousEmploymentSection(),
              // const SizedBox(height: 32),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add details of your previous employment history. You can add multiple previous jobs.',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousEmploymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Previous Employment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...previousEmployments.asMap().entries.map((entry) {
          int index = entry.key;
          PreviousEmploymentData employment = entry.value;
          return _buildPreviousEmploymentCard(employment, index);
        }).toList(),
      ],
    );
  }

  Widget _buildPreviousEmploymentCard(
      PreviousEmploymentData employment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          // Company Name and Designation Row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Company Name',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: employment.companyNameController,
                decoration: _getInputDecoration('ABC Pvt Ltd'),
                validator: ValidationUtils.validateCompanyName,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Designation',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: employment.designationController,
                decoration: _getInputDecoration('Software Engineer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('From Date',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, (date) {
                        setState(() => employment.fromDate = date);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              employment.fromDate != null
                                  ? '${employment.fromDate!.day.toString().padLeft(2, '0')}-${employment.fromDate!.month.toString().padLeft(2, '0')}-${employment.fromDate!.year}'
                                  : 'dd-mm-yyyy',
                              style: TextStyle(
                                color: employment.fromDate != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To Date',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, (date) {
                        setState(() => employment.toDate = date);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              employment.toDate != null
                                  ? '${employment.toDate!.day.toString().padLeft(2, '0')}-${employment.toDate!.month.toString().padLeft(2, '0')}-${employment.toDate!.year}'
                                  : 'dd-mm-yyyy',
                              style: TextStyle(
                                color: employment.toDate != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Reason for Leaving
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reason for Leaving',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: employment.reasonController,
                decoration: _getInputDecoration('e.g., Better Opportunity'),
              ),
            ],
          ),

          // Delete button below all fields
          if (previousEmployments.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Employment',
                  onPressed: () => _removePreviousEmployment(index),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _addPreviousEmployment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            '+ Add Employment',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(height: 45),
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(200, 50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Continue to Contact Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

class PreviousEmploymentData {
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;

  void dispose() {
    companyNameController.dispose();
    designationController.dispose();
    reasonController.dispose();
  }

  bool hasAnyData() {
    return companyNameController.text.isNotEmpty ||
        designationController.text.isNotEmpty ||
        reasonController.text.isNotEmpty ||
        fromDate != null ||
        toDate != null;
  }
}
