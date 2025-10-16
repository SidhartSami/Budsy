// services/streak_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutortyper_app/models/streak_model.dart';
import 'package:tutortyper_app/services/user_service.dart';

class StreakService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate unique streak ID from two user IDs (sorted alphabetically)
  static String _generateStreakId(String userId1, String userId2) {
    final participants = [userId1, userId2]..sort();
    return participants.join('_');
  }

  // Round up to next hour for grace period
  static DateTime _roundUpToNextHour(DateTime dateTime) {
    if (dateTime.minute == 0 &&
        dateTime.second == 0 &&
        dateTime.millisecond == 0) {
      return dateTime;
    }
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour + 1,
      0,
      0,
    );
  }

  // Calculate deadline with grace period (24 hours + round to next hour)
  static DateTime _calculateDeadline(DateTime lastMessageTime) {
    final deadline = lastMessageTime.add(const Duration(hours: 24));
    return _roundUpToNextHour(deadline);
  }

  // Get streak for two users
  Future<StreakModel?> getStreak(String userId1, String userId2) async {
    try {
      final streakId = _generateStreakId(userId1, userId2);
      final doc = await _firestore.collection('streaks').doc(streakId).get();

      if (doc.exists) {
        return StreakModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting streak: $e');
      return null;
    }
  }

  // Get streak stream for real-time updates
  Stream<StreakModel?> getStreakStream(String userId1, String userId2) {
    final streakId = _generateStreakId(userId1, userId2);
    return _firestore.collection('streaks').doc(streakId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return StreakModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Initialize or update streak when a message is sent
  Future<void> handleMessageSent({
    required String senderId,
    required String receiverId,
    required DateTime messageTime,
  }) async {
    try {
      final streakId = _generateStreakId(senderId, receiverId);
      final participants = [senderId, receiverId]..sort();
      final senderIndex = participants.indexOf(senderId);

      print('DEBUG Streak: Handling message from $senderId to $receiverId');

      final doc = await _firestore.collection('streaks').doc(streakId).get();

      if (!doc.exists) {
        // Initialize new streak
        print('DEBUG Streak: Creating new streak');
        await _initializeStreak(
          streakId: streakId,
          participants: participants,
          senderId: senderId,
          messageTime: messageTime,
        );
      } else {
        // Update existing streak
        final streak = StreakModel.fromMap(doc.data()!);
        print(
          'DEBUG Streak: Updating existing streak (count: ${streak.streakCount})',
        );
        await _updateStreak(
          streak: streak,
          senderId: senderId,
          messageTime: messageTime,
        );
      }
    } catch (e) {
      print('Error handling message sent for streak: $e');
      rethrow;
    }
  }

  // Initialize a new streak
  Future<void> _initializeStreak({
    required String streakId,
    required List<String> participants,
    required String senderId,
    required DateTime messageTime,
  }) async {
    final senderIndex = participants.indexOf(senderId);
    final now = DateTime.now();
    final deadline = _calculateDeadline(messageTime);

    final streak = StreakModel(
      id: streakId,
      participants: participants,
      streakCount: 0, // Starts at 0, will increment when both users send
      lastMessageFromUser1: senderIndex == 0 ? messageTime : null,
      lastMessageFromUser2: senderIndex == 1 ? messageTime : null,
      streakStartDate: now,
      lastStreakIncrement: now,
      isActive: true,
      expiresAt: deadline,
      userDeadlines: {
        senderId: deadline,
        participants[senderIndex == 0 ? 1 : 0]:
            null, // Other user has no deadline yet
      },
    );

    await _firestore.collection('streaks').doc(streakId).set(streak.toMap());
    print('DEBUG Streak: Initialized new streak with deadline: $deadline');
  }

  // Update existing streak
  Future<void> _updateStreak({
    required StreakModel streak,
    required String senderId,
    required DateTime messageTime,
  }) async {
    final now = DateTime.now();
    final senderIndex = streak.participants.indexOf(senderId);
    final otherUserId = streak.participants[senderIndex == 0 ? 1 : 0];

    // Check if streak has expired
    if (streak.hasExpired) {
      print('DEBUG Streak: Streak has expired, resetting');
      await _resetStreak(streak.id, senderId, messageTime);
      return;
    }

    // Get current message timestamps
    DateTime? lastFromUser1 = streak.lastMessageFromUser1;
    DateTime? lastFromUser2 = streak.lastMessageFromUser2;

    // Update sender's last message time
    if (senderIndex == 0) {
      lastFromUser1 = messageTime;
    } else {
      lastFromUser2 = messageTime;
    }

    // Calculate new deadline for sender
    final senderDeadline = _calculateDeadline(messageTime);
    final updatedUserDeadlines = Map<String, DateTime?>.from(
      streak.userDeadlines,
    );
    updatedUserDeadlines[senderId] = senderDeadline;

    // Check if both users have sent messages since last increment
    final bothSentAfterLastIncrement =
        lastFromUser1 != null &&
        lastFromUser2 != null &&
        streak.lastStreakIncrement != null &&
        lastFromUser1.isAfter(streak.lastStreakIncrement!) &&
        lastFromUser2.isAfter(streak.lastStreakIncrement!);

    int newStreakCount = streak.streakCount;
    DateTime? newLastIncrement = streak.lastStreakIncrement;
    DateTime? newExpiresAt = streak.expiresAt;

    if (bothSentAfterLastIncrement) {
      // Check if we should increment streak (24 hours passed since last increment)
      final hoursSinceLastIncrement = now
          .difference(streak.lastStreakIncrement!)
          .inHours;

      if (hoursSinceLastIncrement >= 24) {
        newStreakCount++;
        newLastIncrement = now;
        print('DEBUG Streak: Incrementing streak to $newStreakCount');

        // Update expiration based on the most recent deadline
        final earliestDeadline =
            [senderDeadline, updatedUserDeadlines[otherUserId]]
                .where((d) => d != null)
                .cast<DateTime>()
                .reduce((a, b) => a.isBefore(b) ? a : b);
        newExpiresAt = earliestDeadline;
      }
    }

    // Update streak in Firestore
    final updatedStreak = streak.copyWith(
      lastMessageFromUser1: lastFromUser1,
      lastMessageFromUser2: lastFromUser2,
      streakCount: newStreakCount,
      lastStreakIncrement: newLastIncrement,
      expiresAt: newExpiresAt,
      userDeadlines: updatedUserDeadlines,
      isActive: true,
    );

    await _firestore
        .collection('streaks')
        .doc(streak.id)
        .set(updatedStreak.toMap());
    print(
      'DEBUG Streak: Updated streak - Count: $newStreakCount, Expires: $newExpiresAt',
    );
  }

  // Reset streak (when expired or after unfriend)
  Future<void> _resetStreak(
    String streakId,
    String senderId,
    DateTime messageTime,
  ) async {
    final doc = await _firestore.collection('streaks').doc(streakId).get();
    if (!doc.exists) return;

    final streak = StreakModel.fromMap(doc.data()!);
    final participants = streak.participants;
    final senderIndex = participants.indexOf(senderId);
    final now = DateTime.now();
    final deadline = _calculateDeadline(messageTime);

    final resetStreak = StreakModel(
      id: streakId,
      participants: participants,
      streakCount: 0,
      lastMessageFromUser1: senderIndex == 0 ? messageTime : null,
      lastMessageFromUser2: senderIndex == 1 ? messageTime : null,
      streakStartDate: now,
      lastStreakIncrement: now,
      isActive: true,
      expiresAt: deadline,
      userDeadlines: {
        senderId: deadline,
        participants[senderIndex == 0 ? 1 : 0]: null,
      },
    );

    await _firestore
        .collection('streaks')
        .doc(streakId)
        .set(resetStreak.toMap());
    print('DEBUG Streak: Reset streak and started fresh');
  }

  // Delete streak (when users unfriend)
  Future<void> deleteStreak(String userId1, String userId2) async {
    try {
      final streakId = _generateStreakId(userId1, userId2);
      await _firestore.collection('streaks').doc(streakId).delete();
      print('DEBUG Streak: Deleted streak between $userId1 and $userId2');
    } catch (e) {
      print('Error deleting streak: $e');
      rethrow;
    }
  }

  // Check and expire old streaks (call this periodically, e.g., on app start)
  Future<void> checkAndExpireStreaks() async {
    try {
      final currentUserId = UserService.currentUserId;
      if (currentUserId == null) return;

      print(
        'DEBUG Streak: Checking for expired streaks for user: $currentUserId',
      );

      final now = DateTime.now();

      // Get all active streaks where current user is a participant
      final snapshot = await _firestore
          .collection('streaks')
          .where('participants', arrayContains: currentUserId)
          .where('isActive', isEqualTo: true)
          .get();

      print(
        'DEBUG Streak: Found ${snapshot.docs.length} active streaks to check',
      );

      for (final doc in snapshot.docs) {
        final streak = StreakModel.fromMap(doc.data());

        if (streak.expiresAt != null && now.isAfter(streak.expiresAt!)) {
          print(
            'DEBUG Streak: Expiring streak ${streak.id} (was at ${streak.streakCount})',
          );

          // Mark streak as inactive but don't delete it
          await _firestore.collection('streaks').doc(streak.id).update({
            'isActive': false,
            'streakCount': 0,
          });
        }
      }
    } catch (e) {
      print('Error checking and expiring streaks: $e');
    }
  }

  // Get all active streaks for current user
  Future<List<StreakModel>> getUserStreaks() async {
    try {
      final currentUserId = UserService.currentUserId;
      if (currentUserId == null) return [];

      final snapshot = await _firestore
          .collection('streaks')
          .where('participants', arrayContains: currentUserId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => StreakModel.fromMap(doc.data()))
          .where(
            (streak) => streak.streakCount > 0,
          ) // Only return streaks with count > 0
          .toList();
    } catch (e) {
      print('Error getting user streaks: $e');
      return [];
    }
  }

  // Get all active streaks for current user as a stream
  Stream<List<StreakModel>> getUserStreaksStream() {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('streaks')
        .where('participants', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StreakModel.fromMap(doc.data()))
              .where((streak) => streak.streakCount > 0)
              .toList();
        });
  }

  // Get streak display info (for UI)
  Future<Map<String, dynamic>> getStreakDisplayInfo(
    String userId1,
    String userId2,
  ) async {
    try {
      final streak = await getStreak(userId1, userId2);

      if (streak == null || !streak.isActive || streak.streakCount == 0) {
        return {
          'hasStreak': false,
          'streakCount': 0,
          'showFire': false,
          'showHourglass': false,
          'emoji': '',
        };
      }

      // Determine emoji based on streak count
      String emoji = '🔥';
      if (streak.streakCount >= 100) {
        emoji = '💯';
      }

      return {
        'hasStreak': true,
        'streakCount': streak.streakCount,
        'showFire': streak.streakCount >= 3, // Show fire emoji after 3+ days
        'showHourglass': streak.isAboutToExpire,
        'emoji': emoji,
        'expiresAt': streak.expiresAt,
        'isAboutToExpire': streak.isAboutToExpire,
      };
    } catch (e) {
      print('Error getting streak display info: $e');
      return {
        'hasStreak': false,
        'streakCount': 0,
        'showFire': false,
        'showHourglass': false,
        'emoji': '',
      };
    }
  }

  // Get streak display info stream (for real-time updates)
  Stream<Map<String, dynamic>> getStreakDisplayInfoStream(
    String userId1,
    String userId2,
  ) {
    return getStreakStream(userId1, userId2).map((streak) {
      if (streak == null || !streak.isActive || streak.streakCount == 0) {
        return {
          'hasStreak': false,
          'streakCount': 0,
          'showFire': false,
          'showHourglass': false,
          'emoji': '',
        };
      }

      String emoji = '🔥';
      if (streak.streakCount >= 100) {
        emoji = '💯';
      }

      return {
        'hasStreak': true,
        'streakCount': streak.streakCount,
        'showFire': streak.streakCount >= 3,
        'showHourglass': streak.isAboutToExpire,
        'emoji': emoji,
        'expiresAt': streak.expiresAt,
        'isAboutToExpire': streak.isAboutToExpire,
      };
    });
  }

  // Get time remaining until streak expires
  String getTimeRemaining(DateTime? expiresAt) {
    if (expiresAt == null) return '';

    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) return 'Expired';

    if (difference.inHours >= 24) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Expiring soon';
    }
  }
}
