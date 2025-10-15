import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/widgets/user_avatar_widget.dart';

class AddFriendsScreen extends StatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  List<UserModel> _mutualFriendSuggestions = [];
  bool _isSearching = false;
  bool _isLoadingSuggestions = true;
  Set<String> _sentRequestUserIds =
      {}; // Track users to whom requests have been sent
  Set<String> _currentFriendIds = {}; // Track current user's friends

  @override
  void initState() {
    super.initState();
    _loadMutualFriendSuggestions();
    _loadSentRequestsStatus();
    _loadCurrentUserFriends();
  }

  Future<void> _loadSentRequestsStatus() async {
    try {
      final currentUserId = UserService.currentUserId;
      if (currentUserId == null) return;

      // Get all outgoing friend requests
      final querySnapshot = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        _sentRequestUserIds = querySnapshot.docs
            .map((doc) => doc.data()['receiverId'] as String)
            .toSet();
      });
    } catch (e) {
      print('Error loading sent requests status: $e');
    }
  }

  Future<void> _loadCurrentUserFriends() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _currentFriendIds = currentUser.friends.toSet();
        });
      }
    } catch (e) {
      print('Error loading current user friends: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMutualFriendSuggestions() async {
    try {
      setState(() {
        _isLoadingSuggestions = true;
      });

      final suggestions = await _userService.getMutualFriendSuggestions();
      setState(() {
        _mutualFriendSuggestions = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
      });
      print('Error loading mutual friend suggestions: $e');
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _userService.searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Add Friends',
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
              colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMutualFriendSuggestions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchUsers(value);
                setState(() {}); // Rebuild to show/hide clear button
              },
              decoration: InputDecoration(
                hintText: 'Search for people...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF0C3C2B),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
          // Content
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_isLoadingSuggestions) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C3C2B)),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0C3C2B),
      onRefresh: _loadMutualFriendSuggestions,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSectionHeader('Suggested for You'),
          const SizedBox(height: 12),
          if (_mutualFriendSuggestions.isEmpty)
            _buildEmptyState(
              'No suggestions available',
              Icons.people_outline,
              'We couldn\'t find any mutual friends to suggest',
            )
          else
            ..._mutualFriendSuggestions.map(
              (user) => _buildSuggestionCard(user),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildSectionHeader('Search Results'),
        const SizedBox(height: 12),
        if (_searchResults.isEmpty)
          _buildEmptyState(
            'No users found',
            Icons.search_off,
            'Try searching with a different name or username',
          )
        else
          ..._searchResults.map((user) => _buildSuggestionCard(user)),
      ],
    );
  }

  Widget _buildSuggestionCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Picture
            Hero(
              tag: 'profile_${user.id}',
              child: UserAvatarWidget(
                user: user,
                radius: 28,
                backgroundColor: const Color(0xFF0C3C2B).withOpacity(0.1),
              ),
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
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Mutual friends indicator
                  if (!_isSearching)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C3C2B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Mutual friends',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF0C3C2B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Add Button
            _buildAddButton(user),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0C3C2B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF0C3C2B)),
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
      ),
    );
  }

  Widget _buildAddButton(UserModel user) {
    final isRequestSent = _sentRequestUserIds.contains(user.id);
    final isAlreadyFriend = _currentFriendIds.contains(user.id);

    // Determine button state
    String buttonText;
    Color buttonColor;
    Color textColor;
    VoidCallback? onTap;

    if (isAlreadyFriend) {
      buttonText = 'Friends';
      buttonColor = const Color(0xFF10B981).withOpacity(0.1);
      textColor = const Color(0xFF10B981);
      onTap = null; // Disabled
    } else if (isRequestSent) {
      buttonText = 'Sent';
      buttonColor = const Color(0xFF0C3C2B).withOpacity(0.1);
      textColor = const Color(0xFF0C3C2B);
      onTap = null; // Disabled
    } else {
      buttonText = 'Add';
      buttonColor = const Color(0xFF0C3C2B);
      textColor = Colors.white;
      onTap = () => _sendFriendRequest(user);
    }

    return Container(
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              buttonText,
              style: GoogleFonts.inter(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Action Methods
  Future<void> _sendFriendRequest(UserModel user) async {
    try {
      HapticFeedback.lightImpact();
      await _userService.sendFriendRequest(user.username);

      // Add user to sent requests set
      setState(() {
        _sentRequestUserIds.add(user.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent to ${user.displayName}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending request: $e'),
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

  // Refresh friends list (call this when returning from other screens)
  Future<void> _refreshFriendsList() async {
    await _loadCurrentUserFriends();
    await _loadSentRequestsStatus();
  }
}
