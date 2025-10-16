// views/friends_list_screen.dart
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

  // Get plant stage based on streak count
  Map<String, dynamic> _getPlantStage(int streakCount, bool isEndingSoon) {
    if (isEndingSoon) {
      return {
        'emoji': '🥀', // Wilting flower
        'name': 'Wilting',
        'color': Color(0xFFB91C1C), // Red-700
      };
    } else if (streakCount >= 100) {
      return {
        'emoji': '🌺', // Tropical flower - legendary
        'name': 'Blooming',
        'color': Color(0xFF9333EA), // Purple-600
      };
    } else if (streakCount >= 50) {
      return {
        'emoji': '🌸', // Cherry blossom - master
        'name': 'Flowering',
        'color': Color(0xFFDB2777), // Pink-600
      };
    } else if (streakCount >= 30) {
      return {
        'emoji': '🌹', // Rose - expert
        'name': 'Rose',
        'color': Color(0xFFDC2626), // Red-600
      };
    } else if (streakCount >= 14) {
      return {
        'emoji': '🌻', // Sunflower - advanced
        'name': 'Sunflower',
        'color': Color(0xFFEA580C), // Orange-600
      };
    } else if (streakCount >= 7) {
      return {
        'emoji': '🌿', // Herb - growing
        'name': 'Growing',
        'color': Color(0xFF16A34A), // Green-600
      };
    } else if (streakCount >= 3) {
      return {
        'emoji': '🌱', // Seedling - new growth
        'name': 'Sprouting',
        'color': Color(0xFF15803D), // Green-700
      };
    } else {
      return {
        'emoji': '🌰', // Seed - just started
        'name': 'Seed',
        'color': Color(0xFF92400E), // Amber-800
      };
    }
  }

  // Main plant-based streak badge for message cards
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
          final hoursLeft = streakInfo['hoursLeft'] as int? ?? 0;

          if (streakCount == 0) return const SizedBox.shrink();

          final plantStage = _getPlantStage(streakCount, isEndingSoon);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEndingSoon
                    ? [Color(0xFFFEE2E2), Color(0xFFFFEBEB)]
                    : [
                        Colors.white,
                        (plantStage['color'] as Color).withOpacity(0.05),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (plantStage['color'] as Color).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (plantStage['color'] as Color).withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(plantStage['emoji'], style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$streakCount',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: plantStage['color'],
                  ),
                ),
                if (isEndingSoon && hoursLeft > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFB91C1C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${hoursLeft}h',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        } catch (e) {
          print('Error building plant streak badge: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  // Compact plant badge for active people section
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
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (plantStage['color'] as Color).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plantStage['emoji'],
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$streakCount',
                    style: GoogleFonts.inter(
                      color: plantStage['color'],
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          print('Error building compact plant badge: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section with Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
                ),
                borderRadius: BorderRadius.only(
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
                                final userName =
                                    userSnapshot.data?.displayName ?? 'User';
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
                              stream: _userService
                                  .getTotalUnreadMessageCountStream(),
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
                            StreamBuilder<int>(
                              stream: _userService
                                  .getPendingRequestsCountStream(),
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
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                    builder: (context) =>
                                        const AddFriendsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

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
                        stream: _userService.getFriendsStream(
                          currentUser.friends,
                        ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
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

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF0C3C2B),
                      size: 20,
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
                        return const Center(child: CircularProgressIndicator());
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
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          // Close Friends Section
                          if (pinnedFriends.isNotEmpty) ...[
                            Text(
                              'Close Friends (${pinnedFriends.length})',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...pinnedFriends.map(
                              (friend) =>
                                  _buildMessageCard(friend, isPinned: true),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // All Messages Section
                          Text(
                            'All Messages (${regularFriends.length})',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...regularFriends.map(
                            (friend) =>
                                _buildMessageCard(friend, isPinned: false),
                          ),
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
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: UserAvatarWidget(
                    user: friend,
                    radius: 20,
                    backgroundColor: const Color(0xFF0C3C2B).withOpacity(0.1),
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
                        border: Border.all(
                          color: const Color(0xFF0C3C2B),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                if (_isFriendBirthdayToday(friend.id))
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF9800),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text('🎂', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                // Compact plant badge
                _buildCompactPlantBadge(friend.id),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 60,
              child: Text(
                _getFriendDisplayName(friend).split(' ')[0],
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
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 1),
            blurRadius: 4,
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
                Stack(
                  children: [
                    UserAvatarWidget(
                      user: friend,
                      radius: 28,
                      backgroundColor: const Color(0xFFF5F5F5),
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
                    if (_isFriendBirthdayToday(friend.id))
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF9800),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Text('🎂', style: TextStyle(fontSize: 12)),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _getFriendDisplayName(friend),
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
                          const SizedBox(width: 8),
                          // Plant-based streak badge
                          _buildPlantStreakBadge(friend.id),
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
                                    color: const Color(0xFF9E9E9E),
                                    fontSize: 14,
                                  ),
                                );
                              }

                              final lastMessage = messageSnapshot.data;
                              if (lastMessage == null ||
                                  lastMessage['text'].toString().isEmpty) {
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

                              final messageText = lastMessage['text']
                                  .toString();
                              final senderId = lastMessage['senderId']
                                  .toString();
                              final isFromCurrentUser =
                                  senderId == currentUserId;

                              return Text(
                                isFromCurrentUser
                                    ? 'You: $messageText'
                                    : messageText,
                                style: GoogleFonts.inter(
                                  color: hasUnreadMessages && !isFromCurrentUser
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF9E9E9E),
                                  fontSize: 14,
                                  fontWeight:
                                      hasUnreadMessages && !isFromCurrentUser
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
                              horizontal: 6,
                              vertical: 2,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C3C2B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                myUnreadCount > 9 ? '9+' : '$myUnreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _getLastMessageSimple(friend.id),
                          builder: (context, messageSnapshot) {
                            final lastMessage = messageSnapshot.data;
                            if (lastMessage == null)
                              return const SizedBox.shrink();

                            final senderId = lastMessage['senderId'].toString();
                            final isRead = lastMessage['isRead'] ?? false;
                            final isFromCurrentUser = senderId == currentUserId;

                            if (isFromCurrentUser) {
                              return Icon(
                                isRead ? Icons.done_all : Icons.done,
                                size: 16,
                                color: isRead
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFF9E9E9E),
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
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
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
              Row(
                children: [
                  UserAvatarWidget(
                    user: friend,
                    radius: 20,
                    backgroundColor: const Color(0xFF68EAFF),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFriendDisplayName(friend),
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
    final optionColor = isHighlighted
        ? const Color(0xFF0C3C2B)
        : (color ?? Colors.grey[700]);

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
                  ? const Color(0xFF0C3C2B).withOpacity(0.05)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHighlighted
                    ? const Color(0xFF0C3C2B).withOpacity(0.3)
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
                  child: Icon(icon, color: optionColor, size: 20),
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
      desc:
          'You will stop receiving notifications from ${friend.displayName}. You can unmute them anytime.',
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
            backgroundColor: const Color(0xFF0C3C2B),
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
      desc:
          'Are you sure you want to remove ${friend.displayName} from your friends list?',
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
