import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/friend_request_model.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/widgets/user_avatar_widget.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Find Friends',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
                Color(0xFF0C3C2B), // Changed from Color(0xFF68EAFF)
                Color(0xFF1A5C42), // Changed from Color(0xFF4FD1C7)
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildIncomingRequests(), _buildOutgoingRequests()],
      ),
    );
  }

  Widget _buildIncomingRequests() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _userService.getIncomingFriendRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF0C3C2B),
              ), // Changed
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading requests: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No friend requests',
            Icons.inbox_outlined,
            'When someone sends you a friend request, it will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final request = snapshot.data![index];
            return _buildIncomingRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildIncomingRequestCard(Map<String, dynamic> request) {
    final fromUserData = request['fromUser'];
    if (fromUserData == null) {
      return const SizedBox.shrink(); // Skip this request if user data is null
    }

    final user = UserModel.fromMap(fromUserData);
    final requestId = request['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200, // Add border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // Changed from 0.05
            blurRadius: 4, // Changed from 10
            offset: const Offset(0, 1), // Changed from Offset(0, 2)
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Picture
            UserAvatarWidget(
              user: user,
              radius: 28,
              backgroundColor: const Color(
                0xFF0C3C2B,
              ).withOpacity(0.1), // Changed
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
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wants to be your friend',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Row(
              children: [
                // Accept Button - keep green
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(10), // Changed from 8
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _acceptFriendRequest(requestId),
                      child: const Padding(
                        padding: EdgeInsets.all(10), // Changed from symmetric
                        child: Icon(
                          Icons.check_rounded, // Changed to rounded
                          color: Colors.white,
                          size: 20, // Changed from 18
                        ),
                      ),
                    ),
                  ),
                ),

                // Decline Button - keep red but adjust
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10), // Changed from 8
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _declineFriendRequest(requestId),
                      child: const Padding(
                        padding: EdgeInsets.all(10), // Changed from symmetric
                        child: Icon(
                          Icons.close_rounded, // Changed to rounded
                          color: Colors.white,
                          size: 20, // Changed from 18
                        ),
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

  Widget _buildOutgoingRequests() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _userService.getOutgoingFriendRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF0C3C2B),
              ), // Changed
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading requests: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No sent requests',
            Icons.send_outlined,
            'Friend requests you send will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final request = snapshot.data![index];
            return _buildOutgoingRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildOutgoingRequestCard(Map<String, dynamic> request) {
    final toUserData = request['toUser'];
    if (toUserData == null) {
      return const SizedBox.shrink(); // Skip this request if user data is null
    }

    final user = UserModel.fromMap(toUserData);
    final requestId = request['id'] as String;

    // In both _buildIncomingRequestCard and _buildOutgoingRequestCard
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200, // Add border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // Changed from 0.05
            blurRadius: 4, // Changed from 10
            offset: const Offset(0, 1), // Changed from Offset(0, 2)
          ),
        ],
      ),

      // ... rest of code
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Picture
            UserAvatarWidget(
              user: user,
              radius: 28,
              backgroundColor: const Color(0xFF68EAFF).withOpacity(0.1),
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
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Request sent',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(
                        0xFF0C3C2B,
                      ), // Changed from Color(0xFF10B981)
                      fontWeight: FontWeight.w600, // Changed from w500
                    ),
                  ),
                ],
              ),
            ),
            // Cancel Button
            Container(
              decoration: BoxDecoration(
                color: const Color(
                  0xFF0C3C2B,
                ).withOpacity(0.1), // Changed color
                borderRadius: BorderRadius.circular(10), // Changed from 8
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _cancelFriendRequest(requestId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0C3C2B), // Changed from white
                        fontWeight: FontWeight.w600,
                        fontSize: 13, // Changed from 12
                      ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, IconData icon, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0C3C2B).withOpacity(0.1), // Changed
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icon,
              size: 48,
              color: const Color(0xFF0C3C2B), // Changed
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C3C2B), // Changed
              foregroundColor: Colors.white,
              elevation: 0, // Add this
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Changed from 8
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ), // Add this
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14, // Add this
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods

  Future<void> _acceptFriendRequest(String requestId) async {
    try {
      HapticFeedback.lightImpact();
      // Get the sender ID from the request
      final requestDoc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();
      if (requestDoc.exists) {
        final senderId = requestDoc.data()?['senderId'] as String?;
        if (senderId != null) {
          await _userService.acceptFriendRequest(requestId, senderId);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request accepted'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting request: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _declineFriendRequest(String requestId) async {
    try {
      HapticFeedback.lightImpact();
      await _userService.declineFriendRequest(requestId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request declined'),
          backgroundColor: Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error declining request: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _cancelFriendRequest(String requestId) async {
    try {
      HapticFeedback.lightImpact();
      await _userService.cancelFriendRequest(requestId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request cancelled'),
          backgroundColor: Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling request: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
