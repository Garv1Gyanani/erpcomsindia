import 'package:coms_india/employee/add_employee.dart';
import 'package:flutter/material.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  // Dummy static employee data
  final List<Map<String, dynamic>> _employees = [
    {
      'name': 'John Doe',
      'id': 'EMP001',
      'department': 'HR',
      'status': 'Active',
      'color': Colors.green,
    },
    {
      'name': 'Jane Smith',
      'id': 'EMP002',
      'department': 'Finance',
      'status': 'Inactive',
      'color': Colors.red,
    },
    {
      'name': 'Michael Johnson',
      'id': 'EMP003',
      'department': 'Development',
      'status': 'On Leave',
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title:
            const Text('Employee List', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEmployeePage(),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person_add, color: Colors.white),
                  Text(
                    'Add Employee',
                    style: TextStyle(fontSize: 8, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final emp = _employees[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: emp['color'],
                child: Text(emp['name'][0]),
              ),
              title: Text(emp['name']),
              subtitle: Text('ID: ${emp['id']} | Dept: ${emp['department']}'),
              trailing: Chip(
                label: Text(
                  emp['status'],
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: emp['color'],
              ),
            ),
          );
        },
      ),
    );
  }
}
