import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:coms_india/client/client_controller.dart';

class ViewEmployee extends StatelessWidget {
  const ViewEmployee({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ClientDashboardController controller =
        Get.put(ClientDashboardController());

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
              child: Text(controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red)));
        }

        if (controller.employeeGroups.isEmpty) {
          return const Center(child: Text('No employees found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.employeeGroups.length,
          itemBuilder: (context, index) {
            final group = controller.employeeGroups[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(group.role,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('${group.employees.length}'),
                ),
                ...group.employees.map(_buildEmployeeTile).toList(),
                const Divider(),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildEmployeeTile(Employee employee) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            employee.gender == 'male' ? Colors.blue[100] : Colors.pink[100],
        child: Icon(employee.gender == 'male' ? Icons.male : Icons.female),
      ),
      title: Text(employee.name),
      subtitle: Text(employee.employeeId),
      trailing: Text(
        employee.status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: employee.status == 'active' ? Colors.green : Colors.red,
        ),
      ),
      onTap: () {},
    );
  }
}
