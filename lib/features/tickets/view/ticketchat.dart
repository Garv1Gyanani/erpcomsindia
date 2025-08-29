import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/tickets/view/existingticket.dart';

const Color kPrimaryColor = Color(0xFFD32F2F);
const Color kSecondaryColor = Color(0xFFC62828);
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kMyMessageBubbleColor = Color(0xFFE53935);
const Color kOtherMessageBubbleColor = Color(0xFFE0E0E0);
const Color kSurfaceColor = Color(0xFFFFFFFF);

class TicketChatPage extends StatefulWidget {
  final int ticketId;

  const TicketChatPage({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<TicketChatPage> createState() => _TicketChatPageState();
}

class _TicketChatPageState extends State<TicketChatPage> {
  final StorageService _storageService = StorageService();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();

  bool _isLoading = true;
  bool _isSending = false;
  bool _hasInitiallyScrolled = false;
  String _errorMessage = '';
  Ticket? _ticket;
  int? _currentUserId;
  List<ChatMessage> _messages = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    debugPrint("--- 🎫 TicketChatPage initState ---");
    _initializeChat();
  }

  @override
  void dispose() {
    debugPrint("--- 🎫 TicketChatPage dispose ---");
    _replyController.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    await _loadCurrentUser();
    await _fetchTicketDetails();
    await _fetchReplies();
    _startPolling();
  }

  Future<void> _loadCurrentUser() async {
    final authData = await _storageService.getAllAuthData();
    final userData = authData['user']['id']?.toString() ?? '';
    _currentUserId = int.tryParse(userData);
    debugPrint("👤 Current User ID: $_currentUserId");
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isLoading) {
        _fetchReplies(showLoading: false);
      }
    });
  }

  Future<void> _fetchTicketDetails() async {
    debugPrint("🚀 Fetching ticket details...");
    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token']?.trim();

    if (authToken == null || authToken.isEmpty || _currentUserId == null) {
      debugPrint("❌ Auth Check FAILED");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication failed. Please log in again.';
        });
      }
      return;
    }

    try {
      final url = 'https://erp.comsindia.in/api/tickets/${widget.ticketId}';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData['success'] == true && decodedData['ticket'] != null) {
          _ticket = Ticket.fromJson(decodedData['ticket']);
        } else {
          if (mounted) {
            setState(() {
              _errorMessage =
                  decodedData['message'] ?? 'Ticket data is missing.';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to load ticket details. Status code: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while loading ticket details: $e';
        });
      }
    }
  }

  Future<void> _fetchReplies({bool showLoading = true}) async {
    if (showLoading) {
      debugPrint("🚀 Fetching replies...");
    }

    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token']?.trim();

    if (authToken == null || authToken.isEmpty) {
      if (mounted && showLoading) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication failed. Please log in again.';
        });
      }
      return;
    }

    try {
      final url =
          'https://erp.comsindia.in/api/tickets/${widget.ticketId}/replies';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        if (decodedData['success'] == true && decodedData['replies'] != null) {
          List<Reply> replies = (decodedData['replies'] as List)
              .map((replyJson) => Reply.fromJson(replyJson))
              .toList();

          // Create unified message list
          List<ChatMessage> newMessages = [];

          // Add ticket as first message if it exists
          if (_ticket != null) {
            newMessages.add(ChatMessage(
              id: _ticket!.id,
              message: _ticket!.message,
              timestamp: DateTime.parse(_ticket!.createdAt),
              userId: _ticket!.userId,
              isTicket: true,
            ));
          }

          // Add replies
          for (Reply reply in replies) {
            newMessages.add(ChatMessage(
              id: reply.id,
              message: reply.message,
              timestamp: DateTime.parse(reply.createdAt),
              userId: reply.userId,
              isTicket: false,
            ));
          }

          // Sort by timestamp to ensure proper order
          newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          if (mounted) {
            bool hadMessages = _messages.isNotEmpty;
            setState(() {
              _messages = newMessages;
              if (showLoading) {
                _isLoading = false;
              }
            });

            // Auto-scroll to bottom for new messages or initial load
            if (!hadMessages || !_hasInitiallyScrolled) {
              _scrollToBottom(force: true);
              _hasInitiallyScrolled = true;
            } else {
              // Check if user is near bottom, then auto-scroll
              _autoScrollIfNearBottom();
            }
          }
        } else {
          if (mounted && showLoading) {
            setState(() {
              _isLoading = false;
              _errorMessage =
                  decodedData['message'] ?? 'Replies data is missing.';
            });
          }
        }
      } else {
        if (mounted && showLoading) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Failed to load replies. Status code: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted && showLoading) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred while loading replies: $e';
        });
      }
    }
  }

  Future<void> _sendReply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty || _isSending) return;

    debugPrint("🚀 Sending reply...");
    setState(() => _isSending = true);

    final authData = await _storageService.getAllAuthData();
    final String? authToken = authData['token']?.trim();

    if (authToken == null || authToken.isEmpty) {
      _showSnackBar('Authentication error. Please log in again.',
          isError: true);
      setState(() => _isSending = false);
      return;
    }

    final url =
        'https://erp.comsindia.in/api/tickets/${widget.ticketId}/replies';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
        body: {'message': message},
      );

      if (response.statusCode == 201) {
        _replyController.clear();
        _textFieldFocusNode.unfocus();

        // Add optimistic message immediately
        if (mounted && _currentUserId != null) {
          setState(() {
            _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch,
              message: message,
              timestamp: DateTime.now(),
              userId: _currentUserId!,
              isTicket: false,
            ));
          });
          _scrollToBottom(force: true);
        }

        // Fetch updated replies
        _fetchReplies(showLoading: false);
      } else {
        _showSnackBar('Failed to send reply. Please try again.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error sending reply. Please check your connection.',
          isError: true);
      debugPrint('Error sending reply: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _scrollToBottom({bool force = false}) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: force ? 500 : 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _autoScrollIfNearBottom() {
    if (!mounted || !_scrollController.hasClients) return;

    final position = _scrollController.position;
    const threshold = 100.0; // pixels from bottom

    if (position.maxScrollExtent - position.pixels <= threshold) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildModernAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildChatBody(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _ticket?.subjectId ?? 'Ticket Chat',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          if (_ticket != null)
            Text(
              'ID: ${_ticket!.id}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
        ],
      ),
      backgroundColor: kPrimaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => _fetchReplies(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3),
          SizedBox(height: 16),
          Text('Loading conversation...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _initializeChat();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBody() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMyMessage = message.userId == _currentUserId;
                    final showDateHeader = _shouldShowDateHeader(index);

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(message.timestamp),
                        _ModernMessageBubble(
                          isMyMessage: isMyMessage,
                          message: message.message,
                          timestamp: message.timestamp,
                          isTicket: message.isTicket,
                        ),
                      ],
                    );
                  },
                ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;

    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];

    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );
    final previousDate = DateTime(
      previousMessage.timestamp.year,
      previousMessage.timestamp.month,
      previousMessage.timestamp.day,
    );

    return currentDate != previousDate;
  }

  Widget _buildDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM d, y').format(timestamp);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _replyController,
                  focusNode: _textFieldFocusNode,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _sendReply(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey[400] : kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _sendReply,
                      color: Colors.white,
                      tooltip: 'Send Message',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernMessageBubble extends StatelessWidget {
  final bool isMyMessage;
  final String message;
  final DateTime timestamp;
  final bool isTicket;

  const _ModernMessageBubble({
    Key? key,
    required this.isMyMessage,
    required this.message,
    required this.timestamp,
    required this.isTicket,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? kMyMessageBubbleColor
                        : kOtherMessageBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMyMessage ? 18 : 6),
                      bottomRight: Radius.circular(isMyMessage ? 6 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isMyMessage ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTicket)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TICKET',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isTicket) const SizedBox(width: 4),
                      Text(
                        DateFormat('h:mm a').format(timestamp.toLocal()),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMyMessage) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isMyMessage ? kPrimaryColor : Colors.grey[400],
        shape: BoxShape.circle,
      ),
      child: Icon(
        isMyMessage ? Icons.person_rounded : Icons.support_agent_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

// Unified message class
class ChatMessage {
  final int id;
  final String message;
  final DateTime timestamp;
  final int userId;
  final bool isTicket;

  ChatMessage({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.userId,
    required this.isTicket,
  });
}

// Keep your existing Reply and Ticket classes
class Reply {
  final int id;
  final int ticketId;
  final int userId;
  final String message;
  final String createdAt;

  Reply({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    required this.createdAt,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'],
      ticketId: json['ticket_id'],
      userId: json['user_id'],
      message: json['message'] ?? '',
      createdAt: json['created_at'],
    );
  }
}

class Ticket {
  final int id;
  final int userId;
  final String subjectId;
  final String message;
  final String createdAt;
  final String? closedAt;

  Ticket({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.message,
    required this.createdAt,
    this.closedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      userId: json['user_id'],
      subjectId: json['subject_id'] ?? 'No Subject',
      message: json['message'] ?? '',
      createdAt: json['created_at'],
      closedAt: json['closed_at'],
    );
  }
}
