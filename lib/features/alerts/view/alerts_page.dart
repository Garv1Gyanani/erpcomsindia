import 'package:coms_india/core/constants/app_colors.dart';
import 'package:coms_india/core/di/service_locator.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/auth/controllers/auth_controller.dart';
import 'package:coms_india/features/auth/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final AuthController _authController = getIt<AuthController>();
  final StorageService _storageService = getIt<StorageService>();

  final List<AlertData> _alerts = [
    AlertData(
      id: 1,
      title: 'System Maintenance',
      description: 'Scheduled maintenance will begin at 2:00 AM tonight',
      type: 'Warning',
      priority: 'Medium',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      icon: Icons.build,
      color: Colors.orange,
    ),
    AlertData(
      id: 2,
      title: 'Security Alert',
      description: 'Multiple failed login attempts detected',
      type: 'Critical',
      priority: 'High',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: false,
      icon: Icons.security,
      color: Colors.red,
    ),
    AlertData(
      id: 3,
      title: 'Task Deadline',
      description: 'Project Alpha deadline is approaching in 2 days',
      type: 'Reminder',
      priority: 'Medium',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
      icon: Icons.schedule,
      color: Colors.blue,
    ),
    AlertData(
      id: 4,
      title: 'New Team Member',
      description: 'Sarah Wilson has joined the development team',
      type: 'Info',
      priority: 'Low',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
      icon: Icons.person_add,
      color: Colors.green,
    ),
    AlertData(
      id: 5,
      title: 'Server Performance',
      description: 'Server response time is above normal threshold',
      type: 'Warning',
      priority: 'Medium',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      isRead: false,
      icon: Icons.warning,
      color: Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildAlertStats(),
          _buildAlertList(),
        ],
      ),
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
              _buildDrawerItem(Icons.dashboard, 'Dashboard'),
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

  Widget _buildDrawerItem(IconData icon, String title) {
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
        Navigator.pop(context);

        if (title == 'Logout') {
          _authController.logout(context);
        } else if (title == 'Dashboard') {
          context.goNamed('home');
        } else if (title == 'Team') {
          context.goNamed('team');
        } else if (title == 'Tasks') {
          context.goNamed('tasks');
        } else if (title == 'Alerts') {
          context.goNamed('alerts');
        } else if (title == 'Tickets') {
          context.goNamed('tickets');
        } else {
          print('Tapped on: $title');
        }
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.red,
      elevation: 0,
      toolbarHeight: 70,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alerts & Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Stay Updated",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.mark_email_read,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            _markAllAsRead();
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
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
                  final user = _authController.currentUser.value;
                  final name = user?.name ?? '';
                  final letter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

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

  Widget _buildAlertStats() {
    final unreadCount = _alerts.where((alert) => !alert.isRead).length;
    final criticalCount =
        _alerts.where((alert) => alert.type == 'Critical').length;
    final warningCount =
        _alerts.where((alert) => alert.type == 'Warning').length;

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
            "Alerts Overview",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Unread",
                  "$unreadCount",
                  const Color(0xFFDFECFF),
                  Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  "Critical",
                  "$criticalCount",
                  const Color(0xFFFFE4E6),
                  Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  "Warning",
                  "$warningCount",
                  const Color(0xFFFEF9C3),
                  Colors.amber.shade700,
                ),
              ),
            ],
          ),
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

  Widget _buildAlertList() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Alerts",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  return _buildAlertCard(alert);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(AlertData alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: alert.isRead ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert.isRead
              ? Colors.grey.shade200
              : alert.color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: alert.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            alert.icon,
            color: alert.color,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                alert.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      alert.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            if (!alert.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              alert.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: alert.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(alert.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _markAsRead(alert),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _markAsRead(AlertData alert) {
    setState(() {
      alert.isRead = true;
    });
    print('Marked alert as read: ${alert.title}');
  }

  void _markAllAsRead() {
    setState(() {
      for (var alert in _alerts) {
        alert.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All alerts marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class AlertData {
  final int id;
  final String title;
  final String description;
  final String type;
  final String priority;
  final DateTime timestamp;
  bool isRead;
  final IconData icon;
  final Color color;

  AlertData({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.timestamp,
    required this.isRead,
    required this.icon,
    required this.color,
  });
}
