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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Friends',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Friend Requests Button with Badge
          StreamBuilder<int>(
            stream: _userService.getPendingRequestsCountStream(),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline),
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
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showSendFriendRequestDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 104, 234, 243),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild for search
              },
            ),
          ),

          // Friends List
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

                    // Filter friends based on search (now includes username)
                    if (_searchController.text.isNotEmpty) {
                      friends = friends
                          .where(
                            (friend) =>
                                friend.displayName.toLowerCase().contains(
                                  _searchController.text.toLowerCase(),
                                ) ||
                                friend.username.toLowerCase().contains(
                                  _searchController.text.toLowerCase(),
                                ) ||
                                friend.email.toLowerCase().contains(
                                  _searchController.text.toLowerCase(),
                                ),
                          )
                          .toList();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        return _buildFriendTile(friends[index]);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No friends yet',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send friend requests to start connecting!',
            style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showSendFriendRequestDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Send Friend Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 104, 234, 243),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(UserModel friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _startChat(friend), // Main tap opens chat
        onLongPress: () =>
            _showFriendOptions(friend), // Long press shows options
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Profile Picture with Online Status
              Stack(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: friend.photoUrl != null
                        ? CachedNetworkImageProvider(friend.photoUrl!)
                        : null,
                    backgroundColor: const Color.fromARGB(255, 104, 234, 243),
                    child: friend.photoUrl == null
                        ? Text(
                            friend.displayName.isNotEmpty
                                ? friend.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: friend.isOnline
                            ? Colors.green
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${friend.username}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      friend.isOnline
                          ? 'Online'
                          : 'Last seen ${_formatLastSeen(friend.lastSeen)}',
                      style: TextStyle(
                        color: friend.isOnline
                            ? Colors.green
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Chat Indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    104,
                    234,
                    243,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color.fromARGB(255, 104, 234, 243),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFriendOptions(UserModel friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
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
                    backgroundColor: const Color.fromARGB(255, 104, 234, 243),
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
                          style: GoogleFonts.nunito(
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
                icon: Icons.chat,
                title: 'Start Chat',
                onTap: () {
                  Navigator.pop(context);
                  _startChat(friend);
                },
              ),

              _buildOptionTile(
                icon: Icons.notifications_off,
                title: 'Mute Notifications',
                onTap: () {
                  Navigator.pop(context);
                  _showMuteOptions(friend);
                },
              ),

              _buildOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Chat',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChat(friend);
                },
              ),

              _buildOptionTile(
                icon: Icons.person_remove,
                title: 'Remove Friend',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveFriend(friend);
                },
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
    Color? color,
  }) {
    final optionColor = color ?? Colors.grey[700];

    return ListTile(
      leading: Icon(icon, color: optionColor),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          color: optionColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _showMuteOptions(UserModel friend) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      width: MediaQuery.of(context).size.width * 0.8,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.notifications_off, size: 50, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Mute ${friend.displayName}',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              ('15 minutes', '15m'),
              ('1 hour', '1h'),
              ('8 hours', '8h'),
              ('24 hours', '24h'),
              ('Until I turn it back on', 'forever'),
            ].map(
              (option) => ListTile(
                title: Text(option.$1),
                onTap: () {
                  Navigator.of(context).pop();
                  _muteChat(friend, option.$2);
                },
              ),
            ),
          ],
        ),
      ),
    ).show();
  }

  void _confirmDeleteChat(UserModel friend) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Delete Chat',
      desc:
          'Are you sure you want to delete your chat history with ${friend.displayName}? This action cannot be undone.',
      btnCancelOnPress: () {},
      btnOkOnPress: () => _deleteChat(friend),
      btnOkColor: Colors.orange,
      btnOkText: 'Delete',
      btnCancelText: 'Cancel',
    ).show();
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  void _startChat(UserModel friend) async {
    try {
      final chatId = await _userService.createOrGetPrivateChat(friend.id);
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

  void _muteChat(UserModel friend, String duration) {
    // TODO: Implement mute functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Muted ${friend.displayName} for $duration'),
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
      ),
    );
  }

  void _deleteChat(UserModel friend) async {
    try {
      final chatId = await _userService.createOrGetPrivateChat(friend.id);
      // TODO: Implement delete chat functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat history deleted'),
          backgroundColor: Color.fromARGB(255, 104, 234, 243),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to delete chat: $e');
    }
  }

  void _showSendFriendRequestDialog() {
    final usernameController = TextEditingController();

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      width: MediaQuery.of(context).size.width * 0.9,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.person_add,
              size: 50,
              color: Color.fromARGB(255, 104, 234, 243),
            ),
            const SizedBox(height: 16),
            Text(
              'Send Friend Request',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The user will receive a request and can choose to accept or decline',
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Friend\'s Username',
                hintText: 'Enter username (without @)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.alternate_email),
              ),
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the username without the @ symbol',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _sendFriendRequest(usernameController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 104, 234, 243),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Send Request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).show();
  }

  void _sendFriendRequest(String username) async {
    if (username.isEmpty) {
      _showErrorDialog('Please enter a username');
      return;
    }

    // Remove @ if user included it
    if (username.startsWith('@')) {
      username = username.substring(1);
    }

    try {
      final success = await _userService.sendFriendRequest(username);
      if (success) {
        _showSuccessDialog('Friend request sent to @$username!');
      } else {
        _showErrorDialog('User @$username not found');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
      }
      _showErrorDialog(errorMessage);
    }
  }

  void _confirmRemoveFriend(UserModel friend) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Remove Friend',
      desc:
          'Are you sure you want to remove ${friend.displayName} (@${friend.username}) from your friends?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        _removeFriend(friend);
      },
      btnOkColor: Colors.red,
      btnOkText: 'Remove',
      btnCancelText: 'Cancel',
    ).show();
  }

  void _removeFriend(UserModel friend) async {
    try {
      await _userService.removeFriend(friend.id);
      _showSuccessDialog('Friend @${friend.username} removed successfully');
    } catch (e) {
      _showErrorDialog('Failed to remove friend: $e');
    }
  }

  void _showSuccessDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'Success',
      desc: message,
      btnOkOnPress: () {},
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
}
