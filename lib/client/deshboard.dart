import 'package:coms_india/client/attendance_report.dart';
import 'package:coms_india/client/client_controller.dart';
import 'package:coms_india/core/constants/app_colors.dart';
import 'package:coms_india/core/di/service_locator.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class ClientDashboardPage extends StatelessWidget {
  const ClientDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ClientDashboardController controller =
        Get.put(ClientDashboardController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Welcome back, client',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.refreshEmployees,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'attendance_report') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AttendanceScreen()),
                );
              } else {
                _handleLogout(value, context, authController);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: Colors.blue.shade600,
                child: Text(
                  authController.getUserInitials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshEmployees,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActions(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _handleLogout(String? value, BuildContext context,
      AuthController authController) async {
    if (value == 'logout') {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true) {
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const AlertDialog(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Logging out...'),
                  ],
                ),
              );
            },
          );

          // IMMEDIATELY clear the auth state
          await getIt<AuthController>().logout(context);

          if (Navigator.canPop(context)) {
            Navigator.of(context).pop(); // Dismiss loading dialog
          }

          GoRouter.of(context).go('/login');
        } catch (e) {
          print('Error during logout: $e');
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop(); // Dismiss loading dialog
          }

          await getIt<AuthController>().logout(context);
          GoRouter.of(context).go('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showStorageDetails(BuildContext context) async {
    final AuthController authController = Get.find<AuthController>();
    final storageService = authController.storageService;

    final allKeys = await storageService.getAllKeys();
    print("All storage key: $allKeys");
  }

  Future<Map<String, dynamic>> _getAllStorageData(
      StorageService storageService) async {
    Map<String, dynamic> data = {};

    data['Token'] = await storageService.getToken() ?? 'null';
    data['User'] = await storageService.getUser() ?? 'null';
    data['Login Type'] = await storageService.getLoginType() ?? 'null';
    // Add other relevant details

    return data;
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Row for multiple actions (future-ready)
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _quickActionCard(
              context,
              icon: Icons.assignment,
              color: Colors.green,
              label: "Attendance",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AttendanceScreen()),
                );
              },
            ),
            const SizedBox(width: 16),
            // You can add more quick actions here
            // _quickActionCard(context, icon: Icons.people, color: Colors.blue, label: "Employees", onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120, // ✅ fixed width so it doesn’t cover full screen
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Employees',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or employee ID...',
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              // Implement search functionality
            },
          ),
        ],
      ),
    );
  }
}
