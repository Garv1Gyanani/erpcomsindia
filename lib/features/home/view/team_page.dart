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
  final TaskStatusController _taskStatusController =
      Get.put(TaskStatusController());

  final List<MenuItemData> _menuItems = [
    MenuItemData(
      id: 2,
      title: 'Sites List',
      icon: Icons.location_city,
      color: Colors.green,
    ),
    MenuItemData(
      id: 1,
      title: 'Attendance',
      icon: MaterialCommunityIcons.account_group,
      color: Colors.blue,
    ),
    MenuItemData(
      id: 3,
      title: 'Shift Management',
      icon: Icons.schedule,
      color: Colors.purple,
    ),
    MenuItemData(
      id: 5,
      title: 'weekendlist',
      icon: Icons.weekend,
      color: Colors.black,
    ),
    MenuItemData(
      id: 4,
      title: 'Assign Shift',
      icon: Icons.assignment_ind,
      color: Colors.orange,
    ),
    MenuItemData(
      id: 6,
      title: 'Self Attendance',
      icon: Icons.person_2,
      color: Colors.orange,
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
          Expanded(child: _buildMenuGrid()),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return SizedBox(
      // Wrap Drawer with SizedBox
      width: MediaQuery.of(context).size.width *
          0.7, // Adjust width as needed (70% of screen)
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            _buildDrawerMenuItems(context),
            const Divider(height: 30, thickness: 1),
            _buildDrawerSettingsAndHelp(context),
            const Divider(height: 30, thickness: 1),
            _buildDrawerLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Obx(() {
      final user = _authController.currentUser.value;
      final name = user?.name ?? 'User';
      final email = user?.email ?? 'user@example.com';
      final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

      return DrawerHeader(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Text(
                firstLetter,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDrawerMenuItems(BuildContext context) {
    return Column(
      children: [
        _buildDrawerItem(Icons.person_add, 'Employee', onNavigate: () {
          context.goNamed('employees');
        }),
        _buildDrawerItem(Icons.people, 'Team', onNavigate: () {
          context.go('/team');
        }),
        _buildDrawerItem(Icons.assignment, 'Tasks', onNavigate: () {
          context.go('/tasks');
        }),
        _buildDrawerItem(Icons.notifications, 'Alerts', onNavigate: () {
          context.go('/alerts');
        }),
        _buildDrawerItem(Icons.confirmation_number, 'Tickets', onNavigate: () {
          context.go('/tickets');
        }),
        _buildDrawerItem(Icons.history, 'History'),
      ],
    );
  }

  Widget _buildDrawerSettingsAndHelp(BuildContext context) {
    return Column(
      children: [
        _buildDrawerItem(Icons.settings, 'Settings'),
        _buildDrawerItem(Icons.help_outline, 'Help'),
      ],
    );
  }

  Widget _buildDrawerLogoutButton(BuildContext context) {
    return Obx(() {
      return _buildDrawerItem(
        Icons.exit_to_app,
        'Logout',
        isLoading: _authController.isLoading.value,
      );
    });
  }

  Widget _buildDrawerItem(IconData icon, String title,
      {bool isLogout = false, Function()? onNavigate, bool isLoading = false}) {
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
      trailing: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.0),
            )
          : null,
      onTap: () {
        if (isLoading) return;
        Navigator.pop(context); // Close drawer first

        // Handle different menu items
        if (title == 'Logout') {
          _authController.logout(context);
        } else if (onNavigate != null) {
          // Execute custom navigation function if provided
          onNavigate();
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
            'ERP COMS INDIA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Display user role below the app title - reactive with Obx
          Obx(() {
            final user = _authController.currentUser.value;
            String userRole = 'User'; // Default role

            if (user != null && user.roles != null && user.roles!.isNotEmpty) {
              final roleName = user.roles!.first.name;
              if (roleName != null && roleName.isNotEmpty) {
                // Capitalize first letter of role name
                userRole = roleName[0].toUpperCase() +
                    roleName.substring(1).toLowerCase();
              }
            }

            return Text(
              userRole,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            );
          }),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          return _buildMenuItem(item);
        },
      ),
    );
  }

  Widget _buildMenuItem(MenuItemData item) {
    return GestureDetector(
      onTap: () {
        // Handle navigation based on menu item
        if (item.title == 'Sites List') {
          context.goNamed('employees');
        } else if (item.title == 'Attendance') {
          context.goNamed('attendance');
        } else if (item.title == 'Shift Management') {
          context.goNamed('shifts');
        } else if (item.title == 'Weekend Management') {
          context.goNamed('shifts');
        } else if (item.title == 'Assign Shift') {
          context.goNamed('site-shifts');
        } else if (item.title == 'weekendlist') {
          context.goNamed('weekendlist');
        } else if (item.title == 'Self Attendance') {
          context.goNamed('selfatt');
        }
        // Add other menu item navigations here if needed
      },
      child: Column(
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
