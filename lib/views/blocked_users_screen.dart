import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/widgets/user_avatar_widget.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen>
    with TickerProviderStateMixin {
  final UserService _userService = UserService();
  List<UserModel> _blockedUsers = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadBlockedUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final blockedUsers = await _userService.getBlockedUsers();

      setState(() {
        _blockedUsers = blockedUsers;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to load blocked users', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFFF3B30) : Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 22,
            ),
          ),
        ),
        title: Text(
          'Blocked Users',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_blockedUsers.isNotEmpty)
            GestureDetector(
              onTap: _showUnblockAllDialog,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Unblock All',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF3B30),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white : const Color(0xFF0C3C2B),
                ),
              ),
            )
          : _blockedUsers.isEmpty
          ? _buildEmptyState(isDark)
          : _buildBlockedUsersList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade900
                    : const Color(0xFF0C3C2B).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block_outlined,
                size: 48,
                color: isDark ? Colors.grey.shade700 : const Color(0xFF0C3C2B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Blocked Users',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Users you block will appear here.\nYou can unblock them anytime.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedUsersList(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        color: isDark ? Colors.white : const Color(0xFF0C3C2B),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        onRefresh: _loadBlockedUsers,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _blockedUsers.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 0.5,
            indent: 88,
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          ),
          itemBuilder: (context, index) {
            final user = _blockedUsers[index];
            return _buildBlockedUserCard(user, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildBlockedUserCard(UserModel user, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF000000) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Profile Picture
          UserAvatarWidget(
            user: user,
            radius: 28,
            backgroundColor: isDark
                ? Colors.grey.shade900
                : const Color(0xFF0C3C2B).withOpacity(0.1),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '@${user.username}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Blocked',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFFF3B30),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Unblock Button
          GestureDetector(
            onTap: () => _showUnblockDialog(user, isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0C3C2B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Unblock',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnblockDialog(UserModel user, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Unblock User?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        content: Text(
          'Are you sure you want to unblock ${user.displayName}? They will be able to send you friend requests again.',
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.2,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _unblockUser(user, isDark),
            child: Text(
              'Unblock',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: const Color(0xFF0C3C2B),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnblockAllDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Unblock All Users?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        content: Text(
          'Are you sure you want to unblock all ${_blockedUsers.length} users? They will be able to send you friend requests and messages again.',
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.2,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _unblockAllUsers(isDark),
            child: Text(
              'Unblock All',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: const Color(0xFFFF3B30),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(UserModel user, bool isDark) async {
    try {
      Navigator.pop(context); // Close dialog

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white : const Color(0xFF0C3C2B),
              ),
            ),
          ),
        ),
      );

      await _userService.unblockUser(user.id);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Remove from local list
      setState(() {
        _blockedUsers.removeWhere((u) => u.id == user.id);
      });

      // Show success message
      _showSnackBar('${user.displayName} has been unblocked');
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _showSnackBar('Failed to unblock user', isError: true);
    }
  }

  Future<void> _unblockAllUsers(bool isDark) async {
    try {
      Navigator.pop(context); // Close dialog

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white : const Color(0xFF0C3C2B),
              ),
            ),
          ),
        ),
      );

      for (final user in _blockedUsers) {
        await _userService.unblockUser(user.id);
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Clear local list
      setState(() {
        _blockedUsers.clear();
      });

      // Show success message
      _showSnackBar('All users have been unblocked');
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _showSnackBar('Failed to unblock users', isError: true);
    }
  }
}
