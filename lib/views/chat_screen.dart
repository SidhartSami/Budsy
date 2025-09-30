// views/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/message_model.dart';
import 'package:tutortyper_app/models/chat_settings_model.dart';
import 'package:tutortyper_app/services/message_service.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/services/chat_settings_service.dart';
import 'package:tutortyper_app/views/chat_theme_selector_screen.dart';
import 'package:tutortyper_app/views/message_search_screen.dart';
import 'package:tutortyper_app/views/user_profile_screen.dart';
import 'package:tutortyper_app/widgets/user_avatar_widget.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();
  final ChatSettingsService _settingsService = ChatSettingsService();

  bool _isLoading = false;
  ChatSettingsModel? _chatSettings;
  String _currentTheme = 'default';
  String? _nickname;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadChatSettings();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatSettings() async {
    try {
      final settings = await _settingsService.getChatSettings(widget.chatId);
      if (settings != null) {
        setState(() {
          _chatSettings = settings;
          _currentTheme = settings.chatTheme;
          _nickname = settings.nickname;
          _isMuted = settings.isMuted;
        });
      }
    } catch (e) {
      print('Error loading chat settings: $e');
    }
  }

  Map<String, dynamic> _getThemeColors() {
    final themes = ChatSettingsService.getChatThemes();
    final theme = themes.firstWhere(
      (t) => t['id'] == _currentTheme,
      orElse: () => themes.first,
    );
    return theme;
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);
    final backgroundColor = Color(themeColors['backgroundColor']);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.otherUser.isOnline
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.otherUser.photoUrl != null
                        ? CachedNetworkImageProvider(widget.otherUser.photoUrl!)
                        : null,
                    backgroundColor: const Color(0xFF68EAFF),
                    child: widget.otherUser.photoUrl == null
                        ? Text(
                            (_nickname ?? widget.otherUser.displayName).isNotEmpty
                                ? (_nickname ?? widget.otherUser.displayName)[0]
                                      .toUpperCase()
                                : 'U',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                ),
                if (widget.otherUser.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nickname ?? widget.otherUser.displayName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.otherUser.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.otherUser.isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: widget.otherUser.isOnline 
                              ? const Color(0xFF10B981)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isMuted) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.volume_off_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF68EAFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: Color(0xFF68EAFF),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      user: widget.otherUser,
                      chatId: widget.chatId,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages Area
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messageService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
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
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == UserService.currentUserId;
                    return _buildMessageBubble(message, isMe, primaryColor);
                  },
                );
              },
            ),
          ),

          // Message Input Area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF68EAFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF68EAFF),
                  size: 24,
                ),
                onPressed: _showAttachmentOptions,
              ),
            ),
            const SizedBox(width: 12),
            
            // Message Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _sendMessage();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Send Button
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF68EAFF),
                    Color(0xFF4FD1C7),
                  ],
                ),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  if (_messageController.text.trim().isNotEmpty) {
                    _sendMessage();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: widget.otherUser.photoUrl != null
                ? CachedNetworkImageProvider(widget.otherUser.photoUrl!)
                : null,
            backgroundColor: Color(_getThemeColors()['primaryColor']),
            child: widget.otherUser.photoUrl == null
                ? Text(
                    (_nickname ?? widget.otherUser.displayName).isNotEmpty
                        ? (_nickname ?? widget.otherUser.displayName)[0]
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
            'Start chatting with ${_nickname ?? widget.otherUser.displayName}!',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Messages will appear here once you start the conversation.',
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    MessageModel message,
    bool isMe,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            UserAvatarWidget(
              user: widget.otherUser,
              radius: 16,
              backgroundColor: primaryColor,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? const Color(0xFF68EAFF)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withOpacity(0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
                border: isMe 
                    ? null 
                    : Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: isMe ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.inter(
                      color: isMe ? Colors.white.withOpacity(0.8) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading || _isMuted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _messageService.sendMessage(chatId: widget.chatId, text: text);

      // Update chat statistics in database
      await _settingsService.updateChatStats(
        chatId: widget.chatId,
        isMessageSent: true,
        messageTime: DateTime.now(),
      );

      _messageController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
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


  void _showNicknameDialog() {
    final controller = TextEditingController(text: _nickname ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Set Nickname',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set a custom nickname for ${widget.otherUser.displayName}'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter nickname...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final nickname = controller.text.trim();
                Navigator.pop(context);
                try {
                  await _settingsService.setNickname(widget.chatId, nickname);
                  setState(() {
                    _nickname = nickname.isEmpty ? null : nickname;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nickname updated successfully!'),
                      backgroundColor: Color.fromARGB(255, 104, 234, 243),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update nickname: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _openThemeSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatThemeSelectorScreen(
          chatId: widget.chatId,
          currentTheme: _currentTheme,
          onThemeSelected: (theme) {
            setState(() {
              _currentTheme = theme;
            });
          },
        ),
      ),
    );
  }

  Future<void> _toggleMute() async {
    try {
      await _settingsService.toggleMute(widget.chatId);
      setState(() {
        _isMuted = !_isMuted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isMuted ? 'Chat muted' : 'Chat unmuted'),
          backgroundColor: Color(_getThemeColors()['primaryColor']),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${_isMuted ? 'mute' : 'unmute'} chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showChatStats() async {
    try {
      final stats = await _settingsService.getChatStats(widget.chatId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Chat Statistics',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Messages sent:', '${stats?.messagesSent ?? 0}'),
                _buildStatRow(
                  'Messages received:',
                  '${stats?.messagesReceived ?? 0}',
                ),
                _buildStatRow(
                  'Total messages:',
                  '${stats?.totalMessages ?? 0}',
                ),
                if (stats?.firstMessageDate != null)
                  _buildStatRow(
                    'First message:',
                    _formatDate(stats!.firstMessageDate!),
                  ),
                if (stats?.lastMessageDate != null)
                  _buildStatRow(
                    'Last message:',
                    _formatDate(stats!.lastMessageDate!),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load chat stats: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.nunito()),
          Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        ],
      ),
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

  void _showAttachmentOptions() {
    final primaryColor = Color(_getThemeColors()['primaryColor']);

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
        backgroundColor: Color(_getThemeColors()['primaryColor']),
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
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
