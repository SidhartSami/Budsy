import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/chat_settings_model.dart';
import 'package:tutortyper_app/services/chat_settings_service.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/views/message_search_screen.dart';
import 'package:tutortyper_app/views/chat_theme_selector_screen.dart';
import 'package:tutortyper_app/views/mutual_friends_screen.dart';
import 'package:tutortyper_app/widgets/user_avatar_widget.dart';

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
  int _mutualFriendsCount = 0;
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

      final UserService userService = UserService();
      final mutualFriends = await userService.getMutualFriends(
        widget.otherUser.id,
      );

      setState(() {
        _settings = settings;
        _stats = stats;
        _mutualFriendsCount = mutualFriends.length;
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
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
    return Column(
      children: [
        Container(
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
                      child: UserAvatarWidget(
                        user: widget.otherUser,
                        radius: 50,
                        backgroundColor: const Color(0xFF68EAFF),
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
                _settings?.nickname ?? widget.otherUser.displayName,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: widget.otherUser.isOnline
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF10B981).withOpacity(0.1),
                            const Color(0xFF10B981).withOpacity(0.05),
                          ],
                        )
                      : null,
                  color: widget.otherUser.isOnline
                      ? null
                      : const Color(0xFFF1F5F9),
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
        ),
      ],
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      children: [
        _buildMutualFriendsButton(),
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
        ),
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
        _buildSettingsTile(
          icon: Icons.delete_sweep_outlined,
          title: 'Clear Chat History',
          subtitle: 'Permanently delete all messages',
          onTap: _showClearChatDialog,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMutualFriendsButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _openMutualFriends();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
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
                  child: const Icon(
                    Icons.group_outlined,
                    size: 20,
                    color: Color(0xFF68EAFF),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mutual Friends',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _mutualFriendsCount == 0
                            ? 'No mutual friends'
                            : _mutualFriendsCount == 1
                            ? '1 mutual friend'
                            : '$_mutualFriendsCount mutual friends',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_mutualFriendsCount > 0)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF68EAFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool hasValue = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
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
      ),
    );
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

  void _showNicknameDialog() {
    showDialog(context: context, builder: (context) => _buildNicknameDialog());
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

  void _toggleMute(bool value) {
    // Implement mute functionality
  }

  void _showBlockDialog() {
    // Implement block dialog
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

  void _openMutualFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MutualFriendsScreen(otherUser: widget.otherUser),
      ),
    );
  }

  void _showStatsDialog() {
    // Implement stats dialog
  }

  void _showClearChatDialog() {
    // Implement clear chat dialog
  }

  Widget _buildNicknameDialog() {
    // Implement nickname dialog
    return const SizedBox();
  }
}
