// lib/models/chat_model.dart
class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String chatType; // 'private' or 'group'
  final String? chatName; // for group chats
  final Map<String, int> unreadCount; // userId -> count

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    required this.chatType,
    this.chatName,
    required this.unreadCount,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      chatType: map['chatType'] ?? 'private',
      chatName: map['chatName'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'chatType': chatType,
      'chatName': chatName,
      'unreadCount': unreadCount,
    };
  }
}
