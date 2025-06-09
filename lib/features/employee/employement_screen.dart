import 'package:coms_india/core/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

class EmploymentDetailsSection extends StatefulWidget {
  const EmploymentDetailsSection({super.key});

  @override
  State<EmploymentDetailsSection> createState() =>
      _EmploymentDetailsSectionState();
}

class _EmploymentDetailsSectionState extends State<EmploymentDetailsSection> {
  final _punchingCodeController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedDesignation;
  String? _selectedSite;
  String? _selectedLocation;
  String? _selectedModeOfJoining;
  DateTime? _dateOfExit;

  // Using final for options is good practice
  final List<String> _departmentOptions = const [
    'HR',
    'IT',
    'Finance',
    'Operations',
    'Marketing'
  ];
  final List<String> _designationOptions = const [
    'Manager',
    'Senior Executive',
    'Executive',
    'Assistant'
  ];
  final List<String> _siteOptions = const [
    'Site A',
    'Site B',
    'Site C',
    'Head Office'
  ];
  final List<String> _locationOptions = const [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Chennai',
    'Hyderabad'
  ];
  final List<String> _modeOfJoiningOptions = const [
    'Direct',
    'Reference',
    'Campus',
    'Online'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfExit ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dateOfExit) {
      setState(() => _dateOfExit = picked);
    }
  }

  @override
  void dispose() {
    _punchingCodeController.dispose();
    super.dispose();
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _modernInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide:
            BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalGap = 16.0;
    const double verticalGap = 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            context.go("home");
          },
        ),
        title: const Text(
          'Employment Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(AppColors.primary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Material(
          color: Colors.grey[50],
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Department',
                        isRequired: true,
                        value: _selectedDepartment,
                        items: _departmentOptions,
                        onChanged: (value) =>
                            setState(() => _selectedDepartment = value),
                        placeholder: 'Select Department',
                      ),
                    ),
                    const SizedBox(width: horizontalGap),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Designation',
                        value: _selectedDesignation,
                        items: _designationOptions,
                        onChanged: (value) =>
                            setState(() => _selectedDesignation = value),
                        placeholder: 'Select Designation',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: verticalGap),

                // Second Row: Site Name, Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Site Name',
                        value: _selectedSite,
                        items: _siteOptions,
                        onChanged: (value) =>
                            setState(() => _selectedSite = value),
                        placeholder: 'Select Site',
                      ),
                    ),
                    const SizedBox(width: horizontalGap),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Location',
                        isRequired: true,
                        value: _selectedLocation,
                        items: _locationOptions,
                        onChanged: (value) =>
                            setState(() => _selectedLocation = value),
                        placeholder: 'Select Location',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: verticalGap),

                // Third Row: Mode of Joining, Punching Code
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Mode of Joining',
                        isRequired: true,
                        value: _selectedModeOfJoining,
                        items: _modeOfJoiningOptions,
                        onChanged: (value) =>
                            setState(() => _selectedModeOfJoining = value),
                        placeholder: 'Select Mode',
                      ),
                    ),
                    const SizedBox(width: horizontalGap),
                    Expanded(
                      child: _buildTextField(
                        controller: _punchingCodeController,
                        label: 'Punching Code',
                        placeholder: 'Enter Code',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: verticalGap),

                // Fourth Row: Date of Exit
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: 'Date of Exit',
                        selectedDate: _dateOfExit,
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: verticalGap),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          context.go('/add-contact');
                        },
                        child: const Text(
                          'Next',
                          style: TextStyle(color: Colors.white),
                        ))
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    bool isRequired = false,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired),
        DropdownButtonFormField<String>(
          value: value,
          decoration: _modernInputDecoration(hintText: placeholder).copyWith(
            contentPadding:
                const EdgeInsets.only(left: 16, right: 12, top: 14, bottom: 14),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade600),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired),
        TextFormField(
          controller: controller,
          decoration: _modernInputDecoration(hintText: placeholder),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: _modernInputDecoration(
              hintText: 'dd-mm-yyyy',
            ).copyWith(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? DateFormat('dd-MM-yyyy', 'en').format(selectedDate)
                      : 'dd-mm-yyyy',
                  style: TextStyle(
                    color: selectedDate != null
                        ? Colors.black87
                        : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
