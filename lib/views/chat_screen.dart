// views/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/message_model.dart';
import 'package:tutortyper_app/services/message_service.dart';
import 'package:tutortyper_app/services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatScreen({super.key, required this.chatId, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUser.photoUrl != null
                  ? CachedNetworkImageProvider(widget.otherUser.photoUrl!)
                  : null,
              backgroundColor: Colors.white,
              child: widget.otherUser.photoUrl == null
                  ? Text(
                      widget.otherUser.displayName.isNotEmpty
                          ? widget.otherUser.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 104, 234, 243),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.otherUser.isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call coming soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _showUserInfo();
                  break;
                case 'clear':
                  _showClearChatDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('User Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[100]),
              child: StreamBuilder<List<MessageModel>>(
                stream: _messageService.getMessagesStream(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print('DEBUG: Stream error: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading messages',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {}), // Refresh
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: widget.otherUser.photoUrl != null
                                ? CachedNetworkImageProvider(
                                    widget.otherUser.photoUrl!,
                                  )
                                : null,
                            backgroundColor: const Color.fromARGB(
                              255,
                              104,
                              234,
                              243,
                            ),
                            child: widget.otherUser.photoUrl == null
                                ? Text(
                                    widget.otherUser.displayName.isNotEmpty
                                        ? widget.otherUser.displayName[0]
                                              .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start chatting with ${widget.otherUser.displayName}!',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Messages will appear here once you start the conversation.',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Show newest messages at bottom
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe =
                          message.senderId == UserService.currentUserId;

                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
          ),

          // Message Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Attachment button
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 104, 234, 243),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.white),
                    onPressed: _isLoading
                        ? null
                        : () {
                            _showAttachmentOptions();
                          },
                  ),
                ),
                const SizedBox(width: 8),

                // Message input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isLoading,
                      onSubmitted: (_) => _sendMessage(), // Send on enter
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                Container(
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? Colors.grey
                        : const Color.fromARGB(255, 104, 234, 243),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.otherUser.photoUrl != null
                  ? CachedNetworkImageProvider(widget.otherUser.photoUrl!)
                  : null,
              backgroundColor: const Color.fromARGB(255, 104, 234, 243),
              child: widget.otherUser.photoUrl == null
                  ? Text(
                      widget.otherUser.displayName.isNotEmpty
                          ? widget.otherUser.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color.fromARGB(255, 104, 234, 243)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.nunito(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.nunito(
                      color: isMe ? Colors.white70 : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 48), // Space for alignment
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      // Today - show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days - show date and time
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _messageService.sendMessage(chatId: widget.chatId, text: text);

      // Clear the input
      _messageController.clear();

      // Scroll to bottom to show new message
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      print('DEBUG: Message sent successfully');
    } catch (e) {
      print('DEBUG: Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    Icons.camera_alt,
                    'Camera',
                    Colors.pink,
                    () => _handleAttachment('camera'),
                  ),
                  _buildAttachmentOption(
                    Icons.photo_library,
                    'Gallery',
                    Colors.purple,
                    () => _handleAttachment('gallery'),
                  ),
                  _buildAttachmentOption(
                    Icons.insert_drive_file,
                    'Document',
                    Colors.blue,
                    () => _handleAttachment('document'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    Icons.location_on,
                    'Location',
                    Colors.green,
                    () => _handleAttachment('location'),
                  ),
                  _buildAttachmentOption(
                    Icons.mic,
                    'Voice',
                    Colors.orange,
                    () => _handleAttachment('voice'),
                  ),
                  _buildAttachmentOption(
                    Icons.person,
                    'Contact',
                    Colors.teal,
                    () => _handleAttachment('contact'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.nunito(fontSize: 12)),
        ],
      ),
    );
  }

  void _handleAttachment(String type) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type sharing coming soon!'),
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
      ),
    );
  }

  void _showUserInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'User Info',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: widget.otherUser.photoUrl != null
                    ? CachedNetworkImageProvider(widget.otherUser.photoUrl!)
                    : null,
                backgroundColor: const Color.fromARGB(255, 104, 234, 243),
                child: widget.otherUser.photoUrl == null
                    ? Text(
                        widget.otherUser.displayName.isNotEmpty
                            ? widget.otherUser.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                widget.otherUser.displayName,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.otherUser.email,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.otherUser.isOnline ? 'Online' : 'Offline',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: widget.otherUser.isOnline ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Clear Chat',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to clear this chat? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _messageService.clearChatMessages(widget.chatId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat cleared successfully!'),
                      backgroundColor: Color.fromARGB(255, 104, 234, 243),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear chat: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
