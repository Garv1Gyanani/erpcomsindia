import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:coms_india/client/client_controller.dart';

class ViewEmployee extends StatefulWidget {
  const ViewEmployee({Key? key}) : super(key: key);

  @override
  State<ViewEmployee> createState() => _ViewEmployeeState();
}

class _ViewEmployeeState extends State<ViewEmployee> {
  final ClientDashboardController controller =
      Get.find<ClientDashboardController>();

  // Track which designation groups are expanded
  final Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employees"),
        backgroundColor: Colors.red,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Text(
              controller.errorMessage.value,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (controller.employeeGroups.isEmpty) {
          return const Center(child: Text('No employees found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.employeeGroups.length,
          itemBuilder: (context, index) {
            final group = controller.employeeGroups[index];
            final isExpanded = _expandedGroups[group.role] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  // Designation Header with Dropdown Arrow
                  ListTile(
                    title: Text(
                      group.role,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${group.employees.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _expandedGroups[group.role] = !isExpanded;
                      });
                    },
                  ),

                  // Expandable Employee List
                  if (isExpanded) ...[
                    const Divider(height: 1),
                    ...group.employees
                        .map((employee) => _buildEmployeeTile(employee))
                        .toList(),
                  ],
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmployeeTile(Employee employee) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: CircleAvatar(
        backgroundColor:
            employee.gender == 'male' ? Colors.blue[100] : Colors.pink[100],
        child: Icon(
          employee.gender == 'male' ? Icons.male : Icons.female,
          size: 20,
        ),
      ),
      title: Text(
        employee.name,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        employee.employeeId,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: employee.status == 'active'
              ? Colors.green.shade100
              : Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          employee.status.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: employee.status == 'active' ? Colors.green : Colors.red,
          ),
        ),
      ),
      onTap: () {},
    );
  }
}
