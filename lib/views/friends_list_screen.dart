// views/friends_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/views/chat_screen.dart';
import 'package:tutortyper_app/views/friend_requests_screen.dart';
import 'package:tutortyper_app/views/add_friends_screen.dart';
import 'package:tutortyper_app/widgets/user_avatar_widget.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section with Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF68EAFF),
                Color(0xFF4FD1C7),
              ],
            ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Top Bar with Title and Icons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StreamBuilder<UserModel?>(
                              stream: _userService.getCurrentUserStream(),
                              builder: (context, userSnapshot) {
                                final userName = userSnapshot.data?.displayName ?? 'User';
                                return Text(
                                  'Hi, $userName!',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            StreamBuilder<int>(
                              stream: _userService.getTotalUnreadMessageCountStream(),
                              builder: (context, snapshot) {
                                final messageCount = snapshot.data ?? 0;
                                return Text(
                                  'You Received\n$messageCount Messages',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
          // Friend Requests Button with Badge
          StreamBuilder<int>(
            stream: _userService.getPendingRequestsCountStream(),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline),
                                      color: Colors.white,
                                      iconSize: 26,
                    onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendRequestsScreen(),
              ),
            );
                    },
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
                            const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person_add),
                              color: Colors.white,
                              iconSize: 26,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFriendsScreen(),
                ),
              );
            },
          ),
        ],
      ),
                      ],
                    ),
                  ),

                  // Active People (Horizontal Scroll of Online Friends)
                  StreamBuilder<UserModel?>(
                    stream: _userService.getCurrentUserStream(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || userSnapshot.data?.friends.isEmpty == true) {
                        return const SizedBox.shrink();
                      }

                      final currentUser = userSnapshot.data!;
                      return StreamBuilder<List<UserModel>>(
                        stream: _userService.getFriendsStream(currentUser.friends),
                        builder: (context, friendsSnapshot) {
                          if (!friendsSnapshot.hasData || friendsSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // Filter to show only online friends
                          final activeFriends = friendsSnapshot.data!
                              .where((friend) => friend.isOnline)
                              .take(10)
                              .toList();

                          // Only show the section if there are active friends
                          if (activeFriends.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    Text(
                                      'Active People',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
          Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${activeFriends.length}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  itemCount: activeFriends.length,
                                  itemBuilder: (context, index) {
                                    final friend = activeFriends[index];
                                    return _buildActivePersonItem(friend);
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Extended Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF9E9E9E),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(
                          fontSize: 15,
                color: const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF9E9E9E),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Color(0xFF9E9E9E),
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Messages List
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: _userService.getCurrentUserStream(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                  if (!userSnapshot.hasData || userSnapshot.data?.friends.isEmpty == true) {
                  return _buildEmptyState();
                }

                final currentUser = userSnapshot.data!;
                return StreamBuilder<List<UserModel>>(
                  stream: _userService.getFriendsStream(currentUser.friends),
                  builder: (context, friendsSnapshot) {
                      if (friendsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                      if (!friendsSnapshot.hasData || friendsSnapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    List<UserModel> friends = friendsSnapshot.data!;

                    // Filter friends based on search
                    if (_searchController.text.isNotEmpty) {
                        friends = friends.where((friend) =>
                          friend.displayName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                          friend.username.toLowerCase().contains(_searchController.text.toLowerCase())
                        ).toList();
                      }

                      // Separate pinned and regular friends
                      final pinnedFriends = friends.where((f) => currentUser.specialFriends.contains(f.id)).toList();
                      final regularFriends = friends.where((f) => !currentUser.specialFriends.contains(f.id)).toList();

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          // Close Friends Section
                          if (pinnedFriends.isNotEmpty) ...[
                            Text(
                              'Close Friends (${pinnedFriends.length})',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...pinnedFriends.map((friend) => _buildMessageCard(friend, isPinned: true)),
                            const SizedBox(height: 24),
                          ],

                          // All Messages Section
                          Text(
                            'All Message(${regularFriends.length})',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...regularFriends.map((friend) => _buildMessageCard(friend, isPinned: false)),
                          const SizedBox(height: 80),
                        ],
                    );
                  },
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildActivePersonItem(UserModel friend) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: GestureDetector(
        onTap: () => _startChat(friend),
      child: Column(
        children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundImage: friend.photoUrl != null
                        ? CachedNetworkImageProvider(friend.photoUrl!)
                        : null,
                    backgroundColor: Colors.white,
                    child: friend.photoUrl == null
                        ? Text(
                            friend.displayName.isNotEmpty
                                ? friend.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Color(0xFF68EAFF),
              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                ),
                if (friend.isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF68EAFF), width: 2),
              ),
            ),
          ),
        ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 60,
              child: Text(
                friend.displayName.split(' ')[0],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(UserModel friend, {required bool isPinned}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
      child: InkWell(
          onTap: () => _startChat(friend),
        onLongPress: () => _showFriendOptions(friend),
          borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.all(16),
          child: Row(
            children: [
                // Avatar
              Stack(
                children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: friend.photoUrl != null
                          ? CachedNetworkImageProvider(friend.photoUrl!)
                          : null,
                      backgroundColor: const Color(0xFFF5F5F5),
                      child: friend.photoUrl == null
                          ? Text(
                              friend.displayName.isNotEmpty
                                  ? friend.displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Color(0xFF68EAFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                    if (friend.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                    decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

                // Message Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.displayName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                          if (friend.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF3B82F6),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(_generateChatId(friend.id))
                            .snapshots(),
                        builder: (context, chatSnapshot) {
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                          bool hasUnreadMessages = false;
                          
                          if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                            final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
                            final unreadCount = chatData['unreadCount'] as Map<String, dynamic>?;
                            final myUnreadCount = unreadCount?[currentUserId] as int? ?? 0;
                            hasUnreadMessages = myUnreadCount > 0;
                          }
                          
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _getLastMessageSimple(friend.id),
                            builder: (context, messageSnapshot) {
                              if (messageSnapshot.connectionState == ConnectionState.waiting) {
                          return Text(
                            'Loading...',
                            style: GoogleFonts.inter(
                                    color: const Color(0xFF9E9E9E),
                              fontSize: 14,
                            ),
                          );
                        }

                              final lastMessage = messageSnapshot.data;
                        if (lastMessage == null || lastMessage['text'].toString().isEmpty) {
                          return Text(
                                  'Start a conversation',
                            style: GoogleFonts.inter(
                                    color: const Color(0xFF9E9E9E),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }

                        final messageText = lastMessage['text'].toString();
                        final senderId = lastMessage['senderId'].toString();
                        final isFromCurrentUser = senderId == currentUserId;

                              return Text(
                                isFromCurrentUser ? 'You: $messageText' : messageText,
                                style: GoogleFonts.inter(
                                  color: hasUnreadMessages && !isFromCurrentUser 
                                      ? const Color(0xFF1E293B) 
                                      : const Color(0xFF9E9E9E),
                                  fontSize: 14,
                                  fontWeight: hasUnreadMessages && !isFromCurrentUser 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),

                const SizedBox(width: 12),

                // Time and Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      '10:50 am',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(_generateChatId(friend.id))
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }
                        
                        final chatData = snapshot.data!.data() as Map<String, dynamic>;
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                        final unreadCount = chatData['unreadCount'] as Map<String, dynamic>?;
                        final myUnreadCount = unreadCount?[currentUserId] as int? ?? 0;
                        
                        print('DEBUG: ${friend.displayName} - myUnreadCount: $myUnreadCount');
                        
                        // Show unread badge if there are unread messages
                        if (myUnreadCount > 0) {
                          return Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE91E63),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                  child: Text(
                                myUnreadCount > 9 ? '9+' : '$myUnreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                      fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        // Show read receipts for sent messages
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _getLastMessageSimple(friend.id),
                          builder: (context, messageSnapshot) {
                            final lastMessage = messageSnapshot.data;
                            if (lastMessage == null) return const SizedBox.shrink();
                            
                            final senderId = lastMessage['senderId'].toString();
                            final isRead = lastMessage['isRead'] ?? false;
                            final isFromCurrentUser = senderId == currentUserId;
                            
                            if (isFromCurrentUser) {
                              return Icon(
                                isRead ? Icons.done_all : Icons.done,
                                size: 16,
                                color: isRead ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                              );
                            }
                            
                            return const SizedBox.shrink();
                          },
                        );
                      },
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
            'No friends yet',
            style: GoogleFonts.inter(
                fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
            'Send friend requests to start connecting!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
                  ),
                ),
              ],
            ),
    );
  }


  // Keep all your existing helper methods
  void _startChat(UserModel friend) async {
    try {
      final chatId = await _userService.createOrGetPrivateChat(friend.id);
      
      // Mark messages as read when opening the chat
      await _userService.markMessagesAsRead(chatId);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatId: chatId, otherUser: friend),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to start chat: $e');
    }
  }

  void _showFriendOptions(UserModel friend) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Friend Info Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: friend.photoUrl != null
                        ? CachedNetworkImageProvider(friend.photoUrl!)
                        : null,
                    backgroundColor: const Color(0xFF68EAFF),
                    child: friend.photoUrl == null
                        ? Text(
                            friend.displayName.isNotEmpty
                                ? friend.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.displayName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '@${friend.username}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              // Options
              _buildOptionTile(
                icon: Icons.message_outlined,
                title: 'Message',
                subtitle: 'Start a conversation',
                onTap: () {
                  Navigator.pop(context);
                  _startChat(friend);
                },
                isHighlighted: true,
              ),

              _buildOptionTile(
                icon: Icons.notifications_off_outlined,
                title: 'Mute',
                subtitle: 'Stop receiving notifications',
                onTap: () {
                  Navigator.pop(context);
                  _showMuteConfirmation(friend);
                },
              ),

              _buildOptionTile(
                icon: Icons.person_remove_outlined,
                title: 'Unfriend',
                subtitle: 'Remove from friends list',
                onTap: () {
                  Navigator.pop(context);
                  _showUnfriendConfirmation(friend);
                },
                color: Colors.red[600],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? color,
    bool isHighlighted = false,
  }) {
    final optionColor = isHighlighted ? const Color(0xFF68EAFF) : (color ?? Colors.grey[700]);

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
              color: isHighlighted 
                  ? const Color(0xFF68EAFF).withOpacity(0.1)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHighlighted 
                    ? const Color(0xFF68EAFF).withOpacity(0.3)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isHighlighted 
                        ? const Color(0xFF68EAFF).withOpacity(0.2)
                        : const Color(0xFF68EAFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: optionColor,
                    size: 20,
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
                          fontWeight: FontWeight.w600,
                          color: optionColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMuteConfirmation(UserModel friend) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Mute ${friend.displayName}',
      desc: 'You will stop receiving notifications from ${friend.displayName}. You can unmute them anytime.',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        _muteFriend(friend);
      },
      btnOkText: 'Mute',
      btnCancelText: 'Cancel',
    ).show();
  }

  Future<void> _muteFriend(UserModel friend) async {
    try {
      await _userService.muteFriend(friend.id);
      if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
            content: Text('${friend.displayName} has been muted'),
            backgroundColor: const Color(0xFF68EAFF),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () async {
                await _userService.unmuteFriend(friend.id);
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to mute ${friend.displayName}: $e');
    }
  }

  void _showUnfriendConfirmation(UserModel friend) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Unfriend ${friend.displayName}',
      desc: 'Are you sure you want to remove ${friend.displayName} from your friends list?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await _userService.removeFriend(friend.id);
      },
      btnOkText: 'Unfriend',
      btnCancelText: 'Cancel',
      btnOkColor: const Color(0xFFEF4444),
    ).show();
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  String _generateChatId(String friendId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return '';
    
    final participants = [currentUserId, friendId]..sort();
    return participants.join('_');
  }

  Future<Map<String, dynamic>?> _getLastMessageSimple(String friendId) async {
    final chatId = _generateChatId(friendId);
    if (chatId.isEmpty) return null;
    
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      
      if (!chatDoc.exists) return null;
      
      final chatData = chatDoc.data()!;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final unreadCount = chatData['unreadCount'] as Map<String, dynamic>?;
      final hasUnreadMessages = unreadCount != null && 
          currentUserId != null && 
          (unreadCount[currentUserId] as int? ?? 0) > 0;
      
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (messagesSnapshot.docs.isNotEmpty) {
        final messageData = messagesSnapshot.docs.first.data();
        final senderId = messageData['senderId'] ?? '';
        final isFromCurrentUser = senderId == currentUserId;
        
        return {
          'text': messageData['text'] ?? '',
          'senderId': senderId,
          'timestamp': messageData['timestamp'],
          'isRead': messageData['isRead'] ?? false,
          'hasUnreadMessages': hasUnreadMessages && !isFromCurrentUser,
          'unreadCount': hasUnreadMessages ? (unreadCount![currentUserId!] as int? ?? 0) : 0,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}