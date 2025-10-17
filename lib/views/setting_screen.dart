// views/settings_screen.dart - Professional Production-Level Design
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/views/blocked_users_screen.dart';
import 'package:tutortyper_app/views/profile_picture_screen.dart';
import 'package:tutortyper_app/widgets/avatar_selection_widget.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final ValueChanged<bool>? onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.onLogout,
    this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;

  bool isDarkMode = false;
  bool showOnlineStatus = true;
  bool showBirthDate = false;
  bool pushNotifications = true;
  bool emailNotifications = false;
  UserModel? currentUser;
  bool isLoading = false;

  static const Color _primaryGreen = Color(0xFF0C3C2B);
  static const Color _backgroundGray = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserData();
    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          currentUser = user;
          showOnlineStatus = user.showOnlineStatus;
          showBirthDate = user.showBirthDate;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isDarkMode = prefs.getBool('isDarkMode') ?? false;
        pushNotifications = prefs.getBool('pushNotifications') ?? true;
        emailNotifications = prefs.getBool('emailNotifications') ?? false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setBool('pushNotifications', pushNotifications);
    await prefs.setBool('emailNotifications', emailNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Professional AppBar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
              color: Colors.black87,
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(color: Colors.white),
            ),
          ),

          // Profile Header Card
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _animationController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildProfileCard(),
              ),
            ),
          ),

          // Settings Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSettingsGroup('Account', [
                  _buildSettingsTile(
                    icon: Icons.person_outline,
                    title: 'Display Name',
                    subtitle: currentUser?.displayName ?? 'Not set',
                    onTap: () => _showEditDialog(
                      'Display Name',
                      currentUser?.displayName ?? '',
                      _updateDisplayName,
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.alternate_email,
                    title: 'Username',
                    subtitle: '@${currentUser?.username ?? 'username'}',
                    onTap: () => _showEditDialog(
                      'Username',
                      currentUser?.username ?? '',
                      _updateUsername,
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: 'Bio',
                    subtitle: _getBioPreview(),
                    onTap: _showBioEditDialog,
                  ),
                  _buildDivider(),

                  _buildSettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Password',
                    subtitle: '••••••••',
                    onTap: _showChangePasswordDialog,
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSettingsGroup('Preferences', [
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Adjust the appearance',
                    value: isDarkMode,
                    onChanged: _updateDarkMode,
                  ),
                  _buildSettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: pushNotifications ? 'Enabled' : 'Disabled',
                    trailing: _buildStatusBadge(pushNotifications),
                    onTap: _showNotificationSettings,
                  ),
                  _buildSettingsTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English (US)',
                    onTap: () => _showComingSoon('Language settings'),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSettingsGroup('Privacy & Security', [
                  _buildSwitchTile(
                    icon: Icons.circle,
                    title: 'Show Online Status',
                    subtitle: 'Let others see when you\'re active',
                    value: showOnlineStatus,
                    onChanged: _updateShowOnlineStatus,
                    iconColor: Colors.green,
                  ),
                  _buildSettingsTile(
                    icon: Icons.block_outlined,
                    title: 'Blocked Users',
                    subtitle: 'Manage blocked accounts',
                    onTap: _showBlockedUsers,
                  ),
                  _buildSettingsTile(
                    icon: Icons.shield_outlined,
                    title: 'Two-Factor Authentication',
                    subtitle: 'Add extra security',
                    trailing: _buildComingSoonBadge(),
                    onTap: _setup2FA,
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSettingsGroup('Support', [
                  _buildSettingsTile(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    subtitle: 'Get support and answers',
                    onTap: _openHelpCenter,
                  ),
                  _buildSettingsTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Report a Bug',
                    subtitle: 'Help us improve',
                    onTap: _reportBug,
                  ),
                  _buildSettingsTile(
                    icon: Icons.feedback_outlined,
                    title: 'Send Feedback',
                    subtitle: 'Share your thoughts',
                    onTap: _sendSuggestion,
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSettingsGroup('Legal', [
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: _openPrivacyPolicy,
                  ),
                  _buildSettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: _openTermsOfService,
                  ),
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Version 1.0.0',
                    hideArrow: true,
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 24),
                _buildActionButton(
                  'Logout',
                  Icons.logout,
                  Colors.black87,
                  () => _showLogoutDialog(context),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  'Delete Account',
                  Icons.delete_outline,
                  Colors.red.shade600,
                  _showDeleteAccountDialog,
                  isDestructive: true,
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: _showProfilePictureView,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                  ),
                  child: ClipOval(child: _buildProfileAvatar(36)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser?.displayName ?? 'User',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${currentUser?.username ?? 'username'}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (currentUser?.bio != null &&
                      currentUser!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      currentUser!.bio!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool hideArrow = false,
    bool showBadge = false,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? Colors.black87, size: 22),
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
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (!hideArrow)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade400,
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
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Colors.black87, size: 22),
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
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
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
              activeTrackColor: _primaryGreen.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 54),
      child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? _primaryGreen.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'On' : 'Off',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? _primaryGreen : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildComingSoonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200, width: 0.5),
      ),
      child: Text(
        'Soon',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.amber.shade700,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive ? Colors.red.shade200 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(double radius) {
    if (currentUser?.photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: currentUser!.photoUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade100,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade100,
          child: Icon(Icons.person, size: radius, color: Colors.grey.shade400),
        ),
      );
    }

    if (currentUser?.predefinedAvatar != null &&
        AvatarManager.isPredefinedAvatar(currentUser!.predefinedAvatar)) {
      return Image.asset(
        currentUser!.predefinedAvatar!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
      );
    }

    if (currentUser?.gender != null) {
      final defaultAvatar = AvatarManager.getDefaultAvatarForGender(
        currentUser!.gender,
      );
      return Image.asset(
        defaultAvatar,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      color: Colors.grey.shade100,
      child: Icon(Icons.person, size: radius, color: Colors.grey.shade400),
    );
  }

  String _getBioPreview() {
    final bio = currentUser?.bio;
    if (bio != null && bio.isNotEmpty) {
      return bio.length > 35 ? '${bio.substring(0, 35)}...' : bio;
    }
    return 'Add a bio';
  }

  // Action Methods
  void _showProfilePictureView() {
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePictureScreen(currentUser: currentUser!),
        ),
      ).then((_) => _loadUserData());
    }
  }

  Future<void> _updateShowOnlineStatus(bool value) async {
    setState(() {
      showOnlineStatus = value;
      isLoading = true;
    });

    try {
      await _userService.updateUserProfile(showOnlineStatus: value);
      if (!value) {
        await _userService.updateOnlineStatus(false);
      } else {
        await _userService.updateOnlineStatus(true);
      }
      await _saveSettings();
      await _loadUserData();
      if (mounted) _showSuccess('Online status updated');
    } catch (e) {
      setState(() => showOnlineStatus = !value);
      if (mounted) _showError('Failed to update status');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateDarkMode(bool value) async {
    setState(() => isDarkMode = value);
    await _saveSettings();
    widget.onThemeChanged?.call(value);
    if (mounted) _showSuccess('${value ? 'Dark' : 'Light'} mode enabled');
  }

  Future<void> _updateDisplayName(String newDisplayName) async {
    if (newDisplayName.trim().isEmpty) {
      _showError('Display name cannot be empty');
      return;
    }
    setState(() => isLoading = true);
    try {
      await _userService.updateUserProfile(displayName: newDisplayName.trim());
      await _loadUserData();
      if (mounted) _showSuccess('Display name updated');
    } catch (e) {
      if (mounted) _showError('Failed to update display name');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    final normalized = newUsername.toLowerCase().trim();
    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(normalized)) {
      _showError('Username must be 3-30 characters (letters, numbers, _ only)');
      return;
    }
    setState(() => isLoading = true);
    try {
      await _userService.updateUserProfile(username: normalized);
      await _loadUserData();
      if (mounted) _showSuccess('Username updated');
    } catch (e) {
      if (mounted) _showError('Username may be taken');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateBio(String newBio) async {
    setState(() => isLoading = true);
    try {
      await _userService.updateUserProfile(bio: newBio.trim());
      await _loadUserData();
      if (mounted) _showSuccess('Bio updated');
    } catch (e) {
      if (mounted) _showError('Failed to update bio');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showComingSoon(String feature) {
    _showError('$feature coming soon');
  }

  void _showEditDialog(
    String field,
    String currentValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit $field',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: field == 'Username' ? 30 : 50,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  labelText: field,
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _primaryGreen,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onSave(controller.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          color: Colors.white,
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
      ),
    );
  }

  void _showBioEditDialog() {
    final controller = TextEditingController(text: currentUser?.bio ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Bio',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                maxLength: 150,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell others about yourself...',
                  labelStyle: GoogleFonts.inter(),
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _primaryGreen,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateBio(controller.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          color: Colors.white,
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
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Change Password',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your current password and choose a new one',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: GoogleFonts.inter(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _primaryGreen,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: () {
                        setModalState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: GoogleFonts.inter(),
                    hintText: 'At least 6 characters',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _primaryGreen,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: () {
                        setModalState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: GoogleFonts.inter(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _primaryGreen,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: () {
                        setModalState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (currentPasswordController.text.isEmpty) {
                                  _showError('Enter current password');
                                  return;
                                }
                                if (newPasswordController.text.length < 6) {
                                  _showError(
                                    'Password must be at least 6 characters',
                                  );
                                  return;
                                }
                                if (newPasswordController.text !=
                                    confirmPasswordController.text) {
                                  _showError('Passwords do not match');
                                  return;
                                }

                                setModalState(() => isLoading = true);

                                try {
                                  final user = _auth.currentUser;
                                  if (user != null && user.email != null) {
                                    // Re-authenticate user
                                    final credential =
                                        EmailAuthProvider.credential(
                                          email: user.email!,
                                          password:
                                              currentPasswordController.text,
                                        );

                                    await user.reauthenticateWithCredential(
                                      credential,
                                    );
                                    await user.updatePassword(
                                      newPasswordController.text,
                                    );

                                    if (mounted) {
                                      Navigator.pop(context);
                                      _showSuccess(
                                        'Password changed successfully',
                                      );
                                    }
                                  }
                                } on FirebaseAuthException catch (e) {
                                  String errorMessage =
                                      'Failed to change password';
                                  if (e.code == 'wrong-password') {
                                    errorMessage =
                                        'Current password is incorrect';
                                  } else if (e.code == 'weak-password') {
                                    errorMessage = 'Password is too weak';
                                  } else if (e.code ==
                                      'requires-recent-login') {
                                    errorMessage =
                                        'Please logout and login again';
                                  }
                                  if (mounted) {
                                    _showError(errorMessage);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _showError('An error occurred');
                                  }
                                } finally {
                                  if (mounted) {
                                    setModalState(() => isLoading = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Change Password',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalNotificationSettingsScreen(
          initialPushNotifications: pushNotifications,
          initialEmailNotifications: emailNotifications,
          onSettingsChanged: (push, email) async {
            setState(() {
              pushNotifications = push;
              emailNotifications = email;
            });
            await _saveSettings();
          },
        ),
      ),
    );
  }

  void _showBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BlockedUsersScreen()),
    );
  }

  void _setup2FA() => _showComingSoon('Two-Factor Authentication');
  void _openHelpCenter() => _showComingSoon('Help Center');
  void _openPrivacyPolicy() => _showComingSoon('Privacy Policy');
  void _openTermsOfService() => _showComingSoon('Terms of Service');

  void _reportBug() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Report a Bug',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 5,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Describe the issue you encountered...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _primaryGreen,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      _showSuccess('Thank you! Bug report submitted');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit Report',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendSuggestion() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Send Feedback',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 5,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts and ideas...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _primaryGreen,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      _showSuccess('Thank you! Feedback received');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Send Feedback',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            Text(
              'Delete Account?',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        title: Text(
          'Type "DELETE" to confirm',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Type DELETE',
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == 'DELETE') {
                Navigator.pop(context);
                _showComingSoon('Account deletion');
              } else {
                _showError('Please type "DELETE" to confirm');
              }
            },
            child: Text(
              'Delete Forever',
              style: GoogleFonts.inter(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        title: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: _primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Professional Notification Settings Screen
class ProfessionalNotificationSettingsScreen extends StatefulWidget {
  final bool initialPushNotifications;
  final bool initialEmailNotifications;
  final Function(bool push, bool email) onSettingsChanged;

  const ProfessionalNotificationSettingsScreen({
    super.key,
    required this.initialPushNotifications,
    required this.initialEmailNotifications,
    required this.onSettingsChanged,
  });

  @override
  State<ProfessionalNotificationSettingsScreen> createState() =>
      _ProfessionalNotificationSettingsScreenState();
}

class _ProfessionalNotificationSettingsScreenState
    extends State<ProfessionalNotificationSettingsScreen> {
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool friendRequests = true;
  bool messages = true;
  bool notes = false;

  static const Color _primaryGreen = Color(0xFF0C3C2B);
  static const Color _backgroundGray = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    pushNotifications = widget.initialPushNotifications;
    emailNotifications = widget.initialEmailNotifications;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        friendRequests = prefs.getBool('notif_friendRequests') ?? true;
        messages = prefs.getBool('notif_messages') ?? true;
        notes = prefs.getBool('notif_notes') ?? false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_friendRequests', friendRequests);
    await prefs.setBool('notif_messages', messages);
    await prefs.setBool('notif_notes', notes);
    widget.onSettingsChanged(pushNotifications, emailNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('General', [
            _buildSwitchTile(
              'Push Notifications',
              'Receive notifications on this device',
              pushNotifications,
              (v) {
                HapticFeedback.lightImpact();
                setState(() => pushNotifications = v);
                _saveSettings();
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              'Email Notifications',
              'Receive notifications via email',
              emailNotifications,
              (v) {
                HapticFeedback.lightImpact();
                setState(() => emailNotifications = v);
                _saveSettings();
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('Activity', [
            _buildSwitchTile(
              'Friend Requests',
              'New friend requests and acceptances',
              friendRequests,
              pushNotifications
                  ? (v) {
                      HapticFeedback.lightImpact();
                      setState(() => friendRequests = v);
                      _saveSettings();
                    }
                  : null,
            ),
            _buildDivider(),
            _buildSwitchTile(
              'Messages',
              'New messages from friends',
              messages,
              pushNotifications
                  ? (v) {
                      HapticFeedback.lightImpact();
                      setState(() => messages = v);
                      _saveSettings();
                    }
                  : null,
            ),
            _buildDivider(),
            _buildSwitchTile(
              'Notes',
              'Notes shared with you',
              notes,
              pushNotifications
                  ? (v) {
                      HapticFeedback.lightImpact();
                      setState(() => notes = v);
                      _saveSettings();
                    }
                  : null,
            ),
          ]),
          if (!pushNotifications) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enable push notifications to customize activity alerts',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    final isDisabled = onChanged == null;
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: _primaryGreen,
                activeTrackColor: _primaryGreen.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
    );
  }
}
