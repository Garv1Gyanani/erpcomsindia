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
          IconButton(
            icon: Icon(Icons.storage, color: Colors.white),
            onPressed: () {
              _showStorageDetails(context); // Pass context and authController
            },
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
                value: 'attendance_report',
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Attendance Report'),
                  ],
                ),
              ),
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
                // Statistics Cards
                _buildSearchSection(),

                // _buildStatsSection(controller),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 24),

                // Search Section
                const SizedBox(height: 24),

                // Employee Overview
                // _buildEmployeeOverview(controller),

                // Employee Groups
                // _buildEmployeeGroups(controller),
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

          // Logout from API:
          // await GetIt.instance<ApiService>().logout(token, context);

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
    final storageData = await _getAllStorageData(storageService);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Current User Storage Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: storageData.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                      '${entry.key}: ${entry.value is String || entry.value is int || entry.value is bool ? entry.value : 'object'}'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getAllStorageData(
      StorageService storageService) async {
    Map<String, dynamic> data = {};

    data['Token'] =
        await storageService.getToken() ?? 'null'; // Provide a default value
    data['User'] =
        await storageService.getUser() ?? 'null'; // Provide a default value
    data['Login Type'] = await storageService.getLoginType() ??
        'null'; // Provide a default value
    // Add other relevant details

    return data;
  }

  Widget _buildStatsSection(ClientDashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Employees',
                value: '${controller.totalEmployees.value}',
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Active Teams',
                value: '${controller.employeeGroups.length}',
                icon: Icons.groups,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Departments',
                value: '${_getDepartmentCount(controller)}',
                icon: Icons.business,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Active Status',
                value: '${_getActiveEmployeeCount(controller)}',
                icon: Icons.check_circle,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Container(
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.emoji_people,
                label: 'Employee',
                color: Colors.blue,
                onTap: () {
                  // Export functionality
                },
              ),
              _buildActionButton(
                icon: Icons.filter_list,
                label: 'Filter',
                color: Colors.orange,
                onTap: () {
                  // Filter functionality
                  // _showFilterDialog(context);
                },
              ),
              _buildActionButton(
                icon: Icons.analytics,
                label: 'Reports',
                color: Colors.green,
                onTap: () {
                  // Reports functionality
                  Get.snackbar(
                    'Reports',
                    'Generating employee reports',
                    backgroundColor: Colors.green.shade100,
                    colorText: Colors.green.shade800,
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.settings,
                label: 'Settings',
                color: Colors.purple,
                onTap: () {
                  // Settings functionality
                  Get.snackbar(
                    'Settings',
                    'Dashboard settings',
                    backgroundColor: Colors.purple.shade100,
                    colorText: Colors.purple.shade800,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
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

  Widget _buildEmployeeOverview(ClientDashboardController controller) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Employee Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // View all functionality
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...controller.employeeGroups.take(3).map((group) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.group,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.role,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${group.employees.length} employees',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${group.employees.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Widget _buildEmployeeGroups(ClientDashboardController controller) {
  //   if (controller.employeeGroups.isEmpty) {
  //     return Container(
  //       padding: const EdgeInsets.all(40),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(16),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.grey.withOpacity(0.1),
  //             blurRadius: 10,
  //             offset: const Offset(0, 4),
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         children: [
  //           Icon(
  //             Icons.people_outline,
  //             size: 64,
  //             color: Colors.grey.shade400,
  //           ),
  //           const SizedBox(height: 16),
  //           Text(
  //             'No employees found',
  //             style: TextStyle(
  //               fontSize: 18,
  //               fontWeight: FontWeight.w500,
  //               color: Colors.grey.shade600,
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             'Employee data will appear here once available',
  //             style: TextStyle(
  //               fontSize: 14,
  //               color: Colors.grey.shade500,
  //             ),
  //             textAlign: TextAlign.center,
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'All Employees',
  //         style: TextStyle(
  //           fontSize: 20,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black87,
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //       ...controller.employeeGroups.map((group) {
  //         return Container(
  //           margin: const EdgeInsets.only(bottom: 16),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(16),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.grey.withOpacity(0.1),
  //                 blurRadius: 10,
  //                 offset: const Offset(0, 4),
  //               ),
  //             ],
  //           ),
  //           child: Theme(
  //             data: ThemeData().copyWith(dividerColor: Colors.transparent),
  //             child: ExpansionTile(
  //               tilePadding: const EdgeInsets.all(20),
  //               childrenPadding: const EdgeInsets.only(bottom: 20),
  //               title: Text(
  //                 group.role,
  //                 style: const TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 16,
  //                 ),
  //               ),
  //               subtitle: Padding(
  //                 padding: const EdgeInsets.only(top: 4),
  //                 child: Text(
  //                   '${group.employees.length} employee${group.employees.length != 1 ? 's' : ''}',
  //                   style: TextStyle(
  //                     color: Colors.grey.shade600,
  //                     fontSize: 14,
  //                   ),
  //                 ),
  //               ),
  //               leading: Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.blue.shade100,
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 child: Text(
  //                   '${group.employees.length}',
  //                   style: TextStyle(
  //                     color: Colors.blue.shade600,
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 16,
  //                   ),
  //                 ),
  //               ),
  //               children: group.employees
  //                   .map((employee) => _buildEmployeeCard(employee))
  //                   .toList(),
  //             ),
  //           ),
  //         );
  //       }).toList(),
  //     ],
  //   );
  // }

  // Widget _buildEmployeeCard(
  //   Employee employee,
  // ) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  //     child: Card(
  //       elevation: 0,
  //       color: Colors.grey.shade50,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         side: BorderSide(color: Colors.grey.shade200),
  //       ),
  //       child: ListTile(
  //         contentPadding: const EdgeInsets.all(16),
  //         leading: CircleAvatar(
  //           radius: 24,
  //           backgroundColor: employee.gender == 'male'
  //               ? Colors.blue.shade100
  //               : Colors.pink.shade100,
  //           child: Icon(
  //             employee.gender == 'male' ? Icons.person : Icons.person_outline,
  //             color: employee.gender == 'male'
  //                 ? Colors.blue.shade600
  //                 : Colors.pink.shade600,
  //             size: 20,
  //           ),
  //         ),
  //         title: Text(
  //           employee.name,
  //           style: const TextStyle(
  //             fontWeight: FontWeight.w600,
  //             fontSize: 16,
  //           ),
  //         ),
  //         subtitle: Padding(
  //           padding: const EdgeInsets.only(top: 8),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
  //                   const SizedBox(width: 4),
  //                   Text(
  //                     employee.employeeId,
  //                     style: TextStyle(
  //                       color: Colors.grey.shade600,
  //                       fontSize: 12,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 4),
  //               Row(
  //                 children: [
  //                   Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
  //                   const SizedBox(width: 4),
  //                   Text(
  //                     employee.phone,
  //                     style: TextStyle(
  //                       color: Colors.grey.shade600,
  //                       fontSize: 12,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //         trailing: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Container(
  //               padding:
  //                   const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //               decoration: BoxDecoration(
  //                 color: employee.status == 'active'
  //                     ? Colors.green.shade100
  //                     : Colors.red.shade100,
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: Text(
  //                 employee.status.toUpperCase(),
  //                 style: TextStyle(
  //                   color: employee.status == 'active'
  //                       ? Colors.green.shade700
  //                       : Colors.red.shade700,
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Icon(
  //               Icons.chevron_right,
  //               color: Colors.grey.shade400,
  //               size: 20,
  //             ),
  //           ],
  //         ),
  //         onTap: () {
  //           // _showEmployeeDetails(context, employee);
  //         },
  //       ),
  //     ),
  //   );
  // }

  void _showEmployeeDetails(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: employee.gender == 'male'
                          ? Colors.blue.shade100
                          : Colors.pink.shade100,
                      child: Icon(
                        employee.gender == 'male'
                            ? Icons.person
                            : Icons.person_outline,
                        color: employee.gender == 'male'
                            ? Colors.blue.shade600
                            : Colors.pink.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            employee.employeeId,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Email', employee.email, Icons.email),
                _buildDetailRow('Phone', employee.phone, Icons.phone),
                _buildDetailRow(
                    'Gender', employee.gender.capitalize ?? '', Icons.person),
                _buildDetailRow(
                    'Status', employee.status.capitalize ?? '', Icons.info),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Employees'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Active Only'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Apply filter
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Inactive Only'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Apply filter
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Clear Filters'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Clear filters
                },
              ),
            ],
          ),
        );
      },
    );
  }

  int _getDepartmentCount(ClientDashboardController controller) {
    Set<String> departments = {};
    for (var group in controller.employeeGroups) {
      String department = group.role.split(' - ')[0];
      departments.add(department);
    }
    return departments.length;
  }

  int _getActiveEmployeeCount(ClientDashboardController controller) {
    int activeCount = 0;
    for (var group in controller.employeeGroups) {
      for (var employee in group.employees) {
        if (employee.status == 'active') {
          activeCount++;
        }
      }
    }
    return activeCount;
  }
}
