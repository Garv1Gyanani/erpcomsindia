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

  @override
  void initState() {
    super.initState();
    if (_educationEntries.isEmpty) {
      _addEducationEntry();
      // Pre-populate first education entry with sample data
      final firstEntry = _educationEntries.first;
      firstEntry.degreeController.text = "B.Tech";
      firstEntry.universityController.text = "XYZ University";
      firstEntry.specializationController.text = "Computer Science";
      firstEntry.fromYearController.text = "2010";
      firstEntry.toYearController.text = "2014";
      firstEntry.percentageController.text = "78.5";
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
            ),
            style: const TextStyle(fontSize: 13),
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
                IconButton(
                  onPressed: _educationEntries.length > 1
                      ? () => _removeEducationEntry(index)
                      : null, // Disable button when only one entry
                  icon: Icon(Icons.delete,
                      color: _educationEntries.length > 1
                          ? Colors.red[600]
                          : Colors.grey[400], // Grey out when disabled
                      size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _educationEntries.length <= 1
                      ? 'Cannot delete the last education entry'
                      : 'Delete this education entry',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLabeledInputColumn(
              label: "Degree",
              hintText: "e.g. B.Tech, M.Sc",
              controller: entry.degreeController,
              fieldWidth: double.infinity,
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
          const SnackBar(
              content: Text(
                  'Education details saved! Continue to government & bank details.')),
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
        actions: [
          Tooltip(
            textStyle: const TextStyle(color: Colors.white),
            message: 'Add Education Entry',
            child: IconButton(
              onPressed: _addEducationEntry,
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_educationEntries.isNotEmpty)
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
                            "Tap the + button to add your first entry",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _addEducationEntry,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'Add Education Entry',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                ],
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
      // floatingActionButton: _educationEntries.isNotEmpty
      //     ? FloatingActionButton(
      //         onPressed: _addEducationEntry,
      //         backgroundColor: Colors.red,
      //         child: const Icon(Icons.add, color: Colors.white),
      //         tooltip: 'Add Education Entry',
      //       )
      //     : null,
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
