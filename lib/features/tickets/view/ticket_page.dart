import 'package:coms_india/features/tickets/view/ceateticket.dart';
import 'package:coms_india/features/tickets/view/existingticket.dart';
import 'package:flutter/material.dart';

// --- Theme Constants (Good Practice) ---
const Color kPrimaryColor = Color(0xFFD32F2F);
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kSurfaceColor = Colors.white;

class TicketsPage extends StatefulWidget {
  const TicketsPage({Key? key}) : super(key: key);

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions = <Widget>[
    const ExistingTicketsPage(),
    const CreateTicketPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Support Center",
          style: TextStyle(
            color: kSurfaceColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 1,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: kPrimaryColor,
            width: double.infinity,
            child: _buildStyledToggleButtons(),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
    );
  }

  // --- Styled ToggleButtons Widget ---
  Widget _buildStyledToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ToggleButtons(
        onPressed: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        isSelected: [_selectedIndex == 0, _selectedIndex == 1],
        // --- Custom Styling ---
        color: Colors.white.withOpacity(0.7), // Color for unselected text/icon
        selectedColor: kPrimaryColor, // Color for selected text/icon
        fillColor: kSurfaceColor, // Background color when selected
        splashColor: kPrimaryColor.withOpacity(0.12),
        hoverColor: kPrimaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.0),
        borderWidth: 0, // Hide the default outer border
        selectedBorderColor: kPrimaryColor, // Border for the selected item
        constraints: BoxConstraints(
          minHeight: 40.0,
          minWidth: (MediaQuery.of(context).size.width - 40) /
              2, // Take up available space
        ),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Existing Tickets',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Create New',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
