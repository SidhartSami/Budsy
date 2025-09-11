// lib/views/chat_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/chat_settings_model.dart';
import 'package:tutortyper_app/services/chat_settings_service.dart';
import 'package:tutortyper_app/views/message_search_screen.dart';
import 'package:tutortyper_app/views/chat_theme_selector_screen.dart';

class ChatSettingsScreen extends StatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatSettingsScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  final ChatSettingsService _settingsService = ChatSettingsService();
  final TextEditingController _nicknameController = TextEditingController();

  ChatSettingsModel? _settings;
  ChatStatsModel? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _settingsService.getChatSettings(widget.chatId);
      final stats = await _settingsService.getChatStats(widget.chatId);

      setState(() {
        _settings = settings;
        _stats = stats;
        _nicknameController.text = settings?.nickname ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chat settings: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Chat Settings',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // User Info Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
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
                                    fontSize: 36,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getDisplayName(),
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${widget.otherUser.username}',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.otherUser.isOnline
                                ? Colors.green
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.otherUser.isOnline ? 'Online' : 'Offline',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Settings Options
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildSettingsSection('Personalization', [
                          _buildSettingsTile(
                            icon: Icons.edit,
                            title: 'Nickname',
                            subtitle: _settings?.nickname ?? 'Not set',
                            onTap: _showNicknameDialog,
                          ),
                          _buildSettingsTile(
                            icon: Icons.palette,
                            title: 'Chat Theme',
                            subtitle: _getThemeName(
                              _settings?.chatTheme ?? 'default',
                            ),
                            onTap: _showThemeSelector,
                          ),
                        ]),

                        _buildSettingsSection('Privacy & Control', [
                          _buildSwitchTile(
                            icon: Icons.notifications_off,
                            title: 'Mute Chat',
                            subtitle: 'Stop receiving notifications',
                            value: _settings?.isMuted ?? false,
                            onChanged: _toggleMute,
                          ),
                          _buildSettingsTile(
                            icon: Icons.block,
                            title: _settings?.isBlocked == true
                                ? 'Unblock User'
                                : 'Block User',
                            subtitle: _settings?.isBlocked == true
                                ? 'User is blocked'
                                : 'Block this user',
                            textColor: Colors.red,
                            onTap: _showBlockDialog,
                          ),
                        ]),

                        _buildSettingsSection('Chat Tools', [
                          _buildSettingsTile(
                            icon: Icons.search,
                            title: 'Search Messages',
                            subtitle: 'Find specific messages',
                            onTap: _openMessageSearch,
                          ),
                          _buildSettingsTile(
                            icon: Icons.bar_chart,
                            title: 'Chat Statistics',
                            subtitle: 'View message stats',
                            onTap: _showStatsDialog,
                          ),
                        ]),

                        _buildSettingsSection('Actions', [
                          _buildSettingsTile(
                            icon: Icons.clear_all,
                            title: 'Clear Chat History',
                            subtitle: 'Delete all messages',
                            textColor: Colors.orange,
                            onTap: _showClearChatDialog,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getDisplayName() {
    if (_settings?.nickname != null && _settings!.nickname!.isNotEmpty) {
      return _settings!.nickname!;
    }
    return widget.otherUser.displayName;
  }

  String _getThemeName(String themeId) {
    final themes = ChatSettingsService.getChatThemes();
    final theme = themes.firstWhere(
      (t) => t['id'] == themeId,
      orElse: () => themes.first,
    );
    return theme['name'];
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? const Color.fromARGB(255, 104, 234, 243),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey[600]),
      ),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 104, 234, 243)),
      title: Text(
        title,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color.fromARGB(255, 104, 234, 243),
      ),
    );
  }

  void _showNicknameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Set Nickname',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set a custom nickname for ${widget.otherUser.displayName}',
                style: GoogleFonts.nunito(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  hintText: 'Enter nickname',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 104, 234, 243),
                    ),
                  ),
                ),
                maxLength: 30,
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
                try {
                  await _settingsService.setNickname(
                    widget.chatId,
                    _nicknameController.text,
                  );
                  Navigator.pop(context);
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nickname updated successfully!'),
                      backgroundColor: Color.fromARGB(255, 104, 234, 243),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating nickname: $e'),
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

  void _showThemeSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatThemeSelectorScreen(
          chatId: widget.chatId,
          currentTheme: _settings?.chatTheme ?? 'default',
          onThemeSelected: (theme) async {
            await _loadData();
          },
        ),
      ),
    );
  }

  void _toggleMute(bool value) async {
    if (value) {
      // Show mute options
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
                  'Mute Chat',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('1 Hour'),
                  onTap: () =>
                      _muteChat(DateTime.now().add(const Duration(hours: 1))),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('8 Hours'),
                  onTap: () =>
                      _muteChat(DateTime.now().add(const Duration(hours: 8))),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('1 Day'),
                  onTap: () =>
                      _muteChat(DateTime.now().add(const Duration(days: 1))),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_off),
                  title: const Text('Until I turn it back on'),
                  onTap: () => _muteChat(null),
                ),
              ],
            ),
          );
        },
      );
    } else {
      await _muteChat(null, unmute: true);
    }
  }

  Future<void> _muteChat(DateTime? until, {bool unmute = false}) async {
    try {
      if (unmute) {
        await _settingsService.updateChatSettings(
          chatId: widget.chatId,
          isMuted: false,
          mutedUntil: null,
        );
      } else {
        await _settingsService.toggleMute(widget.chatId, mutedUntil: until);
      }

      Navigator.of(context).pop(); // Close bottom sheet if open
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(unmute ? 'Chat unmuted' : 'Chat muted successfully'),
          backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating mute settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBlockDialog() {
    final isBlocked = _settings?.isBlocked ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            isBlocked ? 'Unblock User' : 'Block User',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          ),
          content: Text(
            isBlocked
                ? 'Are you sure you want to unblock ${widget.otherUser.displayName}? They will be able to message you again.'
                : 'Are you sure you want to block ${widget.otherUser.displayName}? You won\'t receive messages from them.',
            style: GoogleFonts.nunito(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _settingsService.toggleBlock(widget.chatId);
                  Navigator.pop(context);
                  await _loadData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBlocked ? 'User unblocked' : 'User blocked',
                      ),
                      backgroundColor: const Color.fromARGB(255, 104, 234, 243),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating block status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: isBlocked ? Colors.green : Colors.red,
              ),
              child: Text(isBlocked ? 'Unblock' : 'Block'),
            ),
          ],
        );
      },
    );
  }

  void _openMessageSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageSearchScreen(
          chatId: widget.chatId,
          otherUser: widget.otherUser,
        ),
      ),
    );
  }

  void _showStatsDialog() {
    if (_stats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No statistics available yet'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Chat Statistics',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Messages Sent', '${_stats!.messagesSent}'),
              _buildStatRow('Messages Received', '${_stats!.messagesReceived}'),
              _buildStatRow('Total Messages', '${_stats!.totalMessages}'),
              if (_stats!.firstMessageDate != null)
                _buildStatRow(
                  'First Message',
                  _formatDate(_stats!.firstMessageDate!),
                ),
              if (_stats!.lastMessageDate != null)
                _buildStatRow(
                  'Last Message',
                  _formatDate(_stats!.lastMessageDate!),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 14)),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 104, 234, 243),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays > 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
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
            'Clear Chat History',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to clear all messages in this chat? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // This would call your existing clear chat method
                Navigator.pop(context, 'clear_chat');
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
