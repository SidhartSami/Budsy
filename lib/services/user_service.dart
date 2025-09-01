// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/friend_request_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;
  static String? get currentUserEmail => _auth.currentUser?.email;

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      // Username validation
      if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(normalizedUsername)) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Find user by username
  Future<UserModel?> findUserByUsername(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return UserModel.fromMap(doc.data());
    } catch (e) {
      print('Error finding user by username: $e');
      return null;
    }
  }

  // Send friend request by username
  Future<bool> sendFriendRequest(String username) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('DEBUG: No current user found');
        return false;
      }

      print(
        'DEBUG: Sending friend request from ${currentUser.uid} to username: $username',
      );

      final normalizedUsername = username.toLowerCase().trim();

      // Find the user by username
      final receiverUser = await findUserByUsername(normalizedUsername);
      if (receiverUser == null) {
        print('DEBUG: User not found with username: $normalizedUsername');
        return false;
      }

      print(
        'DEBUG: Found receiver user: ${receiverUser.id} (${receiverUser.username})',
      );

      // Check if user is trying to add themselves
      if (receiverUser.id == currentUser.uid) {
        throw Exception('You cannot send a friend request to yourself');
      }

      // Get current user data
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!currentUserDoc.exists) {
        print('DEBUG: Current user document does not exist');
        return false;
      }

      final currentUserData = UserModel.fromMap(currentUserDoc.data()!);

      // Check if already friends
      if (currentUserData.friends.contains(receiverUser.id)) {
        throw Exception('User is already in your friends list');
      }

      // Check if there's already a pending request
      final existingRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUser.uid)
          .where('receiverId', isEqualTo: receiverUser.id)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Friend request already sent');
      }

      // Check if there's a pending request from the other user
      final reverseRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: receiverUser.id)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (reverseRequest.docs.isNotEmpty) {
        throw Exception(
          'This user has already sent you a friend request. Check your incoming requests!',
        );
      }

      // Create friend request
      final requestId = _firestore.collection('friendRequests').doc().id;
      final friendRequest = FriendRequestModel(
        id: requestId,
        senderId: currentUser.uid,
        receiverId: receiverUser.id,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      print('DEBUG: Creating friend request with ID: $requestId');
      print('DEBUG: Request data: ${friendRequest.toMap()}');

      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .set(friendRequest.toMap());

      print('DEBUG: Friend request created successfully');
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  // Get incoming friend requests
  Stream<List<Map<String, dynamic>>> getIncomingFriendRequestsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> requestsWithUserData = [];

          for (var doc in snapshot.docs) {
            final request = FriendRequestModel.fromMap(doc.data());

            // Get sender's user data
            final senderDoc = await _firestore
                .collection('users')
                .doc(request.senderId)
                .get();

            if (senderDoc.exists) {
              final senderUser = UserModel.fromMap(senderDoc.data()!);
              requestsWithUserData.add({
                'request': request,
                'sender': senderUser,
              });
            }
          }

          return requestsWithUserData;
        });
  }

  // Get outgoing friend requests
  Stream<List<Map<String, dynamic>>> getOutgoingFriendRequestsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> requestsWithUserData = [];

          for (var doc in snapshot.docs) {
            final request = FriendRequestModel.fromMap(doc.data());

            // Get receiver's user data
            final receiverDoc = await _firestore
                .collection('users')
                .doc(request.receiverId)
                .get();

            if (receiverDoc.exists) {
              final receiverUser = UserModel.fromMap(receiverDoc.data()!);
              requestsWithUserData.add({
                'request': request,
                'receiver': receiverUser,
              });
            }
          }

          return requestsWithUserData;
        });
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String requestId, String senderId) async {
    if (currentUserId == null) return;

    await _firestore.runTransaction((transaction) async {
      // Update request status
      final requestRef = _firestore.collection('friendRequests').doc(requestId);
      transaction.update(requestRef, {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Add to both users' friend lists
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final senderUserRef = _firestore.collection('users').doc(senderId);

      transaction.update(currentUserRef, {
        'friends': FieldValue.arrayUnion([senderId]),
      });

      transaction.update(senderUserRef, {
        'friends': FieldValue.arrayUnion([currentUserId]),
      });
    });
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friendRequests').doc(requestId).update({
      'status': 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancel outgoing friend request
  Future<void> cancelFriendRequest(String requestId) async {
    await _firestore.collection('friendRequests').doc(requestId).delete();
  }

  // Get count of pending incoming requests
  Stream<int> getPendingRequestsCountStream() {
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Updated createUserProfile method to include username
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String displayName,
    required String username,
    String? photoUrl,
  }) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      // Double-check username availability
      final isAvailable = await isUsernameAvailable(normalizedUsername);
      if (!isAvailable) {
        throw Exception('Username is not available');
      }

      final userModel = UserModel(
        id: userId,
        email: email.toLowerCase(),
        displayName: displayName,
        username: normalizedUsername,
        photoUrl: photoUrl,
        lastSeen: DateTime.now(),
        isOnline: true,
        friends: [],
      );

      await _firestore.collection('users').doc(userId).set(userModel.toMap());

      print(
        'User profile created successfully with username: @$normalizedUsername',
      );
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Update user's online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Get current user stream
  Stream<UserModel?> getCurrentUserStream() {
    if (currentUserId == null) return Stream.value(null);

    return _firestore.collection('users').doc(currentUserId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Get current user data (one-time fetch)
  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;

    final doc = await _firestore.collection('users').doc(currentUserId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Find user by email
  Future<UserModel?> findUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  // Remove friend
  Future<void> removeFriend(String friendId) async {
    if (currentUserId == null) return;

    await _firestore.runTransaction((transaction) async {
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final friendUserRef = _firestore.collection('users').doc(friendId);

      transaction.update(currentUserRef, {
        'friends': FieldValue.arrayRemove([friendId]),
      });

      transaction.update(friendUserRef, {
        'friends': FieldValue.arrayRemove([currentUserId]),
      });
    });
  }

  // Get friends stream
  Stream<List<UserModel>> getFriendsStream(List<String> friendIds) {
    if (friendIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Create or get private chat between two users
  Future<String> createOrGetPrivateChat(String otherUserId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Create consistent chat ID
    final participants = [currentUserId!, otherUserId]..sort();
    final chatId = participants.join('_');

    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'id': chatId,
        'participants': participants,
        'chatType': 'private',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTime': null,
        'unreadCount': {currentUserId!: 0, otherUserId: 0},
      });
    }

    return chatId;
  }
}
