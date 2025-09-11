// lib/models/chat_settings_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSettingsModel {
  final String id; // chatId_userId format
  final String chatId;
  final String userId;
  final String? nickname; // Custom nickname for the other user
  final bool isMuted;
  final bool isBlocked;
  final String chatTheme; // Theme identifier
  final DateTime? mutedUntil; // For temporary muting
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSettingsModel({
    required this.id,
    required this.chatId,
    required this.userId,
    this.nickname,
    this.isMuted = false,
    this.isBlocked = false,
    this.chatTheme = 'default',
    this.mutedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'userId': userId,
      'nickname': nickname,
      'isMuted': isMuted,
      'isBlocked': isBlocked,
      'chatTheme': chatTheme,
      'mutedUntil': mutedUntil != null ? Timestamp.fromDate(mutedUntil!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ChatSettingsModel.fromMap(Map<String, dynamic> map) {
    return ChatSettingsModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      userId: map['userId'] ?? '',
      nickname: map['nickname'],
      isMuted: map['isMuted'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      chatTheme: map['chatTheme'] ?? 'default',
      mutedUntil: map['mutedUntil'] != null
          ? (map['mutedUntil'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  ChatSettingsModel copyWith({
    String? id,
    String? chatId,
    String? userId,
    String? nickname,
    bool? isMuted,
    bool? isBlocked,
    String? chatTheme,
    DateTime? mutedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSettingsModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      isMuted: isMuted ?? this.isMuted,
      isBlocked: isBlocked ?? this.isBlocked,
      chatTheme: chatTheme ?? this.chatTheme,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isTemporarilyMuted {
    if (!isMuted || mutedUntil == null) return false;
    return DateTime.now().isBefore(mutedUntil!);
  }

  @override
  String toString() {
    return 'ChatSettingsModel(id: $id, chatId: $chatId, userId: $userId, nickname: $nickname, isMuted: $isMuted, isBlocked: $isBlocked, chatTheme: $chatTheme)';
  }
}

// Chat Statistics Model
class ChatStatsModel {
  final String id; // chatId_userId format
  final String chatId;
  final String userId;
  final int messagesSent;
  final int messagesReceived;
  final DateTime? firstMessageDate;
  final DateTime? lastMessageDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatStatsModel({
    required this.id,
    required this.chatId,
    required this.userId,
    this.messagesSent = 0,
    this.messagesReceived = 0,
    this.firstMessageDate,
    this.lastMessageDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'userId': userId,
      'messagesSent': messagesSent,
      'messagesReceived': messagesReceived,
      'firstMessageDate': firstMessageDate != null
          ? Timestamp.fromDate(firstMessageDate!)
          : null,
      'lastMessageDate': lastMessageDate != null
          ? Timestamp.fromDate(lastMessageDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ChatStatsModel.fromMap(Map<String, dynamic> map) {
    return ChatStatsModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      userId: map['userId'] ?? '',
      messagesSent: map['messagesSent'] ?? 0,
      messagesReceived: map['messagesReceived'] ?? 0,
      firstMessageDate: map['firstMessageDate'] != null
          ? (map['firstMessageDate'] as Timestamp).toDate()
          : null,
      lastMessageDate: map['lastMessageDate'] != null
          ? (map['lastMessageDate'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  int get totalMessages => messagesSent + messagesReceived;

  ChatStatsModel copyWith({
    String? id,
    String? chatId,
    String? userId,
    int? messagesSent,
    int? messagesReceived,
    DateTime? firstMessageDate,
    DateTime? lastMessageDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatStatsModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      messagesSent: messagesSent ?? this.messagesSent,
      messagesReceived: messagesReceived ?? this.messagesReceived,
      firstMessageDate: firstMessageDate ?? this.firstMessageDate,
      lastMessageDate: lastMessageDate ?? this.lastMessageDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ChatStatsModel(id: $id, chatId: $chatId, userId: $userId, messagesSent: $messagesSent, messagesReceived: $messagesReceived, totalMessages: $totalMessages)';
  }
}
