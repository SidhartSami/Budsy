// views/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  const ChatScreen({super.key, required this.chatId, required this.otherUser});

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
  bool _hasPendingSpecialFriendRequest = false;

  @override
  void initState() {
    super.initState();
    _loadChatSettings();
    _checkPendingSpecialFriendRequest();
    _messageController.addListener(() {
      setState(() {});
    });
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          color: const Color(0xFF1E293B),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
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
          child: Row(
            children: [
              Stack(
                children: [
                  UserAvatarWidget(
                    user: widget.otherUser,
                    radius: 18,
                    backgroundColor: primaryColor.withOpacity(0.1),
                  ),
                  if (widget.otherUser.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _nickname ?? widget.otherUser.displayName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.otherUser.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF3B82F6),
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                    if (widget.otherUser.isOnline)
                      Text(
                        'Active now',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            offset: const Offset(0, 50),
            onSelected: (value) {
              switch (value) {
                case 'nickname':
                  _showNicknameDialog();
                  break;
                case 'theme':
                  _openThemeSelector();
                  break;
                case 'mute':
                  _toggleMute();
                  break;
                case 'search':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessageSearchScreen(
                        chatId: widget.chatId,
                        otherUser: widget.otherUser,
                      ),
                    ),
                  );
                  break;
                case 'stats':
                  _showChatStats();
                  break;
                case 'clear':
                  _showClearChatDialog();
                  break;
                case 'special':
                  _handleSpecialFriendRequest();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'special',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Special Friend',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'nickname',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Set Nickname',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.palette_rounded,
                        size: 18,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Change Theme',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search Messages',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isMuted
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        size: 18,
                        color: const Color(0xFFEAB308),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isMuted ? 'Unmute' : 'Mute',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Clear Chat',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
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
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {}),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState(primaryColor);
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _buildMessageItems(messages).length,
                  itemBuilder: (context, index) {
                    final items = _buildMessageItems(messages);
                    final item = items[index];

                    if (item['type'] == 'date_separator') {
                      return _buildDateSeparator(item['date'] as DateTime);
                    } else {
                      final message = item['message'] as MessageModel;
                      final isMe =
                          message.senderId == UserService.currentUserId;
                      final showTimestamp = item['showTimestamp'] as bool;
                      final isGrouped = item['isGrouped'] as bool;

                      return _buildMessageBubble(
                        message,
                        isMe,
                        primaryColor,
                        showTimestamp: showTimestamp,
                        isGrouped: isGrouped,
                      );
                    }
                  },
                );
              },
            ),
          ),

          // Message Input Area
          _buildMessageInput(primaryColor),
        ],
      ),
    );
  }

  Widget _buildMessageInput(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Expanded message input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Attachment button inside input
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                      onPressed: _showAttachmentOptions,
                    ),
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            _sendMessage();
                          }
                        },
                      ),
                    ),
                    // Emoji/Sticker button
                    IconButton(
                      icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: primaryColor,
                        size: 22,
                      ),
                      onPressed: () {
                        // Add emoji picker later
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button - only show when text is not empty
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: _messageController.text.trim().isNotEmpty
                  ? Container(
                      key: const ValueKey('send-button'),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _sendMessage,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UserAvatarWidget(
            user: widget.otherUser,
            radius: 40,
            backgroundColor: primaryColor.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Start chatting with ${_nickname ?? widget.otherUser.displayName}!',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Messages will appear here once you start the conversation.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildMessageItems(List<MessageModel> messages) {
    final items = <Map<String, dynamic>>[];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final previousMessage = i > 0 ? messages[i - 1] : null;
      final nextMessage = i < messages.length - 1 ? messages[i + 1] : null;

      // Check if we need a date separator
      if (previousMessage != null) {
        final currentDate = DateTime(
          message.timestamp.year,
          message.timestamp.month,
          message.timestamp.day,
        );
        final previousDate = DateTime(
          previousMessage.timestamp.year,
          previousMessage.timestamp.month,
          previousMessage.timestamp.day,
        );

        if (currentDate != previousDate) {
          items.add({'type': 'date_separator', 'date': message.timestamp});
        }
      } else {
        // First message, always show date separator
        items.add({'type': 'date_separator', 'date': message.timestamp});
      }

      // Determine if we should show timestamp and if message is grouped
      bool showTimestamp = false;
      bool isGrouped = false;

      if (nextMessage != null) {
        final timeDifference = message.timestamp
            .difference(nextMessage.timestamp)
            .inMinutes;
        final isSameSender = message.senderId == nextMessage.senderId;

        // Group messages from same sender within 2 minutes
        if (isSameSender && timeDifference <= 2) {
          isGrouped = true;
        } else {
          showTimestamp = true;
        }
      } else {
        // Last message, always show timestamp
        showTimestamp = true;
      }

      // Show timestamp if there's a significant time gap (>15 minutes)
      if (nextMessage != null) {
        final timeDifference = message.timestamp
            .difference(nextMessage.timestamp)
            .inMinutes;
        if (timeDifference > 15) {
          showTimestamp = true;
        }
      }

      items.add({
        'type': 'message',
        'message': message,
        'showTimestamp': showTimestamp,
        'isGrouped': isGrouped,
      });
    }

    return items;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDateSeparator(date),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    MessageModel message,
    bool isMe,
    Color primaryColor, {
    bool showTimestamp = true,
    bool isGrouped = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isGrouped ? 2 : 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && !isGrouped) ...[
                UserAvatarWidget(
                  user: widget.otherUser,
                  radius: 16,
                  backgroundColor: primaryColor.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
              ] else if (!isMe && isGrouped) ...[
                const SizedBox(width: 40), // Space for avatar alignment
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? primaryColor : Colors.white,
                    borderRadius: _getBubbleBorderRadius(isMe, isGrouped),
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
                        : Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: isMe ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 48),
            ],
          ),
          if (showTimestamp) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isMe) const SizedBox(width: 48),
                Text(
                  _formatRelativeTime(message.timestamp),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isMe) const SizedBox(width: 48),
              ],
            ),
          ],
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
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Set Nickname',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set a custom nickname for ${widget.otherUser.displayName}',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter nickname...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final nickname = controller.text.trim();
                Navigator.pop(context);
                try {
                  await _settingsService.setNickname(widget.chatId, nickname);
                  setState(() {
                    _nickname = nickname.isEmpty ? null : nickname;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Nickname updated successfully!'),
                      backgroundColor: primaryColor,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    try {
      await _settingsService.toggleMute(widget.chatId);
      setState(() {
        _isMuted = !_isMuted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isMuted ? 'Chat muted' : 'Chat unmuted'),
          backgroundColor: primaryColor,
        ),
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

  Future<void> _showChatStats() async {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    try {
      final stats = await _settingsService.getChatStats(widget.chatId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Chat Statistics',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
          Text(label, style: GoogleFonts.inter()),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showClearChatDialog() {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Clear Chat',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to clear this chat? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _messageService.clearChatMessages(widget.chatId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Chat cleared successfully!'),
                      backgroundColor: primaryColor,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showAttachmentOptions() {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

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
                style: GoogleFonts.inter(
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
          Text(label, style: GoogleFonts.inter(fontSize: 12)),
        ],
      ),
    );
  }

  void _handleAttachment(String type) {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type sharing coming soon!'),
        backgroundColor: primaryColor,
      ),
    );
  }

  BorderRadius _getBubbleBorderRadius(bool isMe, bool isGrouped) {
    if (isGrouped) {
      // Grouped messages have less rounded corners on the sender's side
      return BorderRadius.only(
        topLeft: Radius.circular(isMe ? 20 : 8),
        topRight: Radius.circular(isMe ? 8 : 20),
        bottomLeft: Radius.circular(isMe ? 20 : 8),
        bottomRight: Radius.circular(isMe ? 8 : 20),
      );
    } else {
      // Regular message bubbles
      return BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isMe ? 20 : 6),
        bottomRight: Radius.circular(isMe ? 6 : 20),
      );
    }
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[timestamp.weekday - 1]} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return weekdays[date.weekday - 1];
    } else if (date.year == now.year) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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

  // Special Friend Request Methods
  Stream<Map<String, bool>> _getSpecialFriendAndRequestStatusStream() {
    return UserService().getCurrentUserStream().asyncMap((user) async {
      if (user == null)
        return {
          'isSpecialFriend': false,
          'hasPendingRequest': false,
          'hasIncomingRequest': false,
          'hasExistingSpecialFriend': false,
        };

      final isSpecialFriend = user.specialFriends.contains(widget.otherUser.id);
      final hasPendingRequest = await _checkPendingSpecialFriendRequest();
      final hasIncomingRequest = await _checkIncomingSpecialFriendRequest();
      final hasExistingSpecialFriend =
          user.specialFriends.isNotEmpty && !isSpecialFriend;

      return {
        'isSpecialFriend': isSpecialFriend,
        'hasPendingRequest': hasPendingRequest,
        'hasIncomingRequest': hasIncomingRequest,
        'hasExistingSpecialFriend': hasExistingSpecialFriend,
      };
    });
  }

  Future<void> _handleSpecialFriendRequest() async {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    try {
      final userService = UserService();

      // Check current status
      final isSpecialFriend = await userService.isSpecialFriend(
        widget.otherUser.id,
      );
      final hasPendingRequest = await _checkPendingSpecialFriendRequest();
      final hasIncomingRequest = await _checkIncomingSpecialFriendRequest();

      if (isSpecialFriend) {
        _showSpecialFriendDialog();
        return;
      }

      if (hasIncomingRequest) {
        _showIncomingRequestDialog();
        return;
      }

      if (hasPendingRequest) {
        _showPendingRequestDialog();
        return;
      }

      // Send special friend request
      await userService.sendSpecialFriendRequest(widget.otherUser.id);

      setState(() {
        _hasPendingSpecialFriendRequest = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Special friend request sent to ${widget.otherUser.displayName}!',
          ),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _checkPendingSpecialFriendRequest() async {
    try {
      final currentUserId = UserService.currentUserId;
      if (currentUserId == null) return false;

      // Check if current user has sent a request to this user
      final querySnapshot = await FirebaseFirestore.instance
          .collection('specialFriendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: widget.otherUser.id)
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking pending special friend request: $e');
      return false;
    }
  }

  Future<bool> _checkIncomingSpecialFriendRequest() async {
    try {
      final currentUserId = UserService.currentUserId;
      if (currentUserId == null) return false;

      // Check if this user has sent a request to current user
      final querySnapshot = await FirebaseFirestore.instance
          .collection('specialFriendRequests')
          .where('senderId', isEqualTo: widget.otherUser.id)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking incoming special friend request: $e');
      return false;
    }
  }

  void _showIncomingRequestDialog() {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.favorite_border_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Special Friend Request',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatarWidget(
                user: widget.otherUser,
                radius: 30,
                backgroundColor: Colors.orange.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.otherUser.displayName} wants to be your special friend! 💜',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Back',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _rejectIncomingSpecialFriendRequest();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(
                'Reject',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _acceptIncomingSpecialFriendRequest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Accept',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSpecialFriendDialog() {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Special Friends',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You and ${widget.otherUser.displayName} are special friends! 💜',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _removeSpecialFriend();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove Special Friend'),
            ),
          ],
        );
      },
    );
  }

  void _showPendingRequestDialog() {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Pending Request',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You have already sent a special friend request to ${widget.otherUser.displayName}. Please wait for their response.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _cancelSpecialFriendRequest();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Request'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptIncomingSpecialFriendRequest() async {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    try {
      final currentUserId = UserService.currentUserId;
      if (currentUserId == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('specialFriendRequests')
          .where('senderId', isEqualTo: widget.otherUser.id)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final requestId = querySnapshot.docs.first.id;
        final userService = UserService();
        await userService.acceptSpecialFriendRequest(
          requestId,
          widget.otherUser.id,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You and ${widget.otherUser.displayName} are now special friends! 💜',
            ),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectIncomingSpecialFriendRequest() async {
    try {
      final currentUserId = UserService.currentUserId;
      if (currentUserId == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('specialFriendRequests')
          .where('senderId', isEqualTo: widget.otherUser.id)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final requestId = querySnapshot.docs.first.id;
        final userService = UserService();
        await userService.rejectSpecialFriendRequest(requestId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Special friend request rejected'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeSpecialFriend() async {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    try {
      final userService = UserService();
      await userService.removeSpecialFriend(widget.otherUser.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Removed ${widget.otherUser.displayName} from special friends',
          ),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing special friend: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelSpecialFriendRequest() async {
    final themeColors = _getThemeColors();
    final primaryColor = Color(themeColors['primaryColor']);

    try {
      final currentUserId = UserService.currentUserId;
      if (currentUserId == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('specialFriendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: widget.otherUser.id)
          .where('status', isEqualTo: 'pending')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final requestId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('specialFriendRequests')
            .doc(requestId)
            .delete();

        setState(() {
          _hasPendingSpecialFriendRequest = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Special friend request cancelled'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
