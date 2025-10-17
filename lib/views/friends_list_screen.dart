import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:tutortyper_app/services/birthday_service.dart';
import 'package:tutortyper_app/services/chat_settings_service.dart';
import 'package:tutortyper_app/services/streak_service.dart';
import 'package:tutortyper_app/models/streak_model.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final BirthdayService _birthdayService = BirthdayService();
  final ChatSettingsService _chatSettingsService = ChatSettingsService();
  List<UserModel> _friendsWithBirthdaysToday = [];
  Map<String, String> _friendNicknames = {};
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFriendsWithBirthdaysToday();
    _loadFriendNicknames();
  }

  String _generateChatId(String friendId) {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) return '';

    final participants = [currentUserId, friendId]..sort();
    return participants.join('_');
  }

  Future<void> _loadFriendNicknames() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) return;

      final nicknames = <String, String>{};

      for (final friendId in currentUser.friends) {
        final chatId = _generateChatId(friendId);
        final chatSettings = await _chatSettingsService.getChatSettings(chatId);
        if (chatSettings?.nickname != null &&
            chatSettings!.nickname!.isNotEmpty) {
          nicknames[friendId] = chatSettings.nickname!;
        }
      }

      if (mounted) {
        setState(() {
          _friendNicknames = nicknames;
        });
      }
    } catch (e) {
      print('Error loading friend nicknames: $e');
    }
  }

  String _getFriendDisplayName(UserModel friend) {
    return _friendNicknames[friend.id] ?? friend.displayName;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendsWithBirthdaysToday() async {
    try {
      final friends = await _birthdayService.getFriendsWithBirthdaysToday();
      setState(() {
        _friendsWithBirthdaysToday = friends;
      });
    } catch (e) {
      print('Error loading friends with birthdays today: $e');
    }
  }

  bool _isFriendBirthdayToday(String friendId) {
    return _friendsWithBirthdaysToday.any((friend) => friend.id == friendId);
  }

  Map<String, dynamic> _getPlantStage(int streakCount, bool isEndingSoon) {
    if (isEndingSoon) {
      return {'emoji': '🥀', 'name': 'Wilting', 'color': Color(0xFFEF4444)};
    } else if (streakCount >= 100) {
      return {'emoji': '🌺', 'name': 'Blooming', 'color': Color(0xFF9333EA)};
    } else if (streakCount >= 50) {
      return {'emoji': '🌸', 'name': 'Flowering', 'color': Color(0xFFDB2777)};
    } else if (streakCount >= 30) {
      return {'emoji': '🌹', 'name': 'Rose', 'color': Color(0xFFDC2626)};
    } else if (streakCount >= 14) {
      return {'emoji': '🌻', 'name': 'Sunflower', 'color': Color(0xFFEA580C)};
    } else if (streakCount >= 7) {
      return {'emoji': '🌿', 'name': 'Growing', 'color': Color(0xFF16A34A)};
    } else if (streakCount >= 3) {
      return {'emoji': '🌱', 'name': 'Sprouting', 'color': Color(0xFF15803D)};
    } else {
      return {'emoji': '🌰', 'name': 'Seed', 'color': Color(0xFF92400E)};
    }
  }

  Widget _buildPlantStreakBadge(String friendId) {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<Map<String, dynamic>>(
      stream: StreakService().getStreakDisplayInfoStream(
        currentUserId,
        friendId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        try {
          final streakInfo = snapshot.data!;
          final hasStreak = streakInfo['hasStreak'] as bool? ?? false;
          if (!hasStreak) return const SizedBox.shrink();

          final streakCount = streakInfo['streakCount'] as int? ?? 0;
          final isEndingSoon = streakInfo['isEndingSoon'] as bool? ?? false;

          if (streakCount == 0) return const SizedBox.shrink();

          final plantStage = _getPlantStage(streakCount, isEndingSoon);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: (plantStage['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(plantStage['emoji'], style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                Text(
                  '$streakCount',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: plantStage['color'],
                  ),
                ),
              ],
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildCompactPlantBadge(String friendId) {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<Map<String, dynamic>>(
      stream: StreakService().getStreakDisplayInfoStream(
        currentUserId,
        friendId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        try {
          final streakInfo = snapshot.data!;
          final hasStreak = streakInfo['hasStreak'] as bool? ?? false;
          final streakCount = streakInfo['streakCount'] as int? ?? 0;
          final isEndingSoon = streakInfo['isEndingSoon'] as bool? ?? false;

          if (!hasStreak || streakCount == 0) {
            return const SizedBox.shrink();
          }

          final plantStage = _getPlantStage(streakCount, isEndingSoon);

          return Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: (plantStage['color'] as Color),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                plantStage['emoji'],
                style: const TextStyle(fontSize: 10),
              ),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Messages',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              actions: [
                StreamBuilder<int>(
                  stream: _userService.getPendingRequestsCountStream(),
                  builder: (context, snapshot) {
                    final pendingCount = snapshot.data ?? 0;
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_add_outlined),
                          color: const Color(0xFF0F172A),
                          iconSize: 26,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FriendRequestsScreen(),
                              ),
                            );
                          },
                        ),
                        if (pendingCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                pendingCount > 9 ? '9+' : '$pendingCount',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.group_add_outlined),
                  color: const Color(0xFF0F172A),
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
                const SizedBox(width: 8),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            // Active People Section
            StreamBuilder<UserModel?>(
              stream: _userService.getCurrentUserStream(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData ||
                    userSnapshot.data?.friends.isEmpty == true) {
                  return const SizedBox.shrink();
                }

                final currentUser = userSnapshot.data!;
                return StreamBuilder<List<UserModel>>(
                  stream: _userService.getFriendsStream(currentUser.friends),
                  builder: (context, friendsSnapshot) {
                    if (!friendsSnapshot.hasData ||
                        friendsSnapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final activeFriends = friendsSnapshot.data!
                        .where((friend) => friend.isOnline)
                        .take(10)
                        .toList();

                    if (activeFriends.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Active Now',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${activeFriends.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: activeFriends.length,
                            itemBuilder: (context, index) {
                              final friend = activeFriends[index];
                              return _buildActivePersonItem(friend);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSearching
                        ? const Color(0xFF0C3C2B)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onTap: () => setState(() => _isSearching = true),
                  onChanged: (value) => setState(() {}),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: _isSearching
                          ? const Color(0xFF0C3C2B)
                          : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Messages List
            Expanded(
              child: StreamBuilder<UserModel?>(
                stream: _userService.getCurrentUserStream(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0C3C2B),
                        ),
                        strokeWidth: 3,
                      ),
                    );
                  }

                  if (!userSnapshot.hasData ||
                      userSnapshot.data?.friends.isEmpty == true) {
                    return _buildEmptyState();
                  }

                  final currentUser = userSnapshot.data!;
                  return StreamBuilder<List<UserModel>>(
                    stream: _userService.getFriendsStream(currentUser.friends),
                    builder: (context, friendsSnapshot) {
                      if (friendsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF0C3C2B),
                            ),
                            strokeWidth: 3,
                          ),
                        );
                      }

                      if (!friendsSnapshot.hasData ||
                          friendsSnapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      List<UserModel> friends = friendsSnapshot.data!;

                      if (_searchController.text.isNotEmpty) {
                        friends = friends.where((friend) {
                          final searchTerm = _searchController.text
                              .toLowerCase();
                          final displayName = _getFriendDisplayName(
                            friend,
                          ).toLowerCase();
                          return displayName.contains(searchTerm) ||
                              friend.username.toLowerCase().contains(
                                searchTerm,
                              );
                        }).toList();
                      }

                      final pinnedFriends = friends
                          .where(
                            (f) => currentUser.specialFriends.contains(f.id),
                          )
                          .toList();
                      final regularFriends = friends
                          .where(
                            (f) => !currentUser.specialFriends.contains(f.id),
                          )
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          if (pinnedFriends.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 12,
                              ),
                              child: Text(
                                'FAVORITES',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...pinnedFriends.map(
                              (friend) =>
                                  _buildMessageCard(friend, isPinned: true),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (regularFriends.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 12,
                              ),
                              child: Text(
                                'ALL CHATS',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...regularFriends.map(
                              (friend) =>
                                  _buildMessageCard(friend, isPinned: false),
                            ),
                          ],
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
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _startChat(friend),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: UserAvatarWidget(
                      user: friend,
                      radius: 26,
                      backgroundColor: const Color(0xFFF1F5F9),
                    ),
                  ),
                ),
                if (_isFriendBirthdayToday(friend.id))
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Text('🎂', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                _buildCompactPlantBadge(friend.id),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(
                _getFriendDisplayName(friend).split(' ')[0],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startChat(friend),
          onLongPress: () => _showFriendOptions(friend),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    UserAvatarWidget(
                      user: friend,
                      radius: 28,
                      backgroundColor: const Color(0xFFF1F5F9),
                    ),
                    if (friend.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    if (_isFriendBirthdayToday(friend.id))
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Text(
                            '🎂',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isPinned)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.push_pin,
                                size: 14,
                                color: Color(0xFF0C3C2B),
                              ),
                            ),
                          Flexible(
                            child: Text(
                              _getFriendDisplayName(friend),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (friend.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF3B82F6),
                              size: 14,
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
                          final currentUserId =
                              FirebaseAuth.instance.currentUser?.uid;
                          bool hasUnreadMessages = false;

                          if (chatSnapshot.hasData &&
                              chatSnapshot.data!.exists) {
                            final chatData =
                                chatSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            final unreadCount =
                                chatData['unreadCount']
                                    as Map<String, dynamic>?;
                            final myUnreadCount =
                                unreadCount?[currentUserId] as int? ?? 0;
                            hasUnreadMessages = myUnreadCount > 0;
                          }

                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _getLastMessageSimple(friend.id),
                            builder: (context, messageSnapshot) {
                              if (messageSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text(
                                  'Loading...',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                );
                              }

                              final lastMessage = messageSnapshot.data;
                              if (lastMessage == null ||
                                  lastMessage['text'].toString().isEmpty) {
                                return Text(
                                  'Tap to chat',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }

                              final messageText = lastMessage['text']
                                  .toString();
                              final senderId = lastMessage['senderId']
                                  .toString();
                              final isFromCurrentUser =
                                  senderId == currentUserId;

                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isFromCurrentUser
                                          ? 'You: $messageText'
                                          : messageText,
                                      style: GoogleFonts.inter(
                                        color:
                                            hasUnreadMessages &&
                                                !isFromCurrentUser
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFF94A3B8),
                                        fontSize: 13,
                                        fontWeight:
                                            hasUnreadMessages &&
                                                !isFromCurrentUser
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildPlantStreakBadge(friend.id),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(_generateChatId(friend.id))
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox(width: 20);
                    }

                    final chatData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;
                    final unreadCount =
                        chatData['unreadCount'] as Map<String, dynamic>?;
                    final myUnreadCount =
                        unreadCount?[currentUserId] as int? ?? 0;

                    if (myUnreadCount > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0C3C2B),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            myUnreadCount > 9 ? '9+' : '$myUnreadCount',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getLastMessageSimple(friend.id),
                      builder: (context, messageSnapshot) {
                        final lastMessage = messageSnapshot.data;
                        if (lastMessage == null) {
                          return const SizedBox(width: 20);
                        }

                        final senderId = lastMessage['senderId'].toString();
                        final isRead = lastMessage['isRead'] ?? false;
                        final isFromCurrentUser = senderId == currentUserId;

                        if (isFromCurrentUser) {
                          return Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 16,
                            color: isRead
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                          );
                        }

                        return const SizedBox(width: 20);
                      },
                    );
                  },
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to start chatting',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Material(
              color: const Color(0xFF0C3C2B),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddFriendsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Friends',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startChat(UserModel friend) async {
    try {
      final chatId = await _userService.createOrGetPrivateChat(friend.id);
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
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    UserAvatarWidget(
                      user: friend,
                      radius: 24,
                      backgroundColor: const Color(0xFFF1F5F9),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFriendDisplayName(friend),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '@${friend.username}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _buildOptionTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Message',
                onTap: () {
                  Navigator.pop(context);
                  _startChat(friend);
                },
                isHighlighted: true,
              ),
              _buildOptionTile(
                icon: Icons.notifications_off_outlined,
                title: 'Mute notifications',
                onTap: () {
                  Navigator.pop(context);
                  _showMuteConfirmation(friend);
                },
              ),
              _buildOptionTile(
                icon: Icons.person_remove_outlined,
                title: 'Remove friend',
                onTap: () {
                  Navigator.pop(context);
                  _showUnfriendConfirmation(friend);
                },
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? const Color(0xFF0C3C2B).withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? const Color(0xFF0C3C2B).withOpacity(0.1)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color:
                        color ??
                        (isHighlighted
                            ? const Color(0xFF0C3C2B)
                            : const Color(0xFF64748B)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color ?? const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF94A3B8),
                  size: 20,
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
      desc: 'You will stop receiving notifications from ${friend.displayName}.',
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
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${friend.displayName} muted',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0C3C2B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
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
      title: 'Remove ${friend.displayName}',
      desc:
          'Are you sure you want to remove ${friend.displayName} from your friends?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await _userService.removeFriend(friend.id);
      },
      btnOkText: 'Remove',
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
      final hasUnreadMessages =
          unreadCount != null &&
          currentUserId != null &&
          (unreadCount[currentUserId] as int? ?? 0) > 0;

      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      for (final doc in messagesSnapshot.docs) {
        final messageData = doc.data();
        final deletedBy = List<String>.from(messageData['deletedBy'] ?? []);

        if (deletedBy.contains(currentUserId)) continue;

        final senderId = messageData['senderId'] ?? '';
        final isFromCurrentUser = senderId == currentUserId;

        return {
          'text': messageData['text'] ?? '',
          'senderId': senderId,
          'timestamp': messageData['timestamp'],
          'isRead': messageData['isRead'] ?? false,
          'hasUnreadMessages': hasUnreadMessages && !isFromCurrentUser,
          'unreadCount': hasUnreadMessages
              ? (unreadCount![currentUserId!] as int? ?? 0)
              : 0,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
