// views/settings_screen.dart - Modern Production-Level Design
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

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isDarkMode = false;
  bool showOnlineStatus = true;
  bool showBirthDate = false;
  bool pushNotifications = true;
  bool emailNotifications = false;
  UserModel? currentUser;
  bool isLoading = false;

  static const Color _primaryGreen = Color(0xFF0C3C2B);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern AppBar with Profile
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primaryGreen,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryGreen, const Color(0xFF1A5C42)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),

          // Settings Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Account Section
                  _buildModernSection(
                    title: 'Account',
                    children: [
                      _buildModernTile(
                        icon: Icons.person_outline,
                        title: 'Display Name',
                        subtitle: currentUser?.displayName ?? 'Not set',
                        onTap: () => _showEditDialog(
                          'Display Name',
                          currentUser?.displayName ?? '',
                          _updateDisplayName,
                        ),
                      ),
                      _buildModernTile(
                        icon: Icons.alternate_email,
                        title: 'Username',
                        subtitle: '@${currentUser?.username ?? 'Not set'}',
                        onTap: () => _showEditDialog(
                          'Username',
                          currentUser?.username ?? '',
                          _updateUsername,
                        ),
                      ),
                      _buildModernTile(
                        icon: Icons.info_outline,
                        title: 'Bio',
                        subtitle: () {
                          final bio = currentUser?.bio;
                          if (bio != null && bio.isNotEmpty) {
                            return bio.length > 30
                                ? '${bio.substring(0, 30)}...'
                                : bio;
                          }
                          return 'Tell us about yourself';
                        }(),
                        onTap: _showBioEditDialog,
                      ),
                      _buildModernTile(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        subtitle: _auth.currentUser?.email ?? 'Not set',
                        onTap: _showChangeEmailDialog,
                      ),
                      _buildModernTile(
                        icon: Icons.lock_outline,
                        title: 'Password',
                        subtitle: 'Change your password',
                        onTap: _showChangePasswordDialog,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Preferences Section
                  _buildModernSection(
                    title: 'Preferences',
                    children: [
                      _buildModernSwitchTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        subtitle: 'Adjust the appearance',
                        value: isDarkMode,
                        onChanged: _updateDarkMode,
                      ),
                      _buildModernTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Manage your notifications',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pushNotifications
                                ? _primaryGreen.withOpacity(0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pushNotifications ? 'On' : 'Off',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pushNotifications
                                  ? _primaryGreen
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        onTap: _showNotificationSettings,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Privacy Section
                  _buildModernSection(
                    title: 'Privacy & Security',
                    children: [
                      _buildModernSwitchTile(
                        icon: Icons.visibility_outlined,
                        title: 'Show Online Status',
                        subtitle: 'Let others see when you\'re active',
                        value: showOnlineStatus,
                        onChanged: _updateShowOnlineStatus,
                      ),
                      _buildModernTile(
                        icon: Icons.block,
                        title: 'Blocked Users',
                        subtitle: 'Manage blocked accounts',
                        onTap: _showBlockedUsers,
                      ),
                      _buildModernTile(
                        icon: Icons.security,
                        title: 'Two-Factor Authentication',
                        subtitle: 'Add an extra layer of security',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text(
                            'Soon',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                        onTap: _setup2FA,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Support Section
                  _buildModernSection(
                    title: 'Support',
                    children: [
                      _buildModernTile(
                        icon: Icons.bug_report_outlined,
                        title: 'Report a Bug',
                        subtitle: 'Help us improve',
                        onTap: _reportBug,
                      ),
                      _buildModernTile(
                        icon: Icons.lightbulb_outline,
                        title: 'Send Feedback',
                        subtitle: 'Share your ideas',
                        onTap: _sendSuggestion,
                      ),
                      _buildModernTile(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                        subtitle: 'Get support',
                        onTap: _openHelpCenter,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // About Section
                  _buildModernSection(
                    title: 'About',
                    children: [
                      _buildModernTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        onTap: _openPrivacyPolicy,
                      ),
                      _buildModernTile(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        subtitle: 'Our terms and conditions',
                        onTap: _openTermsOfService,
                      ),
                      _buildModernTile(
                        icon: Icons.info_outline,
                        title: 'App Version',
                        subtitle: '1.0.0',
                        hideArrow: true,
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  _buildLogoutButton(),

                  const SizedBox(height: 16),

                  // Delete Account
                  _buildDeleteAccountButton(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: _showProfilePictureView,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(child: _buildProfileAvatar(40)),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.camera_alt, color: _primaryGreen, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentUser?.displayName ?? 'User',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${currentUser?.username ?? 'username'}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(double radius) {
    // Check if user has a custom photo
    if (currentUser?.photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: currentUser!.photoUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.person, size: radius, color: Colors.grey.shade400),
        ),
      );
    }

    // Check if user has a predefined avatar
    if (currentUser?.predefinedAvatar != null &&
        AvatarManager.isPredefinedAvatar(currentUser!.predefinedAvatar)) {
      return Image.asset(
        currentUser!.predefinedAvatar!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
      );
    }

    // Default to gender-based avatar
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

    // Final fallback
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: radius, color: Colors.grey.shade400),
    );
  }

  Widget _buildModernSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildModernTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool hideArrow = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryGreen, size: 20),
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
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (!hideArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primaryGreen, size: 20),
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
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
          Transform.scale(
            scale: 0.85,
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

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showDeleteAccountDialog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_forever,
                  color: Colors.red.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Delete Account',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... [Previous methods remain the same: _showProfilePictureView, _updateShowOnlineStatus, etc.]
  // ... [I'll continue with the rest of the implementation in the next part]

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Online status ${value ? 'visible' : 'hidden'}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => showOnlineStatus = !value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateDarkMode(bool value) async {
    setState(() => isDarkMode = value);
    await _saveSettings();
    widget.onThemeChanged?.call(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${value ? 'Dark' : 'Light'} mode enabled',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
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
      if (mounted) _showError('Failed to update: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    final normalized = newUsername.toLowerCase().trim();

    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(normalized)) {
      _showError('Username: 3-30 characters (letters, numbers, _ only)');
      return;
    }

    setState(() => isLoading = true);

    try {
      await _userService.updateUserProfile(username: normalized);
      await _loadUserData();
      if (mounted) _showSuccess('Username updated');
    } catch (e) {
      if (mounted) _showError('Failed: $e');
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
      if (mounted) _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Edit $field',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: field == 'Username' ? 30 : 50,
                decoration: InputDecoration(
                  labelText: field,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter()),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(color: Colors.white),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Edit Bio',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell others about yourself...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter()),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(color: Colors.white),
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

  void _showChangeEmailDialog() {
    _showError('Email change coming soon');
  }

  void _showChangePasswordDialog() {
    _showError('Password change coming soon');
  }

  void _showNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernNotificationSettingsScreen(
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

  void _setup2FA() {
    _showError('Two-Factor Authentication coming soon');
  }

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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Report a Bug',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the bug...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      _showSuccess('Bug report sent. Thank you!');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Send Report',
                    style: GoogleFonts.inter(color: Colors.white),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Send Feedback',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your ideas...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      _showSuccess('Feedback sent. Thank you!');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Send Feedback',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHelpCenter() => _showError('Help Center coming soon');
  void _openPrivacyPolicy() => _showError('Privacy Policy coming soon');
  void _openTermsOfService() => _showError('Terms of Service coming soon');

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Text(
              'Delete Account?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'This action is permanent. All your data will be lost forever.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.red.shade600),
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
        title: Text(
          'Type "DELETE" to confirm',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Type DELETE',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == 'DELETE') {
                Navigator.pop(context);
                _showError('Account deletion coming soon');
              } else {
                _showError('Please type "DELETE" to confirm');
              }
            },
            child: Text(
              'Delete Forever',
              style: GoogleFonts.inter(color: Colors.red.shade600),
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
        title: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            child: Text(
              'Logout',
              style: GoogleFonts.inter(color: _primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Notification Settings Screen
class ModernNotificationSettingsScreen extends StatefulWidget {
  final bool initialPushNotifications;
  final bool initialEmailNotifications;
  final Function(bool push, bool email) onSettingsChanged;

  const ModernNotificationSettingsScreen({
    super.key,
    required this.initialPushNotifications,
    required this.initialEmailNotifications,
    required this.onSettingsChanged,
  });

  @override
  State<ModernNotificationSettingsScreen> createState() =>
      _ModernNotificationSettingsScreenState();
}

class _ModernNotificationSettingsScreenState
    extends State<ModernNotificationSettingsScreen> {
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool friendRequests = true;
  bool messages = true;
  bool notes = false;

  static const Color _primaryGreen = Color(0xFF0C3C2B);

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('General', [
            _buildSwitchTile(
              'Push Notifications',
              'Receive notifications on device',
              pushNotifications,
              (v) {
                setState(() => pushNotifications = v);
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              'Email Notifications',
              'Receive notifications via email',
              emailNotifications,
              (v) {
                setState(() => emailNotifications = v);
                _saveSettings();
              },
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Activity', [
            _buildSwitchTile(
              'Friend Requests',
              'New requests and acceptances',
              friendRequests,
              pushNotifications
                  ? (v) {
                      setState(() => friendRequests = v);
                      _saveSettings();
                    }
                  : null,
            ),
            _buildSwitchTile(
              'Messages',
              'New messages from friends',
              messages,
              pushNotifications
                  ? (v) {
                      setState(() => messages = v);
                      _saveSettings();
                    }
                  : null,
            ),
            _buildSwitchTile(
              'Notes',
              'Notes shared with you',
              notes,
              pushNotifications
                  ? (v) {
                      setState(() => notes = v);
                      _saveSettings();
                    }
                  : null,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _primaryGreen,
          ),
        ],
      ),
    );
  }
}
