// models/interaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum InteractionType {
  missYou('Miss You', '💙'),
  loveYou('Love You', '❤️'),
  thinkingOfYou('Thinking of You', '💭'),
  hug('Hug', '🤗'),
  kiss('Kiss', '😘'),
  custom('Custom', '✨');

  const InteractionType(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

class InteractionModel {
  final String id;
  final String senderId;
  final String receiverId;
  final InteractionType type;
  final String? customMessage;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final String? response; // Response from receiver
  final DateTime? respondedAt;

  InteractionModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    this.customMessage,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.response,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.name,
      'customMessage': customMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'response': response,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  factory InteractionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return InteractionModel(
      id: docId ?? map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      type: InteractionType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => InteractionType.custom,
      ),
      customMessage: map['customMessage'],
      createdAt: _parseDateTime(map['createdAt']),
      isRead: map['isRead'] ?? false,
      readAt: map['readAt'] != null ? _parseDateTime(map['readAt']) : null,
      response: map['response'],
      respondedAt: map['respondedAt'] != null ? _parseDateTime(map['respondedAt']) : null,
    );
  }

  factory InteractionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InteractionModel.fromMap(data, docId: doc.id);
  }

  // Helper method to handle different timestamp formats
  static DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

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

  InteractionModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    InteractionType? type,
    String? customMessage,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    String? response,
    DateTime? respondedAt,
  }) {
    return InteractionModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      customMessage: customMessage ?? this.customMessage,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      response: response ?? this.response,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  // Get display text for the interaction
  String get displayText {
    if (type == InteractionType.custom && customMessage != null) {
      return customMessage!;
    }
    return type.displayName;
  }

  // Get display emoji for the interaction
  String get displayEmoji {
    return type.emoji;
  }

  @override
  String toString() {
    return 'InteractionModel(id: $id, senderId: $senderId, receiverId: $receiverId, type: ${type.name}, createdAt: $createdAt)';
  }
}

// Model for daily interaction counts between two users
class DailyInteractionCount {
  final String id; // Format: "userId1_userId2_YYYY-MM-DD"
  final String user1Id;
  final String user2Id;
  final DateTime date;
  final int user1Count; // Interactions sent by user1 to user2
  final int user2Count; // Interactions sent by user2 to user1
  final DateTime lastUpdated;

  DailyInteractionCount({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.date,
    this.user1Count = 0,
    this.user2Count = 0,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'date': Timestamp.fromDate(date),
      'user1Count': user1Count,
      'user2Count': user2Count,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  factory DailyInteractionCount.fromMap(Map<String, dynamic> map, {String? docId}) {
    return DailyInteractionCount(
      id: docId ?? map['id'] ?? '',
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      date: InteractionModel._parseDateTime(map['date']),
      user1Count: map['user1Count'] ?? 0,
      user2Count: map['user2Count'] ?? 0,
      lastUpdated: InteractionModel._parseDateTime(map['lastUpdated']),
    );
  }

  factory DailyInteractionCount.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DailyInteractionCount.fromMap(data, docId: doc.id);
  }

  // Generate ID for a daily count document
  static String generateId(String userId1, String userId2, DateTime date) {
    // Ensure consistent ordering of user IDs
    final users = [userId1, userId2]..sort();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${users[0]}_${users[1]}_$dateStr';
  }

  // Get count for a specific user
  int getCountForUser(String userId) {
    if (userId == user1Id) return user1Count;
    if (userId == user2Id) return user2Count;
    return 0;
  }

  // Get total interactions for the day
  int get totalCount => user1Count + user2Count;

  DailyInteractionCount copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    DateTime? date,
    int? user1Count,
    int? user2Count,
    DateTime? lastUpdated,
  }) {
    return DailyInteractionCount(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      date: date ?? this.date,
      user1Count: user1Count ?? this.user1Count,
      user2Count: user2Count ?? this.user2Count,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'DailyInteractionCount(id: $id, user1Count: $user1Count, user2Count: $user2Count, date: $date)';
  }
}
