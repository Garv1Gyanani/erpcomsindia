import 'package:coms_india/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/employee_provider.dart';

class EducationalDetailsSection extends StatefulWidget {
  @override
  _EducationalDetailsSectionState createState() =>
      _EducationalDetailsSectionState();
}

class _EducationalDetailsSectionState extends State<EducationalDetailsSection> {
  final List<EducationEntry> _educationEntries = [];
  final _formKey = GlobalKey<FormState>(); // Add a form key

  @override
  void initState() {
    super.initState();
    if (_educationEntries.isEmpty) {
      _addEducationEntry();
      // Pre-populate first education entry with sample data
      final firstEntry = _educationEntries.first;
      firstEntry.degreeController.text = "";
      firstEntry.universityController.text = "";
      firstEntry.specializationController.text = "";
      firstEntry.fromYearController.text = "";
      firstEntry.toYearController.text = "";
      firstEntry.percentageController.text = "";
      print('🚀 DEBUG: Education Details - Sample data pre-populated');
    }
  }

  void _addEducationEntry() {
    setState(() {
      _educationEntries.add(EducationEntry());
    });
  }

  void _removeEducationEntry(int index) {
    // Prevent deletion if there's only one education entry
    if (_educationEntries.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cannot delete the last education entry. Please add more entries before deleting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _educationEntries[index].dispose();
      _educationEntries.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var entry in _educationEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  Widget _buildLabeledInputColumn({
    required String label,
    required String hintText,
    required TextEditingController controller,
    double fieldWidth = 120,
    TextInputType keyboardType = TextInputType.text,
    bool isYearField = false,
    String? Function(String?)? validator, // Add validator
  }) {
    return Container(
      width: fieldWidth == double.infinity ? null : fieldWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: isYearField ? 4 : null,
            buildCounter: (context,
                    {required currentLength, required isFocused, maxLength}) =>
                null,
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade50,
              errorStyle: const TextStyle(
                  fontSize: 12), // Add error style for better visibility
            ),
            style: const TextStyle(fontSize: 13),
            validator: validator, // Use the provided validator
          ),
        ],
      ),
    );
  }

  Widget _buildEducationEntryCard(EducationEntry entry, int index) {
    return Card(
      color: Colors.white,
      key: ValueKey(entry.id),
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Education Entry ${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (_educationEntries.length > 1)
                  IconButton(
                    onPressed: () => _removeEducationEntry(index),
                    icon: Icon(Icons.delete, color: Colors.red[600], size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete this education entry',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLabeledInputColumn(
              label: "Degree",
              hintText: "e.g. B.Tech, M.Sc",
              controller: entry.degreeController,
              fieldWidth: double.infinity,
              validator: (value) {
                // Make degree field required
                if (value == null || value.isEmpty) {
                  return 'Degree is required';
                }
                return null;
              },
            ),
            const SizedBox(width: 12),
            _buildLabeledInputColumn(
              label: "University/Institute",
              hintText: "University or Institute name",
              controller: entry.universityController,
              fieldWidth: double.infinity,
            ),
            const SizedBox(height: 12),
            _buildLabeledInputColumn(
              label: "Specialization",
              hintText: "Field of study",
              controller: entry.specializationController,
              fieldWidth: double.infinity,
            ),
            const SizedBox(width: 12),
            _buildLabeledInputColumn(
              label: "From Year",
              hintText: "YYYY",
              controller: entry.fromYearController,
              keyboardType: TextInputType.number,
              isYearField: true,
              fieldWidth: double.infinity,
            ),
            const SizedBox(width: 12),
            _buildLabeledInputColumn(
              label: "To Year",
              hintText: "YYYY",
              controller: entry.toYearController,
              keyboardType: TextInputType.number,
              isYearField: true,
              fieldWidth: double.infinity,
            ),
            const SizedBox(width: 12),
            _buildLabeledInputColumn(
              label: "Percentage (%)",
              hintText: "78.5",
              controller: entry.percentageController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              fieldWidth: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  void _submitEducationDetails() {
    if (_formKey.currentState!.validate()) {
      // Validate the form
      print('🐛 DEBUG: ===== EDUCATION DETAILS FORM SUBMISSION =====');
      print('🐛 DEBUG: Education Entries: ${_educationEntries.length}');

      try {
        // ✅ Update provider with education details data
        final provider = context.read<EmployeeProvider>();
        final educationData = {
          'education': _educationEntries
              .map((entry) => {
                    'degree': entry.degreeController.text,
                    'university': entry.universityController.text,
                    'specialization': entry.specializationController.text,
                    'from_year': entry.fromYearController.text,
                    'to_year': entry.toYearController.text,
                    'percentage': entry.percentageController.text,
                  })
              .toList(),
        };

        provider.updateFormData('education_details', educationData);
        print('🐛 DEBUG: Updated provider with education details');
        print(
            '🐛 DEBUG: Current completion: ${provider.getCompletionPercentage().toStringAsFixed(1)}%');
        print('🐛 DEBUG: ========================================');

        // ✅ Navigate to next screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Education details saved successfully!'),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          context.goNamed('govt_bank_details');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    } else {
      // If the form is not valid, show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the required fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Check if there's something to pop, otherwise go to contact details
            if (context.canPop()) {
              context.pop(); // Go back to contact details
            } else {
              context.goNamed('contact_details'); // Fallback to contact details
            }
          },
        ),
        title: const Text(
          'Educational Details',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                // Wrap the content in a Form
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fill in your educational background details below',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add New Education Details Button

                    if (_educationEntries.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No educational details added yet",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap the button above to add your first entry",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _educationEntries.length,
                        itemBuilder: (context, index) {
                          return _buildEducationEntryCard(
                              _educationEntries[index], index);
                        },
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addEducationEntry,
                          icon: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                          label: const Text(
                            'Add Education',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
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
                  onPressed: _submitEducationDetails,
                  child: const Text(
                    'Continue to Government Details',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EducationEntry {
  final String id;
  final TextEditingController degreeController;
  final TextEditingController universityController;
  final TextEditingController specializationController;
  final TextEditingController fromYearController;
  final TextEditingController toYearController;
  final TextEditingController percentageController;

  EducationEntry({
    String? id,
    String degree = '',
    String university = '',
    String specialization = '',
    String fromYear = '',
    String toYear = '',
    String percentage = '',
  })  : this.id = id ?? UniqueKey().toString(),
        this.degreeController = TextEditingController(text: degree),
        this.universityController = TextEditingController(text: university),
        this.specializationController =
            TextEditingController(text: specialization),
        this.fromYearController = TextEditingController(text: fromYear),
        this.toYearController = TextEditingController(text: toYear),
        this.percentageController = TextEditingController(text: percentage);

  void dispose() {
    degreeController.dispose();
    universityController.dispose();
    specializationController.dispose();
    fromYearController.dispose();
    toYearController.dispose();
    percentageController.dispose();
  }
}
