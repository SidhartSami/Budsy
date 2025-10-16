// models/streak_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StreakModel {
  final String id; // Format: userId1_userId2 (sorted alphabetically)
  final List<String> participants; // [userId1, userId2] sorted
  final int streakCount;
  final DateTime? lastMessageFromUser1; // Last message timestamp from user1
  final DateTime? lastMessageFromUser2; // Last message timestamp from user2
  final DateTime? streakStartDate; // When the streak started
  final DateTime? lastStreakIncrement; // Last time streak was incremented
  final bool isActive; // Whether streak is currently active
  final DateTime? expiresAt; // When the streak will expire if no message sent
  final Map<String, DateTime?>
  userDeadlines; // Individual deadlines for each user

  StreakModel({
    required this.id,
    required this.participants,
    this.streakCount = 0,
    this.lastMessageFromUser1,
    this.lastMessageFromUser2,
    this.streakStartDate,
    this.lastStreakIncrement,
    this.isActive = false,
    this.expiresAt,
    this.userDeadlines = const {},
  });

  // Check if streak is about to expire (less than 4 hours remaining)
  bool get isAboutToExpire {
    if (expiresAt == null) return false;
    final now = DateTime.now();
    final timeRemaining = expiresAt!.difference(now);
    return timeRemaining.inHours < 4 && timeRemaining.inMinutes > 0;
  }

  // Check if streak has expired
  bool get hasExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Get the deadline for a specific user
  DateTime? getDeadlineForUser(String userId) {
    return userDeadlines[userId];
  }

  // Get the most recent message time from either user
  DateTime? get lastMessageTime {
    if (lastMessageFromUser1 == null && lastMessageFromUser2 == null) {
      return null;
    }
    if (lastMessageFromUser1 == null) return lastMessageFromUser2;
    if (lastMessageFromUser2 == null) return lastMessageFromUser1;

    return lastMessageFromUser1!.isAfter(lastMessageFromUser2!)
        ? lastMessageFromUser1
        : lastMessageFromUser2;
  }

  // Check if a user has sent their message for the current period
  bool hasUserSentMessage(String userId) {
    if (lastStreakIncrement == null) return false;

    final userIndex = participants.indexOf(userId);
    if (userIndex == -1) return false;

    final lastMessage = userIndex == 0
        ? lastMessageFromUser1
        : lastMessageFromUser2;
    if (lastMessage == null) return false;

    // Check if user sent a message after the last streak increment
    return lastMessage.isAfter(lastStreakIncrement!);
  }

  // Check if both users have sent messages for the current period
  bool get bothUsersSentMessages {
    if (lastStreakIncrement == null) return false;
    if (lastMessageFromUser1 == null || lastMessageFromUser2 == null)
      return false;

    return lastMessageFromUser1!.isAfter(lastStreakIncrement!) &&
        lastMessageFromUser2!.isAfter(lastStreakIncrement!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'streakCount': streakCount,
      'lastMessageFromUser1': lastMessageFromUser1 != null
          ? Timestamp.fromDate(lastMessageFromUser1!)
          : null,
      'lastMessageFromUser2': lastMessageFromUser2 != null
          ? Timestamp.fromDate(lastMessageFromUser2!)
          : null,
      'streakStartDate': streakStartDate != null
          ? Timestamp.fromDate(streakStartDate!)
          : null,
      'lastStreakIncrement': lastStreakIncrement != null
          ? Timestamp.fromDate(lastStreakIncrement!)
          : null,
      'isActive': isActive,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'userDeadlines': userDeadlines.map(
        (key, value) =>
            MapEntry(key, value != null ? Timestamp.fromDate(value) : null),
      ),
    };
  }

  factory StreakModel.fromMap(Map<String, dynamic> map) {
    return StreakModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      streakCount: map['streakCount'] ?? 0,
      lastMessageFromUser1: map['lastMessageFromUser1'] != null
          ? _parseDateTime(map['lastMessageFromUser1'])
          : null,
      lastMessageFromUser2: map['lastMessageFromUser2'] != null
          ? _parseDateTime(map['lastMessageFromUser2'])
          : null,
      streakStartDate: map['streakStartDate'] != null
          ? _parseDateTime(map['streakStartDate'])
          : null,
      lastStreakIncrement: map['lastStreakIncrement'] != null
          ? _parseDateTime(map['lastStreakIncrement'])
          : null,
      isActive: map['isActive'] ?? false,
      expiresAt: map['expiresAt'] != null
          ? _parseDateTime(map['expiresAt'])
          : null,
      userDeadlines:
          (map['userDeadlines'] as Map<String, dynamic>?)?.map(
            (key, value) =>
                MapEntry(key, value != null ? _parseDateTime(value) : null),
          ) ??
          {},
    );
  }

  static DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }

    return DateTime.now();
  }

  StreakModel copyWith({
    String? id,
    List<String>? participants,
    int? streakCount,
    DateTime? lastMessageFromUser1,
    DateTime? lastMessageFromUser2,
    DateTime? streakStartDate,
    DateTime? lastStreakIncrement,
    bool? isActive,
    DateTime? expiresAt,
    Map<String, DateTime?>? userDeadlines,
  }) {
    return StreakModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      streakCount: streakCount ?? this.streakCount,
      lastMessageFromUser1: lastMessageFromUser1 ?? this.lastMessageFromUser1,
      lastMessageFromUser2: lastMessageFromUser2 ?? this.lastMessageFromUser2,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      lastStreakIncrement: lastStreakIncrement ?? this.lastStreakIncrement,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      userDeadlines: userDeadlines ?? this.userDeadlines,
    );
  }

  @override
  String toString() {
    return 'StreakModel(id: $id, streakCount: $streakCount, isActive: $isActive, expiresAt: $expiresAt)';
  }
}
