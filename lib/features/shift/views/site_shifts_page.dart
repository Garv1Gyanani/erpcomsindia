import 'dart:convert';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SiteShiftsPage extends StatefulWidget {
  const SiteShiftsPage({super.key});

  @override
  State<SiteShiftsPage> createState() => _SiteShiftsPageState();
}

class _SiteShiftsPageState extends State<SiteShiftsPage> {
  final StorageService _storageService = StorageService();
  List<dynamic>? _siteEmployeeData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTeamData();
  }

  Future<void> _fetchTeamData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://erp.comsindia.in/api/shift/site/team'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          final teamData = responseData['data'] as List<dynamic>;
          final Map<String, List<dynamic>> groupedBySite = {};

          for (final teamMember in teamData) {
            final siteName =
                teamMember['site']?['site_name'] as String? ?? 'Unnamed Site';
            final user = teamMember['user'];
            final shift = teamMember['shift'];

            if (user is Map<String, dynamic> && shift is Map<String, dynamic>) {
              final shiftName = shift['name'] ?? 'No shift assigned';
              final startTime = shift['start_time'] as String?;
              final endTime = shift['end_time'] as String?;

              if (startTime != null && endTime != null) {
                user['shift_name'] =
                    '$shiftName (${_formatTime(startTime)} - ${_formatTime(endTime)})';
              } else {
                user['shift_name'] = shiftName;
              }
            }

            if (groupedBySite.containsKey(siteName)) {
              groupedBySite[siteName]!.add(user);
            } else {
              groupedBySite[siteName] = [user];
            }
          }

          final processedData = groupedBySite.entries.map((entry) {
            return {
              'site_name': entry.key,
              'employees': entry.value,
            };
          }).toList();

          setState(() {
            _siteEmployeeData = processedData;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Failed to load team data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to load team data. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Network error. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  String _formatTime(String time) {
    try {
      final parsedTime = DateFormat('HH:mm:ss').parse(time);
      return DateFormat('h:mm a').format(parsedTime);
    } catch (e) {
      // Fallback for any unexpected format
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text('Site Employees',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.goNamed('team');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchTeamData,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String value) {
              switch (value) {
                case 'assign_employee':
                  context.push('/assign-employee');
                  break;
                case 'shift_rotational':
                  // Add your shift rotational navigation logic here
                  context.push('/shift-rotational');
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'assign_employee',
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Assign Employee'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'shift_rotational',
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Shift Rotational'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Loading team data...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchTeamData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_siteEmployeeData == null || _siteEmployeeData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No team data found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later or contact your administrator',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: _siteEmployeeData!.length,
      itemBuilder: (context, index) {
        final siteData = _siteEmployeeData![index];
        final siteName = siteData['site_name'] as String? ?? 'Unnamed Site';
        final employees = siteData['employees'] as List<dynamic>? ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          elevation: 1,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Icon(Icons.business_rounded,
                    color: Colors.red.shade800, size: 30),
                title: Text(
                  siteName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.red.shade900,
                  ),
                ),
                subtitle: Text(
                  '${employees.length} ${employees.length == 1 ? 'Employee' : 'Employees'}',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
                tileColor: Colors.red.shade100,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: employees.expand<Widget>((employee) {
                    final name = employee['name'] ?? 'Unknown User';
                    final initial =
                        name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return [
                      Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 4),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            radius: 24,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.email,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        employee['email'] ?? 'No email',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone,
                                        size: 16, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        employee['phone'] ?? 'No phone number',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule,
                                        size: 16, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.orange
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          employee['shift_name'] ??
                                              'No Shift Assigned',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ];
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
