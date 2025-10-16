// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/friend_request_model.dart';
import 'package:tutortyper_app/models/special_friend_request_model.dart';
import 'package:tutortyper_app/widgets/avatar_selection_widget.dart';
import 'package:tutortyper_app/services/streak_service.dart';

import 'dart:io';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final StreakService _streakService = StreakService();
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
    String? gender,
    String? predefinedAvatar,
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

      // Handle gender update and assign default avatar if needed
      if (gender != null) {
        updates['gender'] = gender;

        // If user doesn't have a custom photo and no predefined avatar is being set,
        // assign the default avatar for their gender
        if (profileImage == null &&
            predefinedAvatar == null &&
            removeImage != true) {
          // Get current user to check if they have a custom photo
          final currentUserDoc = await _firestore
              .collection('users')
              .doc(currentUserId)
              .get();
          if (currentUserDoc.exists) {
            final currentUserData = currentUserDoc.data()!;
            final hasCustomPhoto = currentUserData['photoUrl'] != null;

            // Only set default avatar if user doesn't have a custom photo
            if (!hasCustomPhoto) {
              final defaultAvatar = AvatarManager.getDefaultAvatarForGender(
                gender,
              );
              updates['predefinedAvatar'] = defaultAvatar;
            }
          }
        }
      }

      if (predefinedAvatar != null)
        updates['predefinedAvatar'] = predefinedAvatar;

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
    String? gender,
    String? predefinedAvatar,
    bool profileCompleted = false, // ⚠️ ADD THIS PARAMETER with default false
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
      // Validate age if birth date is provided, but don't change profileCompleted
      if (birthDate != null) {
        final age = _calculateAge(birthDate);
        if (age < 16) {
          throw Exception('You must be at least 16 years old to use this app');
        }
      }

      // Assign default avatar based on gender if no custom photo or predefined avatar is provided
      String? finalPredefinedAvatar = predefinedAvatar;
      if (photoUrl == null && predefinedAvatar == null && gender != null) {
        finalPredefinedAvatar = AvatarManager.getDefaultAvatarForGender(gender);
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
        profileCompleted: profileCompleted, // ⚠️ Use the parameter value
        bio: bio?.trim(),
        gender: gender,
        predefinedAvatar: finalPredefinedAvatar,
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
      // Get current user's privacy settings
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final showOnlineStatus = userData['showOnlineStatus'] ?? true;

      // Only update online status if user allows it to be shown
      // Always update lastSeen regardless of privacy setting
      Map<String, dynamic> updates = {'lastSeen': FieldValue.serverTimestamp()};

      if (showOnlineStatus) {
        updates['isOnline'] = isOnline;
      } else {
        // If privacy is disabled, always show as offline
        updates['isOnline'] = false;
      }

      await _firestore.collection('users').doc(currentUserId).update(updates);

      print(
        'DEBUG: Updated online status - isOnline: ${updates['isOnline']}, showOnlineStatus: $showOnlineStatus',
      );
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

      // Check if there's mutual blocking
      final canInteract = await canInteractWithUser(receiverUser.id);
      if (!canInteract) {
        throw Exception('Cannot send friend request to this user');
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
                  'id': request.id,
                  'fromUser': senderUser.toMap(),
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
                  'id': request.id,
                  'toUser': receiverUser.toMap(),
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

  /// Decline friend request (alias for rejectFriendRequest)
  Future<void> declineFriendRequest(String requestId) async {
    return rejectFriendRequest(requestId);
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
  // SPECIAL FRIEND REQUEST METHODS
  // ============================================================================

  /// Send special friend request (only to existing friends)
  Future<bool> sendSpecialFriendRequest(String friendId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('DEBUG: No current user found');
        return false;
      }

      print(
        'DEBUG: Sending special friend request from ${currentUser.uid} to friend: $friendId',
      );

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

      // Check if they are already friends
      if (!currentUserData.friends.contains(friendId)) {
        throw Exception(
          'You can only send special friend requests to existing friends',
        );
      }

      // Check if they are already special friends
      if (currentUserData.specialFriends.contains(friendId)) {
        throw Exception('You are already special friends with this user');
      }

      // Check if user already has a special friend (only one allowed)
      if (currentUserData.specialFriends.isNotEmpty) {
        throw Exception(
          'You can only have one special friend at a time. Remove your current special friend first.',
        );
      }

      // Check if there's already a pending special friend request
      final existingRequest = await _firestore
          .collection('specialFriendRequests')
          .where('senderId', isEqualTo: currentUser.uid)
          .where('receiverId', isEqualTo: friendId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Special friend request already sent');
      }

      // Check if there's a pending request from the other user
      final reverseRequest = await _firestore
          .collection('specialFriendRequests')
          .where('senderId', isEqualTo: friendId)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (reverseRequest.docs.isNotEmpty) {
        throw Exception(
          'This friend has already sent you a special friend request. Check your incoming requests!',
        );
      }

      // Create special friend request
      final requestId = _firestore.collection('specialFriendRequests').doc().id;
      final specialFriendRequest = SpecialFriendRequestModel(
        id: requestId,
        senderId: currentUser.uid,
        receiverId: friendId,
        status: SpecialFriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      print('DEBUG: Creating special friend request with ID: $requestId');
      print('DEBUG: Request data: ${specialFriendRequest.toMap()}');

      await _firestore
          .collection('specialFriendRequests')
          .doc(requestId)
          .set(specialFriendRequest.toMap());

      print('DEBUG: Special friend request created successfully');
      return true;
    } catch (e) {
      print('Error sending special friend request: $e');
      rethrow;
    }
  }

  /// Get incoming special friend requests stream
  Stream<List<Map<String, dynamic>>> getIncomingSpecialFriendRequestsStream() {
    if (currentUserId == null) return Stream.value([]);

    print(
      'DEBUG: Getting incoming special friend requests for user: $currentUserId',
    );

    return _firestore
        .collection('specialFriendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          print(
            'DEBUG: Found ${snapshot.docs.length} incoming special friend requests',
          );

          List<Map<String, dynamic>> requestsWithUserData = [];

          for (var doc in snapshot.docs) {
            try {
              print('DEBUG: Processing special friend request doc: ${doc.id}');
              print('DEBUG: Request data: ${doc.data()}');

              final request = SpecialFriendRequestModel.fromMap(
                doc.data(),
                docId: doc.id,
              );
              print(
                'DEBUG: Created special friend request model: ${request.toString()}',
              );

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
                  'id': request.id,
                  'fromUser': senderUser.toMap(),
                });
              } else {
                print(
                  'DEBUG: Sender document not found for ID: ${request.senderId}',
                );
              }
            } catch (e) {
              print(
                'ERROR: Error processing incoming special friend request ${doc.id}: $e',
              );
            }
          }

          print(
            'DEBUG: Returning ${requestsWithUserData.length} processed incoming special friend requests',
          );
          return requestsWithUserData;
        });
  }

  /// Get outgoing special friend requests stream
  Stream<List<Map<String, dynamic>>> getOutgoingSpecialFriendRequestsStream() {
    if (currentUserId == null) return Stream.value([]);

    print(
      'DEBUG: Getting outgoing special friend requests for user: $currentUserId',
    );

    return _firestore
        .collection('specialFriendRequests')
        .where('senderId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          print(
            'DEBUG: Found ${snapshot.docs.length} outgoing special friend requests',
          );

          List<Map<String, dynamic>> requestsWithUserData = [];

          for (var doc in snapshot.docs) {
            try {
              print(
                'DEBUG: Processing outgoing special friend request doc: ${doc.id}',
              );
              print('DEBUG: Request data: ${doc.data()}');

              final request = SpecialFriendRequestModel.fromMap(
                doc.data(),
                docId: doc.id,
              );
              print(
                'DEBUG: Created special friend request model: ${request.toString()}',
              );

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
                  'id': request.id,
                  'toUser': receiverUser.toMap(),
                });
              } else {
                print(
                  'DEBUG: Receiver document not found for ID: ${request.receiverId}',
                );
              }
            } catch (e) {
              print(
                'ERROR: Error processing outgoing special friend request ${doc.id}: $e',
              );
            }
          }

          print(
            'DEBUG: Returning ${requestsWithUserData.length} processed outgoing special friend requests',
          );
          return requestsWithUserData;
        });
  }

  /// Accept special friend request
  Future<void> acceptSpecialFriendRequest(
    String requestId,
    String senderId,
  ) async {
    if (currentUserId == null) return;

    try {
      // First check if user already has a special friend
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (currentUserDoc.exists) {
        final currentUserData = UserModel.fromMap({
          ...currentUserDoc.data()!,
          'id': currentUserDoc.id,
        });
        if (currentUserData.specialFriends.isNotEmpty) {
          throw Exception(
            'You can only have one special friend at a time. Remove your current special friend first.',
          );
        }
      }

      // Also check if sender already has a special friend
      final senderUserDoc = await _firestore
          .collection('users')
          .doc(senderId)
          .get();
      if (senderUserDoc.exists) {
        final senderUserData = UserModel.fromMap({
          ...senderUserDoc.data()!,
          'id': senderUserDoc.id,
        });
        if (senderUserData.specialFriends.isNotEmpty) {
          throw Exception(
            'The sender already has a special friend. They can only have one special friend at a time.',
          );
        }
      }

      await _firestore.runTransaction((transaction) async {
        // Update request status
        final requestRef = _firestore
            .collection('specialFriendRequests')
            .doc(requestId);
        transaction.update(requestRef, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });

        // Add to both users' special friends lists
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUserId);
        final senderUserRef = _firestore.collection('users').doc(senderId);

        transaction.update(currentUserRef, {
          'specialFriends': FieldValue.arrayUnion([senderId]),
        });

        transaction.update(senderUserRef, {
          'specialFriends': FieldValue.arrayUnion([currentUserId]),
        });
      });
    } catch (e) {
      print('Error accepting special friend request: $e');
      rethrow;
    }
  }

  /// Reject special friend request
  Future<void> rejectSpecialFriendRequest(String requestId) async {
    try {
      await _firestore
          .collection('specialFriendRequests')
          .doc(requestId)
          .update({
            'status': 'rejected',
            'respondedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error rejecting special friend request: $e');
      rethrow;
    }
  }

  /// Cancel outgoing special friend request
  Future<void> cancelSpecialFriendRequest(String requestId) async {
    try {
      await _firestore
          .collection('specialFriendRequests')
          .doc(requestId)
          .delete();
    } catch (e) {
      print('Error canceling special friend request: $e');
      rethrow;
    }
  }

  /// Get count of pending incoming special friend requests
  Stream<int> getPendingSpecialFriendRequestsCountStream() {
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('specialFriendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Remove special friend (removes from both sides)
  Future<void> removeSpecialFriend(String specialFriendId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUserId);
        final specialFriendUserRef = _firestore
            .collection('users')
            .doc(specialFriendId);

        transaction.update(currentUserRef, {
          'specialFriends': FieldValue.arrayRemove([specialFriendId]),
        });

        transaction.update(specialFriendUserRef, {
          'specialFriends': FieldValue.arrayRemove([currentUserId]),
        });
      });
    } catch (e) {
      print('Error removing special friend: $e');
      rethrow;
    }
  }

  /// Check if user is a special friend
  Future<bool> isSpecialFriend(String userId) async {
    if (currentUserId == null) return false;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (userDoc.exists) {
        final specialFriends = List<String>.from(
          userDoc.data()?['specialFriends'] ?? [],
        );
        return specialFriends.contains(userId);
      }
      return false;
    } catch (e) {
      print('Error checking if user is special friend: $e');
      return false;
    }
  }

  /// Get special friends stream
  Stream<List<UserModel>> getSpecialFriendsStream(
    List<String> specialFriendIds,
  ) {
    if (specialFriendIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: specialFriendIds)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return UserModel.fromMap({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  // ============================================================================
  // FRIENDS MANAGEMENT METHODS
  // ============================================================================

  /// Remove friend (complete unfriend - removes from both sides)

  Future<void> removeFriend(String friendId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUserId);
        final friendUserRef = _firestore.collection('users').doc(friendId);

        // Remove from friends list on both sides
        transaction.update(currentUserRef, {
          'friends': FieldValue.arrayRemove([friendId]),
          'specialFriends': FieldValue.arrayRemove([
            friendId,
          ]), // Also remove from special friends
        });

        transaction.update(friendUserRef, {
          'friends': FieldValue.arrayRemove([currentUserId]),
          'specialFriends': FieldValue.arrayRemove([
            currentUserId,
          ]), // Also remove from special friends
        });
      });

      // Delete streak after successful unfriend
      await _streakService.deleteStreak(currentUserId!, friendId);
      print('DEBUG: Streak deleted after unfriending');
    } catch (e) {
      print('Error removing friend: $e');
      rethrow;
    }
  }

  /// Unfriend user (complete removal - removes all chat data, settings, themes)
  Future<void> unfriendUser(String friendId) async {
    if (currentUserId == null) return;

    try {
      // Get chat ID for this friendship
      final chatId = await _getChatId(currentUserId!, friendId);

      await _firestore.runTransaction((transaction) async {
        // Remove from friends list on both sides
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUserId);
        final friendUserRef = _firestore.collection('users').doc(friendId);

        transaction.update(currentUserRef, {
          'friends': FieldValue.arrayRemove([friendId]),
          'specialFriends': FieldValue.arrayRemove([
            friendId,
          ]), // Also remove from special friends
        });

        transaction.update(friendUserRef, {
          'friends': FieldValue.arrayRemove([currentUserId]),
          'specialFriends': FieldValue.arrayRemove([
            currentUserId,
          ]), // Also remove from special friends
        });

        // Delete all chat-related data for current user
        if (chatId != null) {
          // Delete chat settings
          final settingsId = '${chatId}_$currentUserId';
          transaction.delete(
            _firestore.collection('chatSettings').doc(settingsId),
          );

          // Delete chat stats
          transaction.delete(
            _firestore.collection('chatStats').doc(settingsId),
          );

          // Delete chat document (only if both users unfriend)
          // For now, we'll keep the chat document but mark it as inactive
          transaction.update(_firestore.collection('chats').doc(chatId), {
            'isActive': false,
            'unfriendedBy': currentUserId,
            'unfriendedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Delete streak after successful unfriend
      await _streakService.deleteStreak(currentUserId!, friendId);
      print('DEBUG: Streak deleted after unfriending user');
    } catch (e) {
      print('Error unfriending user: $e');
      rethrow;
    }
  }

  /// Delete chat (user-side only - other user can still see chat)
  Future<void> deleteChatForUser(String friendId) async {
    if (currentUserId == null) return;

    try {
      final chatId = await _getChatId(currentUserId!, friendId);

      if (chatId != null) {
        await _firestore.runTransaction((transaction) async {
          // Delete chat settings for current user only
          final settingsId = '${chatId}_$currentUserId';
          transaction.delete(
            _firestore.collection('chatSettings').doc(settingsId),
          );

          // Delete chat stats for current user only
          transaction.delete(
            _firestore.collection('chatStats').doc(settingsId),
          );

          // Mark chat as deleted for current user
          transaction.update(_firestore.collection('chats').doc(chatId), {
            'deletedBy': FieldValue.arrayUnion([currentUserId]),
            'deletedAt': FieldValue.serverTimestamp(),
          });
        });
      }
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }

  /// Block user (comprehensive blocking with mutual restrictions)
  Future<void> blockUser(String userId) async {
    if (currentUserId == null) return;

    try {
      // Get chat ID for this friendship (if it exists)
      final chatId = await _getChatId(currentUserId!, userId);

      await _firestore.runTransaction((transaction) async {
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUserId);
        final blockedUserRef = _firestore.collection('users').doc(userId);

        // Add to blocked users list and remove from friends and special friends
        transaction.update(currentUserRef, {
          'blockedUsers': FieldValue.arrayUnion([userId]),
          'friends': FieldValue.arrayRemove([userId]),
          'specialFriends': FieldValue.arrayRemove([
            userId,
          ]), // Also remove from special friends
        });

        // Remove current user from the blocked user's friends and special friends list
        transaction.update(blockedUserRef, {
          'friends': FieldValue.arrayRemove([currentUserId]),
          'specialFriends': FieldValue.arrayRemove([
            currentUserId,
          ]), // Also remove from special friends
        });

        // Delete all chat-related data for BOTH users
        if (chatId != null) {
          // Delete chat settings for both users
          final currentUserSettingsId = '${chatId}_$currentUserId';
          final blockedUserSettingsId = '${chatId}_$userId';

          transaction.delete(
            _firestore.collection('chatSettings').doc(currentUserSettingsId),
          );
          transaction.delete(
            _firestore.collection('chatSettings').doc(blockedUserSettingsId),
          );

          // Delete chat stats for both users
          transaction.delete(
            _firestore.collection('chatStats').doc(currentUserSettingsId),
          );
          transaction.delete(
            _firestore.collection('chatStats').doc(blockedUserSettingsId),
          );

          // Mark chat as completely blocked and inactive
          transaction.update(_firestore.collection('chats').doc(chatId), {
            'isActive': false,
            'blockedBy': currentUserId,
            'blockedAt': FieldValue.serverTimestamp(),
            'isBlocked': true,
            'blockedUsers': FieldValue.arrayUnion([currentUserId, userId]),
          });
        }

        // Delete any pending friend requests between these users
        await _deleteFriendRequestsBetweenUsers(
          transaction,
          currentUserId!,
          userId,
        );
      });

      // Delete streak after blocking
      await _streakService.deleteStreak(currentUserId!, userId);
      print('DEBUG: Streak deleted after blocking user');
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock user (does NOT restore friendship - they need to add each other again)
  Future<void> unblockUser(String userId) async {
    if (currentUserId == null) return;

    try {
      final currentUserRef = _firestore.collection('users').doc(currentUserId);

      await _firestore.runTransaction((transaction) async {
        // Only remove from blocked users list - do NOT add back to friends
        transaction.update(currentUserRef, {
          'blockedUsers': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  /// Helper method to delete friend requests between two users
  Future<void> _deleteFriendRequestsBetweenUsers(
    Transaction transaction,
    String userId1,
    String userId2,
  ) async {
    try {
      // Delete requests from userId1 to userId2
      final requestsFrom1To2 = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: userId1)
          .where('toUserId', isEqualTo: userId2)
          .get();

      for (final doc in requestsFrom1To2.docs) {
        transaction.delete(doc.reference);
      }

      // Delete requests from userId2 to userId1
      final requestsFrom2To1 = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: userId2)
          .where('toUserId', isEqualTo: userId1)
          .get();

      for (final doc in requestsFrom2To1.docs) {
        transaction.delete(doc.reference);
      }
    } catch (e) {
      print('Error deleting friend requests between users: $e');
    }
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    if (currentUserId == null) return false;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (userDoc.exists) {
        final blockedUsers = List<String>.from(
          userDoc.data()?['blockedUsers'] ?? [],
        );
        return blockedUsers.contains(userId);
      }
      return false;
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }

  /// Check if there's mutual blocking between two users
  Future<bool> isMutualBlocking(String userId) async {
    if (currentUserId == null) return false;

    try {
      // Check if current user blocked the other user
      final currentUserBlocked = await isUserBlocked(userId);

      // Check if the other user blocked current user
      final otherUserDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      bool otherUserBlocked = false;
      if (otherUserDoc.exists) {
        final otherBlockedUsers = List<String>.from(
          otherUserDoc.data()?['blockedUsers'] ?? [],
        );
        otherUserBlocked = otherBlockedUsers.contains(currentUserId);
      }

      return currentUserBlocked || otherUserBlocked;
    } catch (e) {
      print('Error checking mutual blocking: $e');
      return false;
    }
  }

  /// Check if user can interact with another user (not blocked either way)
  Future<bool> canInteractWithUser(String userId) async {
    if (currentUserId == null) return false;
    return !(await isMutualBlocking(userId));
  }

  /// Get list of blocked users
  Future<List<UserModel>> getBlockedUsers() async {
    if (currentUserId == null) return [];

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!userDoc.exists) return [];

      final blockedUserIds = List<String>.from(
        userDoc.data()?['blockedUsers'] ?? [],
      );
      if (blockedUserIds.isEmpty) return [];

      final blockedUsers = <UserModel>[];

      // Get user data for each blocked user
      for (final userId in blockedUserIds) {
        try {
          final blockedUserDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          if (blockedUserDoc.exists) {
            blockedUsers.add(UserModel.fromFirestore(blockedUserDoc));
          }
        } catch (e) {
          print('Error getting blocked user $userId: $e');
        }
      }

      return blockedUsers;
    } catch (e) {
      print('Error getting blocked users: $e');
      return [];
    }
  }

  /// Get chat ID between two users
  Future<String?> _getChatId(String userId1, String userId2) async {
    try {
      // Try both combinations of user IDs
      final chatId1 = '${userId1}_$userId2';
      final chatId2 = '${userId2}_$userId1';

      final chat1Doc = await _firestore.collection('chats').doc(chatId1).get();
      if (chat1Doc.exists) return chatId1;

      final chat2Doc = await _firestore.collection('chats').doc(chatId2).get();
      if (chat2Doc.exists) return chatId2;

      return null;
    } catch (e) {
      print('Error getting chat ID: $e');
      return null;
    }
  }

  /// Get recommended users (excluding friends, blocked users, and current user)
  Future<List<UserModel>> getRecommendedUsers() async {
    if (currentUserId == null) return [];

    try {
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!currentUserDoc.exists) return [];

      final currentUserData = currentUserDoc.data()!;
      final friends = List<String>.from(currentUserData['friends'] ?? []);
      final blockedUsers = List<String>.from(
        currentUserData['blockedUsers'] ?? [],
      );

      // Get all users except current user, friends, and blocked users
      final querySnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .limit(20)
          .get();

      final recommendations = <UserModel>[];

      for (final doc in querySnapshot.docs) {
        final userId = doc.id;

        // Skip if user is already a friend or blocked
        if (friends.contains(userId) || blockedUsers.contains(userId)) {
          continue;
        }

        // Check if there's already a pending friend request
        final hasPendingRequest = await _hasPendingFriendRequest(userId);
        if (hasPendingRequest) continue;

        recommendations.add(UserModel.fromFirestore(doc));
      }

      return recommendations;
    } catch (e) {
      print('Error getting recommended users: $e');
      return [];
    }
  }

  /// Get mutual friends between current user and another user
  Future<List<UserModel>> getMutualFriends(String otherUserId) async {
    if (currentUserId == null) return [];

    try {
      // Get current user's friends
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!currentUserDoc.exists) return [];

      final currentUserData = currentUserDoc.data()!;
      final currentUserFriends = List<String>.from(
        currentUserData['friends'] ?? [],
      );

      // Get other user's friends
      final otherUserDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();
      if (!otherUserDoc.exists) return [];

      final otherUserData = otherUserDoc.data()!;
      final otherUserFriends = List<String>.from(
        otherUserData['friends'] ?? [],
      );

      // Find mutual friends (intersection of both friend lists)
      final mutualFriendIds = currentUserFriends
          .where((friendId) => otherUserFriends.contains(friendId))
          .toList();

      if (mutualFriendIds.isEmpty) return [];

      // Get user data for mutual friends
      final mutualFriends = <UserModel>[];

      for (final friendId in mutualFriendIds) {
        try {
          final friendDoc = await _firestore
              .collection('users')
              .doc(friendId)
              .get();
          if (friendDoc.exists) {
            mutualFriends.add(UserModel.fromFirestore(friendDoc));
          }
        } catch (e) {
          print('Error getting mutual friend data for $friendId: $e');
        }
      }

      return mutualFriends;
    } catch (e) {
      print('Error getting mutual friends: $e');
      return [];
    }
  }

  /// Get mutual friend suggestions (users who have mutual friends with current user)
  Future<List<UserModel>> getMutualFriendSuggestions() async {
    if (currentUserId == null) return [];

    try {
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!currentUserDoc.exists) return [];

      final currentUserData = currentUserDoc.data()!;
      final friends = List<String>.from(currentUserData['friends'] ?? []);
      final blockedUsers = List<String>.from(
        currentUserData['blockedUsers'] ?? [],
      );

      if (friends.isEmpty) {
        // If user has no friends, return general recommendations
        return getRecommendedUsers();
      }

      // Get friends of friends (potential mutual connections)
      final Set<String> potentialMutualFriends = {};

      for (final friendId in friends.take(10)) {
        // Limit to avoid too many queries
        try {
          final friendDoc = await _firestore
              .collection('users')
              .doc(friendId)
              .get();
          if (friendDoc.exists) {
            final friendData = friendDoc.data()!;
            final friendFriends = List<String>.from(
              friendData['friends'] ?? [],
            );

            // Add friends of this friend to potential mutual friends
            for (final friendOfFriend in friendFriends) {
              if (friendOfFriend != currentUserId &&
                  !friends.contains(friendOfFriend) &&
                  !blockedUsers.contains(friendOfFriend)) {
                potentialMutualFriends.add(friendOfFriend);
              }
            }
          }
        } catch (e) {
          print('Error getting friend data for $friendId: $e');
        }
      }

      // Get user data for potential mutual friends
      final suggestions = <UserModel>[];

      for (final userId in potentialMutualFriends.take(20)) {
        try {
          // Check if there's already a pending friend request
          final hasPendingRequest = await _hasPendingFriendRequest(userId);
          if (hasPendingRequest) continue;

          // Check if there's mutual blocking
          final canInteract = await canInteractWithUser(userId);
          if (!canInteract) continue;

          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            suggestions.add(UserModel.fromFirestore(userDoc));
          }
        } catch (e) {
          print('Error getting user data for $userId: $e');
        }
      }

      return suggestions;
    } catch (e) {
      print('Error getting mutual friend suggestions: $e');
      return [];
    }
  }

  /// Search users by name or username (excluding blocked users)
  Future<List<UserModel>> searchUsers(String query) async {
    if (currentUserId == null || query.isEmpty) return [];

    try {
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!currentUserDoc.exists) return [];

      final currentUserData = currentUserDoc.data()!;
      final blockedUsers = List<String>.from(
        currentUserData['blockedUsers'] ?? [],
      );

      final searchQuery = query.toLowerCase();

      // Search by display name
      final nameQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: searchQuery)
          .where('displayName', isLessThan: searchQuery + '\uf8ff')
          .limit(10)
          .get();

      // Search by username
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: searchQuery)
          .where('username', isLessThan: searchQuery + '\uf8ff')
          .limit(10)
          .get();

      final results = <String, UserModel>{};

      // Process name results
      for (final doc in nameQuery.docs) {
        final userId = doc.id;
        if (userId != currentUserId && !blockedUsers.contains(userId)) {
          // Check if there's mutual blocking
          final canInteract = await canInteractWithUser(userId);
          if (canInteract) {
            results[userId] = UserModel.fromFirestore(doc);
          }
        }
      }

      // Process username results
      for (final doc in usernameQuery.docs) {
        final userId = doc.id;
        if (userId != currentUserId && !blockedUsers.contains(userId)) {
          // Check if there's mutual blocking
          final canInteract = await canInteractWithUser(userId);
          if (canInteract) {
            results[userId] = UserModel.fromFirestore(doc);
          }
        }
      }

      return results.values.toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Check if there's a pending friend request between current user and target user
  Future<bool> _hasPendingFriendRequest(String targetUserId) async {
    if (currentUserId == null) return false;

    try {
      // Check outgoing requests
      final outgoingQuery = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: currentUserId)
          .where('toUserId', isEqualTo: targetUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (outgoingQuery.docs.isNotEmpty) return true;

      // Check incoming requests
      final incomingQuery = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: targetUserId)
          .where('toUserId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      return incomingQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking pending friend request: $e');
      return false;
    }
  }

  /// Get friends stream with privacy-aware online status (excluding blocked users)
  Stream<List<UserModel>> getFriendsStream(List<String> friendIds) {
    if (friendIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .snapshots()
        .asyncMap((snapshot) async {
          final friends = <UserModel>[];

          for (final doc in snapshot.docs) {
            final userData = UserModel.fromMap({...doc.data(), 'id': doc.id});

            // Check if this user is blocked
            final isBlocked = await isUserBlocked(userData.id);
            if (isBlocked) continue; // Skip blocked users

            // If user has disabled showing online status, show them as offline
            if (!userData.showOnlineStatus) {
              friends.add(userData.copyWith(isOnline: false));
            } else {
              friends.add(userData);
            }
          }

          return friends;
        });
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

  /// Get total unread message count for current user
  Future<int> getTotalUnreadMessageCount() async {
    if (currentUserId == null) return 0;

    try {
      // Get all chats where current user is a participant
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId!)
          .get();

      int totalUnreadCount = 0;

      for (final chatDoc in chatsSnapshot.docs) {
        final chatData = chatDoc.data();
        final unreadCount = chatData['unreadCount'] as Map<String, dynamic>?;
        if (unreadCount != null && unreadCount.containsKey(currentUserId!)) {
          totalUnreadCount += (unreadCount[currentUserId!] as int? ?? 0);
        }
      }

      return totalUnreadCount;
    } catch (e) {
      print('Error getting total unread message count: $e');
      return 0;
    }
  }

  /// Get total unread message count stream for current user
  Stream<int> getTotalUnreadMessageCountStream() {
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId!)
        .snapshots()
        .map((snapshot) {
          int totalUnreadCount = 0;

          for (final chatDoc in snapshot.docs) {
            final chatData = chatDoc.data();
            final unreadCount =
                chatData['unreadCount'] as Map<String, dynamic>?;
            if (unreadCount != null &&
                unreadCount.containsKey(currentUserId!)) {
              totalUnreadCount += (unreadCount[currentUserId!] as int? ?? 0);
            }
          }

          return totalUnreadCount;
        });
  }

  /// Mark all messages in a chat as read for current user
  Future<void> markMessagesAsRead(String chatId) async {
    if (currentUserId == null) return;

    try {
      // Update unread count for current user to 0
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });

      // Mark all unread messages from other users as read
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      if (messagesSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Get chat info stream for real-time updates
  Stream<Map<String, dynamic>?> getChatInfoStream(String friendId) {
    if (currentUserId == null) return Stream.value(null);

    final participants = [currentUserId!, friendId]..sort();
    final chatId = participants.join('_');

    print(
      'DEBUG: Getting chat info stream for chatId: $chatId, currentUser: $currentUserId, friend: $friendId',
    );

    return _firestore.collection('chats').doc(chatId).snapshots().asyncMap((
      chatDoc,
    ) async {
      print('DEBUG: Chat doc exists: ${chatDoc.exists} for chatId: $chatId');

      if (!chatDoc.exists) return null;

      final chatData = chatDoc.data()!;
      final unreadCount = chatData['unreadCount'] as Map<String, dynamic>?;
      final myUnreadCount = unreadCount?[currentUserId!] as int? ?? 0;
      final hasUnreadMessages = myUnreadCount > 0;

      print(
        'DEBUG: Unread count for $currentUserId: $myUnreadCount, hasUnread: $hasUnreadMessages',
      );

      // Get the last message that current user hasn't deleted
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(
            10,
          ) // Get more messages to find one not deleted by current user
          .get();

      // Find the first message not deleted by current user
      for (final doc in messagesSnapshot.docs) {
        final messageData = doc.data();
        final deletedBy = List<String>.from(messageData['deletedBy'] ?? []);

        // Skip if current user has deleted this message
        if (deletedBy.contains(currentUserId)) continue;

        final senderId = messageData['senderId'] ?? '';
        final isFromCurrentUser = senderId == currentUserId;

        print(
          'DEBUG: Last visible message from: $senderId, isFromCurrentUser: $isFromCurrentUser, hasUnread: $hasUnreadMessages',
        );

        return {
          'text': messageData['text'] ?? '',
          'senderId': senderId,
          'timestamp': messageData['timestamp'],
          'isRead': messageData['isRead'] ?? false,
          'hasUnreadMessages': hasUnreadMessages && !isFromCurrentUser,
          'unreadCount': hasUnreadMessages && !isFromCurrentUser
              ? myUnreadCount
              : 0,
        };
      }
      return null;
    });
  }

  /// Mute a friend (add to muted list)
  Future<void> muteFriend(String friendId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('users').doc(currentUserId!).update({
        'mutedFriends': FieldValue.arrayUnion([friendId]),
      });
    } catch (e) {
      print('Error muting friend: $e');
      rethrow;
    }
  }

  /// Unmute a friend (remove from muted list)
  Future<void> unmuteFriend(String friendId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('users').doc(currentUserId!).update({
        'mutedFriends': FieldValue.arrayRemove([friendId]),
      });
    } catch (e) {
      print('Error unmuting friend: $e');
      rethrow;
    }
  }

  /// Check if a friend is muted
  Future<bool> isFriendMuted(String friendId) async {
    if (currentUserId == null) return false;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final mutedFriends = List<String>.from(userData['mutedFriends'] ?? []);
      return mutedFriends.contains(friendId);
    } catch (e) {
      print('Error checking if friend is muted: $e');
      return false;
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
