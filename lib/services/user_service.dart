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

  // Get current user ID and email
  static String? get currentUserId => _auth.currentUser?.uid;
  static String? get currentUserEmail => _auth.currentUser?.email;

  // ============================================================================
  // USERNAME AND VALIDATION METHODS
  // ============================================================================

  /// Check if username is available (excluding current user)
  Future<bool> isUsernameAvailable(
    String username, [
    String? excludeUserId,
  ]) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      // Username validation
      if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(normalizedUsername)) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .get();

      if (querySnapshot.docs.isEmpty) return true;

      // If excluding current user, check if the found user is the excluded one
      if (excludeUserId != null &&
          querySnapshot.docs.first.id == excludeUserId) {
        return true;
      }

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  /// Find user by username
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

  /// Find user by email
  Future<UserModel?> findUserByEmail(String email) async {
    try {
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
    } catch (e) {
      print('Error finding user by email: $e');
      return null;
    }
  }

  /// Get user profile by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  /// Search users by display name or username
  Future<List<UserModel>> searchUsers(String query, {int limit = 10}) async {
    try {
      if (query.trim().isEmpty) return [];

      final searchQuery = query.toLowerCase().trim();

      // Search by username
      final usernameResults = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: searchQuery)
          .where('username', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .limit(limit)
          .get();

      // Search by display name
      final nameResults = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(limit)
          .get();

      final Set<String> seenIds = {};
      final List<UserModel> users = [];

      // Combine results and remove duplicates
      for (final doc in [...usernameResults.docs, ...nameResults.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          users.add(UserModel.fromMap({...doc.data(), 'id': doc.id}));
        }
      }

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // ============================================================================
  // PROFILE MANAGEMENT METHODS
  // ============================================================================

  /// Upload profile picture
  Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      // Delete existing image first
      await _deleteProfileImage(userId);

      final storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Delete profile picture
  Future<void> deleteProfilePicture(String userId) async {
    await _deleteProfileImage(userId);
  }

  /// Internal method to delete profile image from Firebase Storage
  Future<void> _deleteProfileImage(String userId) async {
    try {
      final storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      await storageRef.delete();
    } catch (e) {
      // Ignore if file doesn't exist
      if (!e.toString().contains('object-not-found')) {
        print('Error deleting profile picture: $e');
      }
    }
  }

  /// Update user profile with comprehensive validation and image handling
  Future<void> updateUserProfile({
    String? displayName,
    String? username,
    DateTime? birthDate,
    bool? showBirthDate,
    bool? showOnlineStatus,
    String? photoUrl,
    bool? profileCompleted,
    String? bio,
    File? profileImage,
    bool? removeImage = false,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      Map<String, dynamic> updates = {};

      // Validate and update display name
      if (displayName != null) {
        if (displayName.trim().isEmpty) {
          throw Exception('Display name cannot be empty');
        }
        if (displayName.trim().length < 2) {
          throw Exception('Display name must be at least 2 characters');
        }
        if (displayName.trim().length > 50) {
          throw Exception('Display name must be less than 50 characters');
        }
        updates['displayName'] = displayName.trim();
      }

      // Validate and update username
      if (username != null) {
        final normalizedUsername = username.toLowerCase().trim();

        if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(normalizedUsername)) {
          throw Exception(
            'Username can only contain letters, numbers, and underscores (3-30 characters)',
          );
        }

        final isAvailable = await isUsernameAvailable(
          normalizedUsername,
          currentUserId,
        );
        if (!isAvailable) {
          throw Exception('Username @$normalizedUsername is not available');
        }
        updates['username'] = normalizedUsername;
      }

      // Validate and update bio
      if (bio != null) {
        if (bio.length > 150) {
          throw Exception('Bio must be less than 150 characters');
        }
        updates['bio'] = bio.trim();
        updates['lastBioUpdate'] = FieldValue.serverTimestamp();
      }

      // Handle other profile fields
      if (birthDate != null) {
        final age = _calculateAge(birthDate);
        if (age < 16) {
          throw Exception('You must be at least 16 years old to use this app');
        }
        updates['birthDate'] = Timestamp.fromDate(birthDate);
      }

      if (showBirthDate != null) updates['showBirthDate'] = showBirthDate;
      if (showOnlineStatus != null)
        updates['showOnlineStatus'] = showOnlineStatus;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (profileCompleted != null)
        updates['profileCompleted'] = profileCompleted;

      // Handle profile image
      if (profileImage != null) {
        final imageUrl = await uploadProfilePicture(
          profileImage,
          currentUserId!,
        );
        if (imageUrl != null) {
          updates['photoUrl'] = imageUrl;
        }
      } else if (removeImage == true) {
        await deleteProfilePicture(currentUserId!);
        updates['photoUrl'] = FieldValue.delete();
      }

      updates['lastSeen'] = FieldValue.serverTimestamp();

      // Update Firestore document
      await _firestore.collection('users').doc(currentUserId).update(updates);

      // Update Firebase Auth profile if needed
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        if (displayName != null) {
          await currentUser.updateDisplayName(displayName.trim());
        }
        if (profileImage != null && updates.containsKey('photoUrl')) {
          await currentUser.updatePhotoURL(updates['photoUrl']);
        } else if (removeImage == true) {
          await currentUser.updatePhotoURL(null);
        }
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Validate profile data before saving
  Map<String, String?> validateProfileData({
    required String displayName,
    required String username,
    required String bio,
  }) {
    Map<String, String?> errors = {};

    // Validate display name
    if (displayName.trim().isEmpty) {
      errors['displayName'] = 'Display name is required';
    } else if (displayName.trim().length < 2) {
      errors['displayName'] = 'Display name must be at least 2 characters';
    } else if (displayName.trim().length > 50) {
      errors['displayName'] = 'Display name must be less than 50 characters';
    }

    // Validate username
    if (username.trim().isEmpty) {
      errors['username'] = 'Username is required';
    } else if (username.trim().length < 3) {
      errors['username'] = 'Username must be at least 3 characters';
    } else if (username.trim().length > 30) {
      errors['username'] = 'Username must be less than 30 characters';
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.trim())) {
      errors['username'] =
          'Username can only contain letters, numbers, and underscores';
    }

    // Validate bio
    if (bio.length > 150) {
      errors['bio'] = 'Bio must be less than 150 characters';
    }

    return errors;
  }

  /// Get profile completion percentage
  int getProfileCompletionPercentage(UserModel user) {
    int completed = 0;
    const int totalFields = 6;

    if (user.displayName.isNotEmpty) completed++;
    if (user.username.isNotEmpty) completed++;
    if (user.bio?.isNotEmpty == true) completed++;
    if (user.photoUrl != null) completed++;
    if (user.email.isNotEmpty) completed++;
    if (user.birthDate != null) completed++;

    return ((completed / totalFields) * 100).round();
  }

  /// Check if user profile is completed
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

  /// Create user profile with comprehensive validation
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String displayName,
    required String username,
    String? photoUrl,
    DateTime? birthDate,
    String? bio,
  }) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      // Validate display name
      if (displayName.trim().isEmpty || displayName.trim().length < 2) {
        throw Exception('Display name must be at least 2 characters');
      }

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
        displayName: displayName.trim(),
        username: normalizedUsername,
        photoUrl: photoUrl,
        lastSeen: DateTime.now(),
        isOnline: true,
        friends: [],
        birthDate: birthDate,
        showBirthDate: false,
        showOnlineStatus: true,
        profileCompleted: profileCompleted,
        bio: bio?.trim(),
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

  // ============================================================================
  // USER STATUS AND ACTIVITY METHODS
  // ============================================================================

  /// Update user's online status (respects privacy settings)
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  /// Get user activity status
  Future<Map<String, dynamic>> getUserActivityStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data()!;
      final lastSeen = (userData['lastSeen'] as Timestamp?)?.toDate();
      final isOnline = userData['isOnline'] ?? false;

      return {
        'isOnline': isOnline,
        'lastSeen': lastSeen,
        'status': _getActivityStatus(isOnline, lastSeen),
      };
    } catch (e) {
      print('Error getting user activity status: $e');
      return {};
    }
  }

  /// Get formatted activity status string
  String _getActivityStatus(bool isOnline, DateTime? lastSeen) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Unknown';

    final difference = DateTime.now().difference(lastSeen);

    if (difference.inMinutes < 5) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return 'Long time ago';
  }

  /// Update user verification status (admin only)
  Future<void> updateVerificationStatus(String userId, bool isVerified) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': isVerified,
      });
    } catch (e) {
      throw Exception('Failed to update verification status: $e');
    }
  }

  /// Bulk update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      if (currentUserId == null) throw Exception('No authenticated user');

      await _firestore.collection('users').doc(currentUserId).update({
        'preferences': preferences,
        'preferencesUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  // ============================================================================
  // CURRENT USER METHODS
  // ============================================================================

  /// Get current user stream
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

  /// Get current user data
  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        return UserModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // ============================================================================
  // FRIEND REQUEST METHODS
  // ============================================================================

  /// Send friend request by username
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

      final currentUserData = UserModel.fromMap({
        ...currentUserDoc.data()!,
        'id': currentUserDoc.id,
      });

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

  /// Get incoming friend requests stream
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

  /// Get outgoing friend requests stream
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

  /// Accept friend request
  Future<void> acceptFriendRequest(String requestId, String senderId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        // Update request status
        final requestRef = _firestore
            .collection('friendRequests')
            .doc(requestId);
        transaction.update(requestRef, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });

        // Add to both users' friend lists
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUserId);
        final senderUserRef = _firestore.collection('users').doc(senderId);

        transaction.update(currentUserRef, {
          'friends': FieldValue.arrayUnion([senderId]),
        });

        transaction.update(senderUserRef, {
          'friends': FieldValue.arrayUnion([currentUserId]),
        });
      });
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rejecting friend request: $e');
      rethrow;
    }
  }

  /// Cancel outgoing friend request
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).delete();
    } catch (e) {
      print('Error canceling friend request: $e');
      rethrow;
    }
  }

  /// Get count of pending incoming requests
  Stream<int> getPendingRequestsCountStream() {
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============================================================================
  // FRIENDS MANAGEMENT METHODS
  // ============================================================================

  /// Remove friend
  Future<void> removeFriend(String friendId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUserId);
        final friendUserRef = _firestore.collection('users').doc(friendId);

        transaction.update(currentUserRef, {
          'friends': FieldValue.arrayRemove([friendId]),
        });

        transaction.update(friendUserRef, {
          'friends': FieldValue.arrayRemove([currentUserId]),
        });
      });
    } catch (e) {
      print('Error removing friend: $e');
      rethrow;
    }
  }

  /// Get friends stream with privacy-aware online status
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

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data()!;

      return {
        'friendsCount': (userData['friends'] as List?)?.length ?? 0,
        'pendingRequestsCount': await _getPendingRequestsCount(userId),
        'sentRequestsCount': await _getSentRequestsCount(userId),
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {};
    }
  }

  Future<int> _getPendingRequestsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getSentRequestsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================================
  // CHAT AND MESSAGING METHODS
  // ============================================================================

  /// Create or get private chat between two users
  Future<String> createOrGetPrivateChat(String otherUserId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
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
    } catch (e) {
      print('Error creating or getting private chat: $e');
      rethrow;
    }
  }

  // ============================================================================
  // NOTES AND MESSAGING METHODS
  // ============================================================================

  /// Send note to user (special message type)
  Future<void> sendNoteToUser(String recipientId, String noteContent) async {
    try {
      if (currentUserId == null) throw Exception('No authenticated user');

      if (noteContent.trim().isEmpty) {
        throw Exception('Note content cannot be empty');
      }

      if (noteContent.length > 500) {
        throw Exception('Note content must be less than 500 characters');
      }

      // Create a special note document
      await _firestore.collection('notes').add({
        'senderId': currentUserId,
        'recipientId': recipientId,
        'content': noteContent.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'note',
      });

      // Add to recipient's notifications
      await _firestore.collection('notifications').add({
        'userId': recipientId,
        'type': 'note_received',
        'title': 'New Note',
        'body': 'You received a note from someone!',
        'data': {'senderId': currentUserId, 'noteContent': noteContent.trim()},
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending note: $e');
      rethrow;
    }
  }

  /// Get received notes for current user
  Stream<List<Map<String, dynamic>>> getReceivedNotesStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('notes')
        .where('recipientId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Mark note as read
  Future<void> markNoteAsRead(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).update({'isRead': true});
    } catch (e) {
      print('Error marking note as read: $e');
      rethrow;
    }
  }

  /// Delete note
  Future<void> deleteNote(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).delete();
    } catch (e) {
      print('Error deleting note: $e');
      rethrow;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Helper method to calculate age
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Dispose method for cleanup (if needed)
  void dispose() {
    // Add any cleanup logic here if needed
    print('UserService disposed');
  }
}
