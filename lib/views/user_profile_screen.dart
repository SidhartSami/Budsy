// lib/views/user_profile_screen.dart - Production-Level User Profile with Green Theme
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/chat_settings_model.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/services/chat_settings_service.dart';
import 'package:tutortyper_app/views/message_search_screen.dart';
import 'package:tutortyper_app/views/chat_theme_selector_screen.dart';
import 'package:tutortyper_app/views/mutual_friends_screen.dart';
import 'package:tutortyper_app/widgets/avatar_selection_widget.dart';

class UserProfileScreen extends StatefulWidget {
  final UserModel user;
  final String chatId;

  const UserProfileScreen({
    super.key,
    required this.user,
    required this.chatId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ChatSettingsService _settingsService = ChatSettingsService();
  final TextEditingController _nicknameController = TextEditingController();

  bool _isLoadingSettings = true;
  List<UserModel> _mutualFriends = [];
  ChatSettingsModel? _settings;

  // Theme color
  static const Color _primaryGreen = Color(0xFF0C3C2B);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadMutualFriends();
    _loadChatSettings();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadMutualFriends() async {
    try {
      final userService = UserService();
      final currentUser = await userService.getCurrentUser();
      if (currentUser != null) {
        final mutual = <UserModel>[];
        for (String friendId in widget.user.friends) {
          if (currentUser.friends.contains(friendId)) {
            final friend = await userService.getUserById(friendId);
            if (friend != null) {
              mutual.add(friend);
            }
          }
        }
        setState(() => _mutualFriends = mutual);
      }
    } catch (e) {
      print('Error loading mutual friends: $e');
    }
  }

  Future<void> _loadChatSettings() async {
    setState(() => _isLoadingSettings = true);
    try {
      final settings = await _settingsService.getChatSettings(widget.chatId);

      setState(() {
        _settings = settings;
        _nicknameController.text = settings?.nickname ?? '';
      });
    } catch (e) {
      print('Error loading chat settings: $e');
    } finally {
      setState(() => _isLoadingSettings = false);
    }
  }

  Widget _buildUserAvatar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.user.photoUrl != null) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: CachedNetworkImageProvider(widget.user.photoUrl!),
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      );
    }

    if (widget.user.predefinedAvatar != null &&
        AvatarManager.isPredefinedAvatar(widget.user.predefinedAvatar)) {
      return CircleAvatar(
        radius: 44,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage(widget.user.predefinedAvatar!),
      );
    }

    if (widget.user.gender != null) {
      final defaultAvatar = AvatarManager.getDefaultAvatarForGender(
        widget.user.gender,
      );
      return CircleAvatar(
        radius: 44,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage(defaultAvatar),
      );
    }

    return CircleAvatar(
      radius: 44,
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Text(
        widget.user.displayName.isNotEmpty
            ? widget.user.displayName[0].toUpperCase()
            : 'U',
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildProfileContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 0,
      pinned: false,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      foregroundColor: isDark ? Colors.white : _primaryGreen,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 24),
        onPressed: () => Navigator.pop(context),
        splashRadius: 24,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz, size: 24),
          onPressed: _showOptionsMenu,
          splashRadius: 24,
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildProfileHeader(),
        const SizedBox(height: 24),
        _buildActionButtons(),
        if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildBioSection(),
        ],
        if (_mutualFriends.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildMutualFriendsSection(),
        ],
        const SizedBox(height: 8),
        Divider(
          height: 1,
          thickness: 0.5,
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        if (!_isLoadingSettings) _buildSettingsList(),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Stack(
          children: [
            Hero(
              tag: 'user_avatar_${widget.user.id}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.user.isOnline
                        ? const Color(0xFF4CAF50)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _buildUserAvatar(),
              ),
            ),
            if (widget.user.isVerified)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0095F6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF000000) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.user.displayName,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${widget.user.username}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (widget.user.isOnline) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Active now',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Message',
              icon: Icons.chat_bubble,
              isPrimary: true,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              label: 'Search',
              icon: Icons.search,
              isPrimary: false,
              onTap: _openMessageSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isPrimary 
          ? _primaryGreen 
          : (isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : _primaryGreen,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : (isDark ? Colors.white : _primaryGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBioSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        widget.user.bio!,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.black,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMutualFriendsSection() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MutualFriendsScreen(otherUser: widget.user),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primaryGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people, size: 20, color: _primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mutual friends',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${_mutualFriends.length} ${_mutualFriends.length == 1 ? 'friend' : 'friends'} in common',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        _buildSettingsTile(
          icon: Icons.edit,
          title: 'Nickname',
          subtitle: _settings?.nickname?.isEmpty ?? true
              ? 'Not set'
              : _settings!.nickname!,
          onTap: _showNicknameDialog,
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.palette,
          title: 'Theme',
          subtitle: _getThemeName(_settings?.chatTheme ?? 'default'),
          onTap: _showThemeSelector,
        ),
        _buildDivider(),
        _buildSwitchTile(
          icon: Icons.notifications_off,
          title: 'Mute notifications',
          value: _settings?.isMuted ?? false,
          onChanged: _toggleMute,
        ),
        const SizedBox(height: 8),
        Divider(
          height: 1,
          thickness: 8,
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5),
        ),
        const SizedBox(height: 8),
        _buildSettingsTile(
          icon: Icons.delete_outline,
          title: 'Clear chat',
          subtitle: 'Delete all messages',
          onTap: _showClearChatDialog,
          isDestructive: true,
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.person_remove,
          title: 'Unfriend',
          subtitle: 'Remove from friends',
          onTap: _showUnfriendDialog,
          isDestructive: true,
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.block,
          title: 'Block',
          subtitle: 'Block user',
          onTap: _showBlockDialog,
          isDestructive: true,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF000000) : Colors.white,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isDestructive ? Colors.red : _primaryGreen,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDestructive ? Colors.red : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDestructive)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
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
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _primaryGreen),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
              activeColor: _primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 54),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
    );
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'default':
        return 'Default';
      case 'dark':
        return 'Dark';
      case 'blue':
        return 'Blue';
      case 'green':
        return 'Green';
      case 'purple':
        return 'Purple';
      default:
        return 'Custom';
    }
  }

  void _showOptionsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.share, color: _primaryGreen),
              title: Text(
                'Share Profile',
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Share profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.content_copy, color: _primaryGreen),
              title: Text(
                'Copy Username',
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyUsername();
              },
            ),
            Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: Text(
                'Report',
                style: GoogleFonts.inter(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _copyUsername() {
    Clipboard.setData(ClipboardData(text: '@${widget.user.username}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Username copied'),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showUnfriendDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Unfriend ${widget.user.displayName}?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'You can always add them back as a friend.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => _unfriendUser(),
            child: Text(
              'Unfriend',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block ${widget.user.displayName}?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'They won\'t be able to message you or find your profile.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => _blockUser(),
            child: Text(
              'Block',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Report ${widget.user.displayName}?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'We\'ll review this report and take appropriate action.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon('Report user');
            },
            child: Text(
              'Report',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unfriendUser() async {
    try {
      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: _primaryGreen),
        ),
      );

      final userService = UserService();
      await userService.unfriendUser(widget.user.id);

      Navigator.pop(context);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unfriended ${widget.user.displayName}'),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _blockUser() async {
    try {
      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: _primaryGreen),
        ),
      );

      final userService = UserService();
      await userService.blockUser(widget.user.id);

      Navigator.pop(context);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blocked ${widget.user.displayName}'),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _showNicknameDialog() async {
    _nicknameController.text = _settings?.nickname ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Set Nickname',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: TextField(
            controller: _nicknameController,
            autofocus: true,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Enter nickname',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey.shade500,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF000000) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryGreen, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _nicknameController.text),
              child: Text(
                'Save',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await _settingsService.updateChatSettings(
          chatId: widget.chatId,
          nickname: result,
        );
        await _loadChatSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nickname updated'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _showThemeSelector() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatThemeSelectorScreen(
          chatId: widget.chatId,
          currentTheme: _settings?.chatTheme ?? 'default',
          onThemeSelected: (theme) async {
            try {
              await _settingsService.updateChatSettings(
                chatId: widget.chatId,
                chatTheme: theme,
              );
              await _loadChatSettings();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _toggleMute(bool value) async {
    try {
      await _settingsService.updateChatSettings(
        chatId: widget.chatId,
        isMuted: value,
      );
      await _loadChatSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Notifications muted' : 'Notifications enabled',
          ),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _openMessageSearch() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MessageSearchScreen(chatId: widget.chatId, otherUser: widget.user),
      ),
    );
  }

  Future<void> _showClearChatDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Clear chat history?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'This will permanently delete all messages. This action cannot be undone.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: _primaryGreen),
          ),
        );

        await _settingsService.clearChatHistory(widget.chatId);

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chat history cleared'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
