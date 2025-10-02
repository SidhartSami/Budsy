// views/settings_screen.dart - Fixed Version
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/views/blocked_users_screen.dart';
import 'package:tutortyper_app/views/profile_picture_screen.dart';
import 'package:tutortyper_app/widgets/avatar_selection_widget.dart';
import 'dart:io';

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
  final ImagePicker _picker = ImagePicker();

  bool isDarkMode = false;
  bool activityStatus = true;
  bool showOnlineStatus = true;
  bool showBirthDate = false;
  bool pushNotifications = true;
  bool emailNotifications = false;
  UserModel? currentUser;
  bool isLoading = false;
  bool isUploadingImage = false;

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
          activityStatus = user.isOnline;
          showOnlineStatus = user.showOnlineStatus; // Load actual value from user data
          showBirthDate = user.showBirthDate; // Load actual value from user data
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF68EAFF),
                Color(0xFF4FD1C7),
              ],
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(value: 'logout', child: Text('Logout')),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            _buildUserProfileCard(user),

            const SizedBox(height: 24),

            // Account Section
            _buildSectionHeader('Account'),
            _buildSettingsTile(
              Icons.person_outline_rounded,
              'Display Name',
              currentUser?.displayName ?? 'Not set',
              () => _showEditDialog(
                'Display Name',
                currentUser?.displayName ?? '',
                _updateDisplayName,
              ),
            ),
            _buildSettingsTile(
              Icons.alternate_email_rounded,
              'Username',
              '@${currentUser?.username ?? 'Not set'}',
              () => _showEditDialog(
                'Username',
                currentUser?.username ?? '',
                _updateUsername,
              ),
            ),
            _buildSettingsTile(Icons.info_outline_rounded, 'Bio', () {
              final bio = currentUser?.bio;
              if (bio != null && bio.isNotEmpty) {
                return bio.length > 30 ? '${bio.substring(0, 30)}...' : bio;
              }
              return 'Not set';
            }(), () => _showBioEditDialog()),
            _buildSettingsTile(
              Icons.email_outlined,
              'Email',
              user?.email ?? 'Not set',
              () => _showChangeEmailDialog(),
            ),
            _buildSettingsTile(
              Icons.lock_outline_rounded,
              'Password',
              'Change password',
              () => _showChangePasswordDialog(),
            ),

            const SizedBox(height: 24),

            // App Preferences Section
            _buildSectionHeader('App Preferences'),
            _buildSwitchTile(
              Icons.dark_mode_outlined,
              'Dark Mode',
              'Toggle dark/light theme',
              isDarkMode,
              (value) => _updateDarkMode(value),
            ),
            _buildSettingsTile(
              Icons.notifications_outlined,
              'Notifications',
              'Manage notification settings',
              () => _showNotificationSettings(),
            ),

            const SizedBox(height: 24),

            // Privacy Control Section
            _buildSectionHeader('Privacy Control'),
            _buildSwitchTile(
              Icons.visibility_outlined,
              'Show Online Status',
              'Let friends see when you\'re online',
              showOnlineStatus,
              (value) => _updateShowOnlineStatus(value),
            ),
            _buildSettingsTile(
              Icons.block_rounded,
              'Blocked Users',
              'Manage blocked contacts',
              () => _showBlockedUsers(),
            ),
            _buildSettingsTile(
              Icons.security_rounded,
              'Two-Factor Authentication',
              'Add extra security to your account',
              () => _setup2FA(),
            ),

            const SizedBox(height: 24),

            // Support & Feedback Section
            _buildSectionHeader('Support & Feedback'),
            _buildSettingsTile(
              Icons.bug_report_outlined,
              'Report a Bug',
              'Help us improve the app',
              () => _reportBug(),
            ),
            _buildSettingsTile(
              Icons.lightbulb_outline_rounded,
              'Suggestions',
              'Share your ideas with us',
              () => _sendSuggestion(),
            ),
            _buildSettingsTile(
              Icons.help_center_outlined,
              'Help Center',
              'Get help and find answers',
              () => _openHelpCenter(),
            ),
            _buildSettingsTile(
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              'Read our privacy policy',
              () => _openPrivacyPolicy(),
            ),
            _buildSettingsTile(
              Icons.description_outlined,
              'Terms of Service',
              'View terms and conditions',
              () => _openTermsOfService(),
            ),

            const SizedBox(height: 24),

            // Danger Zone Section
            _buildSectionHeader('Danger Zone', color: Colors.red),
            _buildSettingsTile(
              Icons.delete_forever_outlined,
              'Delete Account',
              'Permanently delete your account',
              () => _showDeleteAccountDialog(),
              color: Colors.red,
            ),

            const SizedBox(height: 20),

            // Logout Button
            Card(
              color: Colors.red[50],
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Sign out of your account',
                  style: GoogleFonts.inter(
                    color: Colors.red.withOpacity(0.7),
                  ),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Hero(
      tag: 'profile_picture',
      child: _buildAvatarContent(50),
    );
  }

  Widget _buildFullScreenAvatar() {
    return _buildAvatarContent(150);
  }

  Widget _buildAvatarContent(double radius) {
    // Check if user has a custom photo
    if (currentUser?.photoUrl != null) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(currentUser!.photoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    
    // Check if user has a predefined avatar
    if (currentUser?.predefinedAvatar != null && 
        AvatarManager.isPredefinedAvatar(currentUser!.predefinedAvatar)) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage(currentUser!.predefinedAvatar!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    
    // Default to gender-based avatar or icon
    if (currentUser?.gender != null) {
      final defaultAvatar = AvatarManager.getDefaultAvatarForGender(currentUser!.gender);
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage(defaultAvatar),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    
    // Final fallback to icon
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color.fromARGB(255, 104, 234, 243),
      child: Icon(Icons.person, size: radius, color: Colors.white),
    );
  }

  Widget _buildUserProfileCard(User? user) {
    return Center(
      child: GestureDetector(
        onTap: () => _showProfilePictureView(),
        child: Stack(
          children: [
            _buildProfileAvatar(),
            if (isUploadingImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: color ?? const Color.fromARGB(255, 104, 234, 243),
        ),
        title: Text(
          title,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: color),
        ),
        subtitle: Text(subtitle, style: GoogleFonts.nunito(fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color.fromARGB(255, 104, 234, 243)),
        title: Text(
          title,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: GoogleFonts.nunito(fontSize: 14)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color.fromARGB(255, 104, 234, 243),
        ),
      ),
    );
  }

  // Profile Picture Management
  void _showProfilePictureView() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full screen background - tap to close
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            // Centered profile image
            Center(
              child: Hero(
                tag: 'profile_picture',
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping on image
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.8,
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                      maxHeight: 300,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildFullScreenAvatar(),
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Edit button
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _openEditProfile();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 104, 234, 243),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Profile Picture',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditProfile() {
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePictureScreen(currentUser: currentUser!),
        ),
      ).then((_) {
        // Refresh user data when returning from edit profile
        _loadUserData();
      });
    }
  }






  // Privacy Settings
  Future<void> _updateShowOnlineStatus(bool value) async {
    setState(() {
      showOnlineStatus = value;
      isLoading = true;
    });

    try {
      // Update the user's showOnlineStatus in Firestore
      await _userService.updateUserProfile(showOnlineStatus: value);
      
      // If turning off online status, also set isOnline to false
      if (!value) {
        await _userService.updateOnlineStatus(false);
      } else {
        // If turning on, set to online
        await _userService.updateOnlineStatus(true);
      }

      await _saveSettings();
      await _loadUserData(); // Refresh user data

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Online status visibility ${value ? 'enabled' : 'disabled'}',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      // Revert the state if update failed
      setState(() {
        showOnlineStatus = !value;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update online status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateDarkMode(bool value) async {
    setState(() {
      isDarkMode = value;
    });

    await _saveSettings();
    widget.onThemeChanged?.call(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme updated to ${value ? 'dark' : 'light'} mode'),
        ),
      );
    }
  }


  Future<void> _updateDisplayName(String newDisplayName) async {
    if (newDisplayName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _userService.updateUserProfile(displayName: newDisplayName.trim());
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Display name updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update display name: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    final normalizedUsername = newUsername.toLowerCase().trim();

    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(normalizedUsername)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Username must be 3-30 characters (letters, numbers, underscore only)',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _userService.updateUserProfile(username: normalizedUsername);
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update username: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _sendEmailVerification() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _auth.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send verification email')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showEditDialog(
    String field,
    String currentValue,
    Function(String) onSave,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit $field',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field,
            border: const OutlineInputBorder(),
          ),
          maxLength: field == 'Username' ? 30 : 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSave(controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBioEditDialog() {
    final TextEditingController controller = TextEditingController(
      text: currentUser?.bio ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Bio',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 150,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Tell others about yourself...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateBio(controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBio(String newBio) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _userService.updateUserProfile(bio: newBio.trim());
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bio updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update bio: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showChangeEmailDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Email',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changeEmail(emailController.text, passwordController.text);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeEmail(String newEmail, String password) async {
    if (newEmail.trim().isEmpty || password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification email sent to new address. Please verify to complete the change.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change email';
      if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email is already in use';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changePassword(
                currentPasswordController.text,
                newPasswordController.text,
                confirmPasswordController.text,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (currentPassword.trim().isEmpty ||
        newPassword.trim().isEmpty ||
        confirmPassword.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change password';
      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        message = 'New password is too weak';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  void _showNotificationSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationSettingsScreen(
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
      MaterialPageRoute(
        builder: (context) => const BlockedUsersScreen(),
      ),
    );
  }

  void _setup2FA() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Two-Factor Authentication setup coming soon'),
      ),
    );
  }

  void _reportBug() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Report a Bug',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the bug you encountered...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bug report sent. Thank you!')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _sendSuggestion() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send Suggestion',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Share your suggestions to improve the app...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Suggestion sent. Thank you!')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _openHelpCenter() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening Help Center...')));
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening Privacy Policy...')));
  }

  void _openTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Terms of Service...')),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your data, notes, and connections will be lost forever.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDeleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Final Confirmation',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Type "DELETE" to confirm account deletion:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type DELETE here',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == 'DELETE') {
                Navigator.of(context).pop();
                _deleteAccount();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type "DELETE" exactly to confirm'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE ACCOUNT'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // Delete Firebase Auth account
        await user.delete();

        // Clear local settings
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
          widget.onLogout();
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to delete account';
      if (e.code == 'requires-recent-login') {
        message = 'Please log out and log back in before deleting your account';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete account')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onLogout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Enhanced Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  final bool initialPushNotifications;
  final bool initialEmailNotifications;
  final Function(bool push, bool email) onSettingsChanged;

  const NotificationSettingsScreen({
    super.key,
    required this.initialPushNotifications,
    required this.initialEmailNotifications,
    required this.onSettingsChanged,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool friendRequests = true;
  bool messages = true;
  bool notes = false;
  bool appUpdates = true;
  bool marketingEmails = false;

  @override
  void initState() {
    super.initState();
    pushNotifications = widget.initialPushNotifications;
    emailNotifications = widget.initialEmailNotifications;
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        friendRequests = prefs.getBool('notif_friendRequests') ?? true;
        messages = prefs.getBool('notif_messages') ?? true;
        notes = prefs.getBool('notif_notes') ?? false;
        appUpdates = prefs.getBool('notif_appUpdates') ?? true;
        marketingEmails = prefs.getBool('notif_marketingEmails') ?? false;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_friendRequests', friendRequests);
    await prefs.setBool('notif_messages', messages);
    await prefs.setBool('notif_notes', notes);
    await prefs.setBool('notif_appUpdates', appUpdates);
    await prefs.setBool('notif_marketingEmails', marketingEmails);

    widget.onSettingsChanged(pushNotifications, emailNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GENERAL',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on your device'),
              value: pushNotifications,
              onChanged: (value) {
                setState(() => pushNotifications = value);
                _saveNotificationSettings();
              },
              activeColor: const Color(0xFF68EAFF),
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: emailNotifications,
              onChanged: (value) {
                setState(() => emailNotifications = value);
                _saveNotificationSettings();
              },
              activeColor: const Color(0xFF68EAFF),
            ),

            const SizedBox(height: 24),

            Text(
              'ACTIVITY',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Friend Requests'),
              subtitle: const Text('New friend requests and acceptances'),
              value: friendRequests,
              onChanged: pushNotifications
                  ? (value) {
                      setState(() => friendRequests = value);
                      _saveNotificationSettings();
                    }
                  : null,
              activeColor: const Color(0xFF68EAFF),
            ),
            SwitchListTile(
              title: const Text('Messages'),
              subtitle: const Text('New messages from friends'),
              value: messages,
              onChanged: pushNotifications
                  ? (value) {
                      setState(() => messages = value);
                      _saveNotificationSettings();
                    }
                  : null,
              activeColor: const Color(0xFF68EAFF),
            ),
            SwitchListTile(
              title: const Text('Notes'),
              subtitle: const Text('Notes shared with you'),
              value: notes,
              onChanged: pushNotifications
                  ? (value) {
                      setState(() => notes = value);
                      _saveNotificationSettings();
                    }
                  : null,
              activeColor: const Color(0xFF68EAFF),
            ),

            const SizedBox(height: 24),

            Text(
              'APP UPDATES',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('App Updates'),
              subtitle: const Text('New features and improvements'),
              value: appUpdates,
              onChanged: (value) {
                setState(() => appUpdates = value);
                _saveNotificationSettings();
              },
              activeColor: const Color(0xFF68EAFF),
            ),
            SwitchListTile(
              title: const Text('Marketing Emails'),
              subtitle: const Text('Tips, offers, and product news'),
              value: marketingEmails,
              onChanged: emailNotifications
                  ? (value) {
                      setState(() => marketingEmails = value);
                      _saveNotificationSettings();
                    }
                  : null,
              activeColor: const Color(0xFF68EAFF),
            ),

            const Spacer(),

            if (!pushNotifications)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Push notifications are disabled. Enable them to receive activity notifications.',
                        style: GoogleFonts.nunito(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
