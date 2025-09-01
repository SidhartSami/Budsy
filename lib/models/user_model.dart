// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String username; // New field for unique username
  final String? photoUrl;
  final DateTime lastSeen;
  final bool isOnline;
  final List<String> friends;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.username,
    this.photoUrl,
    required this.lastSeen,
    required this.isOnline,
    required this.friends,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'username': username, // Include username in map
      'photoUrl': photoUrl,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'friends': friends,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      username: map['username'] ?? '', // Handle username from map
      photoUrl: map['photoUrl'],
      lastSeen: _parseDateTime(map['lastSeen']),
      isOnline: map['isOnline'] ?? false,
      friends: List<String>.from(map['friends'] ?? []),
    );
  }

  // Helper method to handle different timestamp formats
  static DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    if (timestamp is Timestamp) {
      // Firestore Timestamp object
      return timestamp.toDate();
    }

    if (timestamp is int) {
      // Milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    if (timestamp is String) {
      // ISO string format
      return DateTime.parse(timestamp);
    }

    // Fallback to current time
    return DateTime.now();
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? username,
    String? photoUrl,
    DateTime? lastSeen,
    bool? isOnline,
    List<String>? friends,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      friends: friends ?? this.friends,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, username: $username, isOnline: $isOnline)';
  }
}
