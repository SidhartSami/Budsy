// models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: _parseDateTime(map['timestamp']),
      isRead: map['isRead'] ?? false,
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
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

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
    );
  }
}
