// lib/views/chat_settings_screen.dart - Enhanced Professional Version
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ChatSettingsScreenState extends State<ChatSettingsScreen>
    with TickerProviderStateMixin {
  final ChatSettingsService _settingsService = ChatSettingsService();
  final TextEditingController _nicknameController = TextEditingController();

  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  ChatSettingsModel? _settings;
  ChatStatsModel? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
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

      _fadeAnimationController.forward();
      _scaleAnimationController.forward();
    } catch (e) {
      print('Error loading chat settings: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildEnhancedAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E293B),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        'Chat Settings',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: const Color(0xFF1E293B),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF68EAFF)),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Loading settings...',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: _buildUserInfoSection(),
            ),
            const SizedBox(height: 20),
            _buildSettingsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF68EAFF).withOpacity(0.2),
                      const Color(0xFF68EAFF).withOpacity(0.1),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.otherUser.isOnline
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE2E8F0),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: widget.otherUser.photoUrl != null
                        ? CachedNetworkImageProvider(widget.otherUser.photoUrl!)
                        : null,
                    backgroundColor: const Color(0xFF68EAFF),
                    child: widget.otherUser.photoUrl == null
                        ? Text(
                            widget.otherUser.displayName.isNotEmpty
                                ? widget.otherUser.displayName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 36,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              if (widget.otherUser.isOnline)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _getDisplayName(),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${widget.otherUser.username}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: widget.otherUser.isOnline
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.1),
                        const Color(0xFF10B981).withOpacity(0.05),
                      ],
                    )
                  : null,
              color: widget.otherUser.isOnline ? null : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.otherUser.isOnline
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 8),
                Text(
                  widget.otherUser.isOnline ? 'Online now' : 'Offline',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.otherUser.isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      children: [
        _buildSettingsCard('Personalization', Icons.palette_outlined, [
          _buildSettingsTile(
            icon: Icons.edit_outlined,
            title: 'Nickname',
            subtitle: _settings?.nickname?.isEmpty ?? true
                ? 'Set a custom name'
                : _settings!.nickname!,
            onTap: _showNicknameDialog,
            hasValue: _settings?.nickname?.isNotEmpty ?? false,
          ),
          _buildSettingsTile(
            icon: Icons.color_lens_outlined,
            title: 'Chat Theme',
            subtitle: _getThemeName(_settings?.chatTheme ?? 'default'),
            onTap: _showThemeSelector,
            hasValue: true,
          ),
        ]),
        const SizedBox(height: 16),

        _buildSettingsCard('Privacy & Control', Icons.security_outlined, [
          _buildSwitchTile(
            icon: Icons.notifications_off_outlined,
            title: 'Mute Notifications',
            subtitle: _getMuteStatus(),
            value: _settings?.isMuted ?? false,
            onChanged: _toggleMute,
          ),
          _buildSettingsTile(
            icon: _settings?.isBlocked == true
                ? Icons.person_add_outlined
                : Icons.block_outlined,
            title: _settings?.isBlocked == true ? 'Unblock User' : 'Block User',
            subtitle: _settings?.isBlocked == true
                ? 'User is currently blocked'
                : 'Prevent messages from this user',
            onTap: _showBlockDialog,
            isDestructive: _settings?.isBlocked != true,
          ),
        ]),
        const SizedBox(height: 16),

        _buildSettingsCard('Chat Tools', Icons.build_outlined, [
          _buildSettingsTile(
            icon: Icons.search_outlined,
            title: 'Search Messages',
            subtitle: 'Find specific messages in this chat',
            onTap: _openMessageSearch,
          ),
          _buildSettingsTile(
            icon: Icons.bar_chart_outlined,
            title: 'Chat Statistics',
            subtitle: _getStatsPreview(),
            onTap: _showStatsDialog,
          ),
        ]),
        const SizedBox(height: 16),

        _buildSettingsCard('Danger Zone', Icons.warning_amber_outlined, [
          _buildSettingsTile(
            icon: Icons.delete_sweep_outlined,
            title: 'Clear Chat History',
            subtitle: 'Permanently delete all messages',
            onTap: _showClearChatDialog,
            isDestructive: true,
          ),
        ], isDangerZone: true),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSettingsCard(
    String title,
    IconData titleIcon,
    List<Widget> children, {
    bool isDangerZone = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDangerZone
            ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.2))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDangerZone
                ? const Color(0xFFEF4444).withOpacity(0.05)
                : const Color(0xFF000000).withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDangerZone
                        ? const Color(0xFFEF4444).withOpacity(0.1)
                        : const Color(0xFF68EAFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    titleIcon,
                    size: 20,
                    color: isDangerZone
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF68EAFF),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDangerZone
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool hasValue = false,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0xFFEF4444).withOpacity(0.1)
                      : const Color(0xFF68EAFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDestructive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF68EAFF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDestructive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasValue)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF68EAFF),
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF68EAFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF68EAFF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch.adaptive(
              value: value,
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
              activeColor: const Color(0xFF68EAFF),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
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

  String _getMuteStatus() {
    if (_settings?.isMuted != true) {
      return 'Receive all notifications';
    }

    if (_settings?.mutedUntil == null) {
      return 'Muted indefinitely';
    }

    final now = DateTime.now();
    final mutedUntil = _settings!.mutedUntil!;

    if (mutedUntil.isBefore(now)) {
      return 'Receive all notifications';
    }

    final difference = mutedUntil.difference(now);
    if (difference.inHours < 1) {
      return 'Muted for ${difference.inMinutes} minutes';
    } else if (difference.inDays < 1) {
      return 'Muted for ${difference.inHours} hours';
    } else {
      return 'Muted for ${difference.inDays} days';
    }
  }

  String _getStatsPreview() {
    if (_stats == null) {
      return 'View conversation insights';
    }
    return '${_stats!.totalMessages} messages exchanged';
  }

  // Dialog Methods
  void _showNicknameDialog() {
    showDialog(context: context, builder: (context) => _buildNicknameDialog());
  }

  Widget _buildNicknameDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.1),
              offset: const Offset(0, 8),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF68EAFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF68EAFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Set Nickname',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Set a custom nickname for ${widget.otherUser.displayName}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  hintText: 'Enter nickname',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF1E293B),
                ),
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                // Replace the existing buildCounter in your TextField with this:
                buildCounter:
                    (
                      context, {
                      required int currentLength,
                      required bool isFocused,
                      required int? maxLength,
                    }) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, right: 8),
                        child: Text(
                          '$currentLength/${maxLength ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      );
                    },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveNickname,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF68EAFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontSize: 15,
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
    );
  }

  Future<void> _saveNickname() async {
    try {
      await _settingsService.setNickname(
        widget.chatId,
        _nicknameController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
      await _loadData();
      _showSuccessMessage('Nickname updated successfully!');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorMessage('Error updating nickname: $e');
    }
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
      _showMuteOptions();
    } else {
      await _muteChat(null, unmute: true);
    }
  }

  void _showMuteOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMuteOptionsBottomSheet(),
    );
  }

  Widget _buildMuteOptionsBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mute Notifications',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildMuteOption(
            'For 1 Hour',
            Icons.schedule_outlined,
            () => _muteChat(DateTime.now().add(const Duration(hours: 1))),
          ),
          _buildMuteOption(
            'For 8 Hours',
            Icons.schedule_outlined,
            () => _muteChat(DateTime.now().add(const Duration(hours: 8))),
          ),
          _buildMuteOption(
            'For 1 Day',
            Icons.calendar_today_outlined,
            () => _muteChat(DateTime.now().add(const Duration(days: 1))),
          ),
          _buildMuteOption(
            'Until I Turn It Back On',
            Icons.notifications_off_outlined,
            () => _muteChat(null),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMuteOption(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF64748B), size: 20),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Close bottom sheet
      }
      await _loadData();
      _showSuccessMessage(unmute ? 'Chat unmuted' : 'Chat muted successfully');
    } catch (e) {
      _showErrorMessage('Error updating mute settings: $e');
    }
  }

  void _showBlockDialog() {
    final isBlocked = _settings?.isBlocked ?? false;
    showDialog(
      context: context,
      builder: (context) => _buildBlockDialog(isBlocked),
    );
  }

  Widget _buildBlockDialog(bool isBlocked) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.1),
              offset: const Offset(0, 8),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isBlocked
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isBlocked ? Icons.person_add_outlined : Icons.block_outlined,
                color: isBlocked
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isBlocked ? 'Unblock User' : 'Block User',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isBlocked
                  ? 'Are you sure you want to unblock ${widget.otherUser.displayName}? They will be able to message you again.'
                  : 'Are you sure you want to block ${widget.otherUser.displayName}? You won\'t receive messages from them.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _toggleBlock(isBlocked),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBlocked
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isBlocked ? 'Unblock' : 'Block',
                      style: GoogleFonts.inter(
                        fontSize: 15,
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
    );
  }

  Future<void> _toggleBlock(bool isCurrentlyBlocked) async {
    try {
      await _settingsService.toggleBlock(widget.chatId);
      if (mounted) Navigator.pop(context);
      await _loadData();
      _showSuccessMessage(
        isCurrentlyBlocked ? 'User unblocked' : 'User blocked',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorMessage('Error updating block status: $e');
    }
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
      _showErrorMessage('No statistics available yet');
      return;
    }

    showDialog(context: context, builder: (context) => _buildStatsDialog());
  }

  Widget _buildStatsDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.1),
              offset: const Offset(0, 8),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF68EAFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bar_chart_outlined,
                    color: Color(0xFF68EAFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Chat Statistics',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF68EAFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF68EAFF),
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
    showDialog(context: context, builder: (context) => _buildClearChatDialog());
  }

  Widget _buildClearChatDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.1),
              offset: const Offset(0, 8),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.delete_sweep_outlined,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Clear Chat History',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to clear all messages in this chat? This action cannot be undone.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearChatHistory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.inter(
                        fontSize: 15,
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
    );
  }

  Future<void> _clearChatHistory() async {
    try {
      await _settingsService.clearChatHistory(widget.chatId);
      if (mounted) Navigator.pop(context);
      _showSuccessMessage('Chat history cleared successfully');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorMessage('Error clearing chat history: $e');
    }
  }

  // Message display methods
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
