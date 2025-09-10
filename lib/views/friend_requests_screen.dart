// views/friend_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/friend_request_model.dart';
import 'package:tutortyper_app/services/user_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Friend Requests',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
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
        print(
          'DEBUG: Incoming requests stream state: ${snapshot.connectionState}',
        );
        print('DEBUG: Incoming requests hasData: ${snapshot.hasData}');
        print(
          'DEBUG: Incoming requests data length: ${snapshot.data?.length ?? 0}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('ERROR: Incoming requests stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading requests: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No incoming friend requests', Icons.inbox);
        }

        final requests = snapshot.data!;
        print('DEBUG: Displaying ${requests.length} incoming requests');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestData = requests[index];
            final request = requestData['request'] as FriendRequestModel;
            final sender = requestData['sender'] as UserModel;

            return _buildIncomingRequestTile(request, sender);
          },
        );
      },
    );
  }

  Widget _buildOutgoingRequests() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _userService.getOutgoingFriendRequestsStream(),
      builder: (context, snapshot) {
        print(
          'DEBUG: Outgoing requests stream state: ${snapshot.connectionState}',
        );
        print('DEBUG: Outgoing requests hasData: ${snapshot.hasData}');
        print(
          'DEBUG: Outgoing requests data length: ${snapshot.data?.length ?? 0}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('ERROR: Outgoing requests stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading requests: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No outgoing friend requests', Icons.send);
        }

        final requests = snapshot.data!;
        print('DEBUG: Displaying ${requests.length} outgoing requests');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestData = requests[index];
            final request = requestData['request'] as FriendRequestModel;
            final receiver = requestData['receiver'] as UserModel;

            return _buildOutgoingRequestTile(request, receiver);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestTile(
    FriendRequestModel request,
    UserModel sender,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 25,
              backgroundImage: sender.photoUrl != null
                  ? CachedNetworkImageProvider(sender.photoUrl!)
                  : null,
              backgroundColor: const Color.fromARGB(255, 104, 234, 243),
              child: sender.photoUrl == null
                  ? Text(
                      sender.displayName.isNotEmpty
                          ? sender.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sender.displayName,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '@${sender.username}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatRequestTime(request.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: 80,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(request, sender),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _rejectRequest(request, sender),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingRequestTile(
    FriendRequestModel request,
    UserModel receiver,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 25,
              backgroundImage: receiver.photoUrl != null
                  ? CachedNetworkImageProvider(receiver.photoUrl!)
                  : null,
              backgroundColor: const Color.fromARGB(255, 104, 234, 243),
              child: receiver.photoUrl == null
                  ? Text(
                      receiver.displayName.isNotEmpty
                          ? receiver.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receiver.displayName,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '@${receiver.username}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Sent ${_formatRequestTime(request.createdAt)}',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cancel Button
            SizedBox(
              width: 80,
              height: 32,
              child: ElevatedButton(
                onPressed: () => _cancelRequest(request, receiver),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRequestTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  void _acceptRequest(FriendRequestModel request, UserModel sender) async {
    try {
      await _userService.acceptFriendRequest(request.id, request.senderId);
      _showSuccessDialog('Friend request from @${sender.username} accepted!');
    } catch (e) {
      _showErrorDialog('Failed to accept request: $e');
    }
  }

  void _rejectRequest(FriendRequestModel request, UserModel sender) async {
    try {
      await _userService.rejectFriendRequest(request.id);
      _showSuccessDialog('Friend request from @${sender.username} rejected');
    } catch (e) {
      _showErrorDialog('Failed to reject request: $e');
    }
  }

  void _cancelRequest(FriendRequestModel request, UserModel receiver) async {
    try {
      await _userService.cancelFriendRequest(request.id);
      _showSuccessDialog('Friend request to @${receiver.username} cancelled');
    } catch (e) {
      _showErrorDialog('Failed to cancel request: $e');
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
