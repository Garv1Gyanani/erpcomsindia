import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

class GlobalBottomNavigation extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const GlobalBottomNavigation({
    Key? key,
    required this.child,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<GlobalBottomNavigation> createState() => _GlobalBottomNavigationState();
}

class _GlobalBottomNavigationState extends State<GlobalBottomNavigation> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: MaterialCommunityIcons.account_group,
      label: 'Dashboard',
      route: '/team',
    ),
    NavigationItem(
      icon: MaterialCommunityIcons.account_multiple,
      label: 'Sites',
      route: '/employees',
    ),
    NavigationItem(
      icon: MaterialCommunityIcons.clipboard_check_outline,
      label: 'Tasks',
      route: '/tasks',
    ),
    NavigationItem(
      icon: MaterialCommunityIcons.bell_outline,
      label: 'Alerts',
      route: '/alerts',
    ),
    NavigationItem(
      icon: MaterialCommunityIcons.ticket_outline,
      label: 'Tickets',
      route: '/tickets',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(GlobalBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    final index = _navigationItems.indexWhere(
      (item) => widget.currentRoute.startsWith(item.route),
    );
    if (index != -1) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Main content - takes up remaining space
          Expanded(
            child: widget.child,
          ),
          // Fixed bottom navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildNavItem(index, item);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavigationItem item) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        context.go(item.route);
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
              item.icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
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

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
