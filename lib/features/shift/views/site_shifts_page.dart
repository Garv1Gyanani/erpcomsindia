import 'dart:convert';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class SiteShiftsPage extends StatefulWidget {
  const SiteShiftsPage({super.key});

  @override
  State<SiteShiftsPage> createState() => _SiteShiftsPageState();
}

class _SiteShiftsPageState extends State<SiteShiftsPage> {
  final StorageService _storageService = StorageService();
  Map<String, List<dynamic>>? _groupedTeamData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTeamShifts();
  }

  Future<void> _fetchTeamShifts() async {
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
          _groupTeamData(teamData);
          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Failed to load team shifts';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to load team shifts. Status: ${response.statusCode}';
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

  void _groupTeamData(List<dynamic> teamData) {
    final groupedData = <String, List<dynamic>>{};
    for (var entry in teamData) {
      final siteName = entry['site']?['site_name'] as String?;
      if (siteName != null) {
        if (groupedData.containsKey(siteName)) {
          groupedData[siteName]!.add(entry);
        } else {
          groupedData[siteName] = [entry];
        }
      }
    }
    setState(() {
      _groupedTeamData = groupedData;
    });
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return 'N/A';
    }
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final timeOfDay = TimeOfDay(hour: hour, minute: minute);

      // Manual formatting to hh:mm AM/PM
      final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
      final hourOfPeriod =
          timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
      final minuteFormatted = timeOfDay.minute.toString().padLeft(2, '0');

      return '$hourOfPeriod:$minuteFormatted $period';
    } catch (e) {
      return timeString; // Return original string if formatting fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Site Shifts',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.goNamed('team');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchTeamShifts,
            tooltip: 'Refresh',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () {
                context.push('/assign-employee');
              },
              icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
              label: const Text(
                'Assign Employee',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  )),
            ),
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    if (_groupedTeamData == null || _groupedTeamData!.isEmpty) {
      return const Center(child: Text('No team shift data found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _groupedTeamData!.keys.length,
      itemBuilder: (context, index) {
        final siteName = _groupedTeamData!.keys.elementAt(index);
        final siteEntries = _groupedTeamData![siteName]!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 1,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: Colors.red.shade50,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.business_rounded, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      siteName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              ...siteEntries.expand<Widget>((entry) {
                final user = entry['user'];
                final shift = entry['shift'];
                final name = user?['name'] ?? 'Unknown User';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                return [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?['email'] ?? 'No email',
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${shift?['name'] ?? 'N/A'} (${_formatTime(shift?['start_time'])} - ${_formatTime(shift?['end_time'])})',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (siteEntries.last != entry)
                    const Divider(height: 1, indent: 72),
                ];
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
