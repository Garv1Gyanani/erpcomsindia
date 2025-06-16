import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FamilyMember {
  TextEditingController nameController = TextEditingController();
  TextEditingController relationController = TextEditingController();
  TextEditingController occupationController = TextEditingController();
  DateTime? dateOfBirth;

  void dispose() {
    nameController.dispose();
    relationController.dispose();
    occupationController.dispose();
  }
}

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  int currentStep = 0;

  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _genderOptions = ['Male', 'Female', 'Other'];
  final _statusOptions = ['Single', 'Married', 'Divorced'];
  final _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final _religionOptions = ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Other'];

  String? _selectedGender;
  String? _selectedStatus;
  String? _selectedBloodGroup;
  String? _selectedReligion;
  DateTime? _dob;
  DateTime? _doj;

  // Updated family information structure
  List<FamilyMember> familyMembers = [FamilyMember()];

  Future<void> _selectDate(
      BuildContext context, Function(DateTime) onDatePicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDatePicked(picked);
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

  @override
  void dispose() {
    for (var member in familyMembers) {
      member.dispose();
    }
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.goNamed('home'),
        ),
        backgroundColor: Colors.red,
        title:
            const Text('Add Employee', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentStep == 0) ...[
                sectionTitle('Basic Information'),
                rowWrap([
                  _buildTextField(_nameController, 'Employee Name *'),
                ]),
                rowWrap([
                  _buildDropdown('Gender *', _genderOptions, _selectedGender,
                      (val) => setState(() => _selectedGender = val)),
                  _buildDropdown(
                      'Marital Status *',
                      _statusOptions,
                      _selectedStatus,
                      (val) => setState(() => _selectedStatus = val)),
                ]),
                rowWrap([
                  _buildDatePicker('Date of Birth *', _dob,
                      (date) => setState(() => _dob = date)),
                  _buildDatePicker('Date of Joining *', _doj,
                      (date) => setState(() => _doj = date)),
                ]),
                rowWrap([
                  _buildDropdown(
                      'Blood Group',
                      _bloodGroupOptions,
                      _selectedBloodGroup,
                      (val) => setState(() => _selectedBloodGroup = val)),
                  _buildDropdown(
                      'Religion *',
                      _religionOptions,
                      _selectedReligion,
                      (val) => setState(() => _selectedReligion = val)),
                ]),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() => currentStep = 1);
                      }
                    },
                    child: const Text('Next',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ] else if (currentStep == 1) ...[
                // Updated Family Information Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    sectionTitle('Family Information'),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _addFamilyMember,
                      child: const Text('Add More',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dynamic Family Members List
                ...familyMembers.asMap().entries.map((entry) {
                  int index = entry.key;
                  FamilyMember member = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      children: [
                        // First Row: Name and Relation
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Name',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: member.nameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Relation',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: member.relationController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Second Row: Occupation and Date of Birth
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Occupation',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: member.occupationController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date of Birth',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _selectDate(
                                  context,
                                  (date) => setState(
                                      () => member.dateOfBirth = date)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      member.dateOfBirth != null
                                          ? '${member.dateOfBirth!.day.toString().padLeft(2, '0')}-${member.dateOfBirth!.month.toString().padLeft(2, '0')}-${member.dateOfBirth!.year}'
                                          : 'dd-mm-yyyy',
                                      style: TextStyle(
                                        color: member.dateOfBirth != null
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    Icon(Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Remove button (show only if more than one member)
                        if (familyMembers.length > 1) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _removeFamilyMember(index),
                                child: const Text('Remove',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Employee added successfully!')),
                          );
                        }

                        context.goNamed("employeeDetails");
                      },
                      child: const Text('Next',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (label.contains('*') && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        value: selectedValue,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: (value) {
          if (label.contains('*') && value == null) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker(
      String label, DateTime? selectedDate, Function(DateTime) onDatePicked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () => _selectDate(context, onDatePicked),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            selectedDate != null
                ? '${selectedDate.day}-${selectedDate.month}-${selectedDate.year}'
                : 'dd-mm-yyyy',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget rowWrap(List<Widget> children) {
    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 10),
        if (children.length > 1) Expanded(child: children[1]),
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
