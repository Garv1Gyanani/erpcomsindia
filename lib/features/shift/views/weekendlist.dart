import 'package:coms_india/core/constants/app_colors.dart';
import 'package:coms_india/core/services/api_service.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/employee/models/employee.dart';
import 'package:coms_india/features/employee/views/weekend_assignment_page.dart';
import 'package:flutter/material.dart';

class WeekendListPage extends StatefulWidget {
  const WeekendListPage({super.key});
  @override
  State<WeekendListPage> createState() => _WeekendListPageState();
}

class _WeekendListPageState extends State<WeekendListPage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  bool _isLoading = true;
  String? _errorMessage;
  List<SiteGroup> _weekendList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authData = await _storageService.getAllAuthData();
      final token = authData['token'];
      if (token == null) throw Exception("Token not found");
      final data = await _apiService.fetchWeekendList(token);
      setState(() => _weekendList = data);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateAndRefresh() async {
    // Navigate to the assignment page. The `.then()` block will execute
    // when the user navigates back from that page.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeekendAssignmentPage()),
    ).then((_) {
      // Refresh the data when returning.
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekend Roster'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Assign New Weekend',
            onPressed: _navigateAndRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null)
      return Center(
          child: Text('Error: $_errorMessage',
              style: const TextStyle(color: Colors.red)));
    if (_weekendList.isEmpty)
      return const Center(child: Text('No weekend assignments found.'));

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _weekendList.length,
      itemBuilder: (context, index) {
        final siteGroup = _weekendList[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(siteGroup.site,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            childrenPadding: const EdgeInsets.all(8).copyWith(top: 0),
            children: siteGroup.employees
                .map((employee) => _buildEmployeeTile(employee))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeTile(WeekendEmployee employee) {
    return Card(
      elevation: 1,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(employee.phone, style: TextStyle(color: Colors.grey.shade700)),
            const Divider(height: 16),
            Text('Shifts: ${employee.shifts.join(", ")}',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: employee.weekendDays
                  .map((day) => Chip(
                        label: Text(day),
                        backgroundColor: Colors.teal.withOpacity(0.1),
                        side: BorderSide(color: Colors.teal.shade200),
                        labelStyle: const TextStyle(color: Colors.teal),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
