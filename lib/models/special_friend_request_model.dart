// models/special_friend_request_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SpecialFriendRequestStatus { pending, accepted, rejected }

class SpecialFriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final SpecialFriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  SpecialFriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
    };
  }

  factory SpecialFriendRequestModel.fromMap(
    Map<String, dynamic> map, {
    String? docId,
  }) {
    return SpecialFriendRequestModel(
      id: docId ?? map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: SpecialFriendRequestStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => SpecialFriendRequestStatus.pending,
      ),
      createdAt: _parseDateTime(map['createdAt']),
      respondedAt: map['respondedAt'] != null
          ? _parseDateTime(map['respondedAt'])
          : null,
    );
  }

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

  SpecialFriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    SpecialFriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return SpecialFriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  String toString() {
    return 'SpecialFriendRequestModel(id: $id, senderId: $senderId, receiverId: $receiverId, status: ${status.name}, createdAt: $createdAt)';
  }
}
