import 'package:coms_india/client/View_attendence.dart';
import 'package:coms_india/client/deshboard.dart';
import 'package:coms_india/client/navbar/view_employee.dart';
import 'package:coms_india/features/tickets/view/ticket_page.dart';
import 'package:flutter/material.dart';

class ClientNavBar extends StatefulWidget {
  const ClientNavBar({super.key});

  @override
  State<ClientNavBar> createState() => _ClientNavBarState();
}

class _ClientNavBarState extends State<ClientNavBar> {
  int _selectedIndex = 0;

  // By keeping the pages in a list here, they are instantiated only once.
  // The IndexedStack below will manage their state.
  final List<Widget> _pages = <Widget>[
    const ClientDashboardPage(),
    const ViewEmployee(),
    const ViewAttendence(),
    const TicketsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using a more specific theme color for the selected item.
    final Color selectedColor = Theme.of(context).colorScheme.primary;
    final Color unselectedColor = Colors.grey.shade600;

    return Scaffold(
      // IMPORTANT: Using IndexedStack preserves the state of each tab.
      // When you switch tabs, the scroll position and any state on the
      // previous tab will not be lost.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // The list of items in the nav bar.
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon:
                const Icon(Icons.dashboard), // A different icon when active
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.checklist_rtl_outlined),
            activeIcon: const Icon(Icons.checklist_rtl),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: 'Tickets',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        // --- UI Improvements ---
        type: BottomNavigationBarType.fixed, // Good for 4+ items
        backgroundColor: Colors.white,
        elevation: 5.0, // A softer shadow

        // Selected item styling
        selectedItemColor: selectedColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        selectedIconTheme: IconThemeData(size: 26, color: selectedColor),

        // Unselected item styling
        unselectedItemColor: unselectedColor,
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        unselectedIconTheme: IconThemeData(color: unselectedColor),

        // Hides the default splash effect which can look clunky
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
