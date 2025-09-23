// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String username;
  final String? photoUrl;
  final DateTime lastSeen;
  final bool isOnline;
  final List<String> friends;
  final DateTime? birthDate;
  final bool showBirthDate;
  final bool showOnlineStatus;
  final bool profileCompleted;
  final String? bio;
  final bool isVerified;
  final DateTime? lastBioUpdate;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.username,
    this.photoUrl,
    required this.lastSeen,
    required this.isOnline,
    required this.friends,
    this.birthDate,
    this.showBirthDate = false,
    this.showOnlineStatus = true,
    this.profileCompleted = false,
    this.bio,
    this.isVerified = false,
    this.lastBioUpdate,
  });

  // Calculate age from birthdate
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  // Check if user meets minimum age requirement (16)
  bool get meetsAgeRequirement {
    return age != null && age! >= 16;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'username': username,
      'photoUrl': photoUrl,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'friends': friends,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'showBirthDate': showBirthDate,
      'showOnlineStatus': showOnlineStatus,
      'profileCompleted': profileCompleted,
      'bio': bio,
      'isVerified': isVerified,
      'lastBioUpdate': lastBioUpdate != null
          ? Timestamp.fromDate(lastBioUpdate!)
          : null,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      username: map['username'] ?? '',
      photoUrl: map['photoUrl'],
      lastSeen: _parseDateTime(map['lastSeen']),
      isOnline: map['isOnline'] ?? false,
      friends: List<String>.from(map['friends'] ?? []),
      birthDate: map['birthDate'] != null
          ? _parseDateTime(map['birthDate'])
          : null,
      showBirthDate: map['showBirthDate'] ?? false,
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      profileCompleted: map['profileCompleted'] ?? false,
      bio: map['bio'],
      isVerified: map['isVerified'] ?? false,
      lastBioUpdate: map['lastBioUpdate'] != null
          ? _parseDateTime(map['lastBioUpdate'])
          : null,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return UserModel.fromMap(data);
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

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? username,
    String? photoUrl,
    DateTime? lastSeen,
    bool? isOnline,
    List<String>? friends,
    DateTime? birthDate,
    bool? showBirthDate,
    bool? showOnlineStatus,
    bool? profileCompleted,
    String? bio,
    bool? isVerified,
    DateTime? lastBioUpdate,
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
      birthDate: birthDate ?? this.birthDate,
      showBirthDate: showBirthDate ?? this.showBirthDate,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      lastBioUpdate: lastBioUpdate ?? this.lastBioUpdate,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, username: $username, isOnline: $isOnline, age: $age, bio: ${bio?.substring(0, bio!.length < 20 ? bio!.length : 20)}...)';
  }
}
