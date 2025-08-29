import 'dart:convert';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/tickets/view/ticketchat.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// --- Theme Constants (Good Practice) ---
const Color kPrimaryColor = Color(0xFFD32F2F);
const Color kBackgroundColor = Color(0xFFF5F5F5);

class ExistingTicketsPage extends StatefulWidget {
  const ExistingTicketsPage({Key? key}) : super(key: key);

  @override
  State<ExistingTicketsPage> createState() => _ExistingTicketsPageState();
}

class _ExistingTicketsPageState extends State<ExistingTicketsPage> {
  final StorageService _storageService = StorageService();
  List<Ticket> tickets = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token'];
    const url = 'http://erp.comsindia.in/api/tickets';

    try {
      if (authToken == null || authToken.isEmpty) {
        if (mounted)
          setState(() {
            _isLoading = false;
            _errorMessage = 'Authentication token is missing.';
          });
        return;
      }
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json'
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          List<Ticket> fetchedTickets = (jsonData['tickets'] as List)
              .map((item) => Ticket.fromJson(item))
              .toList();
          setState(() {
            tickets = fetchedTickets;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = jsonData['message'] ?? 'Unknown error';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'HTTP error: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Exception: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This page is now part of another Scaffold, so it doesn't need its own Scaffold or AppBar.
    return Container(
      color: kBackgroundColor,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: $_errorMessage',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center),
                  ),
                )
              : tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text("You haven't created any tickets yet.",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchTickets,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];
                          return TicketCard(ticket: ticket);
                        },
                      ),
                    ),
    );
  }
}

class TicketCard extends StatelessWidget {
  const TicketCard({Key? key, required this.ticket}) : super(key: key);

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    // --- WRAPPED CARD IN INKWELL FOR TAP EFFECT AND NAVIGATION ---
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior:
          Clip.antiAlias, // Ensures InkWell ripple stays within rounded corners
      child: InkWell(
        onTap: () {
          // --- NAVIGATION LOGIC ---
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TicketChatPage(ticketId: ticket.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket.subjectId, // Show subject as main title
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: TextStyle(
                          color: _getStatusColor(ticket.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Ticket ID: TCK-${ticket.id.toString().padLeft(4, '0')}', // Formatted ID
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Text(
                ticket.message,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[800], height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${DateFormat('MMM d, yyyy').format(DateTime.parse(ticket.createdAt).toLocal())}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade700;
      case 'in-progress':
        return Colors.blue.shade600;
      case 'closed':
        return Colors.grey.shade600;
      default:
        return Colors.blueGrey;
    }
  }
}

// Data model for Tickets (unchanged, but moved here for completeness)
class Ticket {
  final int id;
  final int userId;
  final int? superiorId;
  final int designationId;
  final String subjectId;
  final String message;
  final String? image;
  final String status;
  final String createdAt;
  final String updatedAt;

  Ticket({
    required this.id,
    required this.userId,
    this.superiorId,
    required this.designationId,
    required this.subjectId,
    required this.message,
    this.image,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      userId: json['user_id'],
      superiorId: json['superior_id'],
      designationId: json['designation_id'],
      subjectId: json['subject_id'] ?? 'No Subject',
      message: json['message'] ?? '',
      image: json['image'],
      status: json['status'] ?? 'unknown',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
