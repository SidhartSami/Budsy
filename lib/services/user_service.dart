// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/friend_request_model.dart';
import 'dart:io';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

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
      return UserModel.fromMap({...doc.data(), 'id': doc.id});
    } catch (e) {
      print('Error finding user by username: $e');
      return null;
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      final storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  // Delete profile picture
  Future<void> deleteProfilePicture(String userId) async {
    try {
      final storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      await storageRef.delete();
    } catch (e) {
      print('Error deleting profile picture: $e');
    }
  }

  // Update user profile (for profile completion and updates)
  Future<void> updateUserProfile({
    String? displayName,
    String? username,
    DateTime? birthDate,
    bool? showBirthDate,
    bool? showOnlineStatus,
    String? photoUrl,
    bool? profileCompleted,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      Map<String, dynamic> updates = {};

      if (displayName != null) updates['displayName'] = displayName;
      if (username != null) {
        final normalizedUsername = username.toLowerCase().trim();
        final isAvailable = await isUsernameAvailable(normalizedUsername);
        if (!isAvailable) throw Exception('Username is not available');
        updates['username'] = normalizedUsername;
      }
      if (birthDate != null)
        updates['birthDate'] = Timestamp.fromDate(birthDate);
      if (showBirthDate != null) updates['showBirthDate'] = showBirthDate;
      if (showOnlineStatus != null)
        updates['showOnlineStatus'] = showOnlineStatus;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (profileCompleted != null)
        updates['profileCompleted'] = profileCompleted;

      updates['lastSeen'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(currentUserId).update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Check if user profile is completed
  Future<bool> isProfileCompleted() async {
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (!doc.exists) return false;

      final userData = UserModel.fromMap({...doc.data()!, 'id': doc.id});
      return userData.profileCompleted &&
          userData.birthDate != null &&
          userData.meetsAgeRequirement;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
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

  Stream<List<Map<String, dynamic>>> getIncomingFriendRequestsStream() {
    if (currentUserId == null) return Stream.value([]);

    print('DEBUG: Getting incoming requests for user: $currentUserId');

    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          print('DEBUG: Found ${snapshot.docs.length} incoming requests');

          List<Map<String, dynamic>> requestsWithUserData = [];

          for (var doc in snapshot.docs) {
            try {
              print('DEBUG: Processing request doc: ${doc.id}');
              print('DEBUG: Request data: ${doc.data()}');

              final request = FriendRequestModel.fromMap(
                doc.data(),
                docId: doc.id,
              );
              print('DEBUG: Created request model: ${request.toString()}');

              // Get sender's user data
              final senderDoc = await _firestore
                  .collection('users')
                  .doc(request.senderId)
                  .get();

              if (senderDoc.exists) {
                final senderData = senderDoc.data()!;
                senderData['id'] = senderDoc.id;

                final senderUser = UserModel.fromMap(senderData);
                print(
                  'DEBUG: Found sender: ${senderUser.displayName} (@${senderUser.username})',
                );

                requestsWithUserData.add({
                  'request': request,
                  'sender': senderUser,
                });
              } else {
                print(
                  'DEBUG: Sender document not found for ID: ${request.senderId}',
                );
              }
            } catch (e) {
              print('ERROR: Error processing incoming request ${doc.id}: $e');
            }
          }

          print(
            'DEBUG: Returning ${requestsWithUserData.length} processed incoming requests',
          );
          return requestsWithUserData;
        });
  }

  Stream<List<Map<String, dynamic>>> getOutgoingFriendRequestsStream() {
    if (currentUserId == null) return Stream.value([]);

    print('DEBUG: Getting outgoing requests for user: $currentUserId');

    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          print('DEBUG: Found ${snapshot.docs.length} outgoing requests');

          List<Map<String, dynamic>> requestsWithUserData = [];

          for (var doc in snapshot.docs) {
            try {
              print('DEBUG: Processing outgoing request doc: ${doc.id}');
              print('DEBUG: Request data: ${doc.data()}');

              final request = FriendRequestModel.fromMap(
                doc.data(),
                docId: doc.id,
              );
              print('DEBUG: Created request model: ${request.toString()}');

              // Get receiver's user data
              final receiverDoc = await _firestore
                  .collection('users')
                  .doc(request.receiverId)
                  .get();

              if (receiverDoc.exists) {
                final receiverData = receiverDoc.data()!;
                receiverData['id'] = receiverDoc.id;

                final receiverUser = UserModel.fromMap(receiverData);
                print(
                  'DEBUG: Found receiver: ${receiverUser.displayName} (@${receiverUser.username})',
                );

                requestsWithUserData.add({
                  'request': request,
                  'receiver': receiverUser,
                });
              } else {
                print(
                  'DEBUG: Receiver document not found for ID: ${request.receiverId}',
                );
              }
            } catch (e) {
              print('ERROR: Error processing outgoing request ${doc.id}: $e');
            }
          }

          print(
            'DEBUG: Returning ${requestsWithUserData.length} processed outgoing requests',
          );
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

  // Updated createUserProfile method to include username and birth date validation
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String displayName,
    required String username,
    String? photoUrl,
    DateTime? birthDate,
  }) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      // Double-check username availability
      final isAvailable = await isUsernameAvailable(normalizedUsername);
      if (!isAvailable) {
        throw Exception('Username is not available');
      }

      // Validate age if birth date is provided
      bool profileCompleted = false;
      if (birthDate != null) {
        final age = _calculateAge(birthDate);
        if (age < 16) {
          throw Exception('You must be at least 16 years old to use this app');
        }
        profileCompleted = true;
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
        birthDate: birthDate,
        showBirthDate: false,
        showOnlineStatus: true,
        profileCompleted: profileCompleted,
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

  // Helper method to calculate age
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Update user's online status (respects privacy settings)
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
        return UserModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    });
  }

  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;

    final doc = await _firestore.collection('users').doc(currentUserId).get();
    if (doc.exists) {
      return UserModel.fromMap({...doc.data()!, 'id': doc.id});
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
      final doc = query.docs.first;
      return UserModel.fromMap({...doc.data(), 'id': doc.id});
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

  // Get friends stream with privacy-aware online status
  Stream<List<UserModel>> getFriendsStream(List<String> friendIds) {
    if (friendIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final userData = UserModel.fromMap({...doc.data(), 'id': doc.id});
            // If user has disabled showing online status, show them as offline
            if (!userData.showOnlineStatus) {
              return userData.copyWith(isOnline: false);
            }
            return userData;
          }).toList(),
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
