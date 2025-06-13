import 'package:coms_india/core/constants/app_colors.dart';
import 'package:coms_india/core/di/service_locator.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/auth/controllers/auth_controller.dart';
import 'package:coms_india/features/auth/models/user_model.dart';
import 'package:coms_india/features/task/controller/task_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class SupervisorHomePage extends StatefulWidget {
  const SupervisorHomePage({Key? key}) : super(key: key);

  @override
  State<SupervisorHomePage> createState() => _SupervisorHomePageState();
}

class _SupervisorHomePageState extends State<SupervisorHomePage> {
  final AuthController _authController = getIt<AuthController>();
  final StorageService _storageService = getIt<StorageService>();
  final TaskStatusController _taskStatusController = Get.put(TaskStatusController());
  int _selectedIndex = 0;

  final List<MenuItemData> _menuItems = [
    MenuItemData(
      id: 1,
      title: 'Attendance & Briefing',
      icon: MaterialCommunityIcons.account_group,
      color: Colors.blue,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Load task status data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskStatusController.fetchTaskStatus();
    });

    // For testing - add a dummy user if none exists
    if (_authController.currentUser.value == null) {
      print('No user found, creating test user for debugging');

      // Create a test user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        testUserAuth();
      });
    }
  }

// Create a test user for debugging
  void testUserAuth() {
    try {
      final testUser = UserModel(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        phone: '1234567890',
        roles: [RoleModel(id: 1, name: 'Supervisor', guardName: 'supervisor')],
      );

      _authController.currentUser.value = testUser;
      print('Test user created: ${testUser.name}, roles: ${testUser.roles}');

      _authController.token.value = 'test-token';
      _storageService.saveAuthData('test-token', testUser);
      
    } catch (e) {
      print('Error creating test user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildQuickStats(),
          _buildMenuGrid(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildDrawer() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Drawer(
          backgroundColor: Colors.white,
          elevation: 0,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Obx(() {
                print(
                    'Building drawer header with user: ${_authController.currentUser.value}');
                final user = _authController.currentUser.value;
                final name = user?.name ?? 'User';
                final email = user?.email ?? 'user@example.com';
                final firstLetter =
                    name.isNotEmpty ? name[0].toUpperCase() : 'U';

                return DrawerHeader(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            firstLetter,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user?.roles.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user!.roles.first.name,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              _buildDrawerItem(Icons.person_add, 'Employee',onNavigate: (){
                context.goNamed('employees');
              }),
              _buildDrawerItem(Icons.people, 'Team'),
              _buildDrawerItem(Icons.assignment, 'Tasks'),
              _buildDrawerItem(Icons.notification_important, 'Alerts'),
              _buildDrawerItem(Icons.confirmation_number, 'Tickets'),
              _buildDrawerItem(Icons.history, 'History'),
              const Divider(),
              _buildDrawerItem(Icons.settings, 'Settings'),
              _buildDrawerItem(Icons.help_outline, 'Help'),
              _buildDrawerItem(Icons.exit_to_app, 'Logout'),
            ],
          ),
        ),
      ),
    );
  }

// Updated drawer item with navigation to tasks
  Widget _buildDrawerItem(IconData icon, String title, {
    bool isLogout = false, 
    Function()? onNavigate
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        icon,
        color: Colors.grey[700],
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[800],
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer first

        // Handle different menu items
        if (title == 'Logout') {
          _authController.logout(context);
        } else if (onNavigate != null) {
          // Execute custom navigation function if provided
          onNavigate();
        } else if (title == 'Tasks') {
          // Default tasks navigation
          context.goNamed('tasks');
        } else {
          // Handle other menu item taps
          print('Tapped on: $title');
        }
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    print('Building AppBar');

    return AppBar(
      backgroundColor: Colors.red,
      elevation: 0,
      toolbarHeight: 70,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supervisor App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Display user role below the app title - reactive with Obx
          Text(
            "Supervisor",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                // Debug notification press
                print('Notification button pressed');
                // Handle notification tap
              },
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Profile circle with user's first letter - reactive with Obx
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              // Debug profile press
              print('Profile avatar pressed, navigating to profile');
              context.goNamed('profile');
            },
            child: Container(
              width: 35,
              height: 35,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Obx(() {
                  // Debug user data for avatar
                  print('Getting user name for avatar');
                  final user = _authController.currentUser.value;
                  print('Current user: $user');

                  final name = user?.name ?? '';
                  print('User name: $name');

                  final letter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                  print('Avatar letter: $letter');

                  return Text(
                    letter,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Overview",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Total Task",
                    "${_taskStatusController.taskStatus?.totalTask ?? 0}",
                    const Color(0xFFDFECFF), // blue-100
                    Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    "Pending Task",
                    "${_taskStatusController.taskStatus?.pendingTask ?? 0}",
                    const Color(0xFFFEF9C3), // yellow-100
                    Colors.amber.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    "Completed Task",
                    "${_taskStatusController.taskStatus?.completedTask ?? 0}",
                    const Color(0xFFDCFCE7), // green-100
                    Colors.green.shade700,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _menuItems.length,
          itemBuilder: (context, index) {
            final item = _menuItems[index];
            return _buildMenuItem(item);
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem(MenuItemData item) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            item.icon,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, MaterialCommunityIcons.account_group, 'Team'),
          _buildNavItem(
              1, MaterialCommunityIcons.clipboard_check_outline, 'Tasks'),
          _buildNavItem(2, MaterialCommunityIcons.bell_outline, 'Alerts'),
          _buildNavItem(3, MaterialCommunityIcons.ticket_outline, 'Tickets'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        // Navigate to tasks page when Tasks nav item is tapped
        if (label == 'Tasks') {
          context.goNamed('tasks');
        }
        // Add other navigation logic for other items as needed
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class MenuItemData {
  final int id;
  final String title;
  final IconData icon;
  final Color color;

  MenuItemData({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}