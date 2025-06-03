import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  final _fatherController = TextEditingController();
  final _motherController = TextEditingController();
  final _spouseController = TextEditingController();
  final _child1Controller = TextEditingController();
  final _child2Controller = TextEditingController();

  Future<void> _selectDate(BuildContext context, Function(DateTime) onDatePicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDatePicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.red,
        title: const Text('Add Employee', style: TextStyle(color: Colors.white)),
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
                  _buildTextField(_idController, 'Employee ID *'),
                ]),
                rowWrap([
                  _buildDropdown('Gender *', _genderOptions, _selectedGender,
                      (val) => setState(() => _selectedGender = val)),
                  _buildDropdown('Marital Status *', _statusOptions, _selectedStatus,
                      (val) => setState(() => _selectedStatus = val)),
                ]),
                rowWrap([
                  _buildDatePicker('Date of Birth *', _dob, (date) => setState(() => _dob = date)),
                  _buildDatePicker('Date of Joining *', _doj, (date) => setState(() => _doj = date)),
                ]),
                rowWrap([
                  _buildDropdown('Blood Group', _bloodGroupOptions, _selectedBloodGroup,
                      (val) => setState(() => _selectedBloodGroup = val)),
                  _buildDropdown('Religion *', _religionOptions, _selectedReligion,
                      (val) => setState(() => _selectedReligion = val)),
                ]),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() => currentStep = 1);
                      }
                    },
                    child: const Text('Next', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ] else if (currentStep == 1) ...[
                sectionTitle('Family Information'),
                rowWrap([
                  _buildTextField(_fatherController, "Father's/Husband's Name *"),
                  _buildTextField(_motherController, "Mother's Name"),
                ]),
                _buildTextField(_spouseController, 'Spouse Name'),
                rowWrap([
                  _buildTextField(_child1Controller, 'Child Name 1'),
                  _buildTextField(_child2Controller, 'Child Name 2'),
                ]),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => setState(() => currentStep = 0),
                      child: const Text('Back', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Employee added successfully!')),
                          );
                        }

                        context.goNamed("home");
                      },
                      child: const Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white)),
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
          fillColor: Colors.grey.shade100,
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
          fillColor: Colors.grey.shade100,
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

  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime) onDatePicked) {
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
