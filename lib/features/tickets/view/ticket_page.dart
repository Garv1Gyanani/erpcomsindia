import 'package:coms_india/core/constants/app_colors.dart';
import 'package:coms_india/core/di/service_locator.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/auth/controllers/auth_controller.dart';
import 'package:coms_india/features/auth/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class TicketData {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  final String assignedTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketData({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });
}

class TicketsPage extends StatefulWidget {
  const TicketsPage({Key? key}) : super(key: key);

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final AuthController _authController = getIt<AuthController>();
  final StorageService _storageService = getIt<StorageService>();

  final List<TicketData> _tickets = [
    TicketData(
      id: 1001,
      title: 'Login System Not Working',
      description: 'Users are unable to login to the system since morning',
      status: 'Open',
      priority: 'High',
      category: 'Technical',
      assignedTo: 'John Doe',
      createdBy: 'Sarah Wilson',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    TicketData(
      id: 1002,
      title: 'Request for New Software License',
      description: 'Need Adobe Creative Suite license for design team',
      status: 'In Progress',
      priority: 'Medium',
      category: 'Request',
      assignedTo: 'Mike Johnson',
      createdBy: 'David Brown',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    TicketData(
      id: 1003,
      title: 'Network Connectivity Issues',
      description: 'Slow internet connection in conference room B',
      status: 'Closed',
      priority: 'Low',
      category: 'Infrastructure',
      assignedTo: 'Jane Smith',
      createdBy: 'Mike Johnson',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TicketData(
      id: 1004,
      title: 'Access Request for HR Database',
      description: 'New employee needs access to HR management system',
      status: 'Open',
      priority: 'Medium',
      category: 'Access',
      assignedTo: 'Sarah Wilson',
      createdBy: 'John Doe',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TicketData(
      id: 1005,
      title: 'Printer Not Responding',
      description: 'Office printer on 2nd floor is not working',
      status: 'In Progress',
      priority: 'Low',
      category: 'Hardware',
      assignedTo: 'David Brown',
      createdBy: 'Jane Smith',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildTicketStats(),
          _buildFilterTabs(),
          _buildTicketList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTicketDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawer() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: SizedBox(
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
                              user!.roles.first,
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
      backgroundColor: Colors.purple,
      elevation: 0,
      toolbarHeight: 70,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Tickets',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Manage Support Requests",
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
            Icons.search,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            print('Search tickets');
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

  Widget _buildTicketStats() {
    final openCount =
        _tickets.where((ticket) => ticket.status == 'Open').length;
    final inProgressCount =
        _tickets.where((ticket) => ticket.status == 'In Progress').length;
    final closedCount =
        _tickets.where((ticket) => ticket.status == 'Closed').length;

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
            "Tickets Overview",
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
                  "Open",
                  "$openCount",
                  const Color(0xFFFFE4E6),
                  Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  "In Progress",
                  "$inProgressCount",
                  const Color(0xFFFEF9C3),
                  Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  "Closed",
                  "$closedCount",
                  const Color(0xFFDCFCE7),
                  Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    Color color,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
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
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Missing methods that are referenced in the build method
  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterTab('All'),
          _buildFilterTab('Open'),
          _buildFilterTab('In Progress'),
          _buildFilterTab('Closed'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            filter,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketList() {
    final filteredTickets = _selectedFilter == 'All'
        ? _tickets
        : _tickets.where((ticket) => ticket.status == _selectedFilter).toList();

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTickets.length,
        itemBuilder: (context, index) {
          final ticket = filteredTickets[index];
          return _buildTicketCard(ticket);
        },
      ),
    );
  }

  Widget _buildTicketCard(TicketData ticket) {
    Color statusColor;
    switch (ticket.status) {
      case 'Open':
        statusColor = Colors.red;
        break;
      case 'In Progress':
        statusColor = Colors.amber;
        break;
      case 'Closed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${ticket.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  ticket.assignedTo,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.flag, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  ticket.priority,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTicketDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Ticket'),
          content: const Text('Create ticket functionality would go here.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add create ticket logic here
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
